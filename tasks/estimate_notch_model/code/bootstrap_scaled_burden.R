# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")
# variant <- "all_filings"
# model <- "scaled_burden"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(parallel)
  library(readr)
  library(tibble)
  library(tidyr)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 2L)
  variant <- args[1]
  model <- args[2]
}
stopifnot(model %in% c("scaled_burden", "lot_count_splitting", "site_lot_splitting"))
maximum_units <- 300

# Bootstrap intervals for the main model, the scaled burden of
# fit_heterogeneity.R: each parent's jump is multiplied by one lognormal scale
# with median 1, so kappa is the median jump. Every sample of
# draw_bootstrap_samples.R is re-estimated by likelihood on the full grid of
# median jumps, spreads, gamma, sigma and the unexplained share epsilon. The
# model's choices do not depend on the weights, so one pass scores every draw;
# the values of gamma run in parallel. The variant of the sample is
# all_filings for the main estimate, or a check (horizon_180, cohort_2025,
# placebo, history_2014, zoning_lot_recorded). The models lot_count_splitting
# and site_lot_splitting are the variants of fit_heterogeneity.R that fit recent
# parents on one lot and on several separately, each against the historical
# parents of the same group, with mean splitting cost sigma * exp(-beta) on
# several lots, counted as starting lots or as site lots within 180 days; the
# scaled burden is their case of one group and beta = 0.
parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == !!variant)
stopifnot(nrow(parents) > 0L)
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy")
x <- historical$units
J0 <- historical$buildings

cells <- cells_up_to(maximum_units)
samples <- read_parquet(paste0("../output/bootstrap_samples_", variant, ".parquet"))
draws <- max(samples$draw)
W <- bootstrap_weights(samples, historical)
lots <- c(scaled_burden = NA, lot_count_splitting = "starting_lots", site_lot_splitting = "site_lots")[[model]]
by_lots <- !is.na(lots)
group <- if (by_lots) 1L + (historical[[lots]] >= 2) else rep(1L, length(x))
post_group <- if (by_lots) 1L + (post[[lots]] >= 2) else rep(1L, nrow(post))
groups <- max(group)
betas <- if (by_lots) lot_count_grid else 0
compared <- post |> mutate(group = post_group) |> filter(units <= maximum_units)
n <- do.call(rbind, lapply(seq_len(groups), function(g) {
  bootstrap_counts(samples, compared |> filter(group == g), cells)
}))
cell_group <- rep(seq_len(groups), each = length(cells))
stopifnot(max(abs(W[, 1] - historical$weight_zoning_borough)) < 1e-10,
  sum(n[, 1]) == sum(post$units <= maximum_units), !anyNA(group), !anyNA(post_group))

post_parents <- colSums(n)
observed_cells <- which(rowSums(n) > 0)
uniform <- rep(unexplained_shares(cells), groups)
unit_weight <- W * (x <= maximum_units)
unit_weight <- unit_weight / rep(colSums(unit_weight), each = length(x))
benchmark_units <- post_parents * colSums(unit_weight * x)
candidates <- size_candidates(x, J0, 1, "separate")

# The best point of every draw at one gamma and one beta. At each sigma, the
# shares at every jump are averaged over each distribution, renormalized over
# the compared cells of each group, and scored at the best epsilon; ties keep
# the first sigma and distribution, and across jobs the first gamma and beta.
sizes <- lapply(kappa_values, function(kappa) {
  choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, "separate"))
})
fit_gamma <- function(gamma, beta) {
  scale <- splitting_scale(as.numeric(group == 2L), beta, 0)
  best <- tibble(draw = 0:draws, log_likelihood = -Inf, gamma = gamma, sigma = NA_real_,
    distribution = NA_integer_, epsilon = NA_real_, units_lost = NA_real_)
  levels <- lapply(sizes, function(level_sizes) {
    segments <- organization_segments(level_sizes, J0, gamma)
    probabilities <- segment_probabilities(segments, sigma_grid, scale[segments$i])
    by_parent_cell <- rowsum(probabilities, (outcome_cell(segments$m, segments$J) - 1L) * length(x) + segments$i)
    key <- as.integer(rownames(by_parent_cell)) - 1L
    parent <- key %% length(x) + 1L
    list(by_parent_cell = by_parent_cell, parent = parent,
      cell = match(key %/% length(x) + 1L, cells) + length(cells) * (group[parent] - 1L),
      lost = benchmark_units - post_parents * crossprod(unit_weight, rowsum(probabilities * segments$m, segments$i)))
  })
  for (s in seq_along(sigma_grid)) {
    by_level <- t(sapply(levels, function(level) {
      kept <- !is.na(level$cell)
      shares <- matrix(0, length(cell_group), ncol(W))
      summed <- rowsum(level$by_parent_cell[kept, s] * W[level$parent[kept], , drop = FALSE], level$cell[kept])
      shares[as.integer(rownames(summed)), ] <- summed
      as.vector(shares)
    }))
    mixed <- array(burden_mass %*% by_level, c(nrow(burden_mass), length(cell_group), ncol(W)))
    totals <- sapply(seq_len(groups), function(g) apply(mixed[, cell_group == g, , drop = FALSE], c(1, 3), sum),
      simplify = "array")
    score <- matrix(-Inf, nrow(burden_mass), ncol(W))
    at_epsilon <- matrix(NA_integer_, nrow(burden_mass), ncol(W))
    for (e in seq_along(epsilon_grid)) {
      log_likelihood <- 0
      for (c in observed_cells) {
        log_likelihood <- log_likelihood + rep(n[c, ], each = nrow(burden_mass)) *
          log((1 - epsilon_grid[e]) * mixed[, c, ] / totals[, , cell_group[c]] + epsilon_grid[e] * uniform[c])
      }
      better <- log_likelihood > score
      score[better] <- log_likelihood[better]
      at_epsilon[better] <- e
    }
    distribution <- apply(score, 2, which.max)
    chosen <- cbind(distribution, seq_len(ncol(W)))
    lost <- burden_mass %*% t(do.call(cbind, lapply(levels, function(level) level$lost[, s])))
    improved <- score[chosen] > best$log_likelihood
    best[improved, -1] <- tibble(log_likelihood = score[chosen], gamma = gamma, sigma = sigma_grid[s],
      distribution = distribution, epsilon = epsilon_grid[at_epsilon[chosen]], units_lost = lost[chosen])[improved, ]
  }
  best |> mutate(lot_count_elasticity = beta)
}
jobs <- expand_grid(beta = betas, gamma = gamma_grid)
by_job <- mclapply(seq_len(nrow(jobs)), function(j) fit_gamma(jobs$gamma[j], jobs$beta[j]),
  mc.cores = min(nrow(jobs), detectCores() - 2L))
stopifnot(!vapply(by_job, inherits, logical(1), "try-error"))

bootstrap_draws <- bind_rows(by_job) |>
  group_by(draw) |>
  slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(kappa = burden_distributions$median[distribution], dispersion = burden_distributions$dispersion[distribution],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[distribution],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[distribution],
    post_parents = post_parents[draw + 1L]) |>
  select(draw, kappa, dispersion, gamma, sigma, any_of(if (by_lots) "lot_count_elasticity"), epsilon,
    share_jump_below_0.01, share_jump_above_1, units_lost, log_likelihood, post_parents)

# For the main sample, draw 0 reproduces the estimate of fit_heterogeneity.R.
if (variant == "all_filings") {
  estimate <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE) |>
    filter(model == c(scaled_burden = "scaled_burden", lot_count_splitting = "scaled_burden_lot_count_splitting",
      site_lot_splitting = "scaled_burden_site_lot_splitting")[[!!model]])
  data_draw <- bootstrap_draws |> filter(draw == 0L)
  stopifnot(abs(data_draw$log_likelihood - estimate$log_likelihood) < 1e-8,
    abs(data_draw$units_lost - estimate$units_lost) < 1e-6)
}

parameters <- c("kappa", "dispersion", "gamma", "sigma", if (by_lots) "lot_count_elasticity", "epsilon",
  "share_jump_below_0.01", "share_jump_above_1", "units_lost")
bootstrap_estimates <- bootstrap_draws |>
  pivot_longer(all_of(parameters), names_to = "parameter") |>
  group_by(parameter) |>
  summarise(estimate = value[draw == 0L],
    bootstrap_lower = quantile(value[draw > 0L], 0.025, type = 1),
    bootstrap_median = quantile(value[draw > 0L], 0.5, type = 1),
    bootstrap_upper = quantile(value[draw > 0L], 0.975, type = 1),
    share_draws_at_estimate = mean(value[draw > 0L] == estimate), draws = sum(draw > 0L), .groups = "drop") |>
  arrange(match(parameter, parameters))

print(bootstrap_estimates, width = Inf)
SaveData(bootstrap_draws, "draw", paste0("../output/", model, "_bootstrap_draws_", variant, ".csv"))
SaveData(bootstrap_estimates, "parameter", paste0("../output/", model, "_bootstrap_estimates_", variant, ".csv"))

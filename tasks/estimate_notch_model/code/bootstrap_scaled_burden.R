# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")
# variant <- "all_filings"

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
  stopifnot(length(args) == 1L)
  variant <- args[1]
}
maximum_units <- 300

# Bootstrap intervals for the main model of fit_heterogeneity.R, estimated
# the same way in every sample of draw_bootstrap_samples.R: first on the full
# grid of median jumps, spreads, gamma, sigma and the unexplained share
# epsilon, then refined off the grid. The model's choices do not depend on the
# weights, so one pass over the grid scores every draw, with the values of
# gamma in parallel. The variant of the sample is all_filings for the main
# estimate, or a check (horizon_180, cohort_2025, placebo, history_2014).
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
n <- bootstrap_counts(samples, post |> filter(units <= maximum_units), cells)
stopifnot(max(abs(W[, 1] - historical$weight_zoning_borough)) < 1e-10,
  sum(n[, 1]) == sum(post$units <= maximum_units))

post_parents <- colSums(n)
observed_cells <- which(rowSums(n) > 0)
uniform <- unexplained_shares(cells)
unit_weight <- W * (x <= maximum_units)
unit_weight <- unit_weight / rep(colSums(unit_weight), each = length(x))
benchmark_units <- post_parents * colSums(unit_weight * x)
candidates <- size_candidates(x, J0, 1, "separate")

# The best grid point of every draw at one gamma. At each sigma, the shares at
# every jump are averaged over each distribution, renormalized over the
# compared cells, and scored at the best epsilon; ties keep the first sigma and
# distribution, and across gammas the first gamma.
sizes <- lapply(kappa_values, function(kappa) {
  choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, "separate"))
})
fit_gamma <- function(gamma) {
  best <- tibble(draw = 0:draws, log_likelihood = -Inf, gamma = gamma, sigma = NA_real_,
    distribution = NA_integer_, epsilon = NA_real_, units_lost = NA_real_)
  levels <- lapply(sizes, function(level_sizes) {
    segments <- organization_segments(level_sizes, J0, gamma)
    probabilities <- segment_probabilities(segments, sigma_grid)
    by_parent_cell <- rowsum(probabilities, (outcome_cell(segments$m, segments$J) - 1L) * length(x) + segments$i)
    key <- as.integer(rownames(by_parent_cell)) - 1L
    list(by_parent_cell = by_parent_cell, parent = key %% length(x) + 1L,
      cell = match(key %/% length(x) + 1L, cells),
      lost = benchmark_units - post_parents * crossprod(unit_weight, rowsum(probabilities * segments$m, segments$i)))
  })
  for (s in seq_along(sigma_grid)) {
    by_level <- t(sapply(levels, function(level) {
      kept <- !is.na(level$cell)
      shares <- matrix(0, length(cells), ncol(W))
      summed <- rowsum(level$by_parent_cell[kept, s] * W[level$parent[kept], , drop = FALSE], level$cell[kept])
      shares[as.integer(rownames(summed)), ] <- summed
      as.vector(shares)
    }))
    mixed <- array(burden_mass %*% by_level, c(nrow(burden_mass), length(cells), ncol(W)))
    totals <- apply(mixed, c(1, 3), sum)
    score <- matrix(-Inf, nrow(burden_mass), ncol(W))
    at_epsilon <- matrix(NA_integer_, nrow(burden_mass), ncol(W))
    for (e in seq_along(epsilon_grid)) {
      log_likelihood <- 0
      for (c in observed_cells) {
        log_likelihood <- log_likelihood + rep(n[c, ], each = nrow(burden_mass)) *
          log((1 - epsilon_grid[e]) * mixed[, c, ] / totals + epsilon_grid[e] * uniform[c])
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
  best
}
by_gamma <- mclapply(gamma_grid, fit_gamma, mc.cores = min(length(gamma_grid), detectCores() - 2L))
stopifnot(!vapply(by_gamma, inherits, logical(1), "try-error"))

grid_draws <- bind_rows(by_gamma) |>
  group_by(draw) |>
  slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(kappa = burden_distributions$median[distribution], dispersion = burden_distributions$dispersion[distribution],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[distribution],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[distribution])

# Each draw refined off the grid as the main estimate is: from its grid point,
# at each gamma, keeping the grid point if it fits better.
segments_by_gamma <- lapply(gamma_grid, function(gamma) level_segments(sizes, J0, gamma, cells))
refine_draw <- function(d) {
  grid_point <- grid_draws |> filter(draw == d)
  refined <- refine_scaled_burden(grid_point, segments_by_gamma, x, W[, d + 1L], n[, d + 1L], uniform,
    unit_weight[, d + 1L])
  stopifnot(all(refined$converged))
  refined <- refined |> slice_max(log_likelihood, n = 1, with_ties = FALSE) |> mutate(draw = d)
  if (refined$log_likelihood > grid_point$log_likelihood) refined else grid_point
}
by_draw <- mclapply(0:draws, refine_draw, mc.cores = detectCores() - 2L)
stopifnot(!vapply(by_draw, inherits, logical(1), "try-error"))
bootstrap_draws <- bind_rows(lapply(by_draw, function(d) {
  d |> select(draw, kappa, dispersion, gamma, sigma, epsilon, share_jump_below_0.01, share_jump_above_1, units_lost,
    log_likelihood)
})) |>
  mutate(post_parents = post_parents[draw + 1L])

# For the main sample, draw 0 reproduces the scaled-burden estimate of
# fit_heterogeneity.R.
if (variant == "all_filings") {
  estimate <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE) |>
    filter(model == "scaled_burden")
  data_draw <- bootstrap_draws |> filter(draw == 0L)
  stopifnot(abs(data_draw$log_likelihood - estimate$log_likelihood) < 1e-6,
    abs(data_draw$units_lost - estimate$units_lost) < 1e-3)
}

parameters <- c("kappa", "dispersion", "gamma", "sigma", "epsilon",
  "share_jump_below_0.01", "share_jump_above_1", "units_lost")
bootstrap_estimates <- bootstrap_draws |>
  pivot_longer(all_of(parameters), names_to = "parameter") |>
  group_by(parameter) |>
  summarise(estimate = value[draw == 0L],
    bootstrap_lower = quantile(value[draw > 0L], 0.025, type = 1),
    bootstrap_median = quantile(value[draw > 0L], 0.5, type = 1),
    bootstrap_upper = quantile(value[draw > 0L], 0.975, type = 1),
    draws = sum(draw > 0L), .groups = "drop") |>
  arrange(match(parameter, parameters))

print(bootstrap_estimates, width = Inf)
SaveData(bootstrap_draws, "draw", paste0("../output/scaled_burden_bootstrap_draws_", variant, ".csv"))
SaveData(bootstrap_estimates, "parameter", paste0("../output/scaled_burden_bootstrap_estimates_", variant, ".csv"))

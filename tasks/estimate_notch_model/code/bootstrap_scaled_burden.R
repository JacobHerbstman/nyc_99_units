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

# Bootstrap intervals for the main model, the scaled burden of
# fit_heterogeneity.R: each parent's jump and kink are multiplied by one
# lognormal scale with median 1, so kappa and tau describe the median parent.
# Every sample of draw_bootstrap_samples.R is re-estimated by likelihood on the
# full grid of kink-to-jump ratios, median jumps, spreads, gamma, sigma and the
# unexplained share epsilon. The model's choices do not depend on the weights,
# so one pass scores every draw; the ratios run in parallel. The variant of the
# sample is all_filings for the main estimate, or a check (horizon_180,
# cohort_2025, placebo, history_2014).
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

# The best point of every draw along one kink-to-jump ratio. At each gamma and
# sigma, the shares at every burden level are averaged over each distribution,
# renormalized over the compared cells, and scored at the best epsilon; ties
# keep the first gamma, sigma and distribution.
fit_ratio <- function(r) {
  sizes <- lapply(kappa_values, function(kappa) {
    choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, ratio_grid[r] * kappa, 1, "separate"))
  })
  best <- tibble(draw = 0:draws, log_likelihood = -Inf, gamma = NA_real_, sigma = NA_real_,
    distribution = NA_integer_, epsilon = NA_real_, units_lost = NA_real_)
  for (gamma in gamma_grid) {
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
      lost <- burden_mass %*% t(sapply(levels, function(level) level$lost[, s]))
      improved <- score[chosen] > best$log_likelihood
      best[improved, -1] <- tibble(log_likelihood = score[chosen], gamma = gamma, sigma = sigma_grid[s],
        distribution = distribution, epsilon = epsilon_grid[at_epsilon[chosen]], units_lost = lost[chosen])[improved, ]
    }
  }
  best |> mutate(ray = r)
}
by_ratio <- mclapply(seq_along(ratio_grid), fit_ratio, mc.cores = min(length(ratio_grid), detectCores() - 2L))
stopifnot(!vapply(by_ratio, inherits, logical(1), "try-error"))

bootstrap_draws <- bind_rows(by_ratio) |>
  group_by(draw) |>
  slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(kink_to_jump = ratio_grid[ray], kappa = burden_distributions$median[distribution],
    tau = kink_to_jump * kappa, dispersion = burden_distributions$dispersion[distribution],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[distribution],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[distribution],
    post_parents = post_parents[draw + 1L]) |>
  select(draw, kappa, tau, kink_to_jump, dispersion, gamma, sigma, epsilon, share_jump_below_0.01,
    share_jump_above_1, units_lost, log_likelihood, post_parents)

# For the main sample, draw 0 reproduces the scaled-burden estimate of
# fit_heterogeneity.R.
if (variant == "all_filings") {
  estimate <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE) |>
    filter(model == "scaled_burden")
  data_draw <- bootstrap_draws |> filter(draw == 0L)
  stopifnot(abs(data_draw$log_likelihood - estimate$log_likelihood) < 1e-8,
    abs(data_draw$units_lost - estimate$units_lost) < 1e-6)
}

parameters <- c("kappa", "tau", "kink_to_jump", "dispersion", "gamma", "sigma", "epsilon",
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
SaveData(bootstrap_draws, "draw", paste0("../output/scaled_burden_bootstrap_draws_", variant, ".csv"))
SaveData(bootstrap_estimates, "parameter", paste0("../output/scaled_burden_bootstrap_estimates_", variant, ".csv"))

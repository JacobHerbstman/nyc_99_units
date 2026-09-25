# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

maximum_units <- 300

# Departures from a single burden, estimated by likelihood with the
# unexplained share epsilon of bootstrap_notch_model.R:
#   non-optimizers      a share pi of parents keeps its 2019-2022 outcome, as
#                       if the threshold did not reach it (Kleven and Waseem
#                       2013); they lose no units;
#   heterogeneous jump  the jump differs across parents, lognormal with median
#                       kappa and log standard deviation s; the kink is common;
#   scaled burden       each parent's whole burden, jump and kink, is scaled by
#                       b, lognormal with median 1 and log standard deviation s,
#                       as a gap between required and usual wages would scale
#                       it; kappa and tau describe the median parent.
# Each nests the main model (pi = 0, s = 0); non-optimizers and the
# heterogeneous jump are also combined. Distributions sit on the kappa grid,
# extended to 5, where every parent of at most 300 units avoids 100: each value
# takes the probability between the midpoints to its neighbors, so a
# prediction is a weighted average of predictions at single burdens. Scaling
# keeps the kink-to-jump ratio, so the scaled burden averages along the burden
# levels of one ratio.
kappa_values <- c(kappa_grid, 1.5, 2, 3, 5)
ratio_grid <- c(0, 0.1, 0.2, 0.3, 0.5, 0.75, 1, 1.5, 2, 3, 5, 8)
dispersion_grid <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 4)
pi_grid <- c(0, 0.01, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2, 0.3)
epsilon_grid <- c(0.001, 0.0025, 0.005, 0.0075, 0.01, 0.015, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2)

parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == "all_filings")
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy", units <= maximum_units)
x <- historical$units
J0 <- historical$buildings
w <- historical$weight_zoning_borough

cells <- cells_up_to(maximum_units)
n <- tabulate(outcome_cell(post$units, post$buildings), 45L)[cells]
observed_cells <- which(n > 0)
width <- pmax(0, size_bins[-1] - pmax(head(size_bins, -1), 49))
uniform <- rep(width, 3)[cells] / sum(rep(width, 3)[cells])
benchmark <- cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[cells, 1]
unit_weight <- w * (x <= maximum_units) / sum(w[x <= maximum_units])
benchmark_units <- nrow(post) * sum(unit_weight * x)

# Predictions at single burdens (kappa[p], tau[p]): cell shares by sigma and
# units lost, for every gamma. Points run over kappa_values within each ray:
# a common kink tau, or a kink-to-jump ratio.
candidates <- size_candidates(x, J0, 1, "separate")
predict_burdens <- function(kappa, tau) {
  shares <- array(NA_real_, c(length(cells), length(sigma_grid), length(kappa), length(gamma_grid)))
  lost <- array(NA_real_, c(length(sigma_grid), length(kappa), length(gamma_grid)))
  for (p in seq_along(kappa)) {
    burden <- burden_table(max(x), max(candidates$J), kappa[p], tau[p], 1, "separate")
    sizes <- choose_sizes(candidates, burden)
    for (g in seq_along(gamma_grid)) {
      segments <- organization_segments(sizes, J0, gamma_grid[g])
      probabilities <- segment_probabilities(segments, sigma_grid)
      shares[, , p, g] <- cell_shares(outcome_cell(segments$m, segments$J), w[segments$i] * probabilities)[cells, ]
      lost[, p, g] <- benchmark_units - nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m)
    }
  }
  list(shares = shares, lost = lost)
}
levels <- rep(kappa_values, length(tau_grid))
common_kink <- predict_burdens(levels, rep(tau_grid, each = length(kappa_values)))
levels <- rep(kappa_values, length(ratio_grid))
scaled <- predict_burdens(levels, rep(ratio_grid, each = length(kappa_values)) * levels)

# Distributions of the jump (or burden level): point masses at each value, and
# lognormals.
edges <- c(-Inf, head(kappa_values, -1) + diff(kappa_values) / 2, Inf)
jumps <- bind_rows(tibble(median = kappa_values, dispersion = 0),
  expand_grid(median = kappa_grid[kappa_grid > 0], dispersion = dispersion_grid[-1]))
jump_mass <- t(mapply(function(median, dispersion) {
  if (dispersion == 0) as.numeric(kappa_values == median) else diff(plnorm(edges, log(median), dispersion))
}, jumps$median, jumps$dispersion))
stopifnot(all(abs(rowSums(jump_mass) - 1) < 1e-12))

# Log-likelihood of every (ray, gamma, distribution, pi) at its best sigma and
# epsilon. Columns of mixed run over sigma blocks of distributions.
fit_block <- function(prediction, ray, g, pis) {
  points <- (ray - 1L) * length(kappa_values) + seq_along(kappa_values)
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) {
    prediction$shares[, s, points, g] %*% t(jump_mass)
  }))
  lost <- as.vector(t(prediction$lost[, points, g] %*% t(jump_mass)))
  bind_rows(lapply(pis, function(pi) {
    predicted <- (1 - pi) * mixed + pi * benchmark
    predicted <- predicted / rep(colSums(predicted), each = length(cells))
    log_likelihood <- sapply(epsilon_grid, function(epsilon) {
      colSums(n[observed_cells] * log((1 - epsilon) * predicted[observed_cells, ] + epsilon * uniform[observed_cells]))
    })
    tibble(ray = ray, gamma = gamma_grid[g], sigma = rep(sigma_grid, each = nrow(jumps)),
      jump = rep(seq_len(nrow(jumps)), length(sigma_grid)), pi = pi,
      epsilon = epsilon_grid[max.col(log_likelihood, "first")], log_likelihood = apply(log_likelihood, 1, max),
      units_lost = (1 - pi) * lost) |>
      group_by(jump) |>
      slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
      ungroup()
  }))
}
fit_rays <- function(prediction, rays, pis) {
  bind_rows(lapply(seq_along(rays), function(ray) bind_rows(lapply(seq_along(gamma_grid), function(g) {
    fit_block(prediction, ray, g, pis)
  }))))
}
grid <- bind_rows(
  common_kink = fit_rays(common_kink, tau_grid, pi_grid) |> mutate(tau = tau_grid[ray], kink_to_jump = NA_real_),
  scaled = fit_rays(scaled, ratio_grid, 0) |> mutate(kink_to_jump = ratio_grid[ray]),
  .id = "burden") |>
  mutate(kappa = jumps$median[jump], dispersion = jumps$dispersion[jump],
    tau = if_else(burden == "scaled", kink_to_jump * kappa, tau),
    share_jump_below_0.01 = rowSums(jump_mass[, kappa_values < 0.01, drop = FALSE])[jump],
    share_jump_above_1 = rowSums(jump_mass[, kappa_values > 1, drop = FALSE])[jump])

models <- tribble(
  ~model,                ~burden,        ~free_parameters, ~uses_pi, ~uses_dispersion,
  "single_jump",         "common_kink",  5,                FALSE,    FALSE,
  "non_optimizers",      "common_kink",  6,                TRUE,     FALSE,
  "heterogeneous_jump",  "common_kink",  6,                FALSE,    TRUE,
  "both",                "common_kink",  7,                TRUE,     TRUE,
  "scaled_burden",       "scaled",       6,                FALSE,    TRUE
)
restrict <- function(model) {
  spec <- models[models$model == model, ]
  grid |> filter(burden == spec$burden, spec$uses_pi | pi == 0, spec$uses_dispersion | dispersion == 0)
}
estimates <- bind_rows(lapply(models$model, function(model) {
  restrict(model) |> slice_max(log_likelihood, n = 1, with_ties = FALSE) |> mutate(model = model, .before = 1)
})) |>
  select(-burden) |>
  left_join(models, by = "model", relationship = "one-to-one") |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood,
    likelihood_ratio = 2 * (log_likelihood - log_likelihood[model == "single_jump"])) |>
  select(model, burden, kappa, tau, kink_to_jump, dispersion, gamma, sigma, pi, epsilon, share_jump_below_0.01,
    share_jump_above_1, log_likelihood, free_parameters, aic, likelihood_ratio, units_lost, ray, jump)

# The single jump reproduces the likelihood estimate of bootstrap_notch_model.R.
bootstrap <- read_csv("../output/bootstrap_draws.csv", show_col_types = FALSE) |>
  filter(estimator == "likelihood", draw == 0L)
single <- estimates |> filter(model == "single_jump")
stopifnot(abs(single$log_likelihood + bootstrap$score) < 1e-8, abs(single$units_lost - bootstrap$units_lost) < 1e-6)

# Profiles of the parameters each model adds, and of its kink, with units lost
# at each profile point.
profile_pairs <- tribble(
  ~model,                ~parameter,
  "single_jump",         "tau",
  "non_optimizers",      "pi",
  "heterogeneous_jump",  "dispersion",
  "heterogeneous_jump",  "tau",
  "both",                "pi",
  "both",                "dispersion",
  "scaled_burden",       "dispersion",
  "scaled_burden",       "kink_to_jump"
)
profiles <- bind_rows(lapply(seq_len(nrow(profile_pairs)), function(r) {
  restrict(profile_pairs$model[r]) |>
    group_by(value = .data[[profile_pairs$parameter[r]]]) |>
    slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
    ungroup() |>
    transmute(model = profile_pairs$model[r], parameter = profile_pairs$parameter[r], value, log_likelihood,
      units_lost)
}))

# Cell fit at each model's estimate.
cell_fit <- bind_rows(lapply(seq_len(nrow(estimates)), function(r) {
  e <- estimates[r, ]
  prediction <- if (e$burden == "scaled") scaled else common_kink
  points <- (e$ray - 1L) * length(kappa_values) + seq_along(kappa_values)
  s <- match(e$sigma, sigma_grid)
  g <- match(e$gamma, gamma_grid)
  predicted <- (1 - e$pi) * as.vector(prediction$shares[, s, points, g] %*% jump_mass[e$jump, ]) + e$pi * benchmark
  predicted <- predicted / sum(predicted)
  tibble(model = e$model, cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
    size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n, observed = n / sum(n),
    fitted = (1 - e$epsilon) * predicted + e$epsilon * uniform)
}))
estimates <- estimates |> select(-ray, -jump)

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/heterogeneity_estimates.csv")
SaveData(profiles, c("model", "parameter", "value"), "../output/heterogeneity_profiles.csv")
SaveData(cell_fit, c("model", "cell"), "../output/heterogeneity_cell_fit.csv")

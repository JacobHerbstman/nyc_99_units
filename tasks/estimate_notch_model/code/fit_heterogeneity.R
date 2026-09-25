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

# Two departures from a single jump, estimated by likelihood with the
# unexplained share epsilon of bootstrap_notch_model.R:
#   non-optimizers  a share pi of parents keeps its 2019-2022 outcome, as if the
#                   threshold did not reach it (Kleven and Waseem 2013);
#   heterogeneity   the jump differs across parents, lognormal with median
#                   kappa and log standard deviation s, so some parents feel the
#                   wage rule little and stay above 100 while others shrink.
# Both nest the main model (pi = 0, s = 0) and are also combined. The jump
# distribution sits on the kappa grid, extended to 5 for its upper tail, where
# every parent of at most 300 units avoids 100: each value takes the
# probability between the midpoints to its neighbors, so the prediction is a
# weighted average of predictions at single jumps. Non-optimizers lose no
# units.
kappa_values <- c(kappa_grid, 1.5, 2, 3, 5)
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

# Predictions at every single jump: cell shares by sigma, and units lost.
shares <- array(NA_real_, c(length(cells), length(sigma_grid), length(kappa_values), length(tau_grid),
  length(gamma_grid)))
units_lost <- array(NA_real_, c(length(sigma_grid), length(kappa_values), length(tau_grid), length(gamma_grid)))
candidates <- size_candidates(x, J0, 1, "separate")
for (t in seq_along(tau_grid)) for (k in seq_along(kappa_values)) {
  burden <- burden_table(max(x), max(candidates$J), kappa_values[k], tau_grid[t], 1, "separate")
  sizes <- choose_sizes(candidates, burden)
  for (g in seq_along(gamma_grid)) {
    segments <- organization_segments(sizes, J0, gamma_grid[g])
    probabilities <- segment_probabilities(segments, sigma_grid)
    shares[, , k, t, g] <- cell_shares(outcome_cell(segments$m, segments$J), w[segments$i] * probabilities)[cells, ]
    units_lost[, k, t, g] <- benchmark_units -
      nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m)
  }
}

# Jump distributions: point masses at each value, and lognormals.
edges <- c(-Inf, head(kappa_values, -1) + diff(kappa_values) / 2, Inf)
jumps <- bind_rows(tibble(median = kappa_values, dispersion = 0),
  expand_grid(median = kappa_grid[kappa_grid > 0], dispersion = dispersion_grid[-1]))
jump_mass <- t(mapply(function(median, dispersion) {
  if (dispersion == 0) as.numeric(kappa_values == median) else diff(plnorm(edges, log(median), dispersion))
}, jumps$median, jumps$dispersion))
stopifnot(all(abs(rowSums(jump_mass) - 1) < 1e-12))

# Log-likelihood of every (tau, gamma, jump distribution, pi) at its best sigma
# and epsilon. Columns of mixed run over sigma blocks of jump distributions.
fit_block <- function(t, g) {
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) shares[, s, , t, g] %*% t(jump_mass)))
  lost <- as.vector(t(units_lost[, , t, g] %*% t(jump_mass)))
  bind_rows(lapply(pi_grid, function(pi) {
    predicted <- (1 - pi) * mixed + pi * benchmark
    predicted <- predicted / rep(colSums(predicted), each = length(cells))
    log_likelihood <- sapply(epsilon_grid, function(epsilon) {
      colSums(n[observed_cells] * log((1 - epsilon) * predicted[observed_cells, ] + epsilon * uniform[observed_cells]))
    })
    tibble(tau = tau_grid[t], gamma = gamma_grid[g], sigma = rep(sigma_grid, each = nrow(jumps)),
      jump = rep(seq_len(nrow(jumps)), length(sigma_grid)), pi = pi,
      epsilon = epsilon_grid[max.col(log_likelihood, "first")], log_likelihood = apply(log_likelihood, 1, max),
      units_lost = (1 - pi) * lost) |>
      group_by(jump) |>
      slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
      ungroup()
  }))
}
grid <- bind_rows(lapply(seq_along(tau_grid), function(t) bind_rows(lapply(seq_along(gamma_grid), function(g) {
  fit_block(t, g)
})))) |>
  mutate(kappa = jumps$median[jump], dispersion = jumps$dispersion[jump],
    share_jump_below_0.01 = rowSums(jump_mass[, kappa_values < 0.01, drop = FALSE])[jump],
    share_jump_above_1 = rowSums(jump_mass[, kappa_values > 1, drop = FALSE])[jump])

models <- tribble(
  ~model,                ~free_parameters, ~uses_pi, ~uses_dispersion,
  "single_jump",         5,                FALSE,    FALSE,
  "non_optimizers",      6,                TRUE,     FALSE,
  "heterogeneous_jump",  6,                FALSE,    TRUE,
  "both",                7,                TRUE,     TRUE
)
restrict <- function(model) {
  spec <- models[models$model == model, ]
  grid |> filter(spec$uses_pi | pi == 0, spec$uses_dispersion | dispersion == 0)
}
estimates <- bind_rows(lapply(models$model, function(model) {
  restrict(model) |> slice_max(log_likelihood, n = 1, with_ties = FALSE) |> mutate(model = model, .before = 1)
})) |>
  left_join(models, by = "model", relationship = "one-to-one") |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood,
    likelihood_ratio = 2 * (log_likelihood - log_likelihood[model == "single_jump"])) |>
  select(model, kappa, dispersion, tau, gamma, sigma, pi, epsilon, share_jump_below_0.01, share_jump_above_1,
    log_likelihood,
    free_parameters, aic, likelihood_ratio, units_lost)

# The single jump reproduces the likelihood estimate of bootstrap_notch_model.R.
bootstrap <- read_csv("../output/bootstrap_draws.csv", show_col_types = FALSE) |>
  filter(estimator == "likelihood", draw == 0L)
single <- estimates |> filter(model == "single_jump")
stopifnot(abs(single$log_likelihood + bootstrap$score) < 1e-8, abs(single$units_lost - bootstrap$units_lost) < 1e-6)

# Profiles of the new parameters within each model that frees them.
profiles <- bind_rows(
  lapply(c("non_optimizers", "both"), function(model) {
    restrict(model) |> group_by(value = pi) |> summarise(log_likelihood = max(log_likelihood), .groups = "drop") |>
      mutate(model = model, parameter = "pi", .before = 1)
  }),
  lapply(c("heterogeneous_jump", "both"), function(model) {
    restrict(model) |> group_by(value = dispersion) |>
      summarise(log_likelihood = max(log_likelihood), .groups = "drop") |>
      mutate(model = model, parameter = "dispersion", .before = 1)
  }))

# Cell fit at each model's estimate.
cell_fit <- bind_rows(lapply(seq_len(nrow(estimates)), function(r) {
  e <- estimates[r, ]
  t <- match(e$tau, tau_grid)
  g <- match(e$gamma, gamma_grid)
  s <- match(e$sigma, sigma_grid)
  jump <- which(jumps$median == e$kappa & jumps$dispersion == e$dispersion)
  predicted <- (1 - e$pi) * as.vector(shares[, s, , t, g] %*% jump_mass[jump, ]) + e$pi * benchmark
  predicted <- predicted / sum(predicted)
  tibble(model = e$model, cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
    size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n, observed = n / sum(n),
    fitted = (1 - e$epsilon) * predicted + e$epsilon * uniform)
}))

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/heterogeneity_estimates.csv")
SaveData(profiles, c("model", "parameter", "value"), "../output/heterogeneity_profiles.csv")
SaveData(cell_fit, c("model", "cell"), "../output/heterogeneity_cell_fit.csv")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
  library(tidyr)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

maximum_units <- 300

# Departures from a single jump, estimated by likelihood with the unexplained
# share epsilon of notch_model.R:
#   non-optimizers   a share pi of parents keeps its 2019-2022 outcome, as if
#                    the threshold did not reach it (Kleven and Waseem 2013);
#                    they lose no units;
#   scaled burden    each parent's jump is scaled by b, lognormal with median 1
#                    and log standard deviation s, as a gap between required and
#                    usual wages would scale it; kappa is the median jump;
#   lot or size      the scaled burden with each parent's mean splitting cost
#   splitting        scaled by its lot area or by its preferred size
#                    (splitting_scale in notch_model.R); beta = 0 is the scaled
#                    burden. They are compared, not adopted.
# The scaled burden is the main model. Each nests the single jump (pi = 0,
# s = 0); non-optimizers and the scaled burden are also combined. The
# distributions are burden_distributions in notch_model.R.
pi_grid <- c(0, 0.01, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2, 0.3)

parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == "all_filings")
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy", units <= maximum_units)
x <- historical$units
J0 <- historical$buildings
w <- historical$weight_zoning_borough

cells <- cells_up_to(maximum_units)
n <- tabulate(outcome_cell(post$units, post$buildings), 45L)[cells]
observed_cells <- which(n > 0)
uniform <- unexplained_shares(cells)
benchmark <- cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[cells, 1]
unit_weight <- w * (x <= maximum_units) / sum(w[x <= maximum_units])
benchmark_units <- nrow(post) * sum(unit_weight * x)

# Predictions at each jump in kappa_values: cell shares by sigma and units
# lost, for every gamma, with each parent's splitting cost scaled by scale.
candidates <- size_candidates(x, J0, 1, "separate")
sizes <- lapply(kappa_values, function(kappa) {
  choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, "separate"))
})
predict_burdens <- function(scale = 1) {
  shares <- array(NA_real_, c(length(cells), length(sigma_grid), length(sizes), length(gamma_grid)))
  lost <- array(NA_real_, c(length(sigma_grid), length(sizes), length(gamma_grid)))
  for (p in seq_along(sizes)) for (g in seq_along(gamma_grid)) {
    segments <- organization_segments(sizes[[p]], J0, gamma_grid[g])
    probabilities <- segment_probabilities(segments, sigma_grid, if (length(scale) > 1) scale[segments$i] else scale)
    shares[, , p, g] <- cell_shares(outcome_cell(segments$m, segments$J), w[segments$i] * probabilities)[cells, ]
    lost[, p, g] <- benchmark_units - nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m)
  }
  list(shares = shares, lost = lost)
}
predict_scaled <- function(lot_beta, size_beta) {
  predict_burdens(splitting_scale(historical$log_lot_area, lot_beta) *
    splitting_scale(log(historical$units), size_beta, log(150)))
}
common_cost <- predict_burdens()

# Log-likelihood of every (gamma, distribution, pi) at its best sigma and
# epsilon. Columns of mixed run over sigma blocks of distributions.
fit_block <- function(prediction, g, pis) {
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) {
    prediction$shares[, s, , g] %*% t(burden_mass)
  }))
  lost <- as.vector(t(prediction$lost[, , g] %*% t(burden_mass)))
  bind_rows(lapply(pis, function(pi) {
    predicted <- (1 - pi) * mixed + pi * benchmark
    predicted <- predicted / rep(colSums(predicted), each = length(cells))
    log_likelihood <- sapply(epsilon_grid, function(epsilon) {
      colSums(n[observed_cells] * log((1 - epsilon) * predicted[observed_cells, ] + epsilon * uniform[observed_cells]))
    })
    tibble(gamma = gamma_grid[g], sigma = rep(sigma_grid, each = nrow(burden_distributions)),
      jump = rep(seq_len(nrow(burden_distributions)), length(sigma_grid)), pi = pi,
      epsilon = epsilon_grid[max.col(log_likelihood, "first")], log_likelihood = apply(log_likelihood, 1, max),
      units_lost = (1 - pi) * lost) |>
      group_by(jump) |>
      slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
      ungroup()
  }))
}
fit_gammas <- function(prediction, pis) {
  bind_rows(lapply(seq_along(gamma_grid), function(g) fit_block(prediction, g, pis)))
}
grid <- bind_rows(
  fit_gammas(common_cost, pi_grid) |> mutate(lot_elasticity = 0, size_elasticity = 0),
  lapply(setdiff(splitting_elasticity_grid, 0), function(beta) {
    fit_gammas(predict_scaled(beta, 0), 0) |> mutate(lot_elasticity = beta, size_elasticity = 0)
  }),
  lapply(setdiff(splitting_elasticity_grid, 0), function(beta) {
    fit_gammas(predict_scaled(0, beta), 0) |> mutate(lot_elasticity = 0, size_elasticity = beta)
  })) |>
  mutate(kappa = burden_distributions$median[jump], dispersion = burden_distributions$dispersion[jump],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[jump],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[jump])

models <- tribble(
  ~model,                          ~free_parameters, ~uses_pi, ~uses_dispersion, ~uses_lot, ~uses_size,
  "single_jump",                   4,                FALSE,    FALSE,            FALSE,     FALSE,
  "non_optimizers",                5,                TRUE,     FALSE,            FALSE,     FALSE,
  "scaled_burden",                 5,                FALSE,    TRUE,             FALSE,     FALSE,
  "scaled_burden_non_optimizers",  6,                TRUE,     TRUE,             FALSE,     FALSE,
  "scaled_burden_lot_splitting",   6,                FALSE,    TRUE,             TRUE,      FALSE,
  "scaled_burden_size_splitting",  6,                FALSE,    TRUE,             FALSE,     TRUE
)
restrict <- function(model) {
  spec <- models[models$model == model, ]
  grid |> filter(spec$uses_pi | pi == 0, spec$uses_dispersion | dispersion == 0,
    spec$uses_lot | lot_elasticity == 0, spec$uses_size | size_elasticity == 0)
}
estimates <- bind_rows(lapply(models$model, function(model) {
  restrict(model) |> slice_max(log_likelihood, n = 1, with_ties = FALSE) |> mutate(model = model, .before = 1)
})) |>
  left_join(models, by = "model", relationship = "one-to-one") |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood,
    likelihood_ratio = 2 * (log_likelihood - log_likelihood[model == "single_jump"])) |>
  select(model, kappa, dispersion, gamma, sigma, lot_elasticity, size_elasticity, pi, epsilon,
    share_jump_below_0.01, share_jump_above_1, log_likelihood, free_parameters, aic, likelihood_ratio, units_lost,
    jump)

# Profiles of the parameters each model adds, with units lost at each profile
# point.
profile_pairs <- tribble(
  ~model,                         ~parameter,
  "single_jump",                  "kappa",
  "non_optimizers",               "pi",
  "scaled_burden",                "dispersion",
  "scaled_burden_non_optimizers", "pi",
  "scaled_burden_non_optimizers", "dispersion",
  "scaled_burden_lot_splitting",  "lot_elasticity",
  "scaled_burden_lot_splitting",  "dispersion",
  "scaled_burden_size_splitting", "size_elasticity",
  "scaled_burden_size_splitting", "dispersion"
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
  prediction <- if (e$lot_elasticity == 0 && e$size_elasticity == 0) common_cost else
    predict_scaled(e$lot_elasticity, e$size_elasticity)
  s <- match(e$sigma, sigma_grid)
  g <- match(e$gamma, gamma_grid)
  predicted <- (1 - e$pi) * as.vector(prediction$shares[, s, , g] %*% burden_mass[e$jump, ]) + e$pi * benchmark
  predicted <- predicted / sum(predicted)
  tibble(model = e$model, cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
    size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n, observed = n / sum(n),
    benchmark = benchmark / sum(benchmark), fitted = (1 - e$epsilon) * predicted + e$epsilon * uniform)
}))
estimates <- estimates |> select(-jump)

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/heterogeneity_estimates.csv")
SaveData(profiles, c("model", "parameter", "value"), "../output/heterogeneity_profiles.csv")
SaveData(cell_fit, c("model", "cell"), "../output/heterogeneity_cell_fit.csv")

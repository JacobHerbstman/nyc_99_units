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

# The main model and the alternatives it is compared with, all by likelihood.
# Each treats the recent parents of at most 300 units as draws from the cell
# shares the model predicts by moving the weighted historical parents through
# the policy, with a share epsilon of recent outcomes left unexplained
# (notch_model.R).
#   single jump      one jump kappa for every parent;
#   non-optimizers   a share pi of parents keeps its 2019-2022 outcome, as if
#                    the threshold did not reach it (Kleven and Waseem 2013);
#                    they lose no units;
#   scaled burden    the main model: each parent's jump is kappa times b, with
#                    b lognormal with median 1 and log standard deviation s, as
#                    a gap between required and usual wages would scale it;
#   lot or size      the main model with each parent's mean splitting cost
#   splitting        scaled by its lot area or by its preferred size
#                    (splitting_scale in notch_model.R); beta = 0 is the main
#                    model.
# Every model is fit on the grid in notch_model.R; the main model is then
# refined off the grid.
pi_grid <- c(0, 0.01, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2, 0.3)

parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == "all_filings")
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy", units <= maximum_units)
x <- historical$units
J0 <- historical$buildings
w <- historical$weight_zoning_borough

# Recent parents counted in each cell, the unexplained shares, the historical
# cell shares, and the weights for units lost: historical parents whose own
# size is in the compared range, scaled to the recent parents there.
cells <- cells_up_to(maximum_units)
n <- tabulate(outcome_cell(post$units, post$buildings), 45L)[cells]
uniform <- unexplained_shares(cells)
benchmark <- cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[cells, 1]
unit_weight <- w * (x <= maximum_units) / sum(w[x <= maximum_units])
benchmark_units <- nrow(post) * sum(unit_weight * x)

# Each parent's best total for every building count, at each jump level in
# kappa_values. A distribution of jumps is a weighted average over these
# levels (burden_mass).
candidates <- size_candidates(x, J0, 1, "separate")
sizes <- lapply(kappa_values, function(kappa) {
  choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, "separate"))
})

# Predicted cell shares (cells, sigma, jump level, gamma) and units lost
# (sigma, jump level, gamma), with each parent's mean splitting cost
# multiplied by scale.
predict_levels <- function(scale = 1) {
  shares <- array(NA_real_, c(length(cells), length(sigma_grid), length(sizes), length(gamma_grid)))
  lost <- array(NA_real_, c(length(sigma_grid), length(sizes), length(gamma_grid)))
  for (k in seq_along(sizes)) for (g in seq_along(gamma_grid)) {
    segments <- organization_segments(sizes[[k]], J0, gamma_grid[g])
    probabilities <- segment_probabilities(segments, sigma_grid, if (length(scale) > 1) scale[segments$i] else scale)
    shares[, , k, g] <- cell_shares(outcome_cell(segments$m, segments$J), w[segments$i] * probabilities)[cells, ]
    lost[, k, g] <- benchmark_units - nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m)
  }
  list(shares = shares, lost = lost)
}
predict_scaled <- function(lot_beta, size_beta) {
  predict_levels(splitting_scale(historical$log_lot_area, lot_beta) *
    splitting_scale(log(historical$units), size_beta, log(150)))
}
common_cost <- predict_levels()

# At one gamma, the log-likelihood of every jump distribution, sigma and pi,
# keeping for each distribution its best sigma and epsilon. Columns of mixed
# run over sigma blocks of distributions.
fit_gamma <- function(prediction, g, pis) {
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) prediction$shares[, s, , g] %*% t(burden_mass)))
  lost <- as.vector(t(prediction$lost[, , g] %*% t(burden_mass)))
  observed <- n > 0
  bind_rows(lapply(pis, function(pi) {
    predicted <- (1 - pi) * mixed + pi * benchmark
    predicted <- predicted / rep(colSums(predicted), each = length(cells))
    log_likelihood <- sapply(epsilon_grid, function(epsilon) {
      colSums(n[observed] * log((1 - epsilon) * predicted[observed, ] + epsilon * uniform[observed]))
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
fit_grid <- function(prediction, pis = 0) {
  bind_rows(lapply(seq_along(gamma_grid), function(g) fit_gamma(prediction, g, pis)))
}
grid <- bind_rows(
  fit_grid(common_cost, pi_grid) |> mutate(lot_elasticity = 0, size_elasticity = 0),
  lapply(setdiff(splitting_elasticity_grid, 0), function(beta) {
    fit_grid(predict_scaled(beta, 0)) |> mutate(lot_elasticity = beta, size_elasticity = 0)
  }),
  lapply(setdiff(splitting_elasticity_grid, 0), function(beta) {
    fit_grid(predict_scaled(0, beta)) |> mutate(lot_elasticity = 0, size_elasticity = beta)
  })) |>
  mutate(kappa = burden_distributions$median[jump], dispersion = burden_distributions$dispersion[jump],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[jump],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[jump])

# Each model is its part of the grid; its estimate is the best point there.
# scaled_burden_grid keeps the main model's grid estimate, which the
# alternatives are compared with.
models <- tribble(
  ~model,                          ~free_parameters, ~uses_pi, ~uses_dispersion, ~uses_lot, ~uses_size,
  "single_jump",                   4,                FALSE,    FALSE,            FALSE,     FALSE,
  "non_optimizers",                5,                TRUE,     FALSE,            FALSE,     FALSE,
  "scaled_burden",                 5,                FALSE,    TRUE,             FALSE,     FALSE,
  "scaled_burden_grid",            5,                FALSE,    TRUE,             FALSE,     FALSE,
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
}))

# The main model refined off the grid: with gamma fixed the likelihood is
# smooth in kappa, s, sigma and epsilon, so from the grid estimate it is
# maximized at each gamma (refine_scaled_burden in notch_model.R) and the best
# gamma kept, unless the grid point fits better. The other models stay at their
# grid estimates.
main_grid <- estimates |> filter(model == "scaled_burden")
segments_by_gamma <- lapply(gamma_grid, function(gamma) level_segments(sizes, J0, gamma, cells))
refined_by_gamma <- refine_scaled_burden(main_grid, segments_by_gamma, x, w, n, uniform, unit_weight)
stopifnot(all(refined_by_gamma$converged))
refined <- refined_by_gamma |> slice_max(log_likelihood, n = 1, with_ties = FALSE)
if (refined$log_likelihood > main_grid$log_likelihood) {
  estimates <- estimates |> rows_update(refined |> select(-converged) |> mutate(model = "scaled_burden", jump = NA),
    by = "model")
}
estimates <- estimates |>
  left_join(models |> select(model, free_parameters), by = "model", relationship = "one-to-one") |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood,
    likelihood_ratio = 2 * (log_likelihood - log_likelihood[model == "single_jump"])) |>
  select(model, kappa, dispersion, gamma, sigma, lot_elasticity, size_elasticity, pi, epsilon,
    share_jump_below_0.01, share_jump_above_1, log_likelihood, free_parameters, aic, likelihood_ratio, units_lost,
    jump)

# Profiles of the parameters each model adds, with units lost at each value:
# on the grid, and for the main model's gamma, refined.
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
profiles <- bind_rows(
  lapply(seq_len(nrow(profile_pairs)), function(r) {
    restrict(profile_pairs$model[r]) |>
      group_by(value = .data[[profile_pairs$parameter[r]]]) |>
      slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
      ungroup() |>
      transmute(model = profile_pairs$model[r], parameter = profile_pairs$parameter[r], value, log_likelihood,
        units_lost)
  }),
  refined_by_gamma |> transmute(model = "scaled_burden", parameter = "gamma", value = gamma, log_likelihood,
    units_lost))

# Cell fit at each model's estimate.
cell_fit <- bind_rows(lapply(seq_len(nrow(estimates)), function(r) {
  e <- estimates[r, ]
  predicted <- if (is.na(e$jump)) {
    scaled_burden_at(c(log(e$kappa), log(e$dispersion), log(e$sigma), qlogis(e$epsilon)),
      segments_by_gamma[[match(e$gamma, gamma_grid)]], x, w, n, uniform, unit_weight)$predicted
  } else {
    prediction <- if (e$lot_elasticity == 0 && e$size_elasticity == 0) common_cost else
      predict_scaled(e$lot_elasticity, e$size_elasticity)
    shares <- (1 - e$pi) * as.vector(prediction$shares[, match(e$sigma, sigma_grid), , match(e$gamma, gamma_grid)] %*%
      burden_mass[e$jump, ]) + e$pi * benchmark
    shares / sum(shares)
  }
  tibble(model = e$model, cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
    size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n, observed = n / sum(n),
    benchmark = benchmark / sum(benchmark), fitted = (1 - e$epsilon) * predicted + e$epsilon * uniform)
}))
estimates <- estimates |> select(-jump)

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/heterogeneity_estimates.csv")
SaveData(profiles, c("model", "parameter", "value"), "../output/heterogeneity_profiles.csv")
SaveData(cell_fit, c("model", "cell"), "../output/heterogeneity_cell_fit.csv")

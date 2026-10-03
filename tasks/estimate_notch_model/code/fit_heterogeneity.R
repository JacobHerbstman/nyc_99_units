# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(parallel)
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
#   lot, size or     the scaled burden with each historical parent's mean
#   site splitting   splitting cost scaled by its tax-lot area, its preferred
#                    size, the land of its site, or whether its site spans
#                    several lots (splitting_scale in notch_model.R); the site
#                    is the recorded zoning lot within two years of the first
#                    filing. beta = 0 is the scaled burden. They are compared,
#                    not adopted;
#   by lot group     recent parents on one lot and on several are fit
#                    separately, each against the historical parents of the
#                    same group, and the mean splitting cost of a site on
#                    several lots is sigma * exp(-beta); lots are counted as
#                    starting lots or as the site lots of the zoning lot
#                    recorded within 180 days, the same in both periods. Their
#                    likelihood is not comparable with the pooled ones: beta = 0
#                    is the reference, the scaled burden fit by the same groups.
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
stopifnot(!anyNA(c(historical$starting_lots, post$starting_lots, historical$site_lots, post$site_lots,
  historical$site_lots_two_year)), all(historical$site_lot_area_two_year_sqft > 0))

cells <- cells_up_to(maximum_units)
n <- tabulate(outcome_cell(post$units, post$buildings), 45L)[cells]
uniform <- unexplained_shares(cells)
benchmark <- cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[cells, 1]
unit_weight <- w * (x <= maximum_units) / sum(w[x <= maximum_units])
benchmark_units <- nrow(post) * sum(unit_weight * x)
# The fitted cells: all recent parents together, or by lot group, one lot or
# several. Each group's predicted shares are normalized within the group.
pooled <- list(n = n, uniform = uniform, benchmark = benchmark, group = rep(1L, length(cells)))
lot_grouping <- function(historical_several, post_several) {
  recent_cells <- function(keep) tabulate(outcome_cell(post$units[keep], post$buildings[keep]), 45L)[cells]
  historical_cells <- function(weight) cell_shares(outcome_cell(x, J0), matrix(weight, ncol = 1))[cells, 1]
  list(several = historical_several, n = c(recent_cells(!post_several), recent_cells(post_several)),
    uniform = c(uniform, uniform),
    benchmark = c(historical_cells(w * !historical_several), historical_cells(w * historical_several)),
    group = rep(1:2, each = length(cells)))
}
groupings <- list(by_lots = lot_grouping(historical$starting_lots >= 2, post$starting_lots >= 2),
  by_site_lots = lot_grouping(historical$site_lots >= 2, post$site_lots >= 2))
stopifnot(all(vapply(groupings, function(grouping) sum(grouping$n) == sum(n), logical(1))))

# Predictions at each jump in kappa_values: cell shares by sigma and units
# lost, for every gamma, with each parent's splitting cost scaled by scale.
# The shares of each historical weighting in weights are stacked, one block of
# cells after another.
candidates <- size_candidates(x, J0, 1, "separate")
sizes <- lapply(kappa_values, function(kappa) {
  choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, "separate"))
})
predict_burdens <- function(scale = 1, weights = list(w)) {
  shares <- array(NA_real_, c(length(cells) * length(weights), length(sigma_grid), length(sizes), length(gamma_grid)))
  lost <- array(NA_real_, c(length(sigma_grid), length(sizes), length(gamma_grid)))
  for (p in seq_along(sizes)) for (g in seq_along(gamma_grid)) {
    segments <- organization_segments(sizes[[p]], J0, gamma_grid[g])
    probabilities <- segment_probabilities(segments, sigma_grid, if (length(scale) > 1) scale[segments$i] else scale)
    cell <- outcome_cell(segments$m, segments$J)
    shares[, , p, g] <- do.call(rbind, lapply(weights, function(weight) {
      cell_shares(cell, weight[segments$i] * probabilities)[cells, ]
    }))
    lost[, p, g] <- benchmark_units - nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m)
  }
  list(shares = shares, lost = lost)
}
predict_scaled <- function(lot = 0, size = 0, site_area = 0, site_lots = 0) {
  predict_burdens(splitting_scale(historical$log_lot_area, lot) *
    splitting_scale(log(historical$units), size, log(150)) *
    splitting_scale(log(historical$site_lot_area_two_year_sqft), site_area) *
    splitting_scale(as.numeric(historical$site_lots_two_year >= 2), site_lots, 0))
}
predict_by_lots <- function(beta, grouping) {
  several <- groupings[[grouping]]$several
  predict_burdens(splitting_scale(as.numeric(several), beta, 0), list(w * !several, w * several))
}
common_cost <- predict_burdens()

# Log-likelihood of every (gamma, distribution, pi) at its best sigma and
# epsilon. Columns of mixed run over sigma blocks of distributions.
fit_block <- function(prediction, g, pis, data) {
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) {
    prediction$shares[, s, , g] %*% t(burden_mass)
  }))
  lost <- as.vector(t(prediction$lost[, , g] %*% t(burden_mass)))
  observed <- data$n > 0
  bind_rows(lapply(pis, function(pi) {
    predicted <- (1 - pi) * mixed + pi * data$benchmark
    predicted <- predicted / rowsum(predicted, data$group)[data$group, , drop = FALSE]
    log_likelihood <- sapply(epsilon_grid, function(epsilon) {
      colSums(data$n[observed] * log((1 - epsilon) * predicted[observed, ] + epsilon * data$uniform[observed]))
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
fit_gammas <- function(prediction, pis, data = pooled) {
  bind_rows(lapply(seq_along(gamma_grid), function(g) fit_block(prediction, g, pis, data)))
}
# Each scaled splitting cost, one elasticity at a time, fit in parallel.
scaled_fits <- bind_rows(
  tibble(parameter = "lot_elasticity", beta = setdiff(splitting_elasticity_grid, 0)),
  tibble(parameter = "size_elasticity", beta = setdiff(splitting_elasticity_grid, 0)),
  tibble(parameter = "site_area_elasticity", beta = setdiff(splitting_elasticity_grid, 0)),
  tibble(parameter = "site_lots_elasticity", beta = setdiff(lot_count_grid, 0)),
  tibble(parameter = "by_lots", beta = lot_count_grid),
  tibble(parameter = "by_site_lots", beta = lot_count_grid))
fits <- mclapply(seq_len(nrow(scaled_fits)), function(r) {
  parameter <- scaled_fits$parameter[r]
  beta <- scaled_fits$beta[r]
  if (parameter %in% names(groupings)) {
    return(fit_gammas(predict_by_lots(beta, parameter), 0, groupings[[parameter]]) |>
      mutate(fitted_cells = parameter, lot_count_elasticity = beta))
  }
  prediction <- switch(parameter, lot_elasticity = predict_scaled(lot = beta),
    size_elasticity = predict_scaled(size = beta), site_area_elasticity = predict_scaled(site_area = beta),
    site_lots_elasticity = predict_scaled(site_lots = beta))
  fit_gammas(prediction, 0) |> mutate(fitted_cells = "pooled", "{parameter}" := beta)
}, mc.cores = min(nrow(scaled_fits), detectCores() - 2L))
stopifnot(!vapply(fits, inherits, logical(1), "try-error"))
grid <- bind_rows(fit_gammas(common_cost, pi_grid) |> mutate(fitted_cells = "pooled"), fits) |>
  mutate(across(c(lot_elasticity, size_elasticity, site_area_elasticity, site_lots_elasticity, lot_count_elasticity),
      ~ coalesce(.x, 0)),
    kappa = burden_distributions$median[jump], dispersion = burden_distributions$dispersion[jump],
    share_jump_below_0.01 = rowSums(burden_mass[, kappa_values < 0.01, drop = FALSE])[jump],
    share_jump_above_1 = rowSums(burden_mass[, kappa_values > 1, drop = FALSE])[jump])

models <- tribble(
  ~model,                              ~fitted_cells,  ~free_parameters, ~added,
  "single_jump",                       "pooled",       4, NA,
  "non_optimizers",                    "pooled",       5, "pi",
  "scaled_burden",                     "pooled",       5, "dispersion",
  "scaled_burden_non_optimizers",      "pooled",       6, "pi",
  "scaled_burden_lot_splitting",       "pooled",       6, "lot_elasticity",
  "scaled_burden_size_splitting",      "pooled",       6, "size_elasticity",
  "scaled_burden_site_area_splitting", "pooled",       6, "site_area_elasticity",
  "scaled_burden_site_lots_splitting", "pooled",       6, "site_lots_elasticity",
  "scaled_burden_by_lots",             "by_lots",      5, NA,
  "scaled_burden_lot_count_splitting", "by_lots",      6, "lot_count_elasticity",
  "scaled_burden_by_site_lots",        "by_site_lots", 5, NA,
  "scaled_burden_site_lot_splitting",  "by_site_lots", 6, "lot_count_elasticity"
)
# A model's grid: its fitted cells, the dispersion unless it is a single or
# non-optimizer model, and only the parameters it adds.
elasticities <- c("lot_elasticity", "size_elasticity", "site_area_elasticity", "site_lots_elasticity",
  "lot_count_elasticity")
restrict <- function(model) {
  spec <- models[models$model == model, ]
  uses_dispersion <- !model %in% c("single_jump", "non_optimizers")
  kept <- grid |> filter(fitted_cells == spec$fitted_cells, uses_dispersion | dispersion == 0,
    pi == 0 | model %in% c("non_optimizers", "scaled_burden_non_optimizers"))
  for (parameter in setdiff(elasticities, spec$added)) kept <- kept |> filter(.data[[parameter]] == 0)
  kept
}
estimates <- bind_rows(lapply(models$model, function(model) {
  restrict(model) |> slice_max(log_likelihood, n = 1, with_ties = FALSE) |> mutate(model = model, .before = 1)
})) |>
  select(-fitted_cells) |>
  left_join(models |> select(-added), by = "model", relationship = "one-to-one") |>
  # Likelihood ratios against the single jump, or for the models by lot group
  # against the scaled burden fit by the same groups.
  group_by(fitted_cells) |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood,
    likelihood_ratio = 2 * (log_likelihood -
      log_likelihood[model %in% c("single_jump", "scaled_burden_by_lots", "scaled_burden_by_site_lots")])) |>
  ungroup() |>
  select(model, fitted_cells, kappa, dispersion, gamma, sigma, all_of(elasticities), pi, epsilon,
    share_jump_below_0.01, share_jump_above_1, log_likelihood, free_parameters, aic, likelihood_ratio, units_lost,
    jump)

# Profiles of the parameters each model adds, and of the dispersion, with units
# lost at each profile point.
profile_pairs <- bind_rows(
  models |> filter(!is.na(added)) |> transmute(model, parameter = added),
  models |> filter(!model %in% c("single_jump", "non_optimizers")) |> transmute(model, parameter = "dispersion"),
  tibble(model = "single_jump", parameter = "kappa")) |>
  distinct()
profiles <- bind_rows(lapply(seq_len(nrow(profile_pairs)), function(r) {
  restrict(profile_pairs$model[r]) |>
    group_by(value = .data[[profile_pairs$parameter[r]]]) |>
    slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
    ungroup() |>
    transmute(model = profile_pairs$model[r], parameter = profile_pairs$parameter[r], value, log_likelihood,
      units_lost)
}))

# Cell fit at each model's estimate, by lot group for the models fit by group.
cell_fit <- bind_rows(lapply(seq_len(nrow(estimates)), function(r) {
  e <- estimates[r, ]
  by_group <- e$fitted_cells %in% names(groupings)
  prediction <- if (by_group) predict_by_lots(e$lot_count_elasticity, e$fitted_cells) else
    if (all(unlist(e[elasticities]) == 0)) common_cost else
    predict_scaled(e$lot_elasticity, e$size_elasticity, e$site_area_elasticity, e$site_lots_elasticity)
  data <- if (by_group) groupings[[e$fitted_cells]] else pooled
  s <- match(e$sigma, sigma_grid)
  g <- match(e$gamma, gamma_grid)
  predicted <- (1 - e$pi) * as.vector(prediction$shares[, s, , g] %*% burden_mass[e$jump, ]) + e$pi * data$benchmark
  within <- function(v) v / rowsum(v, data$group)[data$group]
  tibble(model = e$model, lot_group = if (by_group) rep(c("one", "several"), each = length(cells)) else "all",
    cell = rep(cells, max(data$group)), buildings = rep(c("1", "2", "3+"), each = 15)[cell],
    size_bin = rep(size_bin_labels, 3)[cell], observed_parents = data$n, observed = within(data$n),
    benchmark = within(data$benchmark), fitted = (1 - e$epsilon) * within(predicted) + e$epsilon * data$uniform)
}))
estimates <- estimates |> select(-jump)

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/heterogeneity_estimates.csv")
SaveData(profiles, c("model", "parameter", "value"), "../output/heterogeneity_profiles.csv")
SaveData(cell_fit, c("model", "lot_group", "cell"), "../output/heterogeneity_cell_fit.csv")

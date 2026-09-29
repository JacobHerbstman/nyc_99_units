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

# The main model with a logit choice among strategies instead of a random
# splitting cost: a mixed logit, with the scaled burden as its random
# coefficient. A parent chooses a building count, and whether every building
# stays under 100, at the best total for that strategy (choose_strategies and
# strategy_probabilities in notch_model.R); sigma is now a fixed cost per added
# building and mu the scale of the strategy shocks. Everything else, including
# the likelihood and its unexplained share epsilon, is as in
# fit_heterogeneity.R, so the two log-likelihoods compare directly.
logit_scale_grid <- c(0.005, 0.01, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2, 0.3, 0.5)

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

# Strategies at every burden level along every kink-to-jump ratio; points run
# over kappa_values within each ratio.
candidates <- size_candidates(x, J0, 1, "separate")
levels <- rep(kappa_values, length(ratio_grid))
strategies <- lapply(seq_along(levels), function(p) {
  choose_strategies(candidates, burden_table(max(x), max(candidates$J), levels[p],
    rep(ratio_grid, each = length(kappa_values))[p] * levels[p], 1, "separate"))
})

# Log-likelihood of every (ratio, gamma, mu, distribution) at its best sigma and
# epsilon: the shares at each burden level are averaged over each distribution
# and renormalized within the compared cells.
predict_ray <- function(ray, gamma, mu) {
  points <- (ray - 1L) * length(kappa_values) + seq_along(kappa_values)
  shares <- array(NA_real_, c(length(cells), length(sigma_grid), length(points)))
  lost <- matrix(NA_real_, length(sigma_grid), length(points))
  for (p in seq_along(points)) {
    chosen <- strategy_probabilities(strategies[[points[p]]], J0, gamma, sigma_grid, mu)
    i <- chosen$outcomes$i
    shares[, , p] <- cell_shares(outcome_cell(chosen$outcomes$m, chosen$outcomes$J),
      w[i] * chosen$probabilities)[cells, ]
    lost[, p] <- benchmark_units - nrow(post) * colSums(unit_weight[i] * chosen$probabilities * chosen$outcomes$m)
  }
  list(shares = shares, lost = lost)
}
score_ray <- function(ray, gamma, mu) {
  prediction <- predict_ray(ray, gamma, mu)
  mixed <- do.call(cbind, lapply(seq_along(sigma_grid), function(s) prediction$shares[, s, ] %*% t(burden_mass)))
  mixed <- mixed / rep(colSums(mixed), each = length(cells))
  log_likelihood <- sapply(epsilon_grid, function(epsilon) {
    colSums(n[observed_cells] * log((1 - epsilon) * mixed[observed_cells, ] + epsilon * uniform[observed_cells]))
  })
  tibble(ray = ray, gamma = gamma, logit_scale = mu, sigma = rep(sigma_grid, each = nrow(burden_distributions)),
    distribution = rep(seq_len(nrow(burden_distributions)), length(sigma_grid)),
    epsilon = epsilon_grid[max.col(log_likelihood, "first")], log_likelihood = apply(log_likelihood, 1, max),
    units_lost = as.vector(t(prediction$lost %*% t(burden_mass)))) |>
    group_by(distribution) |>
    slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
    ungroup()
}
grid <- bind_rows(lapply(logit_scale_grid, function(mu) bind_rows(lapply(gamma_grid, function(gamma) {
  bind_rows(lapply(seq_along(ratio_grid), score_ray, gamma = gamma, mu = mu))
})))) |>
  mutate(kink_to_jump = ratio_grid[ray], kappa = burden_distributions$median[distribution],
    tau = kink_to_jump * kappa, dispersion = burden_distributions$dispersion[distribution])

# The estimate, compared with the main model.
main <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE) |>
  filter(model == "scaled_burden")
estimate <- grid |> slice_max(log_likelihood, n = 1, with_ties = FALSE)
estimates <- bind_rows(
  main |> transmute(model = "scaled_burden", kappa, tau, kink_to_jump, dispersion, gamma, sigma,
    logit_scale = NA_real_, epsilon, log_likelihood, free_parameters, units_lost),
  estimate |> transmute(model = "scaled_burden_strategy_logit", kappa, tau, kink_to_jump, dispersion, gamma, sigma,
    logit_scale, epsilon, log_likelihood, free_parameters = 7, units_lost)) |>
  mutate(aic = 2 * free_parameters - 2 * log_likelihood)

# Profiles of the logit scale and the other parameters, with units lost.
profiles <- bind_rows(lapply(c("logit_scale", "kink_to_jump", "dispersion", "gamma", "sigma"), function(parameter) {
  grid |>
    group_by(value = .data[[parameter]]) |>
    slice_max(log_likelihood, n = 1, with_ties = FALSE) |>
    ungroup() |>
    transmute(parameter = parameter, value, log_likelihood, units_lost)
}))

# Cell fit at the estimate.
prediction <- predict_ray(estimate$ray, estimate$gamma, estimate$logit_scale)
predicted <- as.vector(prediction$shares[, match(estimate$sigma, sigma_grid), ] %*% burden_mass[estimate$distribution, ])
predicted <- predicted / sum(predicted)
cell_fit <- tibble(cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
  size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n, observed = n / sum(n),
  benchmark = benchmark / sum(benchmark), fitted = (1 - estimate$epsilon) * predicted + estimate$epsilon * uniform)

print(estimates, width = Inf)
SaveData(estimates, "model", "../output/strategy_logit_estimates.csv")
SaveData(profiles, c("parameter", "value"), "../output/strategy_logit_profiles.csv")
SaveData(cell_fit, "cell", "../output/strategy_logit_cell_fit.csv")

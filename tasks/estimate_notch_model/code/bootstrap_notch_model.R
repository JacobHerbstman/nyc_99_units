# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})
source("notch_model.R")
source("../../shared/code/scale_shape_helpers.R")
source("../../shared/code/write_data_report.R")

draws <- 500L
maximum_units <- 300

# The main specification estimated two ways, each with bootstrap intervals.
# Least squares matches cell shares, as in fit_notch_model.R. The likelihood
# treats each recent parent as a draw from the predicted cell probabilities.
# Every grid point gives probability zero to some observed parent (three
# single buildings of 105-119 units, a three-building parent of 180-197), so a
# share epsilon of recorded recent outcomes is left unexplained by the model,
# as linkage or unit-count errors would be, spread uniformly over sizes 50-300
# and 1, 2 or 3+ buildings. Units lost use the model's choices only.
epsilon_grid <- c(0.001, 0.0025, 0.005, 0.0075, 0.01, 0.015, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2)

parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == "all_filings")
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy")
x <- historical$units
J0 <- historical$buildings

# Each draw resamples parents with replacement within period and borough and
# recalibrates the weights to the resampled recent parents. Stratifying keeps
# Staten Island (5 historical, 2 recent parents) in every calibration. Draw 0
# is the data.
cells <- cells_up_to(maximum_units)
resample <- function(data) data |> group_by(borough) |> slice_sample(prop = 1, replace = TRUE) |> ungroup()
set.seed(20260925)
samples <- lapply(0:draws, function(draw) {
  h <- if (draw == 0L) historical else resample(historical)
  p <- if (draw == 0L) post else resample(post)
  calibrated <- rowsum(calibrate_historical_to_target(h, p)$historical$calibration_weight,
    match(h$parent_id, historical$parent_id))
  weight <- numeric(length(x))
  weight[as.integer(rownames(calibrated))] <- calibrated
  p <- p |> filter(units <= maximum_units)
  list(weight = weight / sum(weight), counts = tabulate(outcome_cell(p$units, p$buildings), 45L)[cells])
})
W <- sapply(samples, `[[`, "weight")
n <- sapply(samples, `[[`, "counts")
stopifnot(max(abs(W[, 1] - historical$weight_zoning_borough)) < 1e-10,
  sum(n[, 1]) == sum(post$units <= maximum_units))

post_parents <- colSums(n)
observed_share <- n / rep(post_parents, each = length(cells))
observed_cells <- which(n[, 1] > 0)
width <- pmax(0, size_bins[-1] - pmax(head(size_bins, -1), 49))
uniform <- rep(width, 3)[cells] / sum(rep(width, 3)[cells])
unit_weight <- W * (x <= maximum_units)
unit_weight <- unit_weight / rep(colSums(unit_weight), each = length(x))
benchmark_units <- post_parents * colSums(unit_weight * x)

# Predicted compared-cell shares of every draw at every sigma, and for each
# sigma (rows) and draw (columns) the least-squares objective, the
# log-likelihood at its best epsilon, and units lost.
predict_draws <- function(sizes, gamma) {
  segments <- organization_segments(sizes, J0, gamma)
  probabilities <- segment_probabilities(segments, sigma_grid)
  by_parent_cell <- rowsum(probabilities, (outcome_cell(segments$m, segments$J) - 1L) * length(x) + segments$i)
  key <- as.integer(rownames(by_parent_cell)) - 1L
  parent <- key %% length(x) + 1L
  cell <- key %/% length(x) + 1L
  expected_units <- rowsum(probabilities * segments$m, segments$i)
  stopifnot(nrow(expected_units) == length(x))
  compared <- lapply(seq_along(sigma_grid), function(k) {
    shares <- matrix(0, 45, ncol(W))
    summed <- rowsum(by_parent_cell[, k] * W[parent, , drop = FALSE], cell)
    shares[as.integer(rownames(summed)), ] <- summed
    shares <- shares[cells, , drop = FALSE]
    shares / rep(colSums(shares), each = length(cells))
  })
  log_likelihood <- lapply(compared, function(shares) {
    matrix(sapply(epsilon_grid, function(epsilon) {
      colSums(n[observed_cells, , drop = FALSE] *
        log((1 - epsilon) * shares[observed_cells, , drop = FALSE] + epsilon * uniform[observed_cells]))
    }), ncol = length(epsilon_grid))
  })
  list(compared = compared,
    objective = t(sapply(compared, function(shares) colSums((shares - observed_share)^2))),
    log_likelihood = t(sapply(log_likelihood, function(l) apply(l, 1, max))),
    epsilon = t(sapply(log_likelihood, function(l) epsilon_grid[max.col(l, "first")])),
    units_lost = t(benchmark_units - post_parents * crossprod(unit_weight, expected_units)))
}

# The grid in the order of fit_notch_model.R; ties keep the first point. Each
# estimator minimizes a score: the objective, or minus the log-likelihood.
point_names <- c("kappa", "tau", "gamma", "sigma", "epsilon", "units_lost")
best_score <- list(least_squares = rep(Inf, ncol(W)), likelihood = rep(Inf, ncol(W)))
best_point <- lapply(best_score, function(score) matrix(NA_real_, length(score), 6,
  dimnames = list(NULL, point_names)))
data_grid <- list()
candidates <- size_candidates(x, J0, 1, "separate")
for (tau in tau_grid) for (kappa in kappa_grid) {
  burden <- burden_table(max(x), max(candidates$J), kappa, tau, 1, "separate")
  sizes <- choose_sizes(candidates, burden)
  for (gamma in gamma_grid) {
    p <- predict_draws(sizes, gamma)
    scores <- list(least_squares = p$objective, likelihood = -p$log_likelihood)
    for (estimator in names(scores)) {
      k <- apply(scores[[estimator]], 2, which.min)
      chosen <- cbind(k, seq_len(ncol(W)))
      improved <- scores[[estimator]][chosen] < best_score[[estimator]]
      best_score[[estimator]][improved] <- scores[[estimator]][chosen][improved]
      best_point[[estimator]][improved, ] <- cbind(kappa, tau, gamma, sigma_grid[k],
        if (estimator == "likelihood") p$epsilon[chosen] else NA_real_, p$units_lost[chosen])[improved, ]
    }
    data_grid[[length(data_grid) + 1L]] <- tibble(kappa = kappa, tau = tau, gamma = gamma, sigma = sigma_grid,
      objective = p$objective[, 1], log_likelihood = p$log_likelihood[, 1], epsilon = p$epsilon[, 1],
      units_lost = p$units_lost[, 1])
  }
}
data_grid <- bind_rows(data_grid)

bootstrap_draws <- bind_rows(lapply(names(best_point), function(name) {
  as_tibble(best_point[[name]]) |>
    mutate(estimator = name, draw = 0:draws, score = best_score[[name]], post_parents = post_parents, .before = 1)
}))

# Draw 0 by least squares reproduces the main estimate.
main <- read_csv("../output/estimates.csv", show_col_types = FALSE) |> filter(specification == "main")
least_squares <- bootstrap_draws |> filter(estimator == "least_squares", draw == 0L)
stopifnot(abs(least_squares$kappa - main$kappa) < 1e-9, abs(least_squares$tau - main$tau) < 1e-9,
  abs(least_squares$gamma - main$gamma) < 1e-9, abs(least_squares$sigma / main$sigma - 1) < 1e-9,
  abs(least_squares$units_lost - main$units_lost_model) < 1e-6)

# Likelihood profiles on the data, and likelihood-ratio intervals: the grid
# values whose profile lies within half the 95 percent chi-square(1) value of
# the maximum.
likelihood_profiles <- bind_rows(lapply(c("kappa", "tau", "gamma", "sigma"), function(parameter) {
  data_grid |>
    group_by(value = .data[[parameter]]) |>
    summarise(log_likelihood = max(log_likelihood), .groups = "drop") |>
    mutate(parameter = parameter, .before = 1)
}))
likelihood_ratio <- likelihood_profiles |>
  filter(log_likelihood >= max(data_grid$log_likelihood) - qchisq(0.95, 1) / 2) |>
  group_by(parameter) |>
  summarise(likelihood_ratio_lower = min(value), likelihood_ratio_upper = max(value), .groups = "drop")

bootstrap_estimates <- bootstrap_draws |>
  select(-score, -post_parents) |>
  pivot_longer(c(kappa, tau, gamma, sigma, epsilon, units_lost), names_to = "parameter") |>
  filter(!is.na(value)) |>
  group_by(estimator, parameter) |>
  summarise(estimate = value[draw == 0L],
    bootstrap_lower = quantile(value[draw > 0L], 0.025, type = 1),
    bootstrap_median = quantile(value[draw > 0L], 0.5, type = 1),
    bootstrap_upper = quantile(value[draw > 0L], 0.975, type = 1),
    share_draws_at_estimate = mean(value[draw > 0L] == estimate), draws = sum(draw > 0L), .groups = "drop") |>
  left_join(likelihood_ratio |> mutate(estimator = "likelihood"), by = c("estimator", "parameter"),
    relationship = "one-to-one") |>
  arrange(estimator, match(parameter, c("kappa", "tau", "gamma", "sigma", "epsilon", "units_lost")))

# Cell fit at the likelihood estimate: the model's shares and with the
# unexplained share added.
estimate <- bootstrap_draws |> filter(estimator == "likelihood", draw == 0L)
burden <- burden_table(max(x), max(candidates$J), estimate$kappa, estimate$tau, 1, "separate")
fitted <- predict_draws(choose_sizes(candidates, burden), estimate$gamma)$compared[[match(estimate$sigma,
  sigma_grid)]]
likelihood_cell_fit <- tibble(cell = cells, buildings = rep(c("1", "2", "3+"), each = 15)[cells],
  size_bin = rep(size_bin_labels, 3)[cells], observed_parents = n[, 1], observed = observed_share[, 1],
  model = fitted[, 1], fitted = (1 - estimate$epsilon) * model + estimate$epsilon * uniform)

print(bootstrap_estimates, width = Inf)
SaveData(bootstrap_estimates, c("estimator", "parameter"), "../output/bootstrap_estimates.csv")
SaveData(bootstrap_draws, c("estimator", "draw"), "../output/bootstrap_draws.csv")
SaveData(likelihood_profiles, c("parameter", "value"), "../output/likelihood_profiles.csv")
SaveData(likelihood_cell_fit, "cell", "../output/likelihood_cell_fit.csv")

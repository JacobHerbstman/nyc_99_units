# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

# Each weighted historical parent is moved through the policy choice, and the
# predicted distribution of (total units, buildings) over 45 disjoint cells is
# matched to the recent parents by least squares. Parameters: the jump kappa,
# the kink tau, and the mean splitting cost sigma, found on a grid.
kappa_grid <- c(0, 0.0025, 0.005, seq(0.01, 0.1, by = 0.01), seq(0.12, 0.3, by = 0.02),
  0.35, 0.4, 0.5, 0.6, 0.8, 1)
tau_grid <- c(0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 0.8, 1)
sigma_grid <- exp(seq(log(0.001), log(10), length.out = 41))

# The main specification follows the framework: a jump and a kink at 100,
# separate assessment of each building, lambda = 1, and a splitting cost that
# rises by the same amount with each added building. The others change one
# element at a time.
specifications <- tribble(
  ~specification,          ~variant,      ~weight,                 ~lambda, ~kink, ~growth,  ~assessment,
  "notch_and_kink",        "all_filings", "weight_zoning_borough", 1,       TRUE,  "linear", "separate",
  "pure_notch",            "all_filings", "weight_zoning_borough", 1,       FALSE, "linear", "separate",
  "rising_marginal_cost",  "all_filings", "weight_zoning_borough", 1,       TRUE,  "convex", "separate",
  "lot_area_weights",      "all_filings", "weight_with_lot_area",  1,       TRUE,  "linear", "separate",
  "common_180_day_horizon", "horizon_180", "weight_zoning_borough", 1,      TRUE,  "linear", "separate",
  "curvature_0.5",         "all_filings", "weight_zoning_borough", 0.5,     TRUE,  "linear", "separate",
  "curvature_2",           "all_filings", "weight_zoning_borough", 2,       TRUE,  "linear", "separate",
  "joint_assessment",      "all_filings", "weight_zoning_borough", 1,       TRUE,  "linear", "joint"
)
main_specification <- "notch_and_kink"

parents <- read_parquet("../output/estimation_parents.parquet")

outcome_moments <- function(m, J, mass) {
  rbind(
    share_99 = colSums(mass * (m == 99)),
    share_99_plus_99 = colSums(mass * (m == 198 & J == 2)),
    share_two_buildings = colSums(mass * (J == 2)),
    share_three_plus_buildings = colSums(mass * (J >= 3)),
    share_above_300 = colSums(mass * (m > 300)),
    mean_units = colSums(mass * m)
  )
}

fit_specification <- function(spec) {
  data <- parents |> filter(variant == spec$variant)
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy")
  x <- historical$units
  J0 <- historical$buildings
  w <- historical[[spec$weight]]
  post_parents <- nrow(post)
  observed <- cell_shares(outcome_cell(post$units, post$buildings), matrix(1 / post_parents, post_parents, 1))[, 1]
  candidates <- size_candidates(x, J0, spec$lambda, spec$assessment)
  taus <- if (spec$kink) tau_grid else 0

  results <- list()
  for (tau in taus) for (kappa in kappa_grid) {
    burden <- burden_table(max(x), max(candidates$J), kappa, tau, spec$lambda, spec$assessment)
    sizes <- choose_sizes(candidates, burden)
    segments <- organization_segments(sizes, J0, spec$growth)
    mass <- w[segments$i] * segment_probabilities(segments, sigma_grid)
    shares <- cell_shares(outcome_cell(segments$m, segments$J), mass)
    stopifnot(all(abs(colSums(shares) - 1) < 1e-10))
    fixed_buildings <- sizes$m[sizes$J == J0[sizes$i]]
    results[[length(results) + 1L]] <- list(
      grid = tibble(kappa = kappa, tau = tau, sigma = sigma_grid,
        objective = colSums((shares - observed)^2),
        units_lost_model = post_parents * (sum(w * x) - colSums(mass * segments$m)),
        units_lost_fixed_buildings = post_parents * (sum(w * x) - sum(w * fixed_buildings)),
        as_tibble(t(outcome_moments(segments$m, segments$J, mass)))),
      shares = shares)
  }
  grid <- bind_rows(lapply(results, `[[`, "grid")) |>
    mutate(specification = spec$specification, .before = 1)
  shares <- do.call(cbind, lapply(results, `[[`, "shares"))
  list(grid = grid, shares = shares, observed = observed,
    benchmark = cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[, 1],
    observed_moments = outcome_moments(post$units, post$buildings, matrix(1 / post_parents, post_parents, 1))[, 1],
    benchmark_moments = outcome_moments(x, J0, matrix(w, ncol = 1))[, 1],
    direct_unit_gap = post_parents * (sum(w * x) - mean(post$units)),
    historical_parents = length(x), post_parents = post_parents)
}

fits <- lapply(split(specifications, specifications$specification), fit_specification)

grid <- bind_rows(lapply(fits, `[[`, "grid"))
best <- grid |> group_by(specification) |> slice_min(objective, n = 1, with_ties = FALSE) |> ungroup()

# Grid points within 10 percent of the best objective show how sharply the
# data pick out the parameters.
near_optimal <- grid |>
  group_by(specification) |>
  filter(objective <= 1.1 * min(objective)) |>
  summarise(near_optimal_points = n(),
    kappa_range = paste(range(kappa), collapse = "-"), tau_range = paste(range(tau), collapse = "-"),
    sigma_range = paste(signif(range(sigma), 3), collapse = "-"), .groups = "drop")

estimates <- best |>
  left_join(specifications, by = "specification", relationship = "one-to-one") |>
  left_join(near_optimal, by = "specification", relationship = "one-to-one") |>
  mutate(
    compression = (1 + tau)^(1 / lambda),
    units_preserved_by_splitting = units_lost_fixed_buildings - units_lost_model,
    direct_unit_gap = sapply(fits[specification], `[[`, "direct_unit_gap"),
    historical_parents = sapply(fits[specification], `[[`, "historical_parents"),
    post_parents = sapply(fits[specification], `[[`, "post_parents")) |>
  select(specification, variant, weight, lambda, growth, assessment, kappa, tau, compression,
    sigma, objective, near_optimal_points, kappa_range, tau_range, sigma_range,
    units_lost_model, units_lost_fixed_buildings, units_preserved_by_splitting,
    direct_unit_gap, historical_parents, post_parents) |>
  arrange(match(specification, specifications$specification))

# Observed, benchmark and fitted moments and cells at each best point.
best_column <- function(name) {
  g <- fits[[name]]$grid
  b <- best[best$specification == name, ]
  which(g$kappa == b$kappa & g$tau == b$tau & g$sigma == b$sigma)
}
moment_names <- c("share_99", "share_99_plus_99", "share_two_buildings",
  "share_three_plus_buildings", "share_above_300", "mean_units")
fit_moments <- bind_rows(lapply(specifications$specification, function(name) {
  f <- fits[[name]]
  column <- best_column(name)
  tibble(specification = name, moment = moment_names,
    observed = f$observed_moments[moment_names], benchmark = f$benchmark_moments[moment_names],
    fitted = unlist(f$grid[column, moment_names]))
}))
cell_fit <- bind_rows(lapply(specifications$specification, function(name) {
  f <- fits[[name]]
  column <- best_column(name)
  tibble(specification = name, cell = 1:45,
    buildings = rep(c("1", "2", "3+"), each = 15), size_bin = rep(size_bin_labels, 3),
    observed = f$observed, benchmark = f$benchmark, fitted = f$shares[, column])
}))

# Profiles: the best objective at each value of one parameter.
profiles <- bind_rows(lapply(c("kappa", "tau", "sigma"), function(parameter) {
  grid |>
    group_by(specification, value = .data[[parameter]]) |>
    summarise(objective = min(objective), .groups = "drop") |>
    mutate(parameter = parameter, .after = specification)
}))

# Every grid prediction of the main specification, for the recovery exercise.
main <- fits[[main_specification]]
main_grid_cells <- main$grid |>
  select(kappa, tau, sigma) |>
  mutate(point = row_number()) |>
  slice(rep(seq_len(n()), each = 45)) |>
  mutate(cell = rep(1:45, nrow(main$grid)), share = as.vector(main$shares))

print(estimates, width = Inf)
SaveData(grid, c("specification", "kappa", "tau", "sigma"), "../output/parameter_grid.parquet")
SaveData(estimates, "specification", "../output/estimates.csv")
SaveData(fit_moments, c("specification", "moment"), "../output/fit_moments.csv")
SaveData(cell_fit, c("specification", "cell"), "../output/cell_fit.csv")
SaveData(profiles, c("specification", "parameter", "value"), "../output/parameter_profiles.csv")
SaveData(main_grid_cells, c("point", "cell"), "../output/main_grid_cells.parquet")
SaveData(tibble(cell = 1:45, observed = main$observed), "cell", "../output/main_observed_cells.csv")

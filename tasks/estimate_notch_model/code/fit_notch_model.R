# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

# Each weighted historical parent is moved through the policy choice, and the
# predicted distribution of (total units, buildings) is matched to the recent
# parents by least squares over disjoint cells. Parameters: the jump kappa, the
# kink tau, the mean splitting cost sigma and its growth gamma, on a grid.
kappa_grid <- c(0, 0.0025, 0.005, seq(0.01, 0.1, by = 0.01), seq(0.12, 0.3, by = 0.02),
  0.35, 0.4, 0.5, 0.6, 0.8, 1)
tau_grid <- c(0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 0.8, 1)
gamma_grid <- c(1, 1.25, 1.5, 1.75, 2, 2.5, 3)
sigma_grid <- exp(seq(log(0.001), log(10), length.out = 41))

# The main specification follows the framework, with a separately assessed
# jump and kink at 100 and lambda = 1. It compares parents of at most 300
# units: the size distribution within that range on both sides, so the number
# of very large projects in each period does not enter. Each other
# specification changes one element; below_250 moves the cutoff, and
# all_sizes_linear_cost is the September 24 first fit.
specifications <- tribble(
  ~specification,           ~maximum_units, ~variant,      ~weight,                 ~lambda, ~gamma_free, ~assessment,
  "main",                   300,            "all_filings", "weight_zoning_borough", 1,       TRUE,        "separate",
  "below_250",              249,            "all_filings", "weight_zoning_borough", 1,       TRUE,        "separate",
  "linear_splitting_cost",  300,            "all_filings", "weight_zoning_borough", 1,       FALSE,       "separate",
  "all_sizes",              Inf,            "all_filings", "weight_zoning_borough", 1,       TRUE,        "separate",
  "all_sizes_linear_cost",  Inf,            "all_filings", "weight_zoning_borough", 1,       FALSE,       "separate",
  "lot_area_weights",       300,            "all_filings", "weight_with_lot_area",  1,       TRUE,        "separate",
  "common_180_day_horizon", 300,            "horizon_180", "weight_zoning_borough", 1,       TRUE,        "separate",
  "curvature_0.5",          300,            "all_filings", "weight_zoning_borough", 0.5,     TRUE,        "separate",
  "curvature_2",            300,            "all_filings", "weight_zoning_borough", 2,       TRUE,        "separate",
  "joint_assessment",       300,            "all_filings", "weight_zoning_borough", 1,       FALSE,       "joint"
)
main_specification <- "main"

parents <- read_parquet("../output/estimation_parents.parquet")

# Moments among parents in the compared size range.
outcome_moments <- function(m, J, mass) {
  mass <- mass / rep(colSums(mass), each = nrow(mass))
  rbind(
    share_99 = colSums(mass * (m == 99)),
    share_99_plus_99 = colSums(mass * (m == 198 & J == 2)),
    share_two_buildings = colSums(mass * (J == 2)),
    share_three_plus_buildings = colSums(mass * (J >= 3)),
    mean_units = colSums(mass * m)
  )
}

fit_specification <- function(spec) {
  data <- parents |> filter(variant == spec$variant)
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy")
  maximum_units <- spec$maximum_units
  cells <- cells_up_to(maximum_units)
  x <- historical$units
  J0 <- historical$buildings
  w <- historical[[spec$weight]]
  post <- post |> filter(units <= maximum_units)
  post_parents <- nrow(post)
  post_mass <- matrix(1 / post_parents, post_parents, 1)
  observed <- cell_shares(outcome_cell(post$units, post$buildings), post_mass)[cells, 1]
  stopifnot(abs(sum(observed) - 1) < 1e-12)

  # Units lost are counted among historical parents whose own size is in the
  # compared range, scaled to the recent parents there.
  in_range <- x <= maximum_units
  unit_weight <- w * in_range / sum(w[in_range])
  benchmark_units <- post_parents * sum(unit_weight * x)
  candidates <- size_candidates(x, J0, spec$lambda, spec$assessment)
  gammas <- if (spec$gamma_free) gamma_grid else 1

  results <- list()
  for (tau in tau_grid) for (kappa in kappa_grid) {
    burden <- burden_table(max(x), max(candidates$J), kappa, tau, spec$lambda, spec$assessment)
    sizes <- choose_sizes(candidates, burden)
    fixed_buildings <- sizes$m[sizes$J == J0[sizes$i]]
    for (gamma in gammas) {
      segments <- organization_segments(sizes, J0, gamma)
      probabilities <- segment_probabilities(segments, sigma_grid)
      mass <- w[segments$i] * probabilities
      shares <- cell_shares(outcome_cell(segments$m, segments$J), mass)
      stopifnot(all(abs(colSums(shares) - 1) < 1e-10))
      compared <- shares[cells, , drop = FALSE]
      compared <- compared / rep(colSums(compared), each = length(cells))
      kept <- segments$m <= maximum_units
      results[[length(results) + 1L]] <- list(
        grid = tibble(kappa = kappa, tau = tau, gamma = gamma, sigma = sigma_grid,
          objective = colSums((compared - observed)^2),
          units_lost_model = benchmark_units -
            post_parents * colSums(unit_weight[segments$i] * probabilities * segments$m),
          units_lost_fixed_buildings = benchmark_units - post_parents * sum(unit_weight * fixed_buildings),
          as_tibble(t(outcome_moments(segments$m[kept], segments$J[kept], mass[kept, , drop = FALSE])))),
        shares = compared)
    }
  }
  grid <- bind_rows(lapply(results, `[[`, "grid")) |>
    mutate(specification = spec$specification, .before = 1)
  shares <- do.call(cbind, lapply(results, `[[`, "shares"))
  kept <- x <= maximum_units
  benchmark <- cell_shares(outcome_cell(x, J0), matrix(w, ncol = 1))[cells, 1]
  list(grid = grid, shares = shares, observed = observed, cells = cells,
    benchmark = benchmark / sum(benchmark),
    observed_moments = outcome_moments(post$units, post$buildings, post_mass)[, 1],
    benchmark_moments = outcome_moments(x[kept], J0[kept], matrix(w[kept], ncol = 1))[, 1],
    direct_unit_gap = benchmark_units - sum(post$units),
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
    gamma_range = paste(range(gamma), collapse = "-"),
    sigma_range = paste(signif(range(sigma), 3), collapse = "-"), .groups = "drop")

estimates <- best |>
  left_join(specifications, by = "specification", relationship = "one-to-one") |>
  left_join(near_optimal, by = "specification", relationship = "one-to-one") |>
  mutate(
    compression = (1 + tau)^(1 / lambda),
    units_preserved_by_splitting = units_lost_fixed_buildings - units_lost_model,
    direct_unit_gap = sapply(fits[specification], `[[`, "direct_unit_gap"),
    historical_parents = sapply(fits[specification], `[[`, "historical_parents"),
    post_parents = sapply(fits[specification], `[[`, "post_parents"),
    # Under joint assessment splitting cannot lower the burden, so the
    # splitting cost is not identified.
    across(c(gamma, sigma), ~ if_else(assessment == "joint", NA_real_, .x)),
    across(c(gamma_range, sigma_range), ~ if_else(assessment == "joint", NA_character_, .x))) |>
  select(specification, maximum_units, variant, weight, lambda, assessment, kappa, tau, compression,
    gamma, sigma, objective, near_optimal_points, kappa_range, tau_range, gamma_range, sigma_range,
    units_lost_model, units_lost_fixed_buildings, units_preserved_by_splitting,
    direct_unit_gap, historical_parents, post_parents) |>
  arrange(match(specification, specifications$specification))

# Observed, benchmark and fitted moments and cells at each best point.
best_column <- function(name) {
  g <- fits[[name]]$grid
  b <- best[best$specification == name, ]
  which(g$kappa == b$kappa & g$tau == b$tau & g$gamma == b$gamma & g$sigma == b$sigma)
}
moment_names <- c("share_99", "share_99_plus_99", "share_two_buildings",
  "share_three_plus_buildings", "mean_units")
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
  tibble(specification = name, cell = f$cells,
    buildings = rep(c("1", "2", "3+"), each = 15)[f$cells], size_bin = rep(size_bin_labels, 3)[f$cells],
    observed = f$observed, benchmark = f$benchmark, fitted = f$shares[, column])
}))

# Profiles: the best objective at each value of one parameter.
profiles <- bind_rows(lapply(c("kappa", "tau", "gamma", "sigma"), function(parameter) {
  grid |>
    group_by(specification, value = .data[[parameter]]) |>
    summarise(objective = min(objective), .groups = "drop") |>
    mutate(parameter = parameter, .after = specification)
}))

# Every grid prediction of the main specification, for the recovery exercise.
main <- fits[[main_specification]]
main_grid_cells <- main$grid |>
  select(kappa, tau, gamma, sigma) |>
  mutate(point = row_number()) |>
  slice(rep(seq_len(n()), each = length(main$cells))) |>
  mutate(cell = rep(main$cells, nrow(main$grid)), share = as.vector(main$shares))

print(estimates, width = Inf)
SaveData(estimates, "specification", "../output/estimates.csv")
SaveData(fit_moments, c("specification", "moment"), "../output/fit_moments.csv")
SaveData(cell_fit, c("specification", "cell"), "../output/cell_fit.csv")
SaveData(profiles, c("specification", "parameter", "value"), "../output/parameter_profiles.csv")
SaveData(main_grid_cells, c("point", "cell"), "../output/main_grid_cells.parquet")

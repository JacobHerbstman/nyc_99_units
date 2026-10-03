# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

# The single jump by least squares, a robustness check on the likelihood of
# fit_heterogeneity.R. Each weighted historical parent is moved through the
# policy choice, and the predicted shares of (total units, buildings) cells are
# matched to the recent parents' shares by least squares. The parameters, the
# jump kappa, the mean splitting cost sigma and its growth gamma, run over the
# grid in notch_model.R.

# least_squares compares parents of at most 300 units, the distribution within
# that range on both sides, so the number of very large projects in each period
# does not enter. Each other specification changes one element.
specifications <- tribble(
  ~specification,           ~maximum_units, ~variant,      ~weight,                 ~lambda, ~gamma_free, ~assessment,
  "least_squares",          300,            "all_filings", "weight_zoning_borough", 1,       TRUE,        "separate",
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

parents <- read_parquet("../output/estimation_parents.parquet")

# Every grid point of one specification, with its objective and units lost.
fit_specification <- function(spec) {
  data <- parents |> filter(variant == spec$variant)
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy", units <= spec$maximum_units)
  x <- historical$units
  J0 <- historical$buildings
  w <- historical[[spec$weight]]
  cells <- cells_up_to(spec$maximum_units)
  observed <- tabulate(outcome_cell(post$units, post$buildings), 45L)[cells] / nrow(post)
  stopifnot(abs(sum(observed) - 1) < 1e-12)

  # Units lost are counted among historical parents whose own size is in the
  # compared range, scaled to the recent parents there.
  unit_weight <- w * (x <= spec$maximum_units) / sum(w[x <= spec$maximum_units])
  benchmark_units <- nrow(post) * sum(unit_weight * x)
  candidates <- size_candidates(x, J0, spec$lambda, spec$assessment)
  gammas <- if (spec$gamma_free) gamma_grid else 1

  grid <- list()
  for (kappa in kappa_grid) {
    sizes <- choose_sizes(candidates, burden_table(max(x), max(candidates$J), kappa, spec$assessment))
    # Units lost if every parent kept its historical building count.
    fixed_buildings <- sizes$m[sizes$J == J0[sizes$i]]
    for (gamma in gammas) {
      segments <- organization_segments(sizes, J0, gamma)
      probabilities <- segment_probabilities(segments, sigma_grid)
      shares <- cell_shares(outcome_cell(segments$m, segments$J), w[segments$i] * probabilities)[cells, , drop = FALSE]
      shares <- shares / rep(colSums(shares), each = length(cells))
      grid[[length(grid) + 1L]] <- tibble(kappa = kappa, gamma = gamma, sigma = sigma_grid,
        objective = colSums((shares - observed)^2),
        units_lost_model = benchmark_units -
          nrow(post) * colSums(unit_weight[segments$i] * probabilities * segments$m),
        units_lost_fixed_buildings = benchmark_units - nrow(post) * sum(unit_weight * fixed_buildings))
    }
  }
  # The best point, with the gap in mean units between the reweighted
  # historical parents and the recent ones, which uses no model.
  bind_rows(grid) |>
    slice_min(objective, n = 1, with_ties = FALSE) |>
    mutate(direct_unit_gap = benchmark_units - sum(post$units), historical_parents = length(x),
      post_parents = nrow(post))
}

estimates <- bind_rows(lapply(seq_len(nrow(specifications)), function(r) {
  specifications[r, ] |> bind_cols(fit_specification(specifications[r, ]))
})) |>
  mutate(units_preserved_by_splitting = units_lost_fixed_buildings - units_lost_model,
    # Under joint assessment splitting cannot lower the burden, so the
    # splitting cost is not identified.
    across(c(gamma, sigma), ~ if_else(assessment == "joint", NA_real_, .x))) |>
  select(specification, maximum_units, variant, weight, lambda, assessment, kappa, gamma, sigma, objective,
    units_lost_model, units_lost_fixed_buildings, units_preserved_by_splitting, direct_unit_gap,
    historical_parents, post_parents)

print(estimates, width = Inf)
SaveData(estimates, "specification", "../output/estimates.csv")

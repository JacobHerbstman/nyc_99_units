# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/prepare_developer_cost_calibration/code")
# bunch_units <- 99L
# threshold_units <- 100L

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2L) {
  stop("Expected two arguments: bunch units and policy threshold units.")
}

bunch_units <- as.integer(args[1])
threshold_units <- as.integer(args[2])

if (
  any(is.na(c(bunch_units, threshold_units))) ||
    bunch_units + 1L != threshold_units
) {
  stop("The bunch point must be one unit below the policy threshold.")
}

counterfactual <- read_csv(
  "../input/enhanced_parent_2025_counterfactual.csv",
  show_col_types = FALSE
)

distribution <- read_csv(
  "../input/enhanced_parent_2025_distribution.csv",
  show_col_types = FALSE
)

if (
  nrow(counterfactual) != 1L ||
    counterfactual$unit_definition != "hdb_priority" ||
    anyDuplicated(distribution$units) ||
    any(distribution$expected_count < 0)
) {
  stop("Developer cost-calibration inputs failed key QC.")
}

target_mass <- counterfactual$excess_exact_99

affected_weights <- distribution |>
  filter(units >= threshold_units) |>
  arrange(units) |>
  mutate(
    model = counterfactual$model,
    mass_before = lag(cumsum(expected_count), default = 0),
    affected_parent_mass = pmax(
      pmin(expected_count, target_mass - mass_before),
      0
    ),
    affected_parent_weight = affected_parent_mass / target_mass,
    units_above_bunch_point = units - bunch_units,
    weighted_units_above_bunch_point =
      affected_parent_mass * units_above_bunch_point
  ) |>
  filter(affected_parent_mass > 0) |>
  select(
    model, unit_definition, units_n0 = units,
    no_notch_expected_parent_mass = expected_count,
    affected_parent_mass, affected_parent_weight,
    units_above_bunch_point, weighted_units_above_bunch_point
  )

mean_n0 <- weighted.mean(
  affected_weights$units_n0,
  affected_weights$affected_parent_mass
)

calibration_targets <- counterfactual |>
  transmute(
    model,
    unit_definition,
    bunch_units,
    threshold_units,
    training_parents,
    observed_completed_2025_parents,
    scoreable_completed_2025_parents = scoreable_2025_parents,
    observed_exact_bunch_parents = observed_exact_99,
    expected_no_notch_exact_bunch_parents =
      expected_no_notch_exact_99,
    excess_exact_bunch_parent_mass = excess_exact_99,
    affected_mean_n0 = mean_n0,
    affected_frontier_n0 = frontier_from_exact_99,
    mean_units_above_bunch_point = mean_n0 - bunch_units,
    sample_equivalent_units_above_bunch_point = sum(
      affected_weights$weighted_units_above_bunch_point
    )
  )

if (
  abs(sum(affected_weights$affected_parent_mass) - target_mass) > 1e-8 ||
    abs(sum(affected_weights$affected_parent_weight) - 1) > 1e-8 ||
    abs(mean_n0 - counterfactual$mean_n0_from_exact_99) > 1e-8 ||
    any(!is.finite(unlist(
      calibration_targets |>
        select(where(is.numeric))
    )))
) {
  stop("Developer cost-calibration outputs failed final QC.")
}

write_csv_if_changed(
  calibration_targets,
  "../output/developer_cost_calibration_targets.csv"
)
write_csv_if_changed(
  affected_weights,
  "../output/affected_parent_n0_weights.csv"
)

cat("Wrote developer cost-calibration targets to ../output\n")

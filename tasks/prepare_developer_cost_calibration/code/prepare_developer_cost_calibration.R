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

counterfactual <- bind_rows(
  read_csv(
    "../input/enhanced_parent_2025_counterfactual.csv",
    show_col_types = FALSE
  ) |>
    mutate(preferred_specification = TRUE),
  read_csv(
    "../input/enhanced_parent_completed_365_2025_counterfactual.csv",
    show_col_types = FALSE
  ) |>
    mutate(preferred_specification = FALSE)
)

distribution <- bind_rows(
  read_csv(
    "../input/enhanced_parent_2025_distribution.csv",
    show_col_types = FALSE
  ),
  read_csv(
    "../input/enhanced_parent_completed_365_2025_distribution.csv",
    show_col_types = FALSE
  )
)

if (
  nrow(counterfactual) != 2L ||
    any(counterfactual$unit_definition != "hdb_priority") ||
    sum(counterfactual$preferred_specification) != 1L ||
    anyDuplicated(distribution[c("model", "units")]) ||
    !setequal(distribution$model, counterfactual$model) ||
    any(distribution$expected_count < 0)
) {
  stop("Developer cost-calibration inputs failed key QC.")
}

affected_weights <- distribution |>
  filter(units >= threshold_units) |>
  left_join(
    counterfactual |>
      select(
        model, preferred_specification,
        target_mass = excess_exact_99
      ),
    by = "model",
    relationship = "many-to-one"
  ) |>
  arrange(model, units) |>
  group_by(model) |>
  mutate(
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
  ungroup() |>
  select(
    model, cohort_sample, preferred_specification,
    unit_definition, target_mass, units_n0 = units,
    no_notch_expected_parent_mass = expected_count,
    affected_parent_mass, affected_parent_weight,
    units_above_bunch_point, weighted_units_above_bunch_point
  )

affected_summary <- affected_weights |>
  group_by(model) |>
  summarise(
    affected_mean_n0 = weighted.mean(
      units_n0,
      affected_parent_mass
    ),
    sample_equivalent_units_above_bunch_point = sum(
      weighted_units_above_bunch_point
    ),
    .groups = "drop"
  )

calibration_targets <- counterfactual |>
  transmute(
    model, cohort_sample, preferred_specification,
    minimum_observed_followup_days,
    unit_definition,
    bunch_units,
    threshold_units,
    training_parents,
    observed_2025_parents,
    scoreable_2025_parents,
    observed_exact_bunch_parents = observed_exact_99,
    expected_no_notch_exact_bunch_parents =
      expected_no_notch_exact_99,
    excess_exact_bunch_parent_mass = excess_exact_99,
    affected_frontier_n0 = frontier_from_exact_99
  ) |>
  left_join(
    affected_summary,
    by = "model",
    relationship = "one-to-one"
  ) |>
  mutate(mean_units_above_bunch_point = affected_mean_n0 - bunch_units) |>
  arrange(desc(preferred_specification))

mean_n0_check <- calibration_targets |>
  select(model, affected_mean_n0) |>
  left_join(
    counterfactual |>
      select(model, model_affected_mean_n0 = mean_n0_from_exact_99),
    by = "model",
    relationship = "one-to-one"
  )

if (
  any(abs(
    affected_weights |>
      group_by(model) |>
      summarise(
        error = sum(affected_parent_mass) - first(target_mass),
        .groups = "drop"
      ) |>
      pull(error)
  ) > 1e-8) ||
    any(abs(
      affected_weights |>
        group_by(model) |>
        summarise(
          error = sum(affected_parent_weight) - 1,
          .groups = "drop"
        ) |>
        pull(error)
    ) > 1e-8) ||
    any(abs(
      mean_n0_check$affected_mean_n0 -
        mean_n0_check$model_affected_mean_n0
    ) > 1e-8) ||
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

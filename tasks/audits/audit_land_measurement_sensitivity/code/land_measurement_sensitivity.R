# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_land_measurement_sensitivity/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../../shared/code/scale_shape_helpers.R")
source("../../../shared/code/write_data_report.R")

minimum_units <- 50L
pooled_tail_start <- 301L

# Reweighting sample: adopted rental parents with at least 50 units and
# complete parcel characteristics, as in audit_scale_shape_splitting.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as_tibble() |>
  filter(included_ab, parent_total_units >= minimum_units, composition_eligible)

# Boundary flags and the audit's alternative lot area. candidate_area_sqft is
# the earlier-parcel area for parents passing the boundary checks and missing
# for the flagged parents.
site_scope <- read_csv(
  "../input/parent_site_scope.csv",
  col_types = cols(.default = col_character())
) |>
  transmute(
    parent_id,
    boundary_flagged = as.logical(unresolved),
    candidate_area_sqft = as.numeric(candidate_area_sqft)
  )

stopifnot(
  !anyDuplicated(parents$parent_id),
  !anyDuplicated(site_scope$parent_id),
  setequal(parents$parent_id, site_scope$parent_id)
)

parents <- parents |>
  left_join(site_scope, by = "parent_id", relationship = "one-to-one")

stopifnot(!anyNA(parents$boundary_flagged))

# Land-measurement scenarios. Each changes only the parcel characteristics
# used in calibration (or the sample); units and organization are unchanged.
# Rescaling lot area holds earlier building floor fixed, so built FAR moves
# inversely. Residential FAR is a zoning ratio and is held fixed.
rescale_flagged_land <- function(data, factor) {
  data |>
    mutate(
      lot_area_sqft = if_else(boundary_flagged, lot_area_sqft * factor, lot_area_sqft),
      built_far = if_else(boundary_flagged, built_far / factor, built_far),
      log_lot_area = log(lot_area_sqft)
    )
}

scenarios <- list(
  production = parents,
  drop_flagged_parents = parents |> filter(!boundary_flagged),
  audit_candidate_area = parents |>
    mutate(
      lot_area_sqft = coalesce(candidate_area_sqft, lot_area_sqft),
      log_lot_area = log(lot_area_sqft)
    ),
  flagged_land_halved = rescale_flagged_land(parents, 0.5),
  flagged_land_doubled = rescale_flagged_land(parents, 2),
  # Production land counts DOF mergers recorded within 180 days of filing.
  # Post-period parents filed less than 180 days before the DOF snapshot may
  # still gain lots; this keeps only parents with the full window.
  complete_merger_window = parents |> filter(merger_window_complete),
  # Sites with under 150 sq ft of permitted residential floor per unit.
  drop_implausible_sites = parents |> filter(!implausible_site)
)

summarise_scenario <- function(data, scenario, match) {
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy")

  if (match != "unweighted") {
    historical <- calibrate_historical_to_target(historical, post, matches[[match]])$historical
  } else {
    historical <- historical |> mutate(calibration_weight = 1)
  }
  weight <- historical$calibration_weight / sum(historical$calibration_weight)

  historical_distribution <- weighted_exact_distribution(
    historical, "parent_total_units", "calibration_weight",
    minimum_units, pooled_tail_start
  )
  post_distribution <- weighted_exact_distribution(
    post |> mutate(observation_weight = 1), "parent_total_units",
    "observation_weight", minimum_units, pooled_tail_start
  )
  moments <- local_shape_moments(historical_distribution, post_distribution, "Parent total")

  tibble(
    scenario = scenario,
    match = match,
    historical_parents = nrow(historical),
    post_parents = nrow(post),
    effective_sample_size = 1 / sum(weight^2),
    maximum_weight_share = max(weight),
    historical_share_exact_99 = sum(weight * (historical$parent_total_units == 99)),
    post_share_exact_99 = mean(post$parent_total_units == 99),
    excess_at_99 = moments$estimate[moments$moment == "excess_at_99"],
    excess_at_198 = moments$estimate[moments$moment == "excess_at_198"],
    cumulative_deficit_100_149 =
      moments$estimate[moments$moment == "cumulative_deficit_100_149"],
    historical_share_multi_component = sum(weight * historical$multi_component),
    post_share_multi_component = mean(post$multi_component),
    historical_mean_units = sum(weight * historical$parent_total_units),
    post_mean_units = mean(post$parent_total_units)
  )
}

# Production weights match zoning and borough, so land enters only the
# robustness matches: adding lot area, and the earlier match that also used
# existing building density.
matches <- list(
  zoning_borough = calibration_formula,
  with_lot_area = lot_area_formula,
  previous_match = previous_formula
)
sensitivity <- bind_rows(
  summarise_scenario(parents, "unweighted_historical", "unweighted"),
  bind_rows(lapply(names(matches), function(match) {
    bind_rows(Map(summarise_scenario, scenarios, names(scenarios), match))
  }))
)

# The production scenario must reproduce the saved benchmark weights.
saved_weights <- read_csv(
  "../input/calibration_weights.csv",
  col_types = cols(parent_id = col_character(), calibration_weight = col_double(), .default = col_skip())
)
recomputed_weights <- calibrate_historical_to_target(
  parents |> filter(sample == "historical"),
  parents |> filter(sample == "post_policy")
)$historical |>
  select(parent_id, calibration_weight) |>
  inner_join(saved_weights, by = "parent_id", suffix = c("", "_saved"), relationship = "one-to-one")

stopifnot(
  nrow(recomputed_weights) == nrow(saved_weights),
  max(abs(recomputed_weights$calibration_weight - recomputed_weights$calibration_weight_saved)) < 1e-8
)

SaveData(sensitivity, c("scenario", "match"), "../output/land_measurement_sensitivity.csv")

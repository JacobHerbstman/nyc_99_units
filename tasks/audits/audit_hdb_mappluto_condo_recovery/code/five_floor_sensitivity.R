# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(tibble)
source("../../../shared/code/scale_shape_helpers.R")
source("../../../shared/code/write_data_report.R")
library(readr)

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible)
overlaps <- read_parquet("../output/dof_all_parent_overlaps.parquet") |>
  filter(parent_id == "historical__121207504")
east125_lots <- read_parquet("../input/dcp_mappluto_archive_20v1.parquet") |>
  filter(bbl %in% c("1017730020", "1017730027"))
east125_floor <- overlaps |>
  left_join(east125_lots |> select(bbl, bldgarea), by = "bbl", relationship = "one-to-one") |>
  summarise(floor = sum(old_share * bldgarea)) |>
  pull(floor)
stopifnot(nrow(east125_lots) == 2, nrow(overlaps) == 2, is.finite(east125_floor))
jamaica_floor <- read_csv("../output/jamaica_floor_allocation.csv", show_col_types = FALSE) |>
  summarise(floor = sum(included_frozen_floor)) |>
  pull(floor)
kingsbrook_floor <- read_csv("../output/remaining_floor_candidates.csv", show_col_types = FALSE) |>
  filter(case == "Kingsbrook") |>
  pull(candidate_floor)

# Ground comes from the recorded boundaries cited in five_floor_decisions.md.
# Floor totals are frozen MapPLUTO totals on the contributing old parcels,
# before land allocation; Jamaica excludes the wholly retained lots 89/94.
# Adopted estimates carry a production flag; endpoints are stress tests only.
cases <- tribble(
  ~case, ~parent_id, ~ground, ~old_floor, ~adopted_floor,
  "East 125th", "historical__121207504", 42540, 85223, east125_floor,
  "St. James", "historical__210181747", 17775, 13000, 3650,
  "Jamaica 165th", "post_policy__Q01243880-I1", 39349.5, 52593, jamaica_floor,
  "Onderdonk", "post_policy__Q01337462-I1", 9310, 18658, 18658 * 9310 / 13218,
  "Kingsbrook", "post_policy__B01318629-I1", 105382, 588598, kingsbrook_floor)
stopifnot(!anyDuplicated(parents$parent_id), all(cases$parent_id %in% parents$parent_id))

# Change one parent at a time, keeping the sample, other parents, and weighting
# formula fixed. These endpoints are not confidence intervals or joint bounds.
results <- list()
for (i in seq_len(nrow(cases))) {
  review <- cases[i, ]
  current <- parents |> filter(parent_id == review$parent_id)
  scenarios <- tibble(
    scenario = c("current", "correct_ground_no_old_floor", "correct_ground_all_old_floor", "adopted_flagged_value"),
    ground = c(current$lot_area_sqft, rep(review$ground, 3)),
    floor = c(current$built_floor_area_sqft, 0, review$old_floor, review$adopted_floor))
  for (j in seq_len(nrow(scenarios))) {
    adjusted <- parents
    row <- adjusted$parent_id == review$parent_id
    adjusted$lot_area_sqft[row] <- scenarios$ground[j]
    adjusted$log_lot_area[row] <- log(scenarios$ground[j])
    adjusted$built_far[row] <- scenarios$floor[j] / scenarios$ground[j]
    fit <- calibrate_historical_to_target(
      adjusted |> filter(sample == "historical"),
      adjusted |> filter(sample == "post_policy"))
    w <- fit$historical$calibration_weight
    units <- fit$historical$parent_total_units
    results[[length(results) + 1]] <- scenarios[j, ] |>
      mutate(case = review$case, parent_id = review$parent_id,
        historical_parents = nrow(fit$historical), post_parents = nrow(fit$target),
        counterfactual_99_share = sum(w[units == 99]) / sum(w),
        counterfactual_198_share = sum(w[units == 198]) / sum(w),
        counterfactual_mean_units = sum(w * units) / sum(w),
        maximum_moment_error = fit$maximum_moment_error)
  }
}
SaveData(bind_rows(results), c("parent_id", "scenario"), "../output/five_floor_sensitivity.csv")

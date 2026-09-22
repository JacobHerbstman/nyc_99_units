# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/scale_shape_helpers.R")
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible)
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy")
old_lots <- read_csv("../input/campus_covariate_crosswalk_rows.csv", show_col_types = FALSE) |>
  filter(case == "flatbush", vintage == "18v2_1")
overlaps <- read_csv("../input/flatbush_geometry_overlap.csv", show_col_types = FALSE)
stopifnot(setequal(old_lots$lot, c(18, 23, 24)), !anyDuplicated(old_lots$lot),
  !anyDuplicated(overlaps$bbl), setequal(old_lots$bbl, overlaps$bbl))

# Land and floor use the administrative fields. Only the allocation share comes
# from the polygon intersection. Uniform floor density is a labeled assumption.
complete_floor <- sum(old_lots$bldgarea[old_lots$lot %in% c(23, 24)])
partial_floor <- old_lots$bldgarea[old_lots$lot == 18]
partial_share <- overlaps$old_share[overlaps$bbl == "3001740018"]
scenarios <- tibble(
  scenario = c("previous_parcel_match", "none_of_lot18_floor", "adopted_land_share", "all_of_lot18_floor"),
  lot_area_sqft = c(old_lots$lotarea[old_lots$lot == 23], 12603, 12603, 12603),
  built_far = c(old_lots$builtfar[old_lots$lot == 23],
    complete_floor / 12603, (complete_floor + partial_share * partial_floor) / 12603,
    (complete_floor + partial_floor) / 12603))
flatbush <- historical$parent_id == "historical__321595145"
stopifnot(sum(flatbush) == 1, historical$built_floor_area_estimated[flatbush],
  abs(historical$built_far[flatbush] - scenarios$built_far[3]) < 1e-10,
  historical$lot_area_sqft[flatbush] == 12603)

results <- list()
for (i in seq_len(nrow(scenarios))) {
  adjusted <- historical
  adjusted$lot_area_sqft[flatbush] <- scenarios$lot_area_sqft[i]
  adjusted$log_lot_area[flatbush] <- log(scenarios$lot_area_sqft[i])
  adjusted$built_far[flatbush] <- scenarios$built_far[i]
  fit <- calibrate_historical_to_target(adjusted, post)
  w <- fit$historical$calibration_weight
  units <- fit$historical$parent_total_units
  results[[i]] <- scenarios[i, ] |>
    mutate(built_floor_area_sqft = lot_area_sqft * built_far,
      historical_parents = nrow(historical), post_parents = nrow(post),
      flatbush_weight = w[flatbush],
      counterfactual_99_share = sum(w[units == 99]) / sum(w),
      counterfactual_198_share = sum(w[units == 198]) / sum(w),
      counterfactual_tail_count = sum(w[units > 300]),
      counterfactual_mean_units = sum(w * units) / sum(w),
      maximum_moment_error = fit$maximum_moment_error)
}
SaveData(bind_rows(results), "scenario", "../output/flatbush_floor_sensitivity.csv")

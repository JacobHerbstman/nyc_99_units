# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
})
source("../../shared/code/scale_shape_helpers.R")
source("../../shared/code/write_data_report.R")

minimum_units <- 50L
horizon_days <- 180L

# The comparison sample: adopted rental parents with at least 50 units and
# complete site characteristics, 2019-2022 against January 2025-July 8, 2026.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, composition_eligible)
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |>
  filter(parent_id %in% parents$parent_id) |>
  transmute(parent_id, units = constituent_units,
    days_after_first_filing = as.integer(as.Date(date_filed) - as.Date(cohort_date)))
stopifnot(!anyNA(constituents$days_after_first_filing), all(constituents$days_after_first_filing >= 0))

# Common follow-up horizon: most recent parents have not been observed for a
# full year, so companions filed later are missing. This variant counts only
# buildings filed within 180 days of the first filing, in both periods, and
# keeps recent parents observed for at least 180 days.
count_buildings <- function(data) {
  data |>
    group_by(parent_id) |>
    summarise(units = sum(units), buildings = n(), .groups = "drop")
}
variants <- list(
  all_filings = count_buildings(constituents),
  horizon_180 = count_buildings(constituents |> filter(days_after_first_filing <= horizon_days))
)

site_traits <- parents |>
  select(sample, parent_id, residential_far, built_far, log_lot_area, borough,
    observed_followup_days, parent_total_units, n_components)

estimation_parents <- bind_rows(lapply(names(variants), function(variant) {
  data <- site_traits |>
    inner_join(variants[[variant]], by = "parent_id", relationship = "one-to-one") |>
    filter(units >= minimum_units)
  if (variant == "all_filings") {
    stopifnot(all(data$units == data$parent_total_units), all(data$buildings == data$n_components))
  } else {
    data <- data |> filter(sample == "historical" | observed_followup_days >= horizon_days)
  }
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy")
  zoning_borough <- calibrate_historical_to_target(historical, post)$historical$calibration_weight
  with_lot_area <- calibrate_historical_to_target(historical, post, lot_area_formula)$historical$calibration_weight
  bind_rows(
    historical |> mutate(weight_zoning_borough = zoning_borough / sum(zoning_borough),
      weight_with_lot_area = with_lot_area / sum(with_lot_area)),
    post |> mutate(weight_zoning_borough = 1 / n(), weight_with_lot_area = 1 / n())
  ) |>
    transmute(variant, sample, parent_id, units, buildings, weight_zoning_borough, weight_with_lot_area,
      residential_far, built_far, log_lot_area, borough)
}))

SaveData(estimation_parents, c("variant", "sample", "parent_id"), "../output/estimation_parents.parquet")

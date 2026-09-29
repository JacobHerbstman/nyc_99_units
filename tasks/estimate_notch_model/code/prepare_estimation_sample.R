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
# complete site characteristics, 2019-2022 against January 2025-July 8, 2026,
# with each parent's units and buildings counted over its filings.
count_buildings <- function(constituents) {
  constituents |>
    group_by(parent_id) |>
    summarise(units = sum(units), buildings = n(), .groups = "drop")
}
read_sample <- function(parent_file, constituent_file) {
  parents <- read_parquet(parent_file) |> filter(included_ab, composition_eligible)
  constituents <- read_parquet(constituent_file) |>
    filter(parent_id %in% parents$parent_id) |>
    transmute(parent_id, units = constituent_units,
      days_after_first_filing = as.integer(as.Date(date_filed) - as.Date(cohort_date)))
  stopifnot(!anyNA(constituents$days_after_first_filing), all(constituents$days_after_first_filing >= 0))
  list(parents = parents, constituents = constituents)
}
comparison <- read_sample("../input/parent_opportunity_panel.parquet", "../input/constituent_filing_panel.parquet")
placebo <- read_sample("../input/placebo_parent_opportunity_panel.parquet",
  "../input/placebo_constituent_filing_panel.parquet")

site_traits <- function(parents) {
  parents |>
    select(sample, parent_id, cohort_date, residential_far, built_far, log_lot_area, borough,
      observed_followup_days, parent_total_units, n_components)
}

# Variants of the sample:
#   all_filings  the comparison, counting every filing;
#   horizon_180  a common follow-up horizon: most recent parents have not been
#                observed for a full year, so this counts only buildings filed
#                within 180 days of the first filing, in both periods, and keeps
#                recent parents observed for at least 180 days;
#   cohort_2025  recent parents first filed in 2025, which have the longest
#                follow-up;
#   placebo      a pre-policy placebo: historical parents first filed in
#                2015-2018 stand in for the historical sample and those first
#                filed in 2019-2022, before 485-x, for the recent one.
variants <- list(
  all_filings = site_traits(comparison$parents) |>
    inner_join(count_buildings(comparison$constituents), by = "parent_id", relationship = "one-to-one"),
  horizon_180 = site_traits(comparison$parents) |>
    inner_join(count_buildings(comparison$constituents |> filter(days_after_first_filing <= horizon_days)),
      by = "parent_id", relationship = "one-to-one") |>
    filter(sample == "historical" | observed_followup_days >= horizon_days),
  cohort_2025 = site_traits(comparison$parents) |>
    inner_join(count_buildings(comparison$constituents), by = "parent_id", relationship = "one-to-one") |>
    filter(sample == "historical" | cohort_date < as.Date("2026-01-01")),
  placebo = site_traits(placebo$parents) |>
    filter(sample == "historical") |>
    inner_join(count_buildings(placebo$constituents), by = "parent_id", relationship = "one-to-one") |>
    mutate(sample = if_else(cohort_date < as.Date("2019-01-01"), "historical", "post_policy"))
)
stopifnot(with(variants$all_filings, all(units == parent_total_units), all(buildings == n_components)),
  with(variants$placebo, all(units == parent_total_units), all(buildings == n_components)))

estimation_parents <- bind_rows(lapply(names(variants), function(variant) {
  data <- variants[[variant]] |> filter(units >= minimum_units)
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

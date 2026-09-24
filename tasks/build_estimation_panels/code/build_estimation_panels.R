# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_estimation_panels/code")
# pre_start_date <- as.Date("2019-01-01")
# pre_end_date <- as.Date("2022-12-31")
# post_start_date <- as.Date("2025-01-01")
# post_end_date <- as.Date("2026-07-08")
# minimum_units <- 6L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 5L)
  pre_start_date <- as.Date(args[1])
  pre_end_date <- as.Date(args[2])
  post_start_date <- as.Date(args[3])
  post_end_date <- as.Date(args[4])
  minimum_units <- as.integer(args[5])
}
stopifnot(pre_start_date <= pre_end_date, pre_end_date < post_start_date, post_start_date <= post_end_date)

# The comparison: parents first filed in the historical period and fully
# observed, and parents first filed in the post-policy period with the year
# before their first filing observed, each with at least six units.
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
stopifnot(!anyDuplicated(membership[c("sample", "root_job_id")]),
  n_distinct(membership$source_end_date[membership$sample == "post_policy"]) == 1L,
  post_end_date <= max(membership$source_end_date[membership$sample == "post_policy"]))
parents <- membership |>
  group_by(sample, parent_id) |>
  summarise(cohort_date = first(cohort_date), cohort_year = first(cohort_year),
    refiling_date = if (any(refiled)) min(refiling_date[refiled]) else as.Date(NA), refiled = any(refiled),
    parent_total_units = first(parent_observed_units), left_window_observed = first(left_window_observed),
    right_window_observed = first(right_window_observed), full_window_observed = first(full_window_observed),
    parent_last_filing_date = first(parent_last_filing_date), source_end_date = first(source_end_date),
    .groups = "drop") |>
  filter(parent_total_units >= minimum_units,
    (sample == "historical" & cohort_date >= pre_start_date & cohort_date <= pre_end_date & full_window_observed) |
      (sample == "post_policy" & cohort_date >= post_start_date & cohort_date <= post_end_date &
        left_window_observed)) |>
  mutate(period = if_else(sample == "historical", paste0("Pre: ", format(pre_start_date, "%Y"), "-",
      format(pre_end_date, "%Y")), paste0("Post: ", format(post_start_date, "%Y"), "-",
      format(post_end_date, "%b "), as.integer(format(post_end_date, "%d")), ", ", format(post_end_date, "%Y"))),
    exposure_years = if_else(sample == "historical", as.numeric(pre_end_date - pre_start_date + 1L),
      as.numeric(post_end_date - post_start_date + 1L)) / 365.25,
    observed_followup_days = as.integer(source_end_date - cohort_date)) |>
  select(-source_end_date)

# Constituents are the additive filings, largest first. The latest HPD
# registration of each marks whether it was registered as a separate sub-100
# building.
exposure_universe <- read_csv("../input/parent_485x_exposure_universe.csv", show_col_types = FALSE, guess_max = Inf)
hpd <- read_csv("../input/hpd_485x_registration_dob_links.csv", show_col_types = FALSE, guess_max = Inf) |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(sample = "post_policy", root_job_id = matched_dob_root_job_id, hpd_response_number = response_number,
    hpd_intended_separate_sub100 = intended_separate_sub100_treatment)
stopifnot(!anyDuplicated(exposure_universe[c("sample", "root_job_id")]), !anyDuplicated(hpd$root_job_id))
constituents <- membership |>
  filter(additive_component) |>
  semi_join(parents, by = c("sample", "parent_id")) |>
  left_join(exposure_universe |> select(sample, root_job_id, universe_parent_id = parent_id,
    universe_units = component_units, address, borough_name, owner_name), by = c("sample", "root_job_id"),
    relationship = "one-to-one") |>
  left_join(hpd, by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  group_by(sample, parent_id) |>
  arrange(desc(units), date_filed, root_job_id, .by_group = TRUE) |>
  mutate(parent_constituent_weight = 1 / n()) |>
  ungroup()
stopifnot(all(constituents$universe_parent_id == constituents$parent_id), all(constituents$units > 0L),
  all(is.na(constituents$universe_units) | constituents$units == constituents$universe_units))

# A split is verified when every constituent has its own HPD registration for
# separate sub-100 treatment, and suggestive when constituents sit on
# different filing lots.
components <- constituents |>
  group_by(sample, parent_id) |>
  summarise(n_components = n(), constituent_units = sum(units), max_component_units = max(units),
    second_component_units = if_else(n() >= 2L, nth(units, 2L), NA_integer_),
    third_component_units = if_else(n() >= 3L, nth(units, 3L), NA_integer_),
    n_components_eq_99 = sum(units == 99L), exact_99x2 = n() == 2L && all(units == 99L),
    exact_99x3 = n() == 3L && all(units == 99L), sorted_component_vector = paste(units, collapse = "+"),
    component_job_numbers = paste(root_job_id, collapse = ";"),
    component_addresses = paste(sort(unique(na.omit(address))), collapse = ";"),
    distinct_lots = n_distinct(filing_bbl, na.rm = TRUE),
    verified_separate = n() > 1L && all(!is.na(hpd_response_number)) &&
      n_distinct(hpd_response_number) == n() && all(coalesce(hpd_intended_separate_sub100, FALSE)),
    shared_hpd_response = n() > 1L && anyDuplicated(na.omit(hpd_response_number)) > 0L, .groups = "drop") |>
  mutate(single_component = n_components == 1L, multi_component = n_components > 1L,
    splitting_verification_status = case_when(
      single_component ~ "not_applicable_single_component",
      verified_separate ~ "verified_separate_485x_units",
      shared_hpd_response ~ "same_eligible_site_or_application",
      distinct_lots == n_components ~ "suggestive_separate_components",
      TRUE ~ "unable_to_verify"))

exposure <- read_csv("../input/parent_485x_exposure.csv", show_col_types = FALSE, guess_max = Inf) |>
  select(sample, parent_id, exposure_status, included_ab, included_ab_plus_d, confidence, classification_reason,
    source_url)
features <- bind_rows(read_parquet("../input/historical_parent_site_characteristics.parquet"),
  read_parquet("../input/post_policy_parent_site_characteristics.parquet")) |>
  transmute(sample, parent_id, feature_units = units, composition_eligible, site_feature_method = feature_methods,
    number_unique_lots = feature_lots, lot_area_sqft = lotarea, residential_far = residfar, built_far = builtfar,
    built_floor_area_estimated, merged_lots_added, merger_window_complete, implausible_site, borough,
    community_district)
stopifnot(!anyDuplicated(exposure[c("sample", "parent_id")]), !anyDuplicated(features[c("sample", "parent_id")]))

parent_panel <- parents |>
  left_join(exposure, by = c("sample", "parent_id"), relationship = "one-to-one") |>
  left_join(components, by = c("sample", "parent_id"), relationship = "one-to-one") |>
  left_join(features, by = c("sample", "parent_id"), relationship = "one-to-one") |>
  mutate(response_category = case_when(
      single_component & parent_total_units == 99L ~ "B. Single constituent at 99",
      single_component & parent_total_units < 100L ~ "A. Single constituent below 100 (excluding 99)",
      single_component ~ "C. Single constituent at or above 100",
      exact_99x2 ~ "F. Exact 99 x 2",
      exact_99x3 ~ "G. Exact 99 x 3",
      max_component_units <= 99L ~ "D. Other multiple constituents, all below 100",
      TRUE ~ "E. Multiple constituents, at least one at or above 100"),
    log_lot_area = if_else(lot_area_sqft > 0, log(lot_area_sqft), NA_real_),
    residential_capacity_sqft = lot_area_sqft * residential_far,
    redevelopment_slack_sqft = pmax(residential_capacity_sqft - lot_area_sqft * built_far, 0))
stopifnot(!anyNA(parent_panel$included_ab), all(parent_panel$parent_total_units == parent_panel$constituent_units),
  all(is.na(parent_panel$feature_units) | parent_panel$feature_units == parent_panel$parent_total_units),
  all(parent_panel$refiled == !is.na(parent_panel$refiling_date)))
parent_panel <- parent_panel |>
  select(sample, period, exposure_years, parent_id, cohort_date, cohort_year, refiled, refiling_date,
    parent_last_filing_date, observed_followup_days, left_window_observed, right_window_observed,
    full_window_observed, parent_total_units, n_components, max_component_units, second_component_units,
    third_component_units, n_components_eq_99, single_component, multi_component, exact_99x2, exact_99x3,
    sorted_component_vector, component_job_numbers, component_addresses, splitting_verification_status,
    response_category, exposure_status, included_ab, included_ab_plus_d, confidence, classification_reason,
    source_url, composition_eligible, site_feature_method, number_unique_lots, lot_area_sqft, log_lot_area,
    residential_far, built_far, residential_capacity_sqft, redevelopment_slack_sqft, built_floor_area_estimated,
    merged_lots_added, merger_window_complete, implausible_site, borough, community_district)

# date_filed is the original filing date of a refiled building; record_filing_date
# is the filing's own date.
constituent_panel <- constituents |>
  transmute(sample, parent_id, root_job_id, constituent_units = units, parent_constituent_weight,
    record_filing_date = date_filed, date_filed = original_filing_date, refiled, refiling_date, refiling_basis,
    filing_bbl, address, borough_name, owner_name) |>
  left_join(parent_panel |> select(sample, parent_id, period, exposure_years, cohort_date, cohort_year,
    parent_total_units, n_components, exact_99x2, exact_99x3, splitting_verification_status, included_ab),
    by = c("sample", "parent_id"), relationship = "many-to-one")
stopifnot(!anyDuplicated(constituent_panel[c("sample", "root_job_id")]),
  all(constituent_panel$refiled == !is.na(constituent_panel$refiling_date)))

SaveData(parent_panel, c("sample", "parent_id"), "../output/parent_opportunity_panel.parquet")
SaveData(constituent_panel, c("sample", "root_job_id"), "../output/constituent_filing_panel.parquet")

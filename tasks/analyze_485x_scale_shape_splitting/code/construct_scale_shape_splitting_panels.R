# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# pre_start_date_text <- "2019-01-01"
# pre_end_date_text <- "2022-12-31"
# post_start_date_text <- "2025-01-01"
# post_end_date_text <- "2026-07-08"
# minimum_units <- 6L
# near_99_minimum <- 95L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected pre start/end dates, post start/end dates, minimum units, ",
    "and the lower bound for the near-99 constituent definition."
  )
}

pre_start_date_text <- args[1]
pre_end_date_text <- args[2]
post_start_date_text <- args[3]
post_end_date_text <- args[4]
minimum_units <- as.integer(args[5])
near_99_minimum <- as.integer(args[6])

pre_start_date <- as.Date(pre_start_date_text)
pre_end_date <- as.Date(pre_end_date_text)
post_start_date <- as.Date(post_start_date_text)
post_end_date <- as.Date(post_end_date_text)

if (
  any(is.na(c(
    pre_start_date,
    pre_end_date,
    post_start_date,
    post_end_date,
    minimum_units,
    near_99_minimum
  ))) ||
    pre_start_date > pre_end_date ||
    pre_end_date >= post_start_date ||
    post_start_date > post_end_date ||
    minimum_units < 1L ||
    near_99_minimum < 1L ||
    near_99_minimum > 99L
) {
  stop("Scale-shape panel arguments are not internally consistent.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

exposure <- read_csv(
  "../input/parent_485x_exposure.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

exposure_universe <- read_csv(
  "../input/parent_485x_exposure_universe.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

hpd_links <- read_csv(
  "../input/hpd_485x_registration_dob_links.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

historical_features <- read_parquet(
  "../input/historical_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(sample = "historical")

post_features <- read_parquet(
  "../input/post_policy_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(sample = "post_policy")

if (
  nrow(membership) == 0L ||
    nrow(exposure) == 0L ||
    nrow(exposure_universe) == 0L ||
    anyDuplicated(membership[c("sample", "root_job_id")]) ||
    anyDuplicated(exposure[c("sample", "parent_id")]) ||
    anyDuplicated(exposure_universe[c("sample", "root_job_id")]) ||
    anyDuplicated(historical_features$parent_id) ||
    anyDuplicated(post_features$parent_id)
) {
  stop("A parent or constituent source failed identifier QC.")
}

source_end_dates <- membership |>
  filter(sample == "post_policy") |>
  distinct(source_end_date) |>
  pull(source_end_date)

if (
  length(source_end_dates) != 1L ||
    is.na(source_end_dates) ||
    post_end_date > source_end_dates[1]
) {
  stop("The requested post end date exceeds the common source end date.")
}

hpd_component <- hpd_links |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(
    root_job_id = matched_dob_root_job_id,
    hpd_response_number = as.character(response_number),
    hpd_registration_building_key = registration_building_key,
    hpd_reported_units = as.integer(reported_units),
    hpd_reported_option = str_to_upper(str_squish(
      reported_affordability_option
    )),
    hpd_reported_bbl = normalize_bbl_field(reported_bbl),
    hpd_intended_separate_sub100 = intended_separate_sub100_treatment
  )

if (anyDuplicated(hpd_component$root_job_id)) {
  stop("Latest HPD registration evidence is not unique by constituent job.")
}

parent_dates <- membership |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    parent_total_units_stored = first(parent_observed_units),
    full_window_observed = first(full_window_observed),
    left_window_observed = first(left_window_observed),
    right_window_observed = first(right_window_observed),
    parent_last_filing_date = first(parent_last_filing_date),
    source_end_date = first(source_end_date),
    .groups = "drop"
  ) |>
  filter(
    parent_total_units_stored >= minimum_units,
    (
      sample == "historical" &
        cohort_date >= pre_start_date &
        cohort_date <= pre_end_date &
        full_window_observed
    ) |
      (
        sample == "post_policy" &
          cohort_date >= post_start_date &
          cohort_date <= post_end_date &
          left_window_observed
      )
  ) |>
  mutate(
    period = if_else(
      sample == "historical",
      paste0("Pre: ", format(pre_start_date, "%Y"), "-", format(pre_end_date, "%Y")),
      paste0(
        "Post: ", format(post_start_date, "%Y"), "-",
        format(post_end_date, "%b "),
        as.integer(format(post_end_date, "%d")),
        ", ", format(post_end_date, "%Y")
      )
    ),
    exposure_years = if_else(
      sample == "historical",
      as.numeric(pre_end_date - pre_start_date + 1L) / 365.25,
      as.numeric(post_end_date - post_start_date + 1L) / 365.25
    ),
    observed_followup_days = as.integer(source_end_date - cohort_date)
  )

if (
  nrow(parent_dates) == 0L ||
    anyDuplicated(parent_dates[c("sample", "parent_id")]) ||
    any(parent_dates$exposure_years <= 0)
) {
  stop("The requested parent periods are empty or duplicated.")
}

constituents <- membership |>
  semi_join(
    parent_dates,
    by = c("sample", "parent_id")
  ) |>
  left_join(
    exposure_universe |>
      select(
        sample,
        root_job_id,
        universe_parent_id = parent_id,
        universe_component_units = component_units,
        address,
        borough_name,
        ownership_type,
        owner_name
      ),
    by = c("sample", "root_job_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    hpd_component,
    by = "root_job_id",
    relationship = "many-to-one"
  )

if (
  any(is.na(constituents$universe_parent_id)) ||
    any(constituents$universe_parent_id != constituents$parent_id) ||
    any(is.na(constituents$units)) ||
    any(constituents$units <= 0L) ||
    any(
      !is.na(constituents$universe_component_units) &
        constituents$units != constituents$universe_component_units
    )
) {
  stop("Constituent membership and exposure-universe units do not agree.")
}

constituents <- constituents |>
  group_by(sample, parent_id) |>
  arrange(desc(units), date_filed, root_job_id, .by_group = TRUE) |>
  mutate(
    constituent_rank = row_number(),
    parent_constituent_weight = 1 / n()
  ) |>
  ungroup()

parent_components <- constituents |>
  group_by(sample, parent_id) |>
  summarise(
    constituent_total_units = sum(units),
    n_components = n(),
    max_component_units = max(units),
    second_component_units = if_else(n() >= 2L, nth(units, 2L), NA_integer_),
    third_component_units = if_else(n() >= 3L, nth(units, 3L), NA_integer_),
    min_component_units = min(units),
    n_components_eq_99 = sum(units == 99L),
    n_components_ge_100 = sum(units >= 100L),
    all_components_le_99 = all(units <= 99L),
    any_component_ge_100 = any(units >= 100L),
    single_component = n() == 1L,
    multi_component = n() > 1L,
    exact_99x2 = n() == 2L && all(units == 99L),
    exact_99x3 = n() == 3L && all(units == 99L),
    near_99x2 = n() == 2L && all(units >= near_99_minimum & units <= 99L),
    sorted_component_vector = paste(units, collapse = "+"),
    component_job_numbers = paste(root_job_id, collapse = ";"),
    component_bbls = paste(
      sort(unique(na.omit(normalize_bbl_field(filing_bbl)))),
      collapse = ";"
    ),
    component_addresses = paste(
      sort(unique(na.omit(address))),
      collapse = ";"
    ),
    component_filing_dates = paste(as.character(date_filed), collapse = ";"),
    n_unique_component_bbls = n_distinct(
      normalize_bbl_field(filing_bbl),
      na.rm = TRUE
    ),
    hpd_linked_components = sum(!is.na(hpd_response_number)),
    hpd_distinct_responses = n_distinct(
      hpd_response_number,
      na.rm = TRUE
    ),
    hpd_response_numbers = paste(
      sort(unique(na.omit(hpd_response_number))),
      collapse = ";"
    ),
    hpd_registration_building_keys = paste(
      sort(unique(na.omit(hpd_registration_building_key))),
      collapse = ";"
    ),
    hpd_linked_options = paste(
      sort(unique(na.omit(hpd_reported_option))),
      collapse = ";"
    ),
    all_components_verified_separate = n() > 1L &&
      all(!is.na(hpd_response_number)) &&
      n_distinct(hpd_response_number) == n() &&
      all(coalesce(hpd_intended_separate_sub100, FALSE)),
    any_shared_hpd_response = n() > 1L &&
      any(duplicated(hpd_response_number[!is.na(hpd_response_number)])),
    .groups = "drop"
  )

if (
  anyDuplicated(parent_components[c("sample", "parent_id")]) ||
    any(parent_components$n_components < 1L)
) {
  stop("Parent constituent vectors failed identifier QC.")
}

features <- bind_rows(historical_features, post_features) |>
  transmute(
    sample,
    parent_id,
    feature_units = units_hdb_priority,
    feature_complete,
    model_eligible,
    number_unique_lots = feature_lots,
    lot_area_sqft = lotarea,
    residential_far = residfar,
    broad_zoning_far,
    built_far = builtfar,
    borough = str_squish(as.character(borough)),
    zoning_category = str_squish(as.character(zone_detail)),
    prior_site_use = str_squish(as.character(prior_site_use))
  )

parent_panel <- parent_dates |>
  left_join(
    exposure,
    by = c("sample", "parent_id"),
    relationship = "one-to-one",
    suffix = c("", "_exposure")
  ) |>
  left_join(
    parent_components,
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    features,
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    parent_total_units = parent_total_units_stored,
    splitting_verification_status = case_when(
      single_component ~ "not_applicable_single_component",
      all_components_verified_separate ~ "verified_separate_485x_units",
      any_shared_hpd_response ~ "same_eligible_site_or_application",
      n_unique_component_bbls == n_components ~
        "suggestive_separate_components",
      TRUE ~ "unable_to_verify"
    ),
    splitting_verification_reason = case_when(
      single_component ~ "Parent contains one constituent filing/building.",
      all_components_verified_separate ~ paste0(
        "Every constituent has a distinct HPD response explicitly marked ",
        "for separate sub-100 treatment."
      ),
      any_shared_hpd_response ~
        "Multiple constituents share an HPD registration response.",
      n_unique_component_bbls == n_components ~ paste0(
        "Constituents occupy distinct filing BBLs but lack complete HPD ",
        "application verification."
      ),
      TRUE ~ paste0(
        "Available filing, lot, and HPD records do not establish whether ",
        "constituents are separate eligible sites or applications."
      )
    ),
    response_category = case_when(
      single_component & parent_total_units == 99L ~
        "B. Single constituent at 99",
      single_component & parent_total_units < 100L ~
        "A. Single constituent below 100 (excluding 99)",
      single_component & parent_total_units >= 100L ~
        "C. Single constituent at or above 100",
      exact_99x2 ~ "F. Exact 99 x 2",
      exact_99x3 ~ "G. Exact 99 x 3",
      multi_component & all_components_le_99 ~
        "D. Other multiple constituents, all below 100",
      multi_component & any_component_ge_100 ~
        "E. Multiple constituents, at least one at or above 100",
      TRUE ~ NA_character_
    ),
    log_lot_area = if_else(
      !is.na(lot_area_sqft) & lot_area_sqft > 0,
      log(lot_area_sqft),
      NA_real_
    ),
    residential_capacity_sqft = lot_area_sqft * residential_far,
    built_floor_area_sqft = lot_area_sqft * built_far,
    redevelopment_slack_sqft = pmax(
      residential_capacity_sqft - built_floor_area_sqft,
      0
    ),
    zero_residential_capacity = as.integer(
      residential_capacity_sqft == 0
    ),
    zero_redevelopment_slack = as.integer(
      redevelopment_slack_sqft == 0
    ),
    multi_lot_indicator = as.integer(number_unique_lots > 1L)
  ) |>
  select(
    sample,
    period,
    exposure_years,
    parent_id,
    cohort_date,
    cohort_year,
    parent_last_filing_date,
    source_end_date,
    observed_followup_days,
    left_window_observed,
    right_window_observed,
    full_window_observed,
    parent_total_units,
    constituent_total_units,
    n_components,
    max_component_units,
    second_component_units,
    third_component_units,
    min_component_units,
    n_components_eq_99,
    n_components_ge_100,
    all_components_le_99,
    any_component_ge_100,
    single_component,
    multi_component,
    exact_99x2,
    exact_99x3,
    near_99x2,
    sorted_component_vector,
    component_job_numbers,
    component_bbls,
    component_addresses,
    component_filing_dates,
    n_unique_component_bbls,
    hpd_linked_components,
    hpd_response_numbers,
    hpd_registration_building_keys,
    hpd_linked_options,
    splitting_verification_status,
    splitting_verification_reason,
    response_category,
    exposure_status,
    included_ab,
    included_ab_plus_d,
    confidence,
    classification_reason,
    evidence_source,
    source_url,
    government_owner,
    nycha_owner,
    hotel_project,
    feature_units,
    feature_complete,
    model_eligible,
    number_unique_lots,
    multi_lot_indicator,
    lot_area_sqft,
    log_lot_area,
    residential_far,
    broad_zoning_far,
    built_far,
    residential_capacity_sqft,
    built_floor_area_sqft,
    redevelopment_slack_sqft,
    zero_residential_capacity,
    zero_redevelopment_slack,
    borough,
    zoning_category,
    prior_site_use
  )

if (
  nrow(parent_panel) == 0L ||
    anyDuplicated(parent_panel[c("sample", "parent_id")]) ||
    any(is.na(parent_panel$included_ab)) ||
    any(is.na(parent_panel$constituent_total_units)) ||
    any(parent_panel$parent_total_units != parent_panel$constituent_total_units) ||
    any(is.na(parent_panel$response_category)) ||
    any(
      !is.na(parent_panel$feature_units) &
        parent_panel$feature_units != parent_panel$parent_total_units
    )
) {
  stop("Parent totals, categories, exposure, or feature units failed QC.")
}

constituent_panel <- constituents |>
  select(
    sample,
    parent_id,
    root_job_id,
    constituent_rank,
    constituent_units = units,
    parent_constituent_weight,
    date_filed,
    filing_bbl,
    address,
    borough_name,
    ownership_type,
    owner_name,
    hpd_response_number,
    hpd_registration_building_key,
    hpd_reported_units,
    hpd_reported_option,
    hpd_reported_bbl,
    hpd_intended_separate_sub100
  ) |>
  left_join(
    parent_panel |>
      select(
        sample,
        parent_id,
        period,
        exposure_years,
        cohort_date,
        cohort_year,
        parent_total_units,
        n_components,
        exact_99x2,
        exact_99x3,
        splitting_verification_status,
        exposure_status,
        included_ab,
        included_ab_plus_d
      ),
    by = c("sample", "parent_id"),
    relationship = "many-to-one"
  )

if (
  anyDuplicated(constituent_panel[c("sample", "root_job_id")]) ||
    any(abs(
      constituent_panel |>
        group_by(sample, parent_id) |>
        summarise(weight_sum = sum(parent_constituent_weight), .groups = "drop") |>
        pull(weight_sum) - 1
    ) > 1e-10)
) {
  stop("The constituent panel failed uniqueness or parent-weight QC.")
}

parent_panel_qc <- parent_panel |>
  group_by(period) |>
  summarise(
    parents = n(),
    ab_parents = sum(included_ab),
    component_filings = sum(n_components),
    multi_component_parents = sum(multi_component),
    exact_99x2_parents = sum(exact_99x2),
    exact_99x3_parents = sum(exact_99x3),
    mismatched_parent_unit_totals = sum(
      parent_total_units != constituent_total_units
    ),
    missing_exposure_classification = sum(is.na(exposure_status)),
    missing_feature_rows = sum(is.na(feature_units)),
    model_eligible_ab_parents = sum(included_ab & coalesce(model_eligible, FALSE)),
    right_window_observed_parents = sum(right_window_observed),
    minimum_followup_days = min(observed_followup_days),
    median_followup_days = median(observed_followup_days),
    maximum_followup_days = max(observed_followup_days),
    .groups = "drop"
  )

parent_190_205_audit <- parent_panel |>
  filter(parent_total_units >= 190L, parent_total_units <= 205L) |>
  transmute(
    period,
    sample,
    parent_id,
    cohort_date,
    parent_total_units,
    n_components,
    sorted_component_vector,
    largest_component = max_component_units,
    second_component = second_component_units,
    component_bbls,
    component_job_numbers,
    hpd_response_numbers,
    hpd_registration_building_keys,
    hpd_linked_options,
    splitting_verification_status,
    splitting_verification_reason,
    exposure_status,
    included_ab,
    included_ab_plus_d
  ) |>
  arrange(period, parent_total_units, parent_id)

write_parquet_if_changed(
  parent_panel,
  "../output/parent_opportunity_panel.parquet"
)
write_parquet_if_changed(
  constituent_panel,
  "../output/constituent_filing_panel.parquet"
)
write_csv_if_changed(
  parent_panel_qc,
  "../output/parent_panel_qc.csv"
)
write_csv_if_changed(
  parent_190_205_audit,
  "../output/parent_190_205_audit.csv"
)

cat("Wrote parent and constituent scale-shape panels to ../output\n")

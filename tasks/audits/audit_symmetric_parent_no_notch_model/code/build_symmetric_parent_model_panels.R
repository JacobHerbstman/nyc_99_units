# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_no_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

collapse_category <- function(x, mixed_label) {
  values <- sort(unique(x[!is.na(x) & x != ""]))
  if (length(values) == 0L) {
    "missing"
  } else if (length(values) == 1L) {
    values
  } else {
    mixed_label
  }
}

add_site_categories <- function(rows) {
  rows |>
    mutate(
      zonedist1_clean = str_to_upper(str_squish(zonedist1)),
      zone_base = str_extract(zonedist1_clean, "^[RCM][0-9]+"),
      zone_detail = case_when(
        str_detect(zonedist1_clean, "/") ~ "MX_slash",
        zone_base %in% c("R1", "R2", "R3", "R4", "R5") ~ "R1_R5",
        zone_base == "R6" ~ "R6",
        zone_base == "R7" ~ "R7",
        zone_base %in% c("R8", "R9", "R10") ~ "R8_R10",
        str_detect(zonedist1_clean, "^C") ~ "C",
        str_detect(zonedist1_clean, "^M") ~ "M_non_slash",
        TRUE ~ "Other"
      ),
      landuse_code = str_pad(as.character(landuse), 2L, pad = "0"),
      prior_site_use = case_when(
        !is.na(unitsres) & unitsres > 0 ~ "existing_residential_units",
        landuse_code == "11" ~ "vacant_land",
        landuse_code == "10" ~ "parking",
        landuse_code %in% c("05", "06") ~ "commercial_industrial",
        landuse_code == "04" ~ "mixed_res_commercial",
        landuse_code %in% c("07", "08") ~ "public_transport_utility",
        is.na(landuse_code) ~ "missing_landuse",
        TRUE ~ "other_no_res_units"
      )
    )
}

aggregate_parent_rows <- function(member_rows) {
  parent_outcomes <- member_rows |>
    arrange(parent_id, date_filed, job_number) |>
    group_by(sample, parent_id) |>
    summarise(
      analysis_status = first(analysis_status),
      cohort_date = first(cohort_date),
      cohort_year = first(cohort_year),
      date_last_filed = max(date_filed),
      units_hdb_priority = sum(hdb_priority_units),
      units_dob_i1 = sum(dob_i1_units),
      component_filings = n(),
      exact_99_component_filings = sum(hdb_priority_units == 99L),
      exact_99_component_filings_dob_i1 = sum(dob_i1_units == 99L),
      component_jobs = paste(job_number, collapse = ";"),
      nonmissing_bin_rows = sum(!is.na(bin_clean)),
      distinct_bins = n_distinct(bin_clean[!is.na(bin_clean)]),
      feature_complete = all(!is.na(feature_bbl)),
      feature_methods = paste(sort(unique(feature_method)), collapse = ";"),
      .groups = "drop"
    ) |>
    mutate(
      duplicate_bin_rows = pmax(
        nonmissing_bin_rows - distinct_bins,
        0L
      )
    )

  parent_features <- member_rows |>
    filter(!is.na(feature_bbl)) |>
    arrange(parent_id, date_filed, job_number) |>
    group_by(sample, parent_id, feature_bbl) |>
    slice_head(n = 1L) |>
    ungroup() |>
    group_by(sample, parent_id) |>
    summarise(
      feature_lots = n(),
      lotarea = sum(lotarea),
      residfar_numerator = sum(lotarea * residfar, na.rm = TRUE),
      residfar_denominator = sum(if_else(!is.na(residfar), lotarea, 0)),
      builtfar_numerator = sum(lotarea * builtfar, na.rm = TRUE),
      builtfar_denominator = sum(if_else(!is.na(builtfar), lotarea, 0)),
      borough = collapse_category(borough, "Mixed"),
      zone_detail = collapse_category(zone_detail, "Mixed"),
      prior_site_use = collapse_category(
        prior_site_use,
        "mixed_prior_use"
      ),
      .groups = "drop"
    ) |>
    mutate(
      residfar = if_else(
        residfar_denominator > 0,
        residfar_numerator / residfar_denominator,
        NA_real_
      ),
      builtfar = if_else(
        builtfar_denominator > 0,
        builtfar_numerator / builtfar_denominator,
        NA_real_
      )
    )

  parent_outcomes |>
    left_join(
      parent_features,
      by = c("sample", "parent_id"),
      relationship = "one-to-one"
    ) |>
    mutate(
      observation_id = parent_id,
      filing_year = cohort_year,
      units = units_hdb_priority,
      log_units = log(units),
      log_lotarea = log(lotarea),
      model_eligible =
        feature_complete &
        !is.na(lotarea) &
        lotarea > 0 &
        duplicate_bin_rows == 0L
    ) |>
    select(
      sample, observation_id, parent_id, analysis_status,
      cohort_date, cohort_year, date_last_filed, filing_year,
      units, units_hdb_priority, units_dob_i1, log_units,
      component_filings, exact_99_component_filings,
      exact_99_component_filings_dob_i1, component_jobs,
      nonmissing_bin_rows, distinct_bins, duplicate_bin_rows,
      feature_complete, feature_methods, feature_lots,
      model_eligible, lotarea, log_lotarea, residfar, builtfar,
      borough, zone_detail, prior_site_use
    ) |>
    arrange(cohort_date, parent_id)
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

hdb_panel <- read_parquet(
  "../input/hdb_mappluto_training_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    feature_bbl = normalize_bbl_field(pluto_feature_bbl),
    bin_clean = na_if(str_squish(as.character(bin)), ""),
    borough = hdb_borough_name
  ) |>
  add_site_categories()

fixed_post_lots <- read_parquet(
  "../input/dcp_mappluto_archive_23v3_1.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    bbl = normalize_bbl_field(bbl),
    borough = recode(
      as.character(borough),
      `1` = "Manhattan",
      `2` = "Bronx",
      `3` = "Brooklyn",
      `4` = "Queens",
      `5` = "Staten Island"
    )
  ) |>
  add_site_categories() |>
  select(
    feature_bbl = bbl, lotarea, residfar, builtfar,
    borough, zone_detail, prior_site_use
  )

if (
  nrow(membership) == 0L ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    anyDuplicated(hdb_panel$job_number) ||
    anyDuplicated(fixed_post_lots$feature_bbl)
) {
  stop("A symmetric-parent panel input failed identifier QC.")
}

historical_member_rows <- membership |>
  filter(sample == "historical") |>
  left_join(
    hdb_panel |>
      select(
        job_number, feature_bbl, bin_clean, lotarea, residfar,
        builtfar, borough, zone_detail, prior_site_use
      ),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  mutate(feature_method = "filing_specific_lagged_mappluto")

post_hdb_fields <- hdb_panel |>
  transmute(
    root_job_id = job_number,
    hdb_feature_bbl = feature_bbl,
    bin_clean
  )

post_member_rows <- membership |>
  filter(sample == "post_policy") |>
  left_join(
    post_hdb_fields,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    feature_bbl = case_when(
      hdb_feature_bbl %in% fixed_post_lots$feature_bbl ~ hdb_feature_bbl,
      filing_bbl %in% fixed_post_lots$feature_bbl ~ filing_bbl,
      TRUE ~ NA_character_
    ),
    feature_method = case_when(
      !is.na(feature_bbl) & feature_bbl == hdb_feature_bbl ~
        "hdb_feature_bbl_fixed_23v3_1",
      !is.na(feature_bbl) ~ "filing_bbl_fixed_23v3_1",
      TRUE ~ "unmatched_fixed_23v3_1"
    )
  ) |>
  left_join(
    fixed_post_lots,
    by = "feature_bbl",
    relationship = "many-to-one"
  )

if (
  nrow(historical_member_rows) != sum(membership$sample == "historical") ||
    nrow(post_member_rows) != sum(membership$sample == "post_policy") ||
    any(is.na(historical_member_rows$feature_bbl)) ||
    any(is.na(historical_member_rows$lotarea)) ||
    any(historical_member_rows$lotarea <= 0)
) {
  stop("Historical or post member feature construction failed QC.")
}

historical_panel <- aggregate_parent_rows(historical_member_rows)
post_panel <- aggregate_parent_rows(post_member_rows)

panel_qc <- bind_rows(historical_panel, post_panel) |>
  group_by(sample, analysis_status) |>
  summarise(
    parents = n(),
    component_filings = sum(component_filings),
    exact_99_parents_hdb_priority = sum(units_hdb_priority == 99L),
    exact_99_parents_dob_i1 = sum(units_dob_i1 == 99L),
    feature_complete_parents = sum(feature_complete),
    duplicate_bin_parents = sum(duplicate_bin_rows > 0L),
    model_eligible_parents = sum(model_eligible),
    model_eligible_exact_99_parents_hdb_priority = sum(
      model_eligible & units_hdb_priority == 99L
    ),
    .groups = "drop"
  ) |>
  arrange(sample, analysis_status)

unmatched_post_features <- post_member_rows |>
  filter(is.na(feature_bbl)) |>
  select(
    parent_id, analysis_status, cohort_date, root_job_id, job_number,
    date_filed, hdb_priority_units, dob_i1_units, filing_bbl,
    hdb_feature_bbl, feature_method
  ) |>
  arrange(cohort_date, parent_id, date_filed, job_number)

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id) ||
    sum(historical_panel$component_filings) !=
      nrow(historical_member_rows) ||
    sum(post_panel$component_filings) != nrow(post_member_rows) ||
    any(
      post_panel$model_eligible &
        post_panel$analysis_status == "completed_2025_cohort" &
        is.na(post_panel$lotarea)
    )
) {
  stop("Symmetric-parent model panels failed final QC.")
}

write_parquet_if_changed(
  historical_panel,
  "../output/historical_symmetric_parent_model_panel.parquet"
)
write_parquet_if_changed(
  post_panel,
  "../output/post_policy_symmetric_parent_model_panel.parquet"
)
write_csv_if_changed(
  panel_qc,
  "../output/symmetric_parent_model_panel_qc.csv"
)
write_csv_if_changed(
  unmatched_post_features,
  "../output/unmatched_post_feature_rows.csv"
)

cat("Wrote symmetric-parent model panels to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_site_characteristics/code")
# sample_name <- "historical"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  sample_name <- args[1]
}
stopifnot(sample_name %in% c("historical", "post_policy"))

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
      available_far_fields = rowSums(
        !is.na(pick(residfar, commfar, facilfar, maxallwfar))
      ),
      broad_zoning_far = pmax(
        coalesce(residfar, 0),
        coalesce(commfar, 0),
        coalesce(facilfar, 0),
        coalesce(maxallwfar, 0)
      ),
      broad_zoning_far = if_else(
        available_far_fields > 0,
        broad_zoning_far,
        NA_real_
      ),
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

membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  filter(sample == sample_name)

hdb_panel <- read_parquet("../input/hdb_mappluto_site_panel.parquet") |>
  mutate(
    feature_bbl = normalize_bbl_field(pluto_feature_bbl),
    bin_clean = na_if(str_squish(as.character(bin)), ""),
    borough = hdb_borough_name
  ) |>
  add_site_categories()

stopifnot(nrow(membership) > 0L, !anyDuplicated(membership$job_number),
          !anyDuplicated(hdb_panel$job_number))

# Historical sites use the parcel vintage before each filing. Post-policy sites
# use the fixed 2023 parcel map, before the policy could change development.
if (sample_name == "historical") {
  member_rows <- membership |>
    left_join(
      hdb_panel |>
        select(
          job_number, feature_bbl, bin_clean, lotarea,
          residfar, broad_zoning_far,
          builtfar, borough, zone_detail, prior_site_use
        ),
      by = "job_number",
      relationship = "one-to-one"
    ) |>
    mutate(feature_method = if_else(is.na(feature_bbl),
      "missing_lagged_mappluto", "filing_specific_lagged_mappluto"))
  stopifnot(all(member_rows$job_number %in% hdb_panel$job_number),
            !any(member_rows$lotarea <= 0, na.rm = TRUE))
} else {
  fixed_post_lots <- read_parquet("../input/dcp_mappluto_archive_23v3_1.parquet") |>
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
      feature_bbl = bbl, lotarea, residfar, broad_zoning_far, builtfar,
      borough, zone_detail, prior_site_use
    )
  stopifnot(!anyDuplicated(fixed_post_lots$feature_bbl))

  post_hdb_fields <- hdb_panel |>
    transmute(
      root_job_id = job_number,
      hdb_feature_bbl = feature_bbl,
      bin_clean
    )

  member_rows <- membership |>
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
}
stopifnot(nrow(member_rows) == nrow(membership))

# Sum additive filings, and count each matched tax lot once within its parent.
parent_outcomes <- member_rows |>
  arrange(parent_id, date_filed, job_number) |>
  group_by(sample, parent_id) |>
  summarise(
    analysis_status = first(analysis_status),
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    date_last_filed = max(date_filed),
    observed_units = sum(units[additive_component]),
    units_hdb_priority = sum(hdb_priority_units[additive_component]),
    units_dob_i1 = sum(dob_i1_units[additive_component]),
    source_filings = n(),
    component_filings = sum(additive_component),
    exact_99_component_filings = sum(
      units == 99L & additive_component
    ),
    exact_99_component_filings_dob_i1 = sum(
      dob_i1_units == 99L & additive_component
    ),
    source_jobs = paste(job_number, collapse = ";"),
    component_jobs = paste(job_number[additive_component], collapse = ";"),
    nonmissing_bin_rows = sum(!is.na(bin_clean) & additive_component),
    distinct_bins = n_distinct(bin_clean[!is.na(bin_clean) & additive_component]),
    feature_complete = all(!is.na(feature_bbl) & !is.na(lotarea) & lotarea > 0),
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
    # Keep individual lot areas until all three weighted means are calculated.
    across(c(residfar, broad_zoning_far, builtfar), ~ {
      observed_area <- sum(if_else(!is.na(.x), lotarea, 0))
      if_else(observed_area > 0,
              sum(lotarea * .x, na.rm = TRUE) / observed_area, NA_real_)
    }),
    borough = collapse_category(borough, "Mixed"),
    zone_detail = collapse_category(zone_detail, "Mixed"),
    prior_site_use = collapse_category(
      prior_site_use,
      "mixed_prior_use"
    ),
    lotarea = sum(lotarea),
    .groups = "drop"
  )

panel <- parent_outcomes |>
  left_join(
    parent_features,
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    observation_id = parent_id,
    filing_year = cohort_year,
    units = observed_units,
    log_lotarea = log(lotarea),
    composition_eligible =
      feature_complete &
      !is.na(lotarea) &
      lotarea > 0 &
      duplicate_bin_rows == 0L
  ) |>
  select(
    sample, observation_id, parent_id, analysis_status,
    cohort_date, cohort_year, date_last_filed, filing_year,
    units, units_hdb_priority, units_dob_i1,
    source_filings, component_filings,
    exact_99_component_filings,
    exact_99_component_filings_dob_i1, source_jobs, component_jobs,
    nonmissing_bin_rows, distinct_bins, duplicate_bin_rows,
    feature_complete, feature_methods, feature_lots,
    composition_eligible, lotarea, log_lotarea,
    residfar, broad_zoning_far, builtfar,
    borough, zone_detail, prior_site_use
  ) |>
  arrange(cohort_date, parent_id)

stopifnot(nrow(panel) > 0L, !anyDuplicated(panel$observation_id),
          sum(panel$source_filings) == nrow(member_rows),
          !any(panel$composition_eligible &
                 panel$analysis_status == "completed_2025_cohort" & is.na(panel$lotarea)))

write_parquet_atomic(panel, sprintf("../output/%s_parent_site_characteristics.parquet", sample_name))
write_data_report(
  read_parquet(sprintf("../output/%s_parent_site_characteristics.parquet", sample_name)),
  "parent_id", sprintf("../output/%s_parent_site_characteristics.parquet", sample_name),
  sprintf("../report/%s_parent_site_characteristics.txt", sample_name)
)

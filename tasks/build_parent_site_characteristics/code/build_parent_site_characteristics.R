# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_site_characteristics/code")
# sample_name <- "historical"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
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

if (sample_name == "historical") {
  hdb_panel <- read_parquet("../input/historical_hdb_mappluto_site_panel.parquet")
} else {
  hdb_panel <- read_parquet("../input/hdb_mappluto_site_panel.parquet")
}
hdb_panel <- hdb_panel |>
  mutate(
    feature_bbl = normalize_bbl_field(pluto_feature_bbl),
    hdb_bin = na_if(str_squish(as.character(bin)), ""),
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
          job_number, feature_bbl, hdb_bin, lotarea,
          residfar, broad_zoning_far,
          builtfar, borough, zone_detail, prior_site_use,
          reference_source_id = pluto_source_id_used,
          reference_version = pluto_version_used,
          reference_date = pluto_safe_available_date_used
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
      hdb_bin
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
    ) |>
    mutate(
      reference_source_id = "dcp_mappluto_archive",
      reference_version = "23v3.1",
      reference_date = as.Date("2023-12-28")
    )
}

# Historical building identifiers come from the pre-adoption HDB snapshot.
# Post-policy identifiers use DOB initial filings, with HDB fallback.
dob_filings <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(
    root_job_id = job_number,
    dob_bin = na_if(str_squish(as.character(bin)), "")
  )
stopifnot(!anyDuplicated(dob_filings$root_job_id))

member_rows <- member_rows |>
  left_join(dob_filings, by = "root_job_id", relationship = "many-to-one") |>
  mutate(bin_clean = if (sample_name == "historical") hdb_bin else coalesce(dob_bin, hdb_bin))
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
    distinct_valid_dob_bins = n_distinct(dob_bin[additive_component &
      !is.na(dob_bin) & str_detect(dob_bin, "^[1-5][0-9]{6}$")]),
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

site_lots <- member_rows |>
  filter(!is.na(feature_bbl)) |>
  arrange(parent_id, date_filed, job_number) |>
  group_by(sample, parent_id, feature_bbl) |>
  slice_head(n = 1L) |>
  ungroup() |>
  mutate(feature_lots = 1L)

# Lots merged soon after filing. Developers often file under the one lot that
# will survive a merger DOF records months later, so the reference map shows
# only that lot. Add the lots DOF merged into a filing lot after its reference
# map and no more than 180 days after the parent's first filing. The window is
# the same in both periods; later mergers are ignored so that recent parents,
# with less follow-up, are measured the same way. Splits are not used, because
# a split gives the development only part of the old parcel. The rule applies
# to citywide MapPLUTO reference releases (2018 onward).
merger_window_days <- 180L
dof_snapshot_date <- as.Date("2026-09-15")

dof_changes <- read_parquet("../input/dof_transaction_headers.parquet") |>
  transmute(transaction_id = TRANS_NUM, change_date = as.Date(Change_Date), change_type = Change_Type) |>
  distinct()
stopifnot(!anyDuplicated(dof_changes$transaction_id))
dof_mergers <- read_parquet("../input/dof_lot_actions.parquet") |>
  transmute(transaction_id = TRANS_NUM, bbl = BBL, action = Lot_Action) |>
  distinct() |>
  inner_join(dof_changes |> filter(change_type == "Lot Merger"),
    by = "transaction_id", relationship = "many-to-one") |>
  group_by(transaction_id, change_date) |>
  filter(sum(action %in% c("Affected", "New")) == 1L, any(action == "Dropped")) |>
  summarise(surviving_bbl = bbl[action %in% c("Affected", "New")],
    merged_bbl = list(bbl[action == "Dropped"]), .groups = "drop") |>
  # One row per surviving lot, holding all of its mergers.
  group_by(surviving_bbl) |>
  summarise(mergers = list(tibble(change_date, merged_bbl)), .groups = "drop")

# Each lot keeps the reference release of the parent's first filing on it.
merged_lots <- site_lots |>
  select(sample, parent_id, feature_bbl, reference_source_id, reference_version, reference_date) |>
  left_join(parent_outcomes |> select(parent_id, cohort_date),
    by = "parent_id", relationship = "many-to-one") |>
  filter(reference_source_id == "dcp_mappluto_archive") |>
  inner_join(dof_mergers, by = c("feature_bbl" = "surviving_bbl"), relationship = "many-to-one") |>
  unnest(mergers) |>
  filter(change_date > as.Date(reference_date),
    change_date <= as.Date(cohort_date) + merger_window_days) |>
  unnest_longer(merged_bbl) |>
  distinct(sample, parent_id, reference_version, merged_bbl) |>
  anti_join(site_lots |> select(parent_id, merged_bbl = feature_bbl), by = c("parent_id", "merged_bbl"))

merged_attributes <- bind_rows(lapply(unique(merged_lots$reference_version), function(version) {
  read_parquet(sprintf("../input/%s.parquet", sanitize_file_stub(paste("dcp_mappluto_archive", version)))) |>
    filter(bbl %in% merged_lots$merged_bbl[merged_lots$reference_version == version]) |>
    mutate(reference_version = version)
})) |>
  mutate(borough = recode(as.character(borough),
    `1` = "Manhattan", `2` = "Bronx", `3` = "Brooklyn",
    `4` = "Queens", `5` = "Staten Island")) |>
  add_site_categories() |>
  select(reference_version, merged_bbl = bbl, lotarea, residfar, broad_zoning_far,
    builtfar, borough, zone_detail, prior_site_use)

# A merged lot missing from the reference release adds no land.
merged_lots <- merged_lots |>
  inner_join(merged_attributes, by = c("reference_version", "merged_bbl"),
    relationship = "many-to-one") |>
  filter(lotarea > 0) |>
  transmute(sample, parent_id, feature_bbl = merged_bbl, lotarea, residfar,
    broad_zoning_far, builtfar, borough, zone_detail, prior_site_use, feature_lots = 1L)
stopifnot(!anyDuplicated(merged_lots[c("parent_id", "feature_bbl")]))

site_lots <- bind_rows(site_lots, merged_lots)
parent_outcomes <- parent_outcomes |>
  left_join(merged_lots |> count(parent_id, name = "merged_lots_added"),
    by = "parent_id", relationship = "one-to-one") |>
  mutate(merged_lots_added = coalesce(merged_lots_added, 0L),
    merger_window_complete = as.Date(cohort_date) + merger_window_days <= dof_snapshot_date)

# Reviewed allocations replace the complete parcel set for the named parent.
# Deduct retained floor or an explicitly documented archive correction before
# calculating existing density; source reasons distinguish those decisions.
site_decisions <- read_csv("../input/site_lot_decisions.csv", show_col_types = FALSE,
  col_types = cols(reference_bbls = col_character())) |>
  filter(sample == sample_name)
stopifnot(!anyNA(site_decisions$built_floor_area_estimated))
reference_sets <- site_decisions |>
  select(parent_id, reference_vintage, reference_bbls) |>
  mutate(reference_bbl = reference_bbls) |>
  separate_longer_delim(reference_bbl, ";")
reviewed_parents <- site_decisions |>
  distinct(parent_id, expected_component_jobs) |>
  left_join(parent_outcomes |> select(parent_id, component_jobs),
    by = "parent_id", relationship = "one-to-one")
stopifnot(!anyDuplicated(reference_sets[c("parent_id", "reference_bbl")]),
  !anyNA(reviewed_parents$component_jobs),
  all(reviewed_parents$expected_component_jobs == reviewed_parents$component_jobs))

if (nrow(site_decisions) > 0L) {
  reference_lots <- bind_rows(
    read_parquet("../input/dcp_mappluto_archive_18v1_1.parquet") |>
      mutate(reference_vintage = "18v1_1"),
    read_parquet("../input/dcp_mappluto_archive_18v2beta.parquet") |>
      mutate(reference_vintage = "18v2beta"),
    read_parquet("../input/dcp_mappluto_archive_18v2_1.parquet") |>
      mutate(reference_vintage = "18v2_1"),
    read_parquet("../input/dcp_mappluto_archive_19v1.parquet") |>
      mutate(reference_vintage = "19v1"),
    read_parquet("../input/dcp_mappluto_archive_19v2.parquet") |>
      mutate(reference_vintage = "19v2"),
    read_parquet("../input/dcp_mappluto_archive_20v1.parquet") |>
      mutate(reference_vintage = "20v1"),
    read_parquet("../input/dcp_mappluto_archive_20v3.parquet") |>
      mutate(reference_vintage = "20v3"),
    read_parquet("../input/dcp_mappluto_archive_20v5.parquet") |>
      mutate(reference_vintage = "20v5"),
    read_parquet("../input/dcp_mappluto_archive_20v8.parquet") |>
      mutate(reference_vintage = "20v8"),
    read_parquet("../input/dcp_mappluto_archive_21v1.parquet") |>
      mutate(reference_vintage = "21v1"),
    read_parquet("../input/dcp_mappluto_archive_21v3.parquet") |>
      mutate(reference_vintage = "21v3"),
    read_parquet("../input/dcp_mappluto_archive_22v1.parquet") |>
      mutate(reference_vintage = "22v1"),
    read_parquet("../input/dcp_mappluto_archive_23v3_1.parquet") |>
      mutate(reference_vintage = "23v3_1")
  ) |>
    filter(bbl %in% reference_sets$reference_bbl) |>
    mutate(borough = recode(as.character(borough),
      `1` = "Manhattan", `2` = "Bronx", `3` = "Brooklyn",
      `4` = "Queens", `5` = "Staten Island")) |>
    add_site_categories() |>
    select(reference_vintage, reference_bbl = bbl, lotarea, bldgarea,
      residfar, broad_zoning_far, borough, zone_detail, prior_site_use)
  reference_sets <- reference_sets |>
    left_join(reference_lots, by = c("reference_vintage", "reference_bbl"),
      relationship = "many-to-one")
  stopifnot(!anyNA(reference_sets$lotarea), !anyNA(reference_sets$bldgarea),
    !anyNA(reference_sets$residfar), !anyNA(reference_sets$broad_zoning_far))
  # A documented combined area needs no invented internal allocation when
  # all contributing parcels have the same FARs. Preserve every source lot.
  reference_sets <- reference_sets |>
    group_by(parent_id, reference_vintage, reference_bbls) |>
    summarise(lotarea = sum(lotarea), bldgarea = sum(bldgarea), feature_lots = n(),
      residential_fars = n_distinct(residfar), broad_fars = n_distinct(broad_zoning_far),
      residfar = first(residfar), broad_zoning_far = first(broad_zoning_far),
      borough = collapse_category(borough, "Mixed"),
      zone_detail = collapse_category(zone_detail, "Mixed"),
      prior_site_use = collapse_category(prior_site_use, "mixed_prior_use"), .groups = "drop")
  stopifnot(all(reference_sets$residential_fars == 1L), all(reference_sets$broad_fars == 1L))
  reviewed_lots <- site_decisions |>
    left_join(reference_sets, by = c("parent_id", "reference_vintage", "reference_bbls"),
      relationship = "one-to-one", suffix = c("_reviewed", ""))
  stopifnot(
    all(reviewed_lots$reference_recorded_area_sqft == reviewed_lots$lotarea),
    all(reviewed_lots$development_area_sqft > 0),
    all(reviewed_lots$excluded_building_area_sqft >= 0),
    all(reviewed_lots$excluded_building_area_sqft <= reviewed_lots$bldgarea))
  reviewed_lots <- reviewed_lots |>
    transmute(sample, parent_id, feature_bbl = reference_bbls, feature_lots,
      lotarea = development_area_sqft, residfar, broad_zoning_far,
      builtfar = (bldgarea - excluded_building_area_sqft) / development_area_sqft,
      borough, zone_detail, prior_site_use = coalesce(prior_site_use_reviewed, prior_site_use))
  site_lots <- bind_rows(
    site_lots |> anti_join(reviewed_parents, by = "parent_id"), reviewed_lots)
  parent_outcomes <- parent_outcomes |>
    mutate(feature_complete = if_else(parent_id %in% reviewed_parents$parent_id,
      TRUE, feature_complete),
      feature_methods = if_else(parent_id %in% reviewed_parents$parent_id,
        "reviewed_parcel_allocation", feature_methods))
}

parent_features <- site_lots |>
  group_by(sample, parent_id) |>
  summarise(
    feature_lots = sum(feature_lots),
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
    # Later official identifiers can corroborate separate buildings whose full
    # additive filing set and land allocation have already been reviewed.
    reviewed_distinct_buildings = sample == "historical" & duplicate_bin_rows > 0L &
      parent_id %in% reviewed_parents$parent_id & distinct_valid_dob_bins == component_filings,
    composition_eligible =
      feature_complete &
      !is.na(lotarea) &
      lotarea > 0 &
      (duplicate_bin_rows == 0L | reviewed_distinct_buildings),
    built_floor_area_estimated = parent_id %in%
      site_decisions$parent_id[site_decisions$built_floor_area_estimated],
    merged_lots_added = if_else(parent_id %in% reviewed_parents$parent_id, 0L, merged_lots_added),
    # Under 150 square feet of permitted residential floor per proposed unit
    # cannot hold the proposal even with a doubled FAR: the land is a fragment.
    implausible_site = !is.na(lotarea) &
      lotarea * pmax(residfar, broad_zoning_far) / units < 150
  ) |>
  select(
    sample, observation_id, parent_id, analysis_status,
    cohort_date, cohort_year, date_last_filed, filing_year,
    units, units_hdb_priority, units_dob_i1,
    source_filings, component_filings,
    exact_99_component_filings,
    exact_99_component_filings_dob_i1, source_jobs, component_jobs,
    nonmissing_bin_rows, distinct_bins, duplicate_bin_rows,
    distinct_valid_dob_bins, reviewed_distinct_buildings,
    feature_complete, feature_methods, feature_lots,
    composition_eligible, lotarea, log_lotarea,
    residfar, broad_zoning_far, builtfar, built_floor_area_estimated,
    merged_lots_added, merger_window_complete, implausible_site,
    borough, zone_detail, prior_site_use
  ) |>
  arrange(cohort_date, parent_id)

stopifnot(nrow(panel) > 0L, !anyDuplicated(panel$observation_id),
          sum(panel$source_filings) == nrow(member_rows),
          !any(panel$composition_eligible &
                 panel$analysis_status == "completed_2025_cohort" & is.na(panel$lotarea)))

SaveData(panel, "parent_id", sprintf("../output/%s_parent_site_characteristics.parquet", sample_name))

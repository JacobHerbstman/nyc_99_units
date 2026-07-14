# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_level_no_notch_model/code")
# pre_start_year <- 2010L
# pre_end_year <- 2023L
# post_year <- 2025L
# min_units <- 6L
# max_filing_days <- 365L
# corroboration_days <- 30L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected six arguments: pre-period start and end years, post year, ",
    "minimum units, maximum filing days, and corroboration days."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
max_filing_days <- as.integer(args[5])
corroboration_days <- as.integer(args[6])

if (
  any(is.na(c(
    pre_start_year, pre_end_year, post_year, min_units,
    max_filing_days, corroboration_days
  ))) ||
    pre_start_year > pre_end_year ||
    post_year <= pre_end_year ||
    min_units < 1L ||
    max_filing_days < 0L ||
    corroboration_days < 0L ||
    corroboration_days > max_filing_days
) {
  stop("Parent-panel arguments are not internally consistent.")
}

normalize_match_key <- function(x) {
  out <- str_squish(str_replace_all(str_to_upper(x), "[^A-Z0-9]+", " "))
  out[out %in% c("", "NA", "N A", "NONE", "UNKNOWN")] <- NA_character_
  out
}

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

assign_membership <- function(rows, links, sample_name, definition) {
  ordered_rows <- rows |>
    arrange(date_filed, job_number) |>
    mutate(row_id = row_number())
  component <- seq_len(nrow(ordered_rows))
  link_rows <- links |>
    filter(
      job_number_1 %in% ordered_rows$job_number,
      job_number_2 %in% ordered_rows$job_number,
      job_number_1 != job_number_2
    ) |>
    distinct(job_number_1, job_number_2)
  left_index <- match(link_rows$job_number_1, ordered_rows$job_number)
  right_index <- match(link_rows$job_number_2, ordered_rows$job_number)

  for (link_row in seq_len(nrow(link_rows))) {
    left_component <- component[left_index[link_row]]
    right_component <- component[right_index[link_row]]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <-
      merged_component
  }

  ordered_rows |>
    mutate(component = component) |>
    group_by(component) |>
    mutate(parent_anchor_job = first(job_number)) |>
    ungroup() |>
    transmute(
      sample = sample_name,
      definition,
      job_number,
      parent_id = paste(sample_name, definition, parent_anchor_job, sep = "__")
    )
}

aggregate_model_rows <- function(rows, membership) {
  member_rows <- membership |>
    left_join(rows, by = "job_number", relationship = "many-to-one") |>
    mutate(
      feature_lot_id = case_when(
        !is.na(pluto_feature_bbl) ~ paste0("feature_", pluto_feature_bbl),
        !is.na(filing_bbl) ~ paste0("filing_", filing_bbl),
        TRUE ~ paste0("job_", job_number)
      ),
      bin_clean = na_if(str_squish(as.character(bin)), "")
    )

  parent_outcomes <- member_rows |>
    group_by(sample, definition, parent_id) |>
    summarise(
      date_filed = min(date_filed),
      date_last_filed = max(date_filed),
      filing_year = min(filing_year),
      last_filing_year = max(filing_year),
      units = sum(units),
      component_filings = n(),
      exact_99_component_filings = sum(units == 99L),
      nonmissing_bin_rows = sum(!is.na(bin_clean)),
      distinct_bins = n_distinct(bin_clean[!is.na(bin_clean)]),
      duplicate_bin_rows = pmax(nonmissing_bin_rows - distinct_bins, 0L),
      component_jobs = paste(job_number, collapse = ";"),
      .groups = "drop"
    )

  feature_lots <- member_rows |>
    arrange(date_filed, job_number) |>
    group_by(sample, definition, parent_id, feature_lot_id) |>
    slice_head(n = 1L) |>
    ungroup()

  parent_features <- feature_lots |>
    group_by(sample, definition, parent_id) |>
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
      feature_pluto_versions = n_distinct(
        paste(pluto_source_id_used, pluto_version_used, sep = "::")
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
      by = c("sample", "definition", "parent_id"),
      relationship = "one-to-one"
    ) |>
    mutate(
      observation_id = parent_id,
      log_units = log(units),
      log_lotarea = log(lotarea),
      model_eligible = duplicate_bin_rows == 0L
    ) |>
    select(
      sample, definition, observation_id, parent_id,
      date_filed, date_last_filed, filing_year, last_filing_year,
      units, log_units, component_filings, feature_lots,
      exact_99_component_filings, nonmissing_bin_rows, distinct_bins,
      duplicate_bin_rows, model_eligible, component_jobs,
      lotarea, log_lotarea, residfar, builtfar,
      borough, zone_detail, prior_site_use, feature_pluto_versions
    )
}

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

historical_pairs <- read_parquet(
  "../input/historical_parent_candidate_pairs.parquet"
) |>
  as.data.frame() |>
  as_tibble()

historical_adjacency <- read_parquet(
  "../input/historical_polygon_adjacency_pairs.parquet"
) |>
  as.data.frame() |>
  as_tibble()

dob_crosswalk <- read_parquet(
  "../input/developer_opportunity_job_crosswalk.parquet"
) |>
  as.data.frame() |>
  as_tibble()

mappluto_files <- read_csv(
  "../input/mappluto_files.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  filter(
    source_id == "dcp_mappluto_archive",
    file_role == "mappluto_shapefile_zip"
  ) |>
  transmute(
    source_id,
    vintage,
    raw_path = str_replace(
      raw_path,
      "^[.][.]/[.][.]/[.][.]/",
      "../../../../"
    )
  )

if (
  anyDuplicated(panel$job_number) ||
    anyDuplicated(historical_pairs[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(
      historical_adjacency[c("job_number_1", "job_number_2")]
    ) ||
    anyDuplicated(dob_crosswalk$dob_job_filing_number) ||
    anyDuplicated(mappluto_files[c("source_id", "vintage")])
) {
  stop("A parent-panel source is not unique on its required key.")
}

model_filing_rows <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= min_units,
    !is.na(lotarea),
    lotarea > 0,
    filing_year %in% c(pre_start_year:pre_end_year, post_year)
  ) |>
  mutate(
    units = as.integer(round(classa_prop)),
    filing_bbl = normalize_bbl_field(bbl),
    pluto_feature_bbl = normalize_bbl_field(pluto_feature_bbl),
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
    has_existing_units = !is.na(unitsres) & unitsres > 0,
    landuse_code = str_pad(as.character(landuse), 2L, pad = "0"),
    prior_site_use = case_when(
      has_existing_units ~ "existing_residential_units",
      landuse_code == "11" ~ "vacant_land",
      landuse_code == "10" ~ "parking",
      landuse_code %in% c("05", "06") ~ "commercial_industrial",
      landuse_code == "04" ~ "mixed_res_commercial",
      landuse_code %in% c("07", "08") ~ "public_transport_utility",
      is.na(landuse_code) ~ "missing_landuse",
      TRUE ~ "other_no_res_units"
    ),
    borough = hdb_borough_name
  ) |>
  select(
    job_number, date_filed, filing_year, units, filing_bbl,
    pluto_feature_bbl, bin, lotarea, residfar, builtfar,
    borough, zone_detail, prior_site_use,
    pluto_source_id_used, pluto_version_used
  ) |>
  arrange(date_filed, job_number)

historical_rows <- model_filing_rows |>
  filter(filing_year >= pre_start_year, filing_year <= pre_end_year)

post_rows <- model_filing_rows |>
  filter(filing_year == post_year) |>
  left_join(
    dob_crosswalk |>
      transmute(
        job_number = dob_job_filing_number,
        root_job_id,
        dob_filing_bbl = normalize_bbl_field(dob_bbl),
        historical_appbbl = normalize_bbl_field(historical_appbbl),
        lot_history_group_bbl = normalize_bbl_field(lot_history_group_bbl),
        owner_match_key = normalize_match_key(owner_match_key),
        description_referenced_job_id = str_remove(
          description_referenced_job_id,
          "-I[0-9]+$"
        ),
        description_project_code = na_if(
          str_squish(description_project_code),
          ""
        )
      ),
    by = "job_number",
    relationship = "one-to-one"
  )

if (
  nrow(historical_rows) == 0L ||
    nrow(post_rows) == 0L ||
    anyDuplicated(historical_rows$job_number) ||
    anyDuplicated(post_rows$job_number)
) {
  stop("Historical or post-policy filing rows failed construction QC.")
}

empty_links <- tibble(job_number_1 = character(), job_number_2 = character())

historical_conservative_links <- historical_pairs |>
  filter(high_confidence_prefiling_signal) |>
  select(job_number_1, job_number_2)

historical_enhanced_links <- bind_rows(
  historical_conservative_links,
  historical_adjacency |>
    filter(corroborated_exact_adjacency) |>
    select(job_number_1, job_number_2)
) |>
  distinct(job_number_1, job_number_2)

historical_membership <- bind_rows(
  assign_membership(
    historical_rows,
    empty_links,
    "historical",
    "filing"
  ),
  assign_membership(
    historical_rows,
    historical_conservative_links,
    "historical",
    "conservative_parent"
  ),
  assign_membership(
    historical_rows,
    historical_enhanced_links,
    "historical",
    "enhanced_parent"
  )
)

post_release <- post_rows |>
  distinct(
    source_id = pluto_source_id_used,
    vintage = pluto_version_used
  ) |>
  left_join(
    mappluto_files,
    by = c("source_id", "vintage"),
    relationship = "one-to-one"
  )

if (
  nrow(post_release) != 1L ||
    post_release$source_id != "dcp_mappluto_archive" ||
    is.na(post_release$raw_path)
) {
  stop("Post-policy filings do not share one exact pre-filing MapPLUTO release.")
}

archive_listing <- system2(
  "unzip",
  c("-Z1", post_release$raw_path),
  stdout = TRUE,
  stderr = FALSE
)
shapefile_entry <- archive_listing[
  str_to_lower(basename(archive_listing)) == "mappluto.shp"
][1]
needed_post_bbls <- sort(unique(post_rows$filing_bbl))
needed_post_bbls <- needed_post_bbls[!is.na(needed_post_bbls)]

if (is.na(shapefile_entry) || !nzchar(shapefile_entry)) {
  stop("Post-policy MapPLUTO archive has no MapPLUTO.shp.")
}

post_lots <- st_read(
  paste0(
    "/vsizip/", post_release$raw_path, "/", shapefile_entry
  ),
  query = paste0(
    "SELECT BBL FROM MapPLUTO WHERE BBL IN (",
    paste(needed_post_bbls, collapse = ","),
    ")"
  ),
  quiet = TRUE,
  stringsAsFactors = FALSE
) |>
  mutate(bbl = normalize_bbl_field(BBL)) |>
  select(bbl)

if (
  anyDuplicated(st_drop_geometry(post_lots)$bbl) ||
    any(!st_is_valid(post_lots))
) {
  stop("Post-policy MapPLUTO filing-lot geometries failed QC.")
}

post_touch_index <- st_touches(post_lots)
post_touch_rows <- rep(seq_len(nrow(post_lots)), lengths(post_touch_index))
post_touch_columns <- unlist(post_touch_index, use.names = FALSE)
post_touch_edges <- tibble(
  left_row = post_touch_rows,
  right_row = post_touch_columns
) |>
  filter(left_row < right_row) |>
  transmute(
    bbl_1 = post_lots$bbl[left_row],
    bbl_2 = post_lots$bbl[right_row],
    bbl_low = if_else(bbl_1 <= bbl_2, bbl_1, bbl_2),
    bbl_high = if_else(bbl_1 <= bbl_2, bbl_2, bbl_1),
    exact_polygon_touch = TRUE
  ) |>
  select(bbl_low, bbl_high, exact_polygon_touch)

if (anyDuplicated(post_touch_edges[c("bbl_low", "bbl_high")])) {
  stop("Post-policy exact-touch edges are not unique by BBL pair.")
}

post_rows <- post_rows |>
  arrange(date_filed, job_number)
post_row_ids <- seq_len(nrow(post_rows))
post_right_endpoints <- findInterval(
  post_rows$date_filed + max_filing_days,
  post_rows$date_filed
)
post_pair_counts <- pmax(post_right_endpoints - post_row_ids, 0L)
post_left_rows <- rep(post_row_ids, post_pair_counts)
post_right_rows <- unlist(
  Map(
    function(left_row, right_endpoint) {
      if (right_endpoint <= left_row) integer() else {
        seq.int(left_row + 1L, right_endpoint)
      }
    },
    post_row_ids,
    post_right_endpoints
  ),
  use.names = FALSE
)

post_link_pairs <- tibble(
  job_number_1 = post_rows$job_number[post_left_rows],
  job_number_2 = post_rows$job_number[post_right_rows],
  filing_days_apart = as.integer(
    post_rows$date_filed[post_right_rows] -
      post_rows$date_filed[post_left_rows]
  ),
  filing_bbl_1 = post_rows$filing_bbl[post_left_rows],
  filing_bbl_2 = post_rows$filing_bbl[post_right_rows],
  root_job_id_1 = post_rows$root_job_id[post_left_rows],
  root_job_id_2 = post_rows$root_job_id[post_right_rows],
  historical_appbbl_1 = post_rows$historical_appbbl[post_left_rows],
  historical_appbbl_2 = post_rows$historical_appbbl[post_right_rows],
  lot_history_group_bbl_1 =
    post_rows$lot_history_group_bbl[post_left_rows],
  lot_history_group_bbl_2 =
    post_rows$lot_history_group_bbl[post_right_rows],
  owner_match_key_1 = post_rows$owner_match_key[post_left_rows],
  owner_match_key_2 = post_rows$owner_match_key[post_right_rows],
  description_reference_1 =
    post_rows$description_referenced_job_id[post_left_rows],
  description_reference_2 =
    post_rows$description_referenced_job_id[post_right_rows],
  project_code_1 = post_rows$description_project_code[post_left_rows],
  project_code_2 = post_rows$description_project_code[post_right_rows]
) |>
  mutate(
    bbl_low = if_else(filing_bbl_1 <= filing_bbl_2, filing_bbl_1, filing_bbl_2),
    bbl_high = if_else(filing_bbl_1 <= filing_bbl_2, filing_bbl_2, filing_bbl_1),
    same_filing_bbl = !is.na(filing_bbl_1) & filing_bbl_1 == filing_bbl_2,
    same_lot_history_group =
      !is.na(lot_history_group_bbl_1) &
      lot_history_group_bbl_1 == lot_history_group_bbl_2 &
      (!is.na(historical_appbbl_1) | !is.na(historical_appbbl_2)),
    same_owner =
      !is.na(owner_match_key_1) & owner_match_key_1 == owner_match_key_2,
    explicit_job_reference =
      (!is.na(description_reference_1) &
        description_reference_1 %in% c(job_number_2, root_job_id_2)) |
      (!is.na(description_reference_2) &
        description_reference_2 %in% c(job_number_1, root_job_id_1)),
    same_project_code =
      !is.na(project_code_1) & project_code_1 == project_code_2
  ) |>
  left_join(
    post_touch_edges,
    by = c("bbl_low", "bbl_high"),
    relationship = "many-to-one"
  ) |>
  mutate(
    exact_polygon_touch = coalesce(exact_polygon_touch, FALSE),
    conservative_link =
      same_filing_bbl | same_lot_history_group |
      explicit_job_reference | same_project_code,
    corroborated_exact_adjacency =
      exact_polygon_touch &
      (filing_days_apart <= corroboration_days | same_owner),
    enhanced_link = conservative_link | corroborated_exact_adjacency
  ) |>
  arrange(job_number_1, job_number_2)

if (anyDuplicated(post_link_pairs[c("job_number_1", "job_number_2")])) {
  stop("Post-policy link-pair output is not unique by job pair.")
}

post_conservative_links <- post_link_pairs |>
  filter(conservative_link) |>
  select(job_number_1, job_number_2)

post_enhanced_links <- post_link_pairs |>
  filter(enhanced_link) |>
  select(job_number_1, job_number_2)

post_membership <- bind_rows(
  assign_membership(post_rows, empty_links, "post_policy", "filing"),
  assign_membership(
    post_rows,
    post_conservative_links,
    "post_policy",
    "conservative_parent"
  ),
  assign_membership(
    post_rows,
    post_enhanced_links,
    "post_policy",
    "enhanced_parent"
  )
)

historical_panel <- aggregate_model_rows(
  historical_rows,
  historical_membership
) |>
  arrange(definition, date_filed, parent_id)

post_panel <- aggregate_model_rows(post_rows, post_membership) |>
  arrange(definition, date_filed, parent_id)

membership <- bind_rows(historical_membership, post_membership) |>
  left_join(
    model_filing_rows |>
      select(job_number, date_filed, filing_year, units, bin),
    by = "job_number",
    relationship = "many-to-one"
  ) |>
  arrange(sample, definition, parent_id, date_filed, job_number)

construction_qc <- bind_rows(historical_panel, post_panel) |>
  group_by(sample, definition) |>
  summarise(
    parent_rows = n(),
    multi_filing_parents = sum(component_filings > 1L),
    filings_in_multi_filing_parents = sum(
      component_filings[component_filings > 1L]
    ),
    component_filings = sum(component_filings),
    parents_with_duplicate_bin_rows = sum(duplicate_bin_rows > 0L),
    model_eligible_parents = sum(model_eligible),
    observed_exact_99_parents = sum(units == 99L & model_eligible),
    observed_100_plus_parents = sum(units >= 100L & model_eligible),
    .groups = "drop"
  ) |>
  arrange(sample, definition)

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(
      historical_panel[c("definition", "observation_id")]
    ) ||
    anyDuplicated(post_panel[c("definition", "observation_id")]) ||
    anyDuplicated(membership[c("sample", "definition", "job_number")]) ||
    nrow(construction_qc) != 6L ||
    sum(
      historical_panel$component_filings[
        historical_panel$definition == "filing"
      ]
    ) != nrow(historical_rows) ||
    sum(
      post_panel$component_filings[post_panel$definition == "filing"]
    ) != nrow(post_rows)
) {
  stop("Parent model panels failed final construction QC.")
}

write_parquet_if_changed(
  historical_panel,
  "../output/historical_parent_model_panel.parquet"
)
write_parquet_if_changed(
  post_panel,
  "../output/post_policy_parent_model_panel.parquet"
)
write_parquet_if_changed(
  membership,
  "../output/parent_model_membership.parquet"
)
write_csv_if_changed(
  post_link_pairs,
  "../output/post_policy_parent_link_pairs.csv"
)
write_csv_if_changed(
  construction_qc,
  "../output/parent_panel_construction_qc.csv"
)

cat("Wrote parent model panels and membership to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")
# start_date <- as.Date("2010-01-01")
# end_date <- as.Date("2025-12-31")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2L) {
  stop("Expected two arguments: panel start date and panel end date.")
}

start_date <- as.Date(args[1])
end_date <- as.Date(args[2])

if (is.na(start_date) || is.na(end_date) || end_date < start_date) {
  stop("Panel start and end dates are not valid.")
}

feature_columns <- c(
  "pluto_borough", "pluto_block", "pluto_lot", "pluto_address", "pluto_cd", "zipcode",
  "ct2010", "cb2010", "schooldist", "pluto_council",
  "zonedist1", "zonedist2", "zonedist3", "zonedist4", "overlay1", "overlay2",
  "spdist1", "spdist2", "spdist3", "ltdheight", "splitzone", "zonemap", "zmcode",
  "landuse", "bldgclass", "histdist", "landmark", "firm07_flag", "pfirm15_flag",
  "lotarea", "lotfront", "lotdepth", "bldgarea", "resarea", "comarea", "unitsres",
  "unitstotal", "numbldgs", "numfloors", "yearbuilt", "builtfar", "maxallwfar",
  "residfar", "commfar", "facilfar", "assessland", "assesstot"
)

numeric_feature_columns <- c(
  "lotarea", "lotfront", "lotdepth", "bldgarea", "resarea", "comarea", "unitsres",
  "unitstotal", "numbldgs", "numfloors", "yearbuilt", "builtfar", "maxallwfar",
  "residfar", "commfar", "facilfar", "assessland", "assesstot",
  "allowed_res_area", "residual_res_area"
)

parse_bbl_borough <- function(x) {
  substr(as.character(x), 1L, 1L)
}

parse_bbl_block <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 2L, 6L)))
}

parse_bbl_lot <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 7L, 10L)))
}

min_date_value <- function(x) {
  if (all(is.na(x))) {
    return(as.Date(NA))
  }
  min(x, na.rm = TRUE)
}

max_date_value <- function(x) {
  if (all(is.na(x))) {
    return(as.Date(NA))
  }
  max(x, na.rm = TRUE)
}

hdb <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |>
  as.data.frame() |>
  as_tibble()

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))
release_calendar <- read_csv("../input/mappluto_release_calendar.csv", show_col_types = FALSE, na = c("", "NA"))
mappluto_appbbl_crosswalk <- read_csv("../input/mappluto_appbbl_crosswalk.csv", show_col_types = FALSE, na = c("", "NA"))

missing_mappluto_columns <- setdiff(c("source_id", "vintage", "parquet_path"), names(mappluto_lot_files))

if (length(missing_mappluto_columns) > 0) {
  stop("MapPLUTO lot manifest is missing columns: ", paste(missing_mappluto_columns, collapse = ", "))
}

missing_calendar_columns <- setdiff(c("source_id", "vintage", "release_order", "safe_available_date", "usable_for_training"), names(release_calendar))

if (length(missing_calendar_columns) > 0) {
  stop("MapPLUTO release calendar is missing columns: ", paste(missing_calendar_columns, collapse = ", "))
}

missing_appbbl_columns <- setdiff(c("current_bbl", "appbbl", "appdate_min", "appdate_max", "same_boro_block"), names(mappluto_appbbl_crosswalk))

if (length(missing_appbbl_columns) > 0) {
  stop("MapPLUTO APPBBL crosswalk is missing columns: ", paste(missing_appbbl_columns, collapse = ", "))
}

release_calendar <- release_calendar |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    release_order = suppressWarnings(as.integer(release_order)),
    safe_available_date = as.Date(safe_available_date),
    usable_for_training = str_to_upper(as.character(usable_for_training)) == "TRUE"
  ) |>
  filter(usable_for_training) |>
  arrange(release_order)

if (nrow(release_calendar) == 0) {
  stop("Release calendar has no usable MapPLUTO releases.")
}

if (anyDuplicated(paste(release_calendar$source_id, release_calendar$vintage, sep = "::")) > 0 ||
    anyDuplicated(release_calendar$release_order) > 0) {
  stop("Release calendar must be unique by source/vintage and release_order.")
}

earliest_release <- release_calendar[1, ]

mappluto_appbbl_crosswalk <- mappluto_appbbl_crosswalk |>
  mutate(
    current_bbl = normalize_bbl_field(current_bbl),
    appbbl = normalize_bbl_field(appbbl),
    appdate_min = as.Date(appdate_min),
    appdate_max = as.Date(appdate_max),
    same_boro_block = str_to_upper(as.character(same_boro_block)) == "TRUE",
    appbbl_borough = parse_bbl_borough(appbbl),
    appbbl_block = parse_bbl_block(appbbl),
    appbbl_lot = parse_bbl_lot(appbbl)
  ) |>
  filter(!is.na(current_bbl), !is.na(appbbl), current_bbl != appbbl)

appbbl_duplicate_keys <- mappluto_appbbl_crosswalk |>
  count(current_bbl, appbbl, name = "rows") |>
  filter(rows > 1)

if (nrow(appbbl_duplicate_keys) > 0) {
  stop("APPBBL crosswalk is not unique by current_bbl/appbbl.")
}

candidate_panel <- hdb |>
  filter(job_type == "New Building", date_filed >= start_date, date_filed <= end_date) |>
  mutate(
    filing_year = suppressWarnings(as.integer(format(date_filed, "%Y"))),
    bbl = normalize_bbl_field(bbl),
    bin = as.character(bin),
    classa_prop_integer = !is.na(classa_prop) & classa_prop > 0 & abs(classa_prop - round(classa_prop)) < 1e-8,
    y100 = if_else(classa_prop_integer, classa_prop >= 100, NA)
  ) |>
  transmute(
    job_number,
    job_status,
    date_filed,
    filing_year,
    bbl,
    bin,
    address,
    house_number,
    street_name,
    ownership,
    hdb_borough_code = borough_code,
    hdb_borough_name = borough_name,
    hdb_community_district = community_district,
    hdb_council_district = council_district,
    classa_prop,
    classa_prop_integer,
    y100
  )

latest_pre_filing <- rep(NA_character_, nrow(candidate_panel))
latest_pre_filing_source <- rep(NA_character_, nrow(candidate_panel))
latest_pre_filing_order <- rep(NA_integer_, nrow(candidate_panel))
latest_pre_filing_date <- rep(as.Date(NA), nrow(candidate_panel))
lagged_version <- rep(NA_character_, nrow(candidate_panel))
lagged_source <- rep(NA_character_, nrow(candidate_panel))
lagged_order <- rep(NA_integer_, nrow(candidate_panel))
lagged_date <- rep(as.Date(NA), nrow(candidate_panel))
pluto_timing_status <- rep(NA_character_, nrow(candidate_panel))
true_lagged_pluto_available <- rep(FALSE, nrow(candidate_panel))

for (i in seq_len(nrow(candidate_panel))) {
  available_release_rows <- release_calendar |>
    filter(safe_available_date < candidate_panel$date_filed[i]) |>
    arrange(release_order)

  if (nrow(available_release_rows) == 0) {
    lagged_source[i] <- earliest_release$source_id
    lagged_version[i] <- earliest_release$vintage
    lagged_order[i] <- earliest_release$release_order
    lagged_date[i] <- earliest_release$safe_available_date
    pluto_timing_status[i] <- "post_filing_backfill"
    next
  }

  latest_release <- available_release_rows[nrow(available_release_rows), ]
  latest_pre_filing_source[i] <- latest_release$source_id
  latest_pre_filing[i] <- latest_release$vintage
  latest_pre_filing_order[i] <- latest_release$release_order
  latest_pre_filing_date[i] <- latest_release$safe_available_date

  lagged_release_rows <- release_calendar |>
    filter(release_order < latest_release$release_order) |>
    arrange(release_order)

  if (nrow(lagged_release_rows) == 0) {
    lagged_source[i] <- latest_release$source_id
    lagged_version[i] <- latest_release$vintage
    lagged_order[i] <- latest_release$release_order
    lagged_date[i] <- latest_release$safe_available_date
    pluto_timing_status[i] <- "latest_pre_filing_no_lag"
    next
  }

  lagged_release <- lagged_release_rows[nrow(lagged_release_rows), ]
  lagged_source[i] <- lagged_release$source_id
  lagged_version[i] <- lagged_release$vintage
  lagged_order[i] <- lagged_release$release_order
  lagged_date[i] <- lagged_release$safe_available_date
  pluto_timing_status[i] <- "strict_lag_pre_filing"
  true_lagged_pluto_available[i] <- TRUE
}

candidate_panel <- candidate_panel |>
  mutate(
    pluto_source_id_latest_pre_filing = latest_pre_filing_source,
    pluto_version_latest_pre_filing = latest_pre_filing,
    pluto_release_order_latest_pre_filing = latest_pre_filing_order,
    pluto_safe_available_date_latest_pre_filing = latest_pre_filing_date,
    pluto_source_id_used = lagged_source,
    pluto_version_used = lagged_version,
    pluto_release_order_used = lagged_order,
    pluto_safe_available_date_used = lagged_date,
    pluto_timing_status = pluto_timing_status,
    true_lagged_pluto_available = true_lagged_pluto_available,
    backfill_used = pluto_timing_status %in% c("post_filing_backfill", "latest_pre_filing_no_lag"),
    post_filing_pluto = !is.na(pluto_safe_available_date_used) & pluto_safe_available_date_used >= date_filed,
    pluto_days_relative_to_filing = as.integer(date_filed - pluto_safe_available_date_used),
    valid_bbl = str_detect(bbl, "^[1-5][0-9]{9}$"),
    hdb_bbl_borough = parse_bbl_borough(bbl),
    hdb_bbl_block = parse_bbl_block(bbl),
    hdb_bbl_lot = parse_bbl_lot(bbl),
    hdb_panel_row_id = row_number()
  )

lag_invariant_failures <- candidate_panel |>
  filter(true_lagged_pluto_available) |>
  filter(
    is.na(pluto_release_order_used) |
      is.na(pluto_release_order_latest_pre_filing) |
      is.na(pluto_safe_available_date_used) |
      is.na(pluto_safe_available_date_latest_pre_filing) |
      pluto_timing_status != "strict_lag_pre_filing" |
      pluto_release_order_used != pluto_release_order_latest_pre_filing - 1L |
      pluto_safe_available_date_used >= pluto_safe_available_date_latest_pre_filing |
      pluto_safe_available_date_latest_pre_filing >= date_filed
  )

if (nrow(lag_invariant_failures) > 0) {
  stop("One-release-lag assignment invariant failed for ", nrow(lag_invariant_failures), " rows.")
}

mappluto_lot_files <- mappluto_lot_files |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    parquet_path = as.character(parquet_path),
    raw_status = if ("raw_status" %in% names(mappluto_lot_files)) as.character(raw_status) else NA_character_
  )

mappluto_index <- release_calendar |>
  select(source_id, vintage, release_order) |>
  left_join(
    mappluto_lot_files |>
      select(source_id, vintage, parquet_path, raw_status),
    by = c("source_id", "vintage"),
    relationship = "one-to-one"
  )

candidate_rows_before_pluto_index <- nrow(candidate_panel)

candidate_panel <- candidate_panel |>
  left_join(
    mappluto_index |>
      transmute(
        pluto_source_id_used = source_id,
        pluto_version_used = vintage,
        selected_pluto_parquet_path = parquet_path,
        selected_pluto_raw_status = raw_status
      ),
    by = c("pluto_source_id_used", "pluto_version_used"),
    relationship = "many-to-one"
  )

if (nrow(candidate_panel) != candidate_rows_before_pluto_index) {
  stop("Joining selected PLUTO file metadata changed candidate row count.")
}

appbbl_candidate_rows <- list()

for (i in seq_len(nrow(candidate_panel))) {
  if (!candidate_panel$valid_bbl[i]) {
    next
  }

  row_candidates <- mappluto_appbbl_crosswalk |>
    filter(current_bbl == candidate_panel$bbl[i])

  if (nrow(row_candidates) == 0) {
    next
  }

  appbbl_candidate_rows[[length(appbbl_candidate_rows) + 1L]] <- row_candidates |>
    mutate(
      hdb_panel_row_id = candidate_panel$hdb_panel_row_id[i],
      job_number = candidate_panel$job_number[i],
      date_filed = candidate_panel$date_filed[i],
      hdb_bbl = candidate_panel$bbl[i],
      hdb_bbl_borough = candidate_panel$hdb_bbl_borough[i],
      hdb_bbl_block = candidate_panel$hdb_bbl_block[i],
      hdb_bbl_lot = candidate_panel$hdb_bbl_lot[i],
      pluto_source_id_used = candidate_panel$pluto_source_id_used[i],
      pluto_version_used = candidate_panel$pluto_version_used[i],
      .before = source_id
    )
}

appbbl_candidate_rows <- bind_rows(appbbl_candidate_rows)

if (nrow(appbbl_candidate_rows) == 0) {
  appbbl_candidate_rows <- tibble(
    hdb_panel_row_id = integer(),
    job_number = character(),
    date_filed = as.Date(character()),
    hdb_bbl = character(),
    hdb_bbl_borough = character(),
    hdb_bbl_block = integer(),
    hdb_bbl_lot = integer(),
    pluto_source_id_used = character(),
    pluto_version_used = character(),
    source_id = character(),
    vintage = character(),
    current_bbl = character(),
    appbbl = character(),
    evidence_rows = integer(),
    condono_values = character(),
    plutomapid_values = character(),
    appdate_min = as.Date(character()),
    appdate_max = as.Date(character()),
    current_borough = character(),
    current_block = integer(),
    current_lot = integer(),
    appbbl_borough = character(),
    appbbl_block = integer(),
    appbbl_lot = integer(),
    same_boro_block = logical()
  )
}

needed_feature_bbl <- bind_rows(
  candidate_panel |>
    filter(valid_bbl) |>
    transmute(pluto_source_id_used, pluto_version_used, feature_bbl = bbl),
  appbbl_candidate_rows |>
    filter(same_boro_block) |>
    transmute(pluto_source_id_used, pluto_version_used, feature_bbl = appbbl)
) |>
  filter(!is.na(pluto_source_id_used), !is.na(pluto_version_used), !is.na(feature_bbl)) |>
  distinct(pluto_source_id_used, pluto_version_used, feature_bbl)

empty_features <- tibble(
  bbl = character(),
  pluto_source_id_used = character(),
  pluto_version_used = character(),
  pluto_match_status = character(),
  pluto_borough = character(),
  pluto_block = integer(),
  pluto_lot = integer(),
  pluto_address = character(),
  pluto_cd = integer(),
  schooldist = integer(),
  pluto_council = integer(),
  zipcode = character(),
  ct2010 = character(),
  cb2010 = character(),
  zonedist1 = character(),
  zonedist2 = character(),
  zonedist3 = character(),
  zonedist4 = character(),
  overlay1 = character(),
  overlay2 = character(),
  spdist1 = character(),
  spdist2 = character(),
  spdist3 = character(),
  ltdheight = character(),
  splitzone = character(),
  zonemap = character(),
  zmcode = character(),
  landuse = character(),
  bldgclass = character(),
  histdist = character(),
  landmark = character(),
  firm07_flag = character(),
  pfirm15_flag = character(),
  lotarea = numeric(),
  lotfront = numeric(),
  lotdepth = numeric(),
  bldgarea = numeric(),
  resarea = numeric(),
  comarea = numeric(),
  unitsres = numeric(),
  unitstotal = numeric(),
  numbldgs = integer(),
  numfloors = numeric(),
  yearbuilt = integer(),
  builtfar = numeric(),
  maxallwfar = numeric(),
  residfar = numeric(),
  commfar = numeric(),
  facilfar = numeric(),
  assessland = numeric(),
  assesstot = numeric()
)

matched_feature_rows <- list()
selected_vintages <- candidate_panel |>
  filter(!is.na(pluto_source_id_used), !is.na(pluto_version_used), !is.na(selected_pluto_parquet_path)) |>
  distinct(pluto_source_id_used, pluto_version_used, selected_pluto_parquet_path) |>
  arrange(pluto_source_id_used, pluto_version_used)

for (i in seq_len(nrow(selected_vintages))) {
  version_row <- selected_vintages[i, ]
  parquet_path <- file.path("..", "..", "stage_mappluto_lots", "output", basename(version_row$selected_pluto_parquet_path))

  needed_bbl <- needed_feature_bbl |>
    filter(
      pluto_source_id_used == version_row$pluto_source_id_used,
      pluto_version_used == version_row$pluto_version_used
    ) |>
    distinct(bbl = feature_bbl)

  if (!file.exists(parquet_path) || nrow(needed_bbl) == 0) {
    next
  }

  lot_table <- read_parquet(parquet_path) |>
    as.data.frame() |>
    as_tibble() |>
    mutate(bbl = as.character(bbl)) |>
    filter(bbl %in% needed_bbl$bbl)

  duplicate_bbls <- lot_table |>
    count(bbl, name = "mappluto_bbl_rows") |>
    filter(mappluto_bbl_rows > 1) |>
    select(bbl, mappluto_bbl_rows)

  unique_lots <- lot_table |>
    count(bbl, name = "mappluto_bbl_rows") |>
    filter(mappluto_bbl_rows == 1) |>
    select(bbl) |>
    inner_join(lot_table, by = "bbl", relationship = "one-to-one") |>
    transmute(
      bbl,
      pluto_match_status = "matched_unique_bbl",
      pluto_borough = borough,
      pluto_block = block,
      pluto_lot = lot,
      pluto_address = address,
      pluto_cd = cd,
      zipcode,
      ct2010,
      cb2010,
      schooldist,
      pluto_council = council,
      zonedist1,
      zonedist2,
      zonedist3,
      zonedist4,
      overlay1,
      overlay2,
      spdist1,
      spdist2,
      spdist3,
      ltdheight,
      splitzone,
      zonemap,
      zmcode,
      landuse,
      bldgclass,
      histdist,
      landmark,
      firm07_flag,
      pfirm15_flag,
      lotarea,
      lotfront,
      lotdepth,
      bldgarea,
      resarea,
      comarea,
      unitsres,
      unitstotal,
      numbldgs,
      numfloors,
      yearbuilt,
      builtfar,
      maxallwfar,
      residfar,
      commfar,
      facilfar,
      assessland,
      assesstot
    )

  duplicate_rows <- duplicate_bbls |>
    transmute(
      bbl,
      pluto_match_status = "duplicate_mappluto_bbl",
      pluto_borough = NA_character_,
      pluto_block = NA_integer_,
      pluto_lot = NA_integer_,
      pluto_address = NA_character_,
      pluto_cd = NA_integer_,
      zipcode = NA_character_,
      ct2010 = NA_character_,
      cb2010 = NA_character_,
      schooldist = NA_integer_,
      pluto_council = NA_integer_,
      zonedist1 = NA_character_,
      zonedist2 = NA_character_,
      zonedist3 = NA_character_,
      zonedist4 = NA_character_,
      overlay1 = NA_character_,
      overlay2 = NA_character_,
      spdist1 = NA_character_,
      spdist2 = NA_character_,
      spdist3 = NA_character_,
      ltdheight = NA_character_,
      splitzone = NA_character_,
      zonemap = NA_character_,
      zmcode = NA_character_,
      landuse = NA_character_,
      bldgclass = NA_character_,
      histdist = NA_character_,
      landmark = NA_character_,
      firm07_flag = NA_character_,
      pfirm15_flag = NA_character_,
      lotarea = NA_real_,
      lotfront = NA_real_,
      lotdepth = NA_real_,
      bldgarea = NA_real_,
      resarea = NA_real_,
      comarea = NA_real_,
      unitsres = NA_real_,
      unitstotal = NA_real_,
      numbldgs = NA_integer_,
      numfloors = NA_real_,
      yearbuilt = NA_integer_,
      builtfar = NA_real_,
      maxallwfar = NA_real_,
      residfar = NA_real_,
      commfar = NA_real_,
      facilfar = NA_real_,
      assessland = NA_real_,
      assesstot = NA_real_
    )

  matched_feature_rows[[i]] <- bind_rows(unique_lots, duplicate_rows) |>
    mutate(
      pluto_source_id_used = version_row$pluto_source_id_used,
      pluto_version_used = version_row$pluto_version_used
    )
}

matched_features <- if (length(matched_feature_rows) == 0) {
  empty_features |>
    mutate(pluto_version_used = character())
} else {
  bind_rows(matched_feature_rows)
}

matched_feature_duplicate_keys <- matched_features |>
  count(bbl, pluto_source_id_used, pluto_version_used, name = "matched_feature_rows") |>
  filter(matched_feature_rows > 1)

if (nrow(matched_feature_duplicate_keys) > 0) {
  stop("Matched PLUTO features are not unique by BBL/source/vintage.")
}

matched_feature_status <- matched_features |>
  select(
    pluto_source_id_used,
    pluto_version_used,
    feature_bbl = bbl,
    feature_pluto_match_status = pluto_match_status
  )

candidate_rows_before_strict_status_join <- nrow(candidate_panel)

candidate_panel <- candidate_panel |>
  left_join(
    matched_feature_status |>
      rename(strict_pluto_match_status = feature_pluto_match_status),
    by = c("bbl" = "feature_bbl", "pluto_source_id_used", "pluto_version_used"),
    relationship = "many-to-one"
  ) |>
  mutate(
    strict_pluto_match_status = case_when(
      is.na(pluto_version_used) ~ NA_character_,
      is.na(selected_pluto_parquet_path) ~ "selected_pluto_file_missing",
      is.na(strict_pluto_match_status) ~ "no_mappluto_match",
      TRUE ~ strict_pluto_match_status
    )
  )

if (nrow(candidate_panel) != candidate_rows_before_strict_status_join) {
  stop("Joining strict PLUTO match status changed candidate row count.")
}

appbbl_candidate_status <- appbbl_candidate_rows |>
  left_join(
    candidate_panel |>
      select(hdb_panel_row_id, strict_pluto_match_status),
    by = "hdb_panel_row_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    matched_feature_status,
    by = c("appbbl" = "feature_bbl", "pluto_source_id_used", "pluto_version_used"),
    relationship = "many-to-one"
  ) |>
  mutate(
    appbbl_pluto_match_status = case_when(
      is.na(pluto_version_used) ~ NA_character_,
      is.na(feature_pluto_match_status) ~ "no_mappluto_match",
      TRUE ~ feature_pluto_match_status
    ),
    future_appdate_used_for_linkage = !is.na(appdate_max) & appdate_max > date_filed
  )

appbbl_resolution_counts <- appbbl_candidate_status |>
  group_by(hdb_panel_row_id) |>
  summarise(
    n_appbbl_candidates = n(),
    n_appbbl_distinct_candidates = n_distinct(appbbl),
    n_appbbl_same_boro_block_candidates = sum(same_boro_block),
    n_appbbl_cross_boro_block_candidates = sum(!same_boro_block),
    n_appbbl_unique_lagged_candidates = sum(same_boro_block & appbbl_pluto_match_status == "matched_unique_bbl"),
    n_appbbl_duplicate_lagged_candidates = sum(same_boro_block & appbbl_pluto_match_status == "duplicate_mappluto_bbl"),
    n_appbbl_not_in_lagged_candidates = sum(same_boro_block & appbbl_pluto_match_status == "no_mappluto_match"),
    appbbl_future_appdate_used_for_linkage = any(future_appdate_used_for_linkage),
    .groups = "drop"
  )

appbbl_accepted_rows <- appbbl_candidate_status |>
  filter(strict_pluto_match_status == "no_mappluto_match", same_boro_block, appbbl_pluto_match_status == "matched_unique_bbl") |>
  group_by(hdb_panel_row_id) |>
  filter(n_distinct(appbbl) == 1L) |>
  summarise(
    appbbl_feature_bbl = first(appbbl),
    appbbl_match_method = if_else(
      first(hdb_bbl_lot) >= 7500L,
      "official_appbbl_condo_lagged_match",
      "official_appbbl_noncondo_lagged_match"
    ),
    appbbl_evidence_rows = sum(evidence_rows),
    appbbl_condono_values = paste(sort(unique(as.character(condono_values[!is.na(condono_values) & condono_values != ""]))), collapse = ";"),
    appbbl_appdate_min = min_date_value(appdate_min),
    appbbl_appdate_max = max_date_value(appdate_max),
    .groups = "drop"
  )

appbbl_accepted_rows$appbbl_condono_values[appbbl_accepted_rows$appbbl_condono_values == ""] <- NA_character_

appbbl_feature_bbl_counts <- appbbl_accepted_rows |>
  count(appbbl_feature_bbl, name = "appbbl_feature_bbl_hdb_rows")

appbbl_accepted_rows <- appbbl_accepted_rows |>
  left_join(appbbl_feature_bbl_counts, by = "appbbl_feature_bbl", relationship = "many-to-one")

candidate_rows_before_appbbl_join <- nrow(candidate_panel)

candidate_panel <- candidate_panel |>
  left_join(appbbl_resolution_counts, by = "hdb_panel_row_id", relationship = "one-to-one") |>
  left_join(appbbl_accepted_rows, by = "hdb_panel_row_id", relationship = "one-to-one") |>
  mutate(
    n_appbbl_candidates = coalesce(n_appbbl_candidates, 0L),
    n_appbbl_distinct_candidates = coalesce(n_appbbl_distinct_candidates, 0L),
    n_appbbl_same_boro_block_candidates = coalesce(n_appbbl_same_boro_block_candidates, 0L),
    n_appbbl_cross_boro_block_candidates = coalesce(n_appbbl_cross_boro_block_candidates, 0L),
    n_appbbl_unique_lagged_candidates = coalesce(n_appbbl_unique_lagged_candidates, 0L),
    n_appbbl_duplicate_lagged_candidates = coalesce(n_appbbl_duplicate_lagged_candidates, 0L),
    n_appbbl_not_in_lagged_candidates = coalesce(n_appbbl_not_in_lagged_candidates, 0L),
    appbbl_future_appdate_used_for_linkage = coalesce(appbbl_future_appdate_used_for_linkage, FALSE),
    appbbl_feature_bbl_hdb_rows = coalesce(appbbl_feature_bbl_hdb_rows, 0L),
    appbbl_resolution_status = case_when(
      n_appbbl_candidates == 0L ~ "no_official_appbbl_candidate",
      !is.na(appbbl_feature_bbl) & appbbl_feature_bbl_hdb_rows > 1L ~ "official_appbbl_unique_lagged_shared_feature_bbl",
      !is.na(appbbl_feature_bbl) ~ "official_appbbl_unique_lagged_match",
      n_appbbl_unique_lagged_candidates > 1L ~ "ambiguous_multiple_appbbl_candidates",
      n_appbbl_duplicate_lagged_candidates > 0L ~ "appbbl_candidate_duplicate_in_lagged_pluto",
      n_appbbl_same_boro_block_candidates > 0L ~ "official_appbbl_not_in_lagged_pluto",
      n_appbbl_cross_boro_block_candidates > 0L ~ "only_cross_block_appbbl_candidate",
      TRUE ~ "unresolved_appbbl_candidate"
    ),
    appbbl_recovery_used = strict_pluto_match_status == "no_mappluto_match" & !is.na(appbbl_feature_bbl),
    pluto_feature_bbl = if_else(appbbl_recovery_used, appbbl_feature_bbl, bbl),
    pluto_match_method = case_when(
      appbbl_recovery_used ~ appbbl_match_method,
      strict_pluto_match_status == "matched_unique_bbl" ~ "strict_hdb_bbl_lagged_match",
      strict_pluto_match_status == "duplicate_mappluto_bbl" ~ "strict_hdb_bbl_duplicate",
      TRUE ~ "strict_hdb_bbl_no_match"
    ),
    pluto_feature_bbl_hdb_rows = if_else(appbbl_recovery_used, appbbl_feature_bbl_hdb_rows, 1L)
  )

if (nrow(candidate_panel) != candidate_rows_before_appbbl_join) {
  stop("Joining APPBBL recovery metadata changed candidate row count.")
}

candidate_rows_before_feature_join <- nrow(candidate_panel)

candidate_panel <- candidate_panel |>
  left_join(
    matched_features |>
      rename(pluto_feature_bbl = bbl),
    by = c("pluto_feature_bbl", "pluto_source_id_used", "pluto_version_used"),
    relationship = "many-to-one"
  ) |>
  mutate(
    pluto_match_status = case_when(
      is.na(pluto_version_used) ~ NA_character_,
      is.na(selected_pluto_parquet_path) ~ "selected_pluto_file_missing",
      is.na(pluto_match_status) ~ "no_mappluto_match",
      TRUE ~ pluto_match_status
    ),
    allowed_res_area = if_else(!is.na(lotarea) & !is.na(residfar), lotarea * residfar, NA_real_),
    residual_res_area = if_else(!is.na(allowed_res_area) & !is.na(resarea), pmax(allowed_res_area - resarea, 0), NA_real_),
    is_vacant_landuse = !is.na(landuse) & landuse == "11",
    is_vacant_bldgclass = !is.na(bldgclass) & str_starts(str_to_upper(bldgclass), "V"),
    is_vacant_lot = is_vacant_landuse | is_vacant_bldgclass,
    exclusion_reason = case_when(
      !valid_bbl ~ "invalid_bbl",
      !classa_prop_integer ~ "invalid_classa_prop",
      is.na(pluto_version_used) ~ "no_pluto_release_assigned",
      is.na(selected_pluto_parquet_path) ~ "selected_pluto_file_missing",
      pluto_match_status == "duplicate_mappluto_bbl" ~ "duplicate_mappluto_bbl",
      pluto_match_status == "no_mappluto_match" ~ "no_mappluto_match",
      is.na(lotarea) | lotarea <= 0 ~ "nonpositive_lotarea",
      TRUE ~ "included_primary_sample"
    ),
    primary_sample = exclusion_reason == "included_primary_sample",
    primary_leakage_safe_sample = primary_sample & true_lagged_pluto_available,
    expanded_backfill_sample = primary_sample
  )

if (nrow(candidate_panel) != candidate_rows_before_feature_join) {
  stop("Joining matched PLUTO features changed candidate row count.")
}

for (feature_name in numeric_feature_columns) {
  candidate_panel[[paste0("missing_", feature_name)]] <- is.na(candidate_panel[[feature_name]])
}

candidate_panel <- candidate_panel |>
  select(
    hdb_panel_row_id, job_number, job_status, date_filed, filing_year, bbl, hdb_bbl_borough, hdb_bbl_block, hdb_bbl_lot,
    bin, address, house_number, street_name, ownership,
    hdb_borough_code, hdb_borough_name, hdb_community_district, hdb_council_district,
    classa_prop, classa_prop_integer, y100,
    pluto_source_id_latest_pre_filing, pluto_version_latest_pre_filing,
    pluto_release_order_latest_pre_filing, pluto_safe_available_date_latest_pre_filing,
    pluto_source_id_used, pluto_version_used,
    pluto_release_order_used, pluto_safe_available_date_used,
    pluto_timing_status, true_lagged_pluto_available, backfill_used,
    post_filing_pluto, pluto_days_relative_to_filing,
    selected_pluto_parquet_path, selected_pluto_raw_status,
    pluto_feature_bbl, pluto_match_method, pluto_feature_bbl_hdb_rows,
    strict_pluto_match_status, appbbl_recovery_used, appbbl_resolution_status,
    appbbl_feature_bbl, appbbl_feature_bbl_hdb_rows, appbbl_match_method,
    appbbl_evidence_rows, appbbl_condono_values, appbbl_appdate_min, appbbl_appdate_max,
    appbbl_future_appdate_used_for_linkage,
    n_appbbl_candidates, n_appbbl_distinct_candidates, n_appbbl_same_boro_block_candidates,
    n_appbbl_cross_boro_block_candidates, n_appbbl_unique_lagged_candidates,
    n_appbbl_duplicate_lagged_candidates, n_appbbl_not_in_lagged_candidates,
    pluto_match_status,
    valid_bbl, primary_sample, primary_leakage_safe_sample, expanded_backfill_sample, exclusion_reason,
    all_of(feature_columns),
    allowed_res_area, residual_res_area,
    is_vacant_landuse, is_vacant_bldgclass, is_vacant_lot,
    starts_with("missing_")
  )

write_parquet_if_changed(candidate_panel, "../output/hdb_mappluto_site_panel.parquet")
cat("Wrote HDB-MapPLUTO site panel to ../output/hdb_mappluto_site_panel.parquet\n")

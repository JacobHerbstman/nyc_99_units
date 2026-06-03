# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_training_panel/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

start_date <- as.Date("2010-01-01")
end_date <- as.Date("2023-12-31")

feature_columns <- c(
  "pluto_borough", "pluto_block", "pluto_lot", "pluto_address", "pluto_cd", "zipcode",
  "ct2010", "cb2010", "schooldist", "pluto_council",
  "zonedist1", "zonedist2", "zonedist3", "zonedist4", "overlay1", "overlay2",
  "spdist1", "spdist2", "spdist3", "ltdheight", "splitzone", "zonemap", "zmcode",
  "landuse", "bldgclass", "histdist", "landmark", "firm07_flag", "pfirm15_flag",
  "lotarea", "bldgarea", "resarea", "comarea", "unitsres", "unitstotal",
  "numbldgs", "numfloors", "yearbuilt", "builtfar", "residfar", "commfar",
  "facilfar", "assessland", "assesstot"
)

numeric_feature_columns <- c(
  "lotarea", "bldgarea", "resarea", "comarea", "unitsres", "unitstotal",
  "numbldgs", "numfloors", "yearbuilt", "builtfar", "residfar", "commfar",
  "facilfar", "assessland", "assesstot", "allowed_res_area", "residual_res_area"
)

hdb <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |>
  as.data.frame() |>
  as_tibble()

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))
release_calendar <- read_csv("../input/mappluto_release_calendar.csv", show_col_types = FALSE, na = c("", "NA"))

missing_mappluto_columns <- setdiff(c("source_id", "vintage", "parquet_path"), names(mappluto_lot_files))

if (length(missing_mappluto_columns) > 0) {
  stop("MapPLUTO lot manifest is missing columns: ", paste(missing_mappluto_columns, collapse = ", "))
}

missing_calendar_columns <- setdiff(c("source_id", "vintage", "release_order", "safe_available_date", "usable_for_training"), names(release_calendar))

if (length(missing_calendar_columns) > 0) {
  stop("MapPLUTO release calendar is missing columns: ", paste(missing_calendar_columns, collapse = ", "))
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

candidate_panel <- hdb |>
  filter(job_type == "New Building", date_filed >= start_date, date_filed <= end_date) |>
  mutate(
    filing_year = suppressWarnings(as.integer(format(date_filed, "%Y"))),
    bbl = as.character(bbl),
    bin = as.character(bin),
    classa_prop_integer = !is.na(classa_prop) & classa_prop > 0 & abs(classa_prop - round(classa_prop)) < 1e-8,
    y100 = if_else(classa_prop_integer, classa_prop >= 100, NA)
  ) |>
  transmute(
    job_number,
    date_filed,
    filing_year,
    bbl,
    bin,
    address,
    house_number,
    street_name,
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
    valid_bbl = str_detect(bbl, "^[1-5][0-9]{9}$")
  )

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
  bldgarea = numeric(),
  resarea = numeric(),
  comarea = numeric(),
  unitsres = numeric(),
  unitstotal = numeric(),
  numbldgs = integer(),
  numfloors = numeric(),
  yearbuilt = integer(),
  builtfar = numeric(),
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

  needed_bbl <- candidate_panel |>
    filter(
      pluto_source_id_used == version_row$pluto_source_id_used,
      pluto_version_used == version_row$pluto_version_used,
      valid_bbl
    ) |>
    distinct(bbl)

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
      bldgarea,
      resarea,
      comarea,
      unitsres,
      unitstotal,
      numbldgs,
      numfloors,
      yearbuilt,
      builtfar,
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
      bldgarea = NA_real_,
      resarea = NA_real_,
      comarea = NA_real_,
      unitsres = NA_real_,
      unitstotal = NA_real_,
      numbldgs = NA_integer_,
      numfloors = NA_real_,
      yearbuilt = NA_integer_,
      builtfar = NA_real_,
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

candidate_panel <- candidate_panel |>
  left_join(
    matched_features,
    by = c("bbl", "pluto_source_id_used", "pluto_version_used"),
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

for (feature_name in numeric_feature_columns) {
  candidate_panel[[paste0("missing_", feature_name)]] <- is.na(candidate_panel[[feature_name]])
}

candidate_panel <- candidate_panel |>
  select(
    job_number, date_filed, filing_year, bbl, bin, address, house_number, street_name,
    hdb_borough_code, hdb_borough_name, hdb_community_district, hdb_council_district,
    classa_prop, classa_prop_integer, y100,
    pluto_source_id_latest_pre_filing, pluto_version_latest_pre_filing,
    pluto_release_order_latest_pre_filing, pluto_safe_available_date_latest_pre_filing,
    pluto_source_id_used, pluto_version_used,
    pluto_release_order_used, pluto_safe_available_date_used,
    pluto_timing_status, true_lagged_pluto_available, backfill_used,
    post_filing_pluto, pluto_days_relative_to_filing,
    selected_pluto_parquet_path, selected_pluto_raw_status, pluto_match_status,
    valid_bbl, primary_sample, primary_leakage_safe_sample, expanded_backfill_sample, exclusion_reason,
    all_of(feature_columns),
    allowed_res_area, residual_res_area,
    is_vacant_landuse, is_vacant_bldgclass, is_vacant_lot,
    starts_with("missing_")
  )

write_parquet_if_changed(candidate_panel, "../output/hdb_mappluto_training_panel.parquet")
cat("Wrote HDB-MapPLUTO training panel to ../output/hdb_mappluto_training_panel.parquet\n")

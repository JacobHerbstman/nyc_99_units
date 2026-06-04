# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_mappluto_lot_staging/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))

required_columns <- c("source_id", "vintage", "parquet_path")
missing_columns <- setdiff(required_columns, names(mappluto_lot_files))

if (length(missing_columns) > 0) {
  stop("MapPLUTO lot index is missing required columns: ", paste(missing_columns, collapse = ", "))
}

jia_codes <- c(164L, 226L, 227L, 228L, 355L, 356L, 480L, 481L, 482L, 483L, 484L, 595L)
current_year <- as.integer(format(Sys.Date(), "%Y"))

field_nonmissing_share <- function(data, field) {
  if (!field %in% names(data)) {
    return(NA_real_)
  }

  mean(!is.na(data[[field]]))
}

safe_min_int <- function(x) {
  x <- suppressWarnings(as.integer(x))
  if (all(is.na(x))) {
    return(NA_integer_)
  }

  min(x, na.rm = TRUE)
}

safe_max_int <- function(x) {
  x <- suppressWarnings(as.integer(x))
  if (all(is.na(x))) {
    return(NA_integer_)
  }

  max(x, na.rm = TRUE)
}

if (nrow(mappluto_lot_files) == 0) {
  write_csv(tibble(), "../output/mappluto_lot_staging_qc.csv", na = "")
  quit(save = "no")
}

qc_rows <- list()
borough_count_rows <- list()
zip_selection_rows <- list()

for (i in seq_len(nrow(mappluto_lot_files))) {
  row <- mappluto_lot_files[i, ]
  parquet_path <- file.path("..", "..", "..", "stage_mappluto_lots", "output", basename(as.character(row$parquet_path)))
  raw_path_manifest <- if ("raw_path" %in% names(mappluto_lot_files)) as.character(row$raw_path) else NA_character_
  raw_path <- if_else(
    !is.na(raw_path_manifest),
    file.path("..", "..", "..", "stage_mappluto_lots", "code", raw_path_manifest),
    NA_character_
  )

  if (!is.na(raw_path) && file.exists(raw_path) && str_detect(tolower(raw_path), "[.]zip$")) {
    zip_listing <- suppressWarnings(system2("unzip", c("-Z1", raw_path), stdout = TRUE, stderr = FALSE))
    zip_status <- attr(zip_listing, "status")
    if (is.null(zip_status)) {
      zip_status <- 0L
    }

    candidate_table_entries <- zip_listing[str_detect(tolower(zip_listing), "[.](csv|txt)$")]
    selected_table_entries <- candidate_table_entries[
      !str_detect(tolower(basename(candidate_table_entries)), "change|dictionary|readme|layout|lay|dates")
    ]

    zip_selection_rows[[i]] <- tibble(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      raw_path = raw_path_manifest,
      raw_path_resolved = raw_path,
      zip_status = if_else(identical(zip_status, 0L), "listed", "listing_failed"),
      all_entries_n = length(zip_listing),
      candidate_table_entries_n = length(candidate_table_entries),
      selected_table_entries_n = length(selected_table_entries),
      excluded_table_entries_n = length(candidate_table_entries) - length(selected_table_entries),
      dbf_entries_n = sum(str_detect(tolower(zip_listing), "[.]dbf$")),
      gpkg_entries_n = sum(str_detect(tolower(zip_listing), "[.]gpkg$")),
      duplicate_selected_basenames = anyDuplicated(basename(selected_table_entries)) > 0,
      selected_table_entries = paste(selected_table_entries, collapse = "|")
    )
  } else {
    zip_selection_rows[[i]] <- tibble(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      raw_path = raw_path_manifest,
      raw_path_resolved = raw_path,
      zip_status = "not_available",
      all_entries_n = NA_integer_,
      candidate_table_entries_n = NA_integer_,
      selected_table_entries_n = NA_integer_,
      excluded_table_entries_n = NA_integer_,
      dbf_entries_n = NA_integer_,
      gpkg_entries_n = NA_integer_,
      duplicate_selected_basenames = NA,
      selected_table_entries = NA_character_
    )
  }

  if (!file.exists(parquet_path)) {
    qc_rows[[i]] <- tibble(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      parquet_path = parquet_path,
      status = "missing_parquet",
      row_count = NA_integer_,
      nonmissing_bbl_share = NA_real_,
      missing_bbl_count = NA_integer_,
      unique_bbl_count = NA_integer_,
      duplicate_bbl_count = NA_integer_,
      invalid_bbl_count = NA_integer_,
      nonmissing_lotarea_share = NA_real_,
      zero_or_negative_lotarea_count = NA_integer_,
      nonmissing_zonedist1_share = NA_real_,
      nonmissing_residfar_share = NA_real_,
      nonmissing_builtfar_share = NA_real_,
      nonmissing_unitsres_share = NA_real_,
      nonmissing_landuse_share = NA_real_,
      nonmissing_bldgclass_share = NA_real_,
      nonmissing_assessland_share = NA_real_,
      nonmissing_assesstot_share = NA_real_,
      nonmissing_yearbuilt_share = NA_real_,
      nonmissing_cd_share = NA_real_,
      min_yearbuilt = NA_integer_,
      max_yearbuilt = NA_integer_,
      future_yearbuilt_count = NA_integer_,
      ordinary_cd_rows = NA_integer_,
      joint_interest_area_rows = NA_integer_
    )

    borough_count_rows[[i]] <- tibble(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      bbl_borough = NA_character_,
      row_count = NA_integer_,
      unique_bbl_count = NA_integer_
    )

    next
  }

  lot_table <- read_parquet(parquet_path) |>
    as.data.frame() |>
    as_tibble()

  bbl_values <- if ("bbl" %in% names(lot_table)) lot_table$bbl[!is.na(lot_table$bbl)] else character()
  valid_bbl_values <- str_detect(as.character(bbl_values), "^[1-5][0-9]{9}$")
  lotarea_values <- if ("lotarea" %in% names(lot_table)) suppressWarnings(as.numeric(lot_table$lotarea)) else numeric()
  yearbuilt_values <- if ("yearbuilt" %in% names(lot_table)) suppressWarnings(as.integer(lot_table$yearbuilt)) else integer()
  cd_values <- if ("cd" %in% names(lot_table)) suppressWarnings(as.integer(lot_table$cd)) else integer()

  borough_count_rows[[i]] <- lot_table |>
    mutate(bbl_borough = if ("bbl" %in% names(lot_table)) substr(as.character(bbl), 1, 1) else NA_character_) |>
    count(bbl_borough, name = "row_count") |>
    left_join(
      lot_table |>
        mutate(bbl_borough = if ("bbl" %in% names(lot_table)) substr(as.character(bbl), 1, 1) else NA_character_) |>
        filter(!is.na(bbl)) |>
        distinct(bbl_borough, bbl) |>
        count(bbl_borough, name = "unique_bbl_count"),
      by = "bbl_borough",
      relationship = "one-to-one"
    ) |>
    mutate(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      unique_bbl_count = if_else(is.na(unique_bbl_count), 0L, unique_bbl_count)
    ) |>
    select(source_id, vintage, bbl_borough, row_count, unique_bbl_count)

  qc_rows[[i]] <- tibble(
    source_id = as.character(row$source_id),
    vintage = as.character(row$vintage),
    parquet_path = parquet_path,
    status = "summarized",
    row_count = nrow(lot_table),
    nonmissing_bbl_share = field_nonmissing_share(lot_table, "bbl"),
    missing_bbl_count = if ("bbl" %in% names(lot_table)) sum(is.na(lot_table$bbl)) else NA_integer_,
    unique_bbl_count = length(unique(bbl_values)),
    duplicate_bbl_count = sum(duplicated(bbl_values)),
    invalid_bbl_count = sum(!valid_bbl_values),
    nonmissing_lotarea_share = field_nonmissing_share(lot_table, "lotarea"),
    zero_or_negative_lotarea_count = sum(!is.na(lotarea_values) & lotarea_values <= 0),
    nonmissing_zonedist1_share = field_nonmissing_share(lot_table, "zonedist1"),
    nonmissing_residfar_share = field_nonmissing_share(lot_table, "residfar"),
    nonmissing_builtfar_share = field_nonmissing_share(lot_table, "builtfar"),
    nonmissing_unitsres_share = field_nonmissing_share(lot_table, "unitsres"),
    nonmissing_landuse_share = field_nonmissing_share(lot_table, "landuse"),
    nonmissing_bldgclass_share = field_nonmissing_share(lot_table, "bldgclass"),
    nonmissing_assessland_share = field_nonmissing_share(lot_table, "assessland"),
    nonmissing_assesstot_share = field_nonmissing_share(lot_table, "assesstot"),
    nonmissing_yearbuilt_share = field_nonmissing_share(lot_table, "yearbuilt"),
    nonmissing_cd_share = field_nonmissing_share(lot_table, "cd"),
    min_yearbuilt = safe_min_int(yearbuilt_values),
    max_yearbuilt = safe_max_int(yearbuilt_values),
    future_yearbuilt_count = sum(yearbuilt_values > current_year, na.rm = TRUE),
    ordinary_cd_rows = sum(!is.na(cd_values) & !(cd_values %in% jia_codes)),
    joint_interest_area_rows = sum(!is.na(cd_values) & cd_values %in% jia_codes)
  )
}

write_csv(bind_rows(qc_rows), "../output/mappluto_lot_staging_qc.csv", na = "")
write_csv(bind_rows(borough_count_rows), "../output/mappluto_lot_staging_borough_counts.csv", na = "")
write_csv(bind_rows(zip_selection_rows), "../output/mappluto_lot_staging_zip_selection.csv", na = "")
cat("Wrote MapPLUTO lot staging QC to ../output/mappluto_lot_staging_qc.csv\n")

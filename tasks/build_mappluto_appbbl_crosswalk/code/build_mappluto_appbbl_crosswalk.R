# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_mappluto_appbbl_crosswalk/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(foreign)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

parse_bbl_borough <- function(x) {
  substr(as.character(x), 1L, 1L)
}

parse_bbl_block <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 2L, 6L)))
}

parse_bbl_lot <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 7L, 10L)))
}

normalize_text_field <- function(x) {
  out <- trimws(as.character(x))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  out
}

normalize_integer_field <- function(x) {
  suppressWarnings(as.integer(normalize_text_field(x)))
}

paste_unique <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & as.character(x) != ""])))
  if (length(x) == 0) {
    return(NA_character_)
  }
  paste(x, collapse = ";")
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

read_raw_appbbl_keys <- function(raw_path) {
  read_path <- raw_path
  read_mode <- if (str_detect(tolower(raw_path), "\\.dbf$")) "dbf" else "delimited"
  temp_dir <- NULL

  if (str_detect(tolower(raw_path), "\\.zip$")) {
    temp_dir <- tempfile(pattern = "appbbl_keys_")
    dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
    zip_listing <- suppressWarnings(system2("unzip", c("-Z1", raw_path), stdout = TRUE, stderr = FALSE))
    table_entries <- zip_listing[str_detect(tolower(zip_listing), "\\.(csv|txt)$")]
    table_entries <- table_entries[!str_detect(tolower(basename(table_entries)), "change|dictionary|readme|layout|lay|dates")]
    dbf_entry <- zip_listing[str_detect(tolower(zip_listing), "\\.dbf$")][1]

    if (length(table_entries) > 0) {
      unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, table_entries, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
      if (!identical(unzip_status, 0L)) {
        stop("System unzip failed for PLUTO table files in ", raw_path)
      }
      read_path <- file.path(temp_dir, basename(table_entries))
      read_mode <- "delimited"
    } else if (!is.na(dbf_entry) && nzchar(dbf_entry)) {
      unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, dbf_entry, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
      if (!identical(unzip_status, 0L)) {
        stop("System unzip failed for DBF in ", raw_path)
      }
      read_path <- file.path(temp_dir, basename(dbf_entry))
      read_mode <- "dbf"
    } else {
      stop("No .csv, .txt, or .dbf found in ", raw_path)
    }
  }

  raw_table <- if (read_mode == "dbf") {
    read.dbf(read_path, as.is = TRUE) |>
      as_tibble()
  } else {
    bind_rows(lapply(read_path, function(path) {
      read_csv(
        path,
        show_col_types = FALSE,
        col_types = cols(.default = col_character()),
        lazy = FALSE
      )
    }))
  }

  names(raw_table) <- normalize_names(names(raw_table))

  out <- tibble(
    current_bbl = pick_first_existing(raw_table, c("bbl")),
    borough = pick_first_existing(raw_table, c("borough", "boro_code", "borocode")),
    block = pick_first_existing(raw_table, c("block")),
    lot = pick_first_existing(raw_table, c("lot")),
    condono = pick_first_existing(raw_table, c("condono", "condo_no")),
    appbbl = pick_first_existing(raw_table, c("appbbl", "app_bbl")),
    appdate = pick_first_existing(raw_table, c("appdate")),
    plutomapid = pick_first_existing(raw_table, c("plutomapid", "pluto_map_id"))
  )

  missing_bbl <- is.na(out$current_bbl) | out$current_bbl == ""
  out$current_bbl[missing_bbl] <- build_bbl(out$borough, out$block, out$lot)[missing_bbl]
  out
}

mappluto_files <- read_csv("../input/mappluto_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    raw_path = as.character(raw_path),
    file_role = as.character(file_role)
  ) |>
  filter(
    source_id == "dcp_pluto_current",
    file_role == "pluto_csv_zip",
    !is.na(raw_path)
  )

if (nrow(mappluto_files) == 0) {
  stop("No current PLUTO CSV source is available in ../input/mappluto_files.csv.")
}

appbbl_rows <- list()

for (i in seq_len(nrow(mappluto_files))) {
  raw_path <- file.path("..", "..", "fetch_mappluto_archive", "code", mappluto_files$raw_path[i])

  if (!file.exists(raw_path)) {
    stop("Missing raw PLUTO path: ", raw_path)
  }

  appbbl_rows[[length(appbbl_rows) + 1L]] <- read_raw_appbbl_keys(raw_path) |>
    mutate(
      source_id = mappluto_files$source_id[i],
      vintage = mappluto_files$vintage[i],
      current_bbl = normalize_bbl_field(current_bbl),
      appbbl = normalize_bbl_field(appbbl),
      condono = normalize_integer_field(condono),
      appdate = parse_mixed_date(appdate),
      plutomapid = normalize_integer_field(plutomapid),
      current_borough = parse_bbl_borough(current_bbl),
      current_block = parse_bbl_block(current_bbl),
      current_lot = parse_bbl_lot(current_bbl),
      appbbl_borough = parse_bbl_borough(appbbl),
      appbbl_block = parse_bbl_block(appbbl),
      appbbl_lot = parse_bbl_lot(appbbl)
    )
}

mappluto_appbbl_crosswalk <- bind_rows(appbbl_rows) |>
  filter(
    !is.na(current_bbl),
    !is.na(appbbl),
    current_bbl != appbbl
  ) |>
  group_by(source_id, vintage, current_bbl, appbbl) |>
  summarise(
    evidence_rows = n(),
    condono_values = paste_unique(condono),
    plutomapid_values = paste_unique(plutomapid),
    appdate_min = min_date_value(appdate),
    appdate_max = max_date_value(appdate),
    current_borough = first(current_borough),
    current_block = first(current_block),
    current_lot = first(current_lot),
    appbbl_borough = first(appbbl_borough),
    appbbl_block = first(appbbl_block),
    appbbl_lot = first(appbbl_lot),
    same_boro_block = first(current_borough) == first(appbbl_borough) & first(current_block) == first(appbbl_block),
    .groups = "drop"
  ) |>
  arrange(current_bbl, appbbl, source_id, vintage)

duplicate_crosswalk_keys <- mappluto_appbbl_crosswalk |>
  count(source_id, vintage, current_bbl, appbbl, name = "rows") |>
  filter(rows > 1)

if (nrow(duplicate_crosswalk_keys) > 0) {
  stop("APPBBL crosswalk is not unique by source/vintage/current_bbl/appbbl.")
}

write_csv_if_changed(mappluto_appbbl_crosswalk, "../output/mappluto_appbbl_crosswalk.csv")
cat("Wrote MapPLUTO APPBBL crosswalk to ../output/mappluto_appbbl_crosswalk.csv\n")

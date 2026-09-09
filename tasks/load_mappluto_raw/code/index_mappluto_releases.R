# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/load_mappluto_raw/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(foreign)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")

mappluto_files <- read_csv("../input/mappluto_files.csv", show_col_types = FALSE, na = c("", "NA"))

extract_pluto_release_from_path <- function(path) {
  release <- str_match(
    tolower(basename(path)),
    "^nyc_(?:mappluto|pluto)_([0-9]{2}v[0-9]+(?:_[0-9]+)?|[0-9]{2}[a-z])(?:_arc)?(?:_shp|_csv)?[.]zip$"
  )[, 2]

  str_replace_all(release, "_", ".")
}

mappluto_vintage_matches_file <- function(vintage, file_release) {
  vintage_clean <- str_replace_all(tolower(as.character(vintage)), "_", ".")
  file_clean <- str_replace_all(tolower(as.character(file_release)), "_", ".")

  !is.na(file_clean) & nzchar(file_clean) &
    (vintage_clean == file_clean | startsWith(vintage_clean, file_clean))
}

zip_has_valid_listing <- function(path) {
  if (!str_detect(tolower(path), "[.]zip$")) {
    return(TRUE)
  }

  listing <- suppressWarnings(system2("unzip", c("-Z1", path), stdout = TRUE, stderr = FALSE))
  status <- attr(listing, "status")

  if (is.null(status)) {
    status <- 0L
  }

  identical(status, 0L) && length(listing) > 0
}

available_rows <- mappluto_files |>
  filter(
    (source_id == "dcp_mappluto_archive" & file_role == "mappluto_shapefile_zip") |
      (source_id == "dcp_pluto_archive" & file_role == "pluto_csv_zip")
  ) |>
  mutate(
    raw_path = as.character(raw_path),
    vintage = as.character(vintage),
    fetch_status = as.character(status),
    raw_file_release = extract_pluto_release_from_path(raw_path),
    raw_zip_valid = vapply(file.path("../input", basename(raw_path)), zip_has_valid_listing, logical(1)),
    status = case_when(
      !fetch_status %in% c("downloaded", "already_present", "redownloaded_after_validation_failure") ~ "upstream_fetch_not_valid",
      !raw_zip_valid ~ "raw_zip_validation_failed",
      is.na(raw_file_release) ~ "release_not_detected_from_filename",
      !mappluto_vintage_matches_file(vintage, raw_file_release) ~ "vintage_file_mismatch",
      TRUE ~ "loadable"
    )
  )

stopifnot(nrow(available_rows) > 0L, all(available_rows$raw_zip_valid))
file_index <- available_rows |>
  mutate(raw_parquet_path = if_else(status == "loadable",
    paste0("../../load_mappluto_raw/output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), "_raw.parquet"), NA_character_),
    status = if_else(status == "loadable", "loaded", status)) |>
  arrange(status == "loaded") |>
  select(source_id, vintage, raw_path, raw_parquet_path, file_role, raw_file_release, fetch_status, raw_zip_valid, status)
write_csv_atomic(file_index, "../output/mappluto_raw_files.csv")

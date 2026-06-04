# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/define_mappluto_release_calendar/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

calendar <- read_csv("mappluto_release_calendar_manual.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    release_order = suppressWarnings(as.integer(release_order)),
    safe_available_date = as.Date(safe_available_date),
    usable_for_training = str_to_upper(as.character(usable_for_training)) == "TRUE",
    evidence_url = as.character(evidence_url),
    date_basis = as.character(date_basis),
    notes = as.character(notes)
  )

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))

required_calendar_columns <- c(
  "source_id", "vintage", "release_order", "safe_available_date", "usable_for_training",
  "evidence_url", "date_basis", "notes"
)
missing_calendar_columns <- setdiff(required_calendar_columns, names(calendar))

if (length(missing_calendar_columns) > 0) {
  stop("Release calendar is missing columns: ", paste(missing_calendar_columns, collapse = ", "))
}

missing_mappluto_columns <- setdiff(c("source_id", "vintage"), names(mappluto_lot_files))

if (length(missing_mappluto_columns) > 0) {
  stop("MapPLUTO lot manifest is missing columns: ", paste(missing_mappluto_columns, collapse = ", "))
}

if (any(is.na(calendar$source_id)) || any(is.na(calendar$vintage))) {
  stop("Release calendar has missing source_id or vintage.")
}

if (anyDuplicated(paste(calendar$source_id, calendar$vintage, sep = "::")) > 0) {
  stop("Release calendar source_id/vintage pairs must be unique.")
}

if (any(is.na(calendar$release_order)) || anyDuplicated(calendar$release_order) > 0) {
  stop("Release calendar release_order values must be nonmissing and unique.")
}

if (any(calendar$usable_for_training & is.na(calendar$safe_available_date))) {
  stop("Usable release calendar rows must have safe_available_date.")
}

if (any(calendar$usable_for_training & (is.na(calendar$evidence_url) | calendar$evidence_url == ""))) {
  stop("Usable release calendar rows must have evidence_url.")
}

usable_calendar <- calendar |>
  filter(usable_for_training) |>
  arrange(release_order)

if (any(diff(usable_calendar$safe_available_date) < 0)) {
  stop("Usable release safe_available_date values must be monotone in release_order.")
}

staged_training_vintages <- mappluto_lot_files |>
  filter(
    (source_id == "dcp_pluto_archive" & str_detect(as.character(vintage), "^((09|10|11|12|13|14|15|16|17)v|18v1)$")) |
      (source_id == "dcp_mappluto_archive" & str_detect(as.character(vintage), "^(18|19|20|21|22|23)v")),
    if ("raw_status" %in% names(mappluto_lot_files)) raw_status == "loaded" else TRUE
  ) |>
  distinct(source_id = as.character(source_id), vintage = as.character(vintage))

calendar_keys <- paste(calendar$source_id, calendar$vintage, sep = "::")
staged_keys <- paste(staged_training_vintages$source_id, staged_training_vintages$vintage, sep = "::")
missing_from_calendar <- setdiff(staged_keys, calendar_keys)

if (length(missing_from_calendar) > 0) {
  stop("Staged PLUTO/MapPLUTO training vintages missing from calendar: ", paste(missing_from_calendar, collapse = ", "))
}

calendar <- calendar |>
  arrange(release_order) |>
  select(
    source_id, vintage, release_order, safe_available_date, usable_for_training,
    evidence_url, date_basis, notes
  )

write_csv_if_changed(calendar, "../output/mappluto_release_calendar.csv")
cat("Wrote MapPLUTO release calendar to ../output/mappluto_release_calendar.csv\n")

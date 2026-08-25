# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_hpd_485x_registrations/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

page_limit <- 50000L

source_catalog <- read_csv(
  "../input/source_catalog.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

source_row <- source_catalog |>
  filter(source_id == "hpd_485x_registrations")

if (nrow(source_row) != 1L || source_row$access_mode != "public_script") {
  stop("Expected one public hpd_485x_registrations row in the source catalog.")
}

pull_date <- resolve_raw_pull_date(list(
  hpd_485x_registrations = c(
    "hpd_485x_registrations.csv",
    "hpd_485x_registrations_metadata.json"
  )
))

registration_url <- paste0(
  "https://data.cityofnewyork.us/resource/rrtd-iyd7.csv",
  "?$order=no&$limit=", page_limit
)
metadata_url <- "https://data.cityofnewyork.us/api/views/rrtd-iyd7"

registration_path <- file.path(
  "../../../data_raw/hpd_485x_registrations",
  pull_date,
  "hpd_485x_registrations.csv"
)
metadata_path <- file.path(
  "../../../data_raw/hpd_485x_registrations",
  pull_date,
  "hpd_485x_registrations_metadata.json"
)

registration_status <- if (file.exists(registration_path)) {
  "already_present"
} else {
  download_with_status(registration_url, registration_path)
}

metadata_status <- if (file.exists(metadata_path)) {
  "already_present"
} else {
  download_with_status(metadata_url, metadata_path)
}

if (registration_status == "download_failed" || metadata_status == "download_failed") {
  stop("HPD 485-x registration download failed.")
}

registrations <- read_csv(
  registration_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

required_columns <- c(
  "no", "form_submission_date", "reported_property_address",
  "reported_property_borough", "reported_dob_bin",
  "reported_dob_permit_sequence", "reported_property_tax_block",
  "reported_property_tax_lot", "reported_units",
  "reported_restricted_units", "reported_commencement_date",
  "reported_anticipated", "reported_affordability_option",
  "presumed_community_board", "presumed_duplicate", "duplicate_count",
  "presumed_building_units", "presumed_restricted_units", "presumed_bbl",
  "postcode", "latitude", "longitude", "council_district", "ct2020",
  "nta2020"
)

if (!all(required_columns %in% names(registrations))) {
  stop("HPD 485-x registration schema is missing expected columns.")
}

if (nrow(registrations) == 0L || nrow(registrations) >= page_limit) {
  stop("HPD 485-x registration extract is empty or reached the page limit.")
}

if (anyDuplicated(registrations$no)) {
  stop("HPD 485-x registration response number is not unique.")
}

metadata <- fromJSON(metadata_path, simplifyVector = TRUE)

if (!identical(metadata$id, "rrtd-iyd7")) {
  stop("Downloaded metadata does not describe the HPD 485-x dataset.")
}

source_updated_at <- format(
  as.POSIXct(metadata$rowsUpdatedAt, origin = "1970-01-01", tz = "UTC"),
  "%Y-%m-%d %H:%M:%S UTC"
)

file_manifest <- bind_rows(
  tibble(
    source_id = source_row$source_id,
    pull_date = pull_date,
    file_role = "building_registration_submissions",
    row_count = nrow(registrations),
    source_updated_at = source_updated_at,
    latest_form_submission_date = max(registrations$form_submission_date),
    raw_path = registration_path,
    sha256 = compute_sha256(registration_path),
    status = registration_status,
    source_url = registration_url
  ),
  tibble(
    source_id = source_row$source_id,
    pull_date = pull_date,
    file_role = "socrata_metadata",
    row_count = NA_integer_,
    source_updated_at = source_updated_at,
    latest_form_submission_date = NA_character_,
    raw_path = metadata_path,
    sha256 = compute_sha256(metadata_path),
    status = metadata_status,
    source_url = metadata_url
  )
)

write_csv_if_changed(
  file_manifest,
  "../output/hpd_485x_registration_files.csv"
)

cat("Wrote HPD 485-x registration fetch manifest to ../output\n")

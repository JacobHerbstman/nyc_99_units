# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dob_now_new_building_filings/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

page_limit <- 50000L
initial_raw_filename <- "dob_now_new_building_initial_filings_2016_2026.csv"
amendment_raw_filename <- "dob_now_new_building_amendments_2024_2026.csv"

source_catalog <- read_csv(
  "../input/source_catalog.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

source_row <- source_catalog |>
  filter(source_id == "dob_now_build_job_filings")

if (nrow(source_row) != 1L) {
  stop("Expected one dob_now_build_job_filings row in the source catalog.")
}

pull_date <- resolve_raw_pull_date(list(
  dob_now_build_job_filings = c(initial_raw_filename, amendment_raw_filename)
))

initial_raw_path <- file.path(
  "../../../data_raw/dob_now_build_job_filings",
  pull_date,
  initial_raw_filename
)

amendment_raw_path <- file.path(
  "../../../data_raw/dob_now_build_job_filings",
  pull_date,
  amendment_raw_filename
)

selected_fields <- paste(
  c(
    "job_filing_number", "filing_status", "house_no", "street_name",
    "borough", "block", "lot", "bin", "commmunity_board",
    "applicant_professional_title", "applicant_license",
    "applicant_first_name", "applicants_middle_initial", "applicant_last_name",
    "applicant_business_name", "owner_s_business_name", "owner_first_name",
    "owner_last_name", "owner_type", "initial_cost",
    "total_construction_floor_area", "building_type", "existing_stories",
    "existing_height", "existing_dwelling_units", "proposed_no_of_stories",
    "proposed_height", "proposed_dwelling_units", "filing_date",
    "current_status_date", "first_permit_date", "approved_date", "signoff_date",
    "job_type", "latitude", "longitude", "postcode", "council_district",
    "census_tract", "bbl", "nta", "job_description", "filing_review_type"
  ),
  collapse = ","
)

initial_where_clause <- paste(
  "job_type='New Building'",
  "and job_filing_number like '%-I1'",
  "and filing_date >= '2016-01-01T00:00:00.000'",
  "and filing_date < '2027-01-01T00:00:00.000'"
)

amendment_where_clause <- paste(
  "job_type='New Building'",
  "and job_filing_number not like '%-I1'",
  "and filing_date >= '2024-01-01T00:00:00.000'",
  "and filing_date < '2027-01-01T00:00:00.000'"
)

initial_query_url <- paste0(
  "https://data.cityofnewyork.us/resource/w9ak-ipjd.csv",
  "?$select=", URLencode(selected_fields, reserved = TRUE),
  "&$where=", URLencode(initial_where_clause, reserved = TRUE),
  "&$order=", URLencode("filing_date,job_filing_number", reserved = TRUE),
  "&$limit=", page_limit
)

amendment_query_url <- paste0(
  "https://data.cityofnewyork.us/resource/w9ak-ipjd.csv",
  "?$select=", URLencode(selected_fields, reserved = TRUE),
  "&$where=", URLencode(amendment_where_clause, reserved = TRUE),
  "&$order=", URLencode("filing_date,job_filing_number", reserved = TRUE),
  "&$limit=", page_limit
)

initial_download_status <- if (file.exists(initial_raw_path)) {
  "already_present"
} else {
  download_with_status(initial_query_url, initial_raw_path)
}

if (initial_download_status == "download_failed") {
  stop("DOB NOW initial New Building filing extract failed to download.")
}

amendment_download_status <- if (file.exists(amendment_raw_path)) {
  "already_present"
} else {
  download_with_status(amendment_query_url, amendment_raw_path)
}

if (amendment_download_status == "download_failed") {
  stop("DOB NOW New Building amendment extract failed to download.")
}

initial_rows <- read_csv(
  initial_raw_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

amendment_rows <- read_csv(
  amendment_raw_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

if (nrow(initial_rows) == 0L || nrow(amendment_rows) == 0L) {
  stop("DOB NOW initial New Building filing extract contains no rows.")
}

if (nrow(initial_rows) >= page_limit || nrow(amendment_rows) >= page_limit) {
  stop("DOB NOW extract reached the page limit and may be truncated.")
}

if (any(!str_detect(initial_rows$job_filing_number, "-I1$"), na.rm = TRUE)) {
  stop("DOB NOW initial extract contains a non-initial filing number.")
}

if (any(str_detect(amendment_rows$job_filing_number, "-I1$"), na.rm = TRUE)) {
  stop("DOB NOW amendment extract contains an initial filing number.")
}

file_manifest <- bind_rows(
  tibble(
    source_id = source_row$source_id,
    pull_date = pull_date,
    file_role = "initial_new_building_filings_2016_2026",
    row_count = nrow(initial_rows),
    raw_path = initial_raw_path,
    status = initial_download_status,
    query_url = initial_query_url
  ),
  tibble(
  source_id = source_row$source_id,
  pull_date = pull_date,
    file_role = "new_building_amendments_2024_2026",
    row_count = nrow(amendment_rows),
    raw_path = amendment_raw_path,
    status = amendment_download_status,
    query_url = amendment_query_url
  )
)

write_csv_if_changed(
  file_manifest,
  "../output/dob_now_new_building_filing_files.csv"
)

cat("Wrote DOB NOW New Building filing-history fetch manifest to ../output\n")

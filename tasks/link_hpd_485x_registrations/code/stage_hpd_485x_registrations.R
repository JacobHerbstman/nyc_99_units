# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/link_hpd_485x_registrations/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# August 20, 2026 snapshot published by fetch_hpd_485x_registrations.
registrations <- read_csv(
  "../input/hpd_485x_registrations.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character()),
  na = c("", "NA")
)

stopifnot(nrow(registrations) == 312L)

staged_registrations <- registrations |>
  transmute(
    source_id = "hpd_485x_registrations",
    source_pull_date = 20260820,
    response_number = suppressWarnings(as.integer(no)),
    form_submission_timestamp = ymd_hms(form_submission_date, tz = "America/New_York"),
    reported_property_address = str_squish(reported_property_address),
    reported_borough_code = standardize_borough_code(reported_property_borough),
    reported_borough_name = standardize_borough_name(reported_property_borough),
    dob_bin = str_squish(reported_dob_bin),
    reported_dob_permit_sequence = str_to_upper(str_squish(reported_dob_permit_sequence)),
    dob_now_root_job_id = str_extract(reported_dob_permit_sequence, "[BMQX][0-9]{8}"),
    dob_bis_job_number = str_extract(reported_dob_permit_sequence, "[1-5][0-9]{8}"),
    reported_block = suppressWarnings(as.integer(reported_property_tax_block)),
    reported_lot = suppressWarnings(as.integer(reported_property_tax_lot)),
    reported_bbl = build_bbl(
      reported_property_borough,
      reported_property_tax_block,
      reported_property_tax_lot
    ),
    reported_units = suppressWarnings(as.integer(reported_units)),
    reported_restricted_units = suppressWarnings(as.integer(reported_restricted_units)),
    reported_commencement_date = suppressWarnings(as.Date(str_sub(reported_commencement_date, 1L, 10L))),
    reported_anticipated_completion_date = suppressWarnings(as.Date(str_sub(reported_anticipated, 1L, 10L))),
    reported_affordability_option = str_to_upper(str_squish(reported_affordability_option)),
    presumed_community_board = suppressWarnings(as.integer(presumed_community_board)),
    source_presumed_duplicate = str_squish(presumed_duplicate),
    source_duplicate_count = suppressWarnings(as.integer(duplicate_count)),
    presumed_building_units = suppressWarnings(as.integer(presumed_building_units)),
    presumed_restricted_units = suppressWarnings(as.integer(presumed_restricted_units)),
    presumed_bbl = normalize_bbl_field(presumed_bbl),
    postcode = str_squish(postcode),
    latitude = suppressWarnings(as.numeric(latitude)),
    longitude = suppressWarnings(as.numeric(longitude)),
    council_district = standardize_council_district(council_district),
    census_tract_2020 = suppressWarnings(as.numeric(ct2020)),
    nta_2020 = str_squish(nta2020)
  ) |>
  mutate(
    dob_identifier_type = case_when(
      !is.na(dob_now_root_job_id) ~ "dob_now_root_job",
      !is.na(dob_bis_job_number) ~ "dob_bis_job",
      TRUE ~ "unparsed"
    )
  ) |>
  arrange(response_number)

if (anyDuplicated(staged_registrations$response_number)) {
  stop("Staged HPD response_number is not unique.")
}

if (any(is.na(staged_registrations$response_number))) {
  stop("Staged HPD response_number is missing.")
}

if (any(!str_detect(staged_registrations$dob_bin, "^[1-5][0-9]{6}$"))) {
  stop("Staged HPD DOB BIN is missing or malformed.")
}

SaveData(staged_registrations, NULL, "../output/hpd_485x_registrations.parquet")

cat("Wrote staged HPD 485-x registration responses to ../output\n")

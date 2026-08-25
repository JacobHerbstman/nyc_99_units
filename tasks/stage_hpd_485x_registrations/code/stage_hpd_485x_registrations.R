# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_hpd_485x_registrations/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv(
  "../input/hpd_485x_registration_files.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

registration_file <- file_manifest |>
  filter(file_role == "building_registration_submissions")

if (nrow(registration_file) != 1L || !file.exists(registration_file$raw_path)) {
  stop("Expected one available HPD 485-x registration extract.")
}

if (compute_sha256(registration_file$raw_path) != registration_file$sha256) {
  stop("HPD 485-x registration file does not match the fetch manifest checksum.")
}

registrations <- read_csv(
  registration_file$raw_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character()),
  na = c("", "NA")
)

if (nrow(registrations) != registration_file$row_count) {
  stop("HPD 485-x registration row count does not match the fetch manifest.")
}

staged_registrations <- registrations |>
  transmute(
    source_id = registration_file$source_id,
    source_pull_date = registration_file$pull_date,
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

write_parquet_if_changed(
  staged_registrations,
  "../output/hpd_485x_registrations.parquet"
)

cat("Wrote staged HPD 485-x registration responses to ../output\n")

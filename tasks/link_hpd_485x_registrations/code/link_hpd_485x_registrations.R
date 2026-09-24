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

# HPD's 485-x prospective applicant registrations (August 20, 2026 snapshot),
# each a self-reported building registration, linked to DOB NOW initial
# filings.
registrations <- read_csv("../input/hpd_485x_registrations.csv", col_types = cols(.default = col_character())) |>
  transmute(response_number = as.integer(no),
    form_submission_timestamp = ymd_hms(form_submission_date, tz = "America/New_York"),
    reported_property_address = str_squish(reported_property_address),
    reported_borough_name = standardize_borough_name(reported_property_borough),
    dob_bin = str_squish(reported_dob_bin),
    dob_now_root_job_id = str_extract(str_to_upper(reported_dob_permit_sequence), "[BMQX][0-9]{8}"),
    dob_bis_job_number = str_extract(str_to_upper(reported_dob_permit_sequence), "[1-5][0-9]{8}"),
    reported_bbl = build_bbl(reported_property_borough, reported_property_tax_block, reported_property_tax_lot),
    reported_units = as.integer(reported_units),
    reported_affordability_option = str_to_upper(str_squish(reported_affordability_option)))
stopifnot(nrow(registrations) == 312L, !anyNA(registrations$response_number),
  !anyDuplicated(registrations$response_number), all(str_detect(registrations$dob_bin, "^[1-5][0-9]{6}$")))

dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(job_number = str_squish(job_number), bin = str_squish(bin))
stopifnot(!anyDuplicated(dob$job_number))
jobs_per_bin <- dob |>
  filter(coalesce(bin, "") != "") |>
  group_by(bin) |>
  summarise(bin_jobs = n_distinct(job_number), bin_job = if_else(bin_jobs == 1L, first(job_number), NA_character_),
    .groups = "drop")

# A registration links through its reported DOB NOW job or, failing that, a BIN
# held by exactly one DOB NOW filing. Several responses for one building keep
# the latest as its evidence.
links <- registrations |>
  mutate(root_job_matches = dob_now_root_job_id %in% dob$job_number) |>
  left_join(jobs_per_bin, by = c("dob_bin" = "bin"), relationship = "many-to-one") |>
  mutate(bin_unique = coalesce(bin_jobs == 1L, FALSE),
    link_method = case_when(
      root_job_matches & bin_unique & dob_now_root_job_id == bin_job ~ "dob_root_and_bin",
      root_job_matches & is.na(bin_jobs) ~ "dob_root_only_bin_unmatched",
      root_job_matches & bin_jobs > 1L ~ "dob_root_only_bin_nonunique",
      root_job_matches & bin_unique ~ "identifier_conflict_unresolved",
      bin_unique ~ "unique_bin_only",
      coalesce(bin_jobs > 1L, FALSE) ~ "nonunique_bin_unresolved",
      TRUE ~ "unmatched"),
    matched_dob_root_job_id = case_when(
      str_starts(link_method, "dob_root") ~ dob_now_root_job_id,
      link_method == "unique_bin_only" ~ bin_job),
    registration_building_key = case_when(
      !is.na(matched_dob_root_job_id) ~ paste0("matched_dob_now:", matched_dob_root_job_id),
      !is.na(dob_now_root_job_id) ~ paste0("reported_dob_now:", dob_now_root_job_id),
      !is.na(dob_bis_job_number) ~ paste0("reported_dob_bis:", dob_bis_job_number),
      TRUE ~ paste0("reported_bin:", dob_bin)),
    # Option B below 100 units signals an intended separate sub-100 building.
    intended_separate_sub100_treatment = reported_affordability_option == "OPTION B" & reported_units < 100L) |>
  group_by(registration_building_key) |>
  arrange(desc(form_submission_timestamp), desc(response_number), .by_group = TRUE) |>
  mutate(is_latest_building_response = row_number() == 1L) |>
  ungroup() |>
  select(response_number, form_submission_timestamp, registration_building_key, is_latest_building_response,
    link_method, matched_dob_root_job_id, dob_now_root_job_id, dob_bis_job_number, dob_bin,
    reported_property_address, reported_borough_name, reported_bbl, reported_units, reported_affordability_option,
    intended_separate_sub100_treatment) |>
  arrange(response_number)

SaveData(links, "response_number", "../output/hpd_485x_registration_dob_links.csv")

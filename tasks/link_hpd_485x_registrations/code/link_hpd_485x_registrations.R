# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/link_hpd_485x_registrations/code")
# threshold_units <- 100L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Expected argument: threshold_units.")
}

threshold_units <- as.integer(args[1])

if (is.na(threshold_units)) {
  stop("threshold_units must be an integer.")
}

hpd_registrations <- read_parquet("../input/hpd_485x_registrations.parquet")
dob_initial <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  mutate(
    job_number = str_squish(job_number),
    job_filing_number = str_squish(job_filing_number),
    bin = str_squish(bin)
  )

if (anyDuplicated(hpd_registrations$response_number)) {
  stop("HPD response_number must be unique before linkage.")
}

if (anyDuplicated(dob_initial$job_number)) {
  stop("DOB initial job_number must be unique before linkage.")
}

dob_root_lookup <- dob_initial |>
  select(
    root_lookup_job_number = job_number,
    root_lookup_filing_number = job_filing_number,
    root_lookup_bin = bin
  )

dob_bin_lookup <- dob_initial |>
  filter(!is.na(bin), bin != "") |>
  group_by(bin) |>
  summarise(
    bin_initial_job_count = n_distinct(job_number),
    bin_unique_root_job_id = if_else(
      bin_initial_job_count == 1L,
      first(job_number),
      NA_character_
    ),
    .groups = "drop"
  )

if (anyDuplicated(dob_bin_lookup$bin)) {
  stop("DOB BIN lookup must have one row per BIN.")
}

registration_links <- hpd_registrations |>
  left_join(
    dob_root_lookup,
    by = c("dob_now_root_job_id" = "root_lookup_job_number"),
    relationship = "many-to-one"
  ) |>
  left_join(
    dob_bin_lookup,
    by = c("dob_bin" = "bin"),
    relationship = "many-to-one"
  ) |>
  mutate(
    root_job_matches = !is.na(root_lookup_filing_number),
    bin_uniquely_matches = bin_initial_job_count == 1L,
    root_and_bin_agree = root_job_matches & bin_uniquely_matches &
      dob_now_root_job_id == bin_unique_root_job_id,
    link_method = case_when(
      root_and_bin_agree ~ "dob_root_and_bin",
      root_job_matches & is.na(bin_initial_job_count) ~ "dob_root_only_bin_unmatched",
      root_job_matches & bin_initial_job_count > 1L ~ "dob_root_only_bin_nonunique",
      root_job_matches & bin_uniquely_matches ~ "identifier_conflict_unresolved",
      !root_job_matches & bin_uniquely_matches ~ "unique_bin_only",
      !root_job_matches & bin_initial_job_count > 1L ~ "nonunique_bin_unresolved",
      TRUE ~ "unmatched"
    ),
    matched_dob_root_job_id = case_when(
      link_method %in% c(
        "dob_root_and_bin",
        "dob_root_only_bin_unmatched",
        "dob_root_only_bin_nonunique"
      ) ~ dob_now_root_job_id,
      link_method == "unique_bin_only" ~ bin_unique_root_job_id,
      TRUE ~ NA_character_
    ),
    registration_building_key = case_when(
      !is.na(matched_dob_root_job_id) ~ paste0("matched_dob_now:", matched_dob_root_job_id),
      !is.na(dob_now_root_job_id) ~ paste0("reported_dob_now:", dob_now_root_job_id),
      !is.na(dob_bis_job_number) ~ paste0("reported_dob_bis:", dob_bis_job_number),
      TRUE ~ paste0("reported_bin:", dob_bin)
    ),
    intended_separate_sub100_treatment =
      reported_affordability_option == "OPTION B" & reported_units < threshold_units
  ) |>
  group_by(registration_building_key) |>
  arrange(desc(form_submission_timestamp), desc(response_number), .by_group = TRUE) |>
  mutate(
    building_response_count = n(),
    is_latest_building_response = row_number() == 1L
  ) |>
  ungroup() |>
  arrange(response_number)

dob_match_fields <- dob_initial |>
  select(
    matched_dob_root_job_id = job_number,
    matched_dob_filing_number = job_filing_number,
    matched_dob_filing_date = filing_date,
    matched_dob_bin = bin,
    matched_dob_bbl = bbl,
    matched_dob_address = address,
    matched_dob_units = proposed_dwelling_units,
    matched_dob_first_permit_date = first_permit_date
  )

registration_links <- registration_links |>
  left_join(
    dob_match_fields,
    by = "matched_dob_root_job_id",
    relationship = "many-to-one"
  ) |>
  select(
    response_number,
    form_submission_timestamp,
    registration_building_key,
    building_response_count,
    is_latest_building_response,
    link_method,
    matched_dob_root_job_id,
    dob_now_root_job_id,
    dob_bis_job_number,
    dob_bin,
    reported_dob_permit_sequence,
    reported_property_address,
    reported_borough_name,
    reported_bbl,
    presumed_bbl,
    reported_units,
    reported_restricted_units,
    reported_affordability_option,
    reported_commencement_date,
    reported_anticipated_completion_date,
    intended_separate_sub100_treatment,
    matched_dob_filing_number,
    matched_dob_filing_date,
    matched_dob_bin,
    matched_dob_bbl,
    matched_dob_address,
    matched_dob_units,
    matched_dob_first_permit_date,
    root_job_matches,
    bin_uniquely_matches,
    root_and_bin_agree
  )

write_csv(
  registration_links,
  "../output/hpd_485x_registration_dob_links.csv",
  na = ""
)

cat("Wrote HPD registration-to-DOB links to ../output\n")

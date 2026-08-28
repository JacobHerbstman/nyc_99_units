# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_485x_exposure_universe/code")
# pre_start_year <- 2011L
# pre_end_year <- 2022L
# post_start_date_text <- "2023-01-01"
# min_units <- 6L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 4L) {
  stop(
    "Expected pre start year, pre end year, post start date, and minimum units."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_start_date_text <- args[3]
post_start_date <- as.Date(post_start_date_text)
min_units <- as.integer(args[4])

if (
  any(is.na(c(
    pre_start_year, pre_end_year, post_start_date, min_units
  ))) ||
    pre_start_year > pre_end_year ||
    min_units < 1L
) {
  stop("Exposure-universe arguments are not internally consistent.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

hdb <- read_parquet(
  "../input/dcp_housing_database_project_level_25q4.parquet"
) |>
  as.data.frame() |>
  as_tibble()

dob <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

historical_fields <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  anyDuplicated(membership[c("sample", "root_job_id")]) ||
    anyDuplicated(hdb$job_number) ||
    anyDuplicated(dob$job_number) ||
    anyDuplicated(historical_fields$job_number)
) {
  stop("An exposure-universe source is not unique by its expected job key.")
}

parent_membership <- membership |>
  filter(
    (
      sample == "historical" &
        full_window_observed &
        cohort_year >= pre_start_year &
        cohort_year <= pre_end_year
    ) |
      (
        sample == "post_policy" &
          left_window_observed &
          cohort_date >= post_start_date
    ),
    parent_observed_units >= min_units
  )

hdb_fields <- hdb |>
  transmute(
    root_job_id = job_number,
    hdb_address = str_squish(address),
    hdb_borough_name = str_squish(borough_name),
    hdb_ownership = str_squish(ownership)
  )

dob_fields <- dob |>
  transmute(
    root_job_id = job_number,
    dob_address = str_squish(address),
    dob_borough_name = str_squish(borough_name),
    dob_owner_type = str_squish(owner_type),
    dob_owner_name = str_squish(case_when(
      !is.na(owner_business_name) &
        owner_business_name != "" &
        str_to_upper(owner_business_name) != "NOT APPLICABLE" ~
          owner_business_name,
      !is.na(owner_first_name) | !is.na(owner_last_name) ~
        str_squish(paste(owner_first_name, owner_last_name)),
      TRUE ~ NA_character_
    )),
    dob_job_description = str_squish(job_description)
  )

historical_job_fields <- historical_fields |>
  transmute(
    root_job_id = job_number,
    historical_owner_name = str_squish(coalesce(
      dob_owner_name,
      pluto_owner_name
    )),
    historical_job_description = str_squish(description)
  )

exposure_universe <- parent_membership |>
  left_join(hdb_fields, by = "root_job_id", relationship = "many-to-one") |>
  left_join(dob_fields, by = "root_job_id", relationship = "many-to-one") |>
  left_join(
    historical_job_fields,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  transmute(
    sample,
    parent_id,
    root_job_id,
    member_order,
    cohort_date,
    cohort_year,
    parent_total_units = parent_observed_units,
    component_units = units,
    filing_bbl,
    address = coalesce(dob_address, hdb_address),
    borough_name = coalesce(dob_borough_name, hdb_borough_name),
    ownership_type = coalesce(dob_owner_type, hdb_ownership),
    owner_name = coalesce(dob_owner_name, historical_owner_name),
    job_description = coalesce(
      dob_job_description,
      historical_job_description
    ),
    ag_search_query = str_squish(address)
  ) |>
  arrange(sample, cohort_date, parent_id, member_order)

if (
  nrow(exposure_universe) == 0L ||
    anyDuplicated(exposure_universe[c("sample", "root_job_id")]) ||
    any(is.na(exposure_universe$parent_id)) ||
    any(is.na(exposure_universe$parent_total_units))
) {
  stop("Final exposure universe failed row-level QC.")
}

write_csv_if_changed(
  exposure_universe,
  "../output/parent_485x_exposure_universe.csv"
)

cat(
  "Wrote ",
  n_distinct(exposure_universe$parent_id),
  " parents and ",
  nrow(exposure_universe),
  " component filings to ../output\n",
  sep = ""
)

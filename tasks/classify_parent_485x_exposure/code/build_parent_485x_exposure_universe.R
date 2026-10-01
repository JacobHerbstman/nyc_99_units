# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/classify_parent_485x_exposure/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(stringr)
})
source("../../shared/code/write_data_report.R")

# Filings of the parents to classify: fully observed 2011-2022 historical
# parents and post-policy parents from 2023 on, with at least six units. Each
# filing carries the address, ownership and description the rules use: 23Q4
# Housing Database and archived owners historically, DOB NOW with Housing
# Database fallback afterwards.
membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  filter((sample == "historical" & full_window_observed & cohort_year >= 2011L & cohort_year <= 2022L) |
    (sample == "post_policy" & left_window_observed & cohort_date >= as.Date("2023-01-01")),
    parent_observed_units >= 6)

hdb <- bind_rows(
  read_parquet("../input/dcp_housing_database_project_level_23q4.parquet") |> mutate(sample = "historical"),
  read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |> mutate(sample = "post_policy")
) |>
  transmute(sample, root_job_id = job_number, hdb_address = str_squish(address),
    hdb_borough_name = str_squish(borough_name), hdb_ownership = str_squish(ownership))
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(sample = "post_policy", root_job_id = job_number, dob_address = str_squish(address),
    dob_borough_name = str_squish(borough_name), dob_owner_type = str_squish(owner_type),
    dob_owner_name = str_squish(case_when(
      coalesce(owner_business_name, "") != "" & str_to_upper(owner_business_name) != "NOT APPLICABLE" ~
        owner_business_name,
      !is.na(owner_first_name) | !is.na(owner_last_name) ~ str_squish(paste(owner_first_name, owner_last_name)))),
    dob_job_description = str_squish(job_description))
historical <- read_parquet("../input/historical_parent_filing_link_fields.parquet") |>
  transmute(sample = "historical", root_job_id = job_number, historical_owner_name = str_squish(pluto_owner_name),
    historical_job_description = str_squish(description))
stopifnot(!anyDuplicated(hdb[c("sample", "root_job_id")]), !anyDuplicated(dob$root_job_id),
  all(membership$root_job_id[membership$sample == "historical"] %in%
    intersect(hdb$root_job_id[hdb$sample == "historical"], historical$root_job_id)))

universe <- membership |>
  left_join(hdb, by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  left_join(dob, by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  left_join(historical, by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  mutate(historical_sample = sample == "historical") |>
  transmute(sample, parent_id, root_job_id, cohort_date, cohort_year, parent_total_units = parent_observed_units,
    component_units = units,
    address = if_else(historical_sample, hdb_address, coalesce(dob_address, hdb_address)),
    borough_name = if_else(historical_sample, hdb_borough_name, coalesce(dob_borough_name, hdb_borough_name)),
    ownership_type = if_else(historical_sample, hdb_ownership, coalesce(dob_owner_type, hdb_ownership)),
    owner_name = if_else(historical_sample, historical_owner_name, dob_owner_name),
    job_description = if_else(historical_sample, historical_job_description, dob_job_description),
    member_order) |>
  arrange(sample, cohort_date, parent_id, member_order) |>
  select(-member_order)

SaveData(universe, c("sample", "root_job_id"), "../output/parent_485x_exposure_universe.csv")

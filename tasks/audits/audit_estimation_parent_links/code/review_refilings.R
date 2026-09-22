# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

membership <- read_parquet("../input/symmetric_parent_membership.parquet")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
hdb_historical <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet") |>
  select(original_job = job_number, archived_address = address)
stopifnot(!anyDuplicated(membership[c("sample", "job_number")]), !anyDuplicated(dob$job_number),
  !anyDuplicated(hdb_historical$original_job))
refilings <- membership |> filter(filing_role == "superseded_refiling") |>
  transmute(sample, parent_id, original_job = job_number, root_job_id,
    replacement_job_number, original_filing_date, refiling_date, original_units = units,
    refiling_basis, archived_original_status = hdb_job_status) |>
  left_join(membership |> select(sample, replacement_job_number = job_number,
    replacement_parent = parent_id, replacement_units = units, additive_component,
    archived_replacement_status = hdb_job_status),
    by = c("sample", "replacement_job_number"), relationship = "many-to-one") |>
  left_join(dob |> select(root_job_id = job_number, address, bin,
    filing_status, dob_current_status_date = current_status_date),
    by = "root_job_id", relationship = "many-to-one") |>
  left_join(hdb_historical, by = "original_job", relationship = "many-to-one") |>
  mutate(address = if_else(sample == "historical", archived_address, address),
    withdrawal_date = if_else(sample == "post_policy" & filing_status == "Filing Withdrawn",
      dob_current_status_date, as.Date(NA))) |>
  arrange(sample, original_filing_date, original_job)
stopifnot(!anyDuplicated(refilings[c("sample", "original_job")]),
  all(refilings$parent_id == refilings$replacement_parent),
  all(refilings$additive_component),
  all(refilings$refiling_basis[refilings$sample == "historical"] %in%
    c("archived_same_building_alternatives", "reviewed_archived_alternative")),
  all(refilings$archived_original_status[refilings$sample == "historical"] == "9. Withdrawn"),
  all(refilings$archived_replacement_status[refilings$sample == "historical"] != "9. Withdrawn"),
  all(refilings$filing_status[refilings$sample == "post_policy"] == "Filing Withdrawn"),
  all(refilings$refiling_date[refilings$sample == "post_policy"] >
    refilings$withdrawal_date[refilings$sample == "post_policy"]),
  all(refilings$refiling_date > refilings$original_filing_date))
SaveData(refilings, c("sample", "original_job"), "../output/refilings.csv")

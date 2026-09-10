# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)

membership <- read_parquet("../input/symmetric_parent_membership.parquet")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
stopifnot(!anyDuplicated(membership[c("sample", "job_number")]), !anyDuplicated(dob$job_number))
refilings <- membership |> filter(filing_role == "superseded_refiling") |>
  transmute(sample, parent_id, original_job = job_number, root_job_id,
    replacement_job_number, original_filing_date, refiling_date, original_units = units) |>
  left_join(membership |> select(sample, replacement_job_number = job_number,
    replacement_parent = parent_id, replacement_units = units, additive_component),
    by = c("sample", "replacement_job_number"), relationship = "many-to-one") |>
  left_join(dob |> select(root_job_id = job_number, address, bin,
    filing_status, withdrawal_date = current_status_date),
    by = "root_job_id", relationship = "many-to-one") |>
  arrange(sample, original_filing_date, original_job)
stopifnot(!anyDuplicated(refilings[c("sample", "original_job")]),
  all(refilings$parent_id == refilings$replacement_parent),
  all(refilings$additive_component), all(refilings$filing_status == "Filing Withdrawn"),
  all(refilings$refiling_date > refilings$withdrawal_date),
  all(refilings$refiling_date > refilings$original_filing_date))
write_csv(refilings, "../output/refilings.csv", na = "")

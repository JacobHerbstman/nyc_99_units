# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_dob_now_new_building_filings/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

staged_filings <- read_parquet(
  "../input/dob_now_new_building_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

initial_filings <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

source_ids <- unique(staged_filings$source_id)
source_pull_dates <- unique(staged_filings$source_pull_date)
expected_initial_job_numbers <- staged_filings |>
  filter(filing_type == "I1") |>
  pull(job_number) |>
  sort()

if (
  length(source_ids) != 1L ||
    length(source_pull_dates) != 1L ||
    !identical(sort(initial_filings$job_number), expected_initial_job_numbers)
) {
  stop("Staged DOB NOW source metadata or initial-filing subset failed QC.")
}

duplicate_job_filing_numbers <- staged_filings |>
  count(job_filing_number, name = "rows") |>
  filter(rows > 1L)

duplicate_initial_job_numbers <- initial_filings |>
  count(job_number, name = "rows") |>
  filter(rows > 1L)

staging_qc <- tibble(
  source_id = source_ids,
  source_pull_date = source_pull_dates,
  source_rows = nrow(staged_filings),
  staged_filing_rows = nrow(staged_filings),
  staged_initial_rows = nrow(initial_filings),
  duplicate_job_filing_numbers = nrow(duplicate_job_filing_numbers),
  duplicate_initial_job_numbers = nrow(duplicate_initial_job_numbers),
  missing_filing_date = sum(is.na(initial_filings$filing_date)),
  missing_or_nonpositive_proposed_units = sum(
    is.na(initial_filings$proposed_dwelling_units) |
      initial_filings$proposed_dwelling_units <= 0
  ),
  noninteger_proposed_units = sum(
    !is.na(initial_filings$proposed_dwelling_units) &
      abs(
        initial_filings$proposed_dwelling_units -
          round(initial_filings$proposed_dwelling_units)
      ) > 1e-8
  ),
  missing_bbl = sum(is.na(initial_filings$bbl)),
  missing_bin = sum(is.na(initial_filings$bin) | initial_filings$bin == ""),
  missing_or_nonpositive_total_construction_floor_area = sum(
    is.na(initial_filings$total_construction_floor_area) |
      initial_filings$total_construction_floor_area <= 0
  ),
  first_filing_date = safe_min_date(initial_filings$filing_date),
  last_filing_date = safe_max_date(initial_filings$filing_date)
)

write_csv_if_changed(
  staging_qc,
  "../output/dob_now_new_building_initial_filings_qc.csv"
)

cat("Wrote staged DOB NOW filing QC to ../output\n")

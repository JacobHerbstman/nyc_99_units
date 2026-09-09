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
allowed_bbl_relations <- c(
  "agree", "lot_differs", "block_differs", "borough_differs",
  "filing_bbl_missing", "reported_bbl_missing", "both_missing"
)

if (
  length(source_ids) != 1L ||
    length(source_pull_dates) != 1L ||
    !identical(sort(initial_filings$job_number), expected_initial_job_numbers) ||
    any(is.na(staged_filings$bbl_field_relation)) ||
    any(!staged_filings$bbl_field_relation %in% allowed_bbl_relations)
) {
  stop(
    "Staged DOB NOW source metadata, initial subset, or BBL fields failed QC."
  )
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
  missing_filing_bbl = sum(is.na(initial_filings$filing_bbl)),
  missing_reported_bbl = sum(is.na(initial_filings$reported_bbl)),
  disagreeing_bbl_fields = sum(
    initial_filings$bbl_field_relation %in%
      c("lot_differs", "block_differs", "borough_differs")
  ),
  missing_bin = sum(is.na(initial_filings$bin) | initial_filings$bin == ""),
  missing_or_nonpositive_total_construction_floor_area = sum(
    is.na(initial_filings$total_construction_floor_area) |
      initial_filings$total_construction_floor_area <= 0
  ),
  first_filing_date = safe_min_date(initial_filings$filing_date),
  last_filing_date = safe_max_date(initial_filings$filing_date)
)

bbl_field_summary <- staged_filings |>
  mutate(filing_year = as.integer(format(filing_date, "%Y"))) |>
  count(filing_year, filing_type, bbl_field_relation, name = "filings") |>
  arrange(filing_year, filing_type, bbl_field_relation)

reported_bbl_initial_counts <- initial_filings |>
  filter(!is.na(reported_bbl)) |>
  count(reported_bbl, name = "initial_filings_sharing_reported_bbl")

bbl_disagreements <- staged_filings |>
  filter(bbl_field_relation != "agree") |>
  mutate(
    filing_year = as.integer(format(filing_date, "%Y")),
    analysis_priority = case_when(
      filing_type == "I1" & filing_year >= 2022L &
        proposed_dwelling_units >= 6 ~ "post_2022_initial_ge_6_units",
      filing_type == "I1" ~ "other_initial_filing",
      TRUE ~ "amendment"
    )
  ) |>
  left_join(
    reported_bbl_initial_counts,
    by = "reported_bbl",
    relationship = "many-to-one"
  ) |>
  select(
    analysis_priority,
    job_filing_number,
    job_number,
    filing_type,
    filing_date,
    filing_year,
    filing_status,
    address,
    borough_name,
    block,
    lot,
    filing_bbl,
    reported_bbl,
    bbl_field_relation,
    initial_filings_sharing_reported_bbl,
    bin,
    proposed_dwelling_units,
    proposed_stories,
    total_construction_floor_area,
    owner_business_name,
    applicant_business_name,
    job_description
  ) |>
  arrange(
    factor(
      analysis_priority,
      levels = c(
        "post_2022_initial_ge_6_units",
        "other_initial_filing",
        "amendment"
      )
    ),
    filing_date,
    job_filing_number
  )

write_csv_if_changed(
  staging_qc,
  "../output/dob_now_new_building_initial_filings_qc.csv"
)

write_csv_if_changed(
  bbl_field_summary,
  "../output/dob_now_bbl_field_summary.csv"
)

write_csv_if_changed(
  bbl_disagreements,
  "../output/dob_now_bbl_field_disagreements.csv"
)

cat("Wrote staged DOB NOW filing QC to ../output\n")

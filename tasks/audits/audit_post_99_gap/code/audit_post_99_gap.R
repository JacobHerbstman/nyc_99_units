# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_post_99_gap/code")
# post_start_date <- as.Date("2025-01-01")
library(arrow)
library(dplyr)
library(readr)
library(tidyr)
source("../../../shared/code/source_pipeline_utils.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  post_start_date <- as.Date(args[1])
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

initial_filings <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

filing_history <- read_parquet(
  "../input/dob_now_new_building_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

parent_exposure <- read_csv(
  "../input/parent_485x_exposure.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

parent_rows <- membership |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    total_units = first(parent_observed_units),
    component_filings = n(),
    full_window_observed = first(full_window_observed),
    left_window_observed = first(left_window_observed),
    source_end_date = first(source_end_date),
    .groups = "drop"
  )

if (
  nrow(parent_rows) == 0L ||
    anyDuplicated(parent_rows[c("sample", "parent_id")]) ||
    any(is.na(parent_rows$total_units)) ||
    any(parent_rows$total_units <= 0L)
) {
  stop("Parent-unit distribution inputs failed parent-level QC.")
}

post_end_dates <- parent_rows |>
  filter(sample == "post_policy") |>
  distinct(source_end_date) |>
  pull(source_end_date)

if (length(post_end_dates) != 1L || is.na(post_end_dates)) {
  stop("Post-policy source end date is missing or inconsistent.")
}

post_end_date <- post_end_dates[1]
post_rows <- parent_rows |>
  filter(
    sample == "post_policy",
    left_window_observed,
    cohort_date >= post_start_date,
    cohort_date <= post_end_date
  )

all_post_rows <- parent_rows |>
  filter(
    sample == "post_policy",
    cohort_date >= post_start_date,
    cohort_date <= post_end_date
  )

post_initial_filings <- initial_filings |>
  filter(
    filing_date >= post_start_date,
    filing_date <= post_end_date
  )

latest_post_filing_versions <- filing_history |>
  filter(
    filing_date <= post_end_date,
    job_number %in% post_initial_filings$job_number
  ) |>
  group_by(job_number) |>
  arrange(filing_date, job_filing_number, .by_group = TRUE) |>
  slice_tail(n = 1L) |>
  ungroup()

next_unit_audit <- tibble(unit_count = 99L:106L) |>
  left_join(
    post_rows |>
      count(unit_count = total_units, name = "plotted_parent_count"),
    by = "unit_count",
    relationship = "one-to-one"
  ) |>
  left_join(
    all_post_rows |>
      count(
        unit_count = total_units,
        name = "all_parent_count_including_left_boundary"
      ),
    by = "unit_count",
    relationship = "one-to-one"
  ) |>
  left_join(
    post_initial_filings |>
      count(
        unit_count = as.integer(proposed_dwelling_units),
        name = "initial_filing_count"
      ),
    by = "unit_count",
    relationship = "one-to-one"
  ) |>
  left_join(
    latest_post_filing_versions |>
      count(
        unit_count = as.integer(proposed_dwelling_units),
        name = "latest_filing_version_count"
      ),
    by = "unit_count",
    relationship = "one-to-one"
  ) |>
  mutate(
    plotted_parent_count = coalesce(plotted_parent_count, 0L),
    all_parent_count_including_left_boundary = coalesce(
      all_parent_count_including_left_boundary,
      0L
    ),
    initial_filing_count = coalesce(initial_filing_count, 0L),
    latest_filing_version_count = coalesce(
      latest_filing_version_count,
      0L
    ),
    all_four_layers_empty =
      plotted_parent_count == 0L &
      all_parent_count_including_left_boundary == 0L &
      initial_filing_count == 0L &
      latest_filing_version_count == 0L
  )

post_105_parent_cases <- membership |>
  filter(
    sample == "post_policy",
    left_window_observed,
    cohort_date >= post_start_date,
    cohort_date <= post_end_date,
    parent_observed_units == 105L
  ) |>
  group_by(parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    parent_total_units = first(parent_observed_units),
    component_filings = n(),
    component_job = first(job_number),
    component_jobs = paste(job_number, collapse = ";"),
    component_units = paste(units, collapse = ";"),
    component_dates = paste(date_filed, collapse = ";"),
    .groups = "drop"
  ) |>
  left_join(
    initial_filings |>
      select(
        component_job = job_filing_number,
        filing_status,
        address,
        filing_bbl,
        reported_bbl,
        bbl_field_relation,
        owner_business_name,
        applicant_business_name,
        job_description
      ),
    by = "component_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    parent_exposure |>
      select(
        parent_id,
        exposure_status,
        included_ab,
        included_ab_plus_d,
        confidence,
        classification_reason
      ),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  arrange(cohort_date, parent_id)

unit_105_counts <- next_unit_audit |>
  filter(unit_count == 105L) |>
  select(
    plotted_parent_count,
    all_parent_count_including_left_boundary,
    initial_filing_count,
    latest_filing_version_count
  ) |>
  unlist(use.names = FALSE)
stopifnot(
  !anyDuplicated(initial_filings$job_number), nrow(post_initial_filings) > 0L,
  all(next_unit_audit$all_four_layers_empty[next_unit_audit$unit_count %in% 100L:104L]),
  all(unit_105_counts > 0L), nrow(post_105_parent_cases) == 3L,
  all(post_105_parent_cases$component_filings == 1L), !anyNA(post_105_parent_cases$address)
)
write_csv_atomic(next_unit_audit, "../output/post_99_next_observed_unit_audit.csv")
write_csv_atomic(post_105_parent_cases, "../output/post_105_parent_cases.csv")

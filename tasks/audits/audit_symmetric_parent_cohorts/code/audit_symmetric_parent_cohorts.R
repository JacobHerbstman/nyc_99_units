# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_cohorts/code")
# post_cohort_year <- 2025L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Expected one argument: post-policy cohort year.")
}

post_cohort_year <- as.integer(args[1])

if (is.na(post_cohort_year)) {
  stop("The post-policy cohort year must be an integer.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

links <- read_parquet(
  "../input/symmetric_parent_links.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(membership) == 0L ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    anyDuplicated(links[c("sample", "job_number_1", "job_number_2")])
) {
  stop("Production parent-cohort inputs failed identifier QC.")
}

cohort_inventory <- membership |>
  arrange(sample, parent_id, date_filed, job_number) |>
  group_by(sample, parent_id) |>
  summarise(
    parent_anchor_job = first(parent_anchor_job),
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    parent_last_filing_date = first(parent_last_filing_date),
    parent_span_days = first(parent_span_days),
    parent_observed_filings = first(parent_observed_filings),
    parent_observed_units = first(parent_observed_units),
    parent_observed_units_dob_i1 = first(parent_observed_units_dob_i1),
    parent_exact_99_filings = first(parent_exact_99_filings),
    parent_exact_99_filings_dob_i1 =
      first(parent_exact_99_filings_dob_i1),
    distinct_filing_bbls = n_distinct(filing_bbl[!is.na(filing_bbl)]),
    cross_calendar_year = n_distinct(filing_year) > 1L,
    all_geometry_available = all(geometry_available),
    source_start_date = first(source_start_date),
    source_end_date = first(source_end_date),
    left_window_observed = first(left_window_observed),
    right_window_observed = first(right_window_observed),
    full_window_observed = first(full_window_observed),
    analysis_status = first(analysis_status),
    component_root_jobs = paste(root_job_id, collapse = ";"),
    component_jobs = paste(job_number, collapse = ";"),
    component_units = paste(hdb_priority_units, collapse = ";"),
    component_units_dob_i1 = paste(dob_i1_units, collapse = ";"),
    component_unit_sources = paste(unit_source, collapse = ";"),
    .groups = "drop"
  ) |>
  arrange(sample, cohort_date, parent_anchor_job)

post_job_link_evidence <- bind_rows(
  links |>
    filter(sample == "post_policy") |>
    transmute(
      job_number = job_number_1,
      linked_job_number = job_number_2,
      link_reason
    ),
  links |>
    filter(sample == "post_policy") |>
    transmute(
      job_number = job_number_2,
      linked_job_number = job_number_1,
      link_reason
    )
) |>
  group_by(job_number) |>
  summarise(
    directly_linked_jobs = paste(
      sort(unique(linked_job_number)),
      collapse = ";"
    ),
    direct_link_reasons = paste(
      sort(unique(link_reason)),
      collapse = "|"
    ),
    .groups = "drop"
  )

exact_99_path_rows <- bind_rows(
  membership |>
    filter(
      sample == "post_policy",
      filing_year == post_cohort_year,
      hdb_priority_units == 99L
    ) |>
    mutate(unit_definition = "hdb_priority"),
  membership |>
    filter(
      sample == "post_policy",
      filing_year == post_cohort_year,
      dob_i1_units == 99L
    ) |>
    mutate(unit_definition = "dob_i1")
) |>
  transmute(
    unit_definition,
    exact_99_root_job_id = root_job_id,
    exact_99_job_number = job_number,
    exact_99_filing_date = date_filed,
    exact_99_filing_bbl = filing_bbl,
    exact_99_hdb_priority_units = hdb_priority_units,
    exact_99_dob_i1_units = dob_i1_units,
    exact_99_geometry_available = geometry_available,
    hdb_classa_units = if_else(
      unit_source == "hdb",
      hdb_priority_units,
      NA_integer_
    ),
    parent_id
  ) |>
  left_join(
    cohort_inventory |>
      filter(sample == "post_policy") |>
      select(-sample),
    by = "parent_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    post_job_link_evidence,
    by = c("exact_99_job_number" = "job_number"),
    relationship = "many-to-one"
  ) |>
  mutate(
    parent_companion_filings = parent_observed_filings - 1L,
    parent_is_singleton = parent_observed_filings == 1L,
    parent_observed_units_equal_198 = parent_observed_units == 198L,
    parent_observed_units_dob_i1_equal_198 =
      parent_observed_units_dob_i1 == 198L,
    hdb_model_match = !is.na(hdb_classa_units),
    hdb_dob_units_match =
      exact_99_hdb_priority_units == exact_99_dob_i1_units,
    directly_linked_jobs = coalesce(directly_linked_jobs, "none"),
    direct_link_reasons = coalesce(direct_link_reasons, "none")
  ) |>
  relocate(
    hdb_classa_units,
    .after = direct_link_reasons
  ) |>
  arrange(unit_definition, exact_99_filing_date, exact_99_job_number)

exact_99_paths <- exact_99_path_rows |>
  filter(unit_definition == "hdb_priority")

exact_99_paths_dob_i1 <- exact_99_path_rows |>
  filter(unit_definition == "dob_i1")

signals <- c(
  "same_filing_bbl",
  "strict_lot_history_link",
  "later_lot_history_candidate",
  "explicit_job_reference",
  "same_project_code",
  "corroborated_exact_adjacency",
  "enhanced_link"
)

link_summary <- bind_rows(lapply(unique(links$sample), function(sample_name) {
  sample_links <- links |>
    filter(sample == sample_name)

  bind_rows(lapply(signals, function(signal) {
    selected <- coalesce(sample_links[[signal]], FALSE)
    selected_jobs <- c(
      sample_links$job_number_1[selected],
      sample_links$job_number_2[selected]
    )
    tibble(
      sample = sample_name,
      signal,
      accepted_links = nrow(sample_links),
      signal_links = sum(selected),
      distinct_jobs = n_distinct(selected_jobs)
    )
  }))
}))

cohort_summary <- bind_rows(
  cohort_inventory |>
    group_by(sample, cohort_group = analysis_status) |>
    summarise(
      parent_count = n(),
      observed_filings = sum(parent_observed_filings),
      observed_units = sum(parent_observed_units),
      observed_units_dob_i1 = sum(parent_observed_units_dob_i1),
      exact_99_filings = sum(parent_exact_99_filings),
      exact_99_filings_dob_i1 = sum(parent_exact_99_filings_dob_i1),
      .groups = "drop"
    ),
  cohort_inventory |>
    filter(sample == "post_policy", cohort_year == post_cohort_year) |>
    summarise(
      sample = "post_policy",
      cohort_group = "descriptive_all_2025_cohorts",
      parent_count = n(),
      observed_filings = sum(parent_observed_filings),
      observed_units = sum(parent_observed_units),
      observed_units_dob_i1 = sum(parent_observed_units_dob_i1),
      exact_99_filings = sum(parent_exact_99_filings),
      exact_99_filings_dob_i1 = sum(parent_exact_99_filings_dob_i1)
    )
) |>
  arrange(sample, cohort_group)

cohort_qc <- tibble(
  check = c(
    "historical_filings",
    "post_filings",
    "historical_accepted_links",
    "post_accepted_links",
    "components_over_365_days",
    "completed_2025_parents",
    "right_censored_2025_parents",
    "observed_2025_exact_99_filings_hdb_priority",
    "observed_2025_exact_99_filings_dob_i1",
    "imputed_companions"
  ),
  value = as.character(c(
    sum(membership$sample == "historical"),
    sum(membership$sample == "post_policy"),
    sum(links$sample == "historical"),
    sum(links$sample == "post_policy"),
    sum(cohort_inventory$parent_span_days > 365L),
    sum(cohort_inventory$analysis_status == "completed_2025_cohort"),
    sum(
      cohort_inventory$analysis_status == "right_censored_2025_cohort"
    ),
    nrow(exact_99_paths),
    nrow(exact_99_paths_dob_i1),
    0L
  ))
)

if (
  anyDuplicated(cohort_inventory[c("sample", "parent_id")]) ||
    any(cohort_inventory$parent_span_days > 365L) ||
    any(is.na(exact_99_paths$analysis_status)) ||
    any(cohort_inventory$analysis_status == "unclassified")
) {
  stop("Symmetric parent-cohort audit outputs failed final QC.")
}

write_csv_if_changed(
  cohort_inventory,
  "../output/symmetric_parent_cohort_inventory.csv"
)
write_csv_if_changed(
  exact_99_paths,
  "../output/symmetric_parent_2025_exact_99_paths.csv"
)
write_csv_if_changed(
  exact_99_paths_dob_i1,
  "../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv"
)
write_csv_if_changed(
  link_summary,
  "../output/symmetric_parent_link_summary.csv"
)
write_csv_if_changed(
  cohort_summary,
  "../output/symmetric_parent_cohort_summary.csv"
)
write_csv_if_changed(
  cohort_qc,
  "../output/symmetric_parent_cohort_qc.csv"
)

cat("Wrote symmetric parent-cohort audit outputs to ../output\n")

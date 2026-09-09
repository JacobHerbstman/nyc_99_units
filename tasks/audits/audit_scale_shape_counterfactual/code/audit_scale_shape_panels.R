# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_scale_shape_counterfactual/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as.data.frame() |>
  as_tibble()
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(parents) == 0L ||
    nrow(constituents) == 0L ||
    anyDuplicated(parents[c("sample", "parent_id")]) ||
    anyDuplicated(constituents[c("sample", "root_job_id")])
) {
  stop("Scale-shape panel identifiers failed audit uniqueness checks.")
}

parent_panel_qc <- parents |>
  group_by(period) |>
  summarise(
    parents = n(),
    ab_parents = sum(included_ab),
    component_filings = sum(n_components),
    multi_component_parents = sum(multi_component),
    exact_99x2_parents = sum(exact_99x2),
    exact_99x3_parents = sum(exact_99x3),
    mismatched_parent_unit_totals = sum(
      parent_total_units != constituent_total_units
    ),
    missing_exposure_classification = sum(is.na(exposure_status)),
    missing_feature_rows = sum(is.na(feature_units)),
    composition_eligible_ab_parents = sum(
      included_ab & coalesce(composition_eligible, FALSE)
    ),
    right_window_observed_parents = sum(right_window_observed),
    minimum_followup_days = min(observed_followup_days),
    median_followup_days = median(observed_followup_days),
    maximum_followup_days = max(observed_followup_days),
    .groups = "drop"
  )

parent_190_205_audit <- parents |>
  filter(parent_total_units >= 190L, parent_total_units <= 205L) |>
  transmute(
    period,
    sample,
    parent_id,
    cohort_date,
    parent_total_units,
    n_components,
    sorted_component_vector,
    largest_component = max_component_units,
    second_component = second_component_units,
    component_bbls,
    component_job_numbers,
    hpd_response_numbers,
    hpd_registration_building_keys,
    hpd_linked_options,
    splitting_verification_status,
    splitting_verification_reason,
    exposure_status,
    included_ab,
    included_ab_plus_d
  ) |>
  arrange(period, parent_total_units, parent_id)

write_csv_if_changed(parent_panel_qc, "../output/parent_panel_qc.csv")
write_csv_if_changed(parent_190_205_audit, "../output/parent_190_205_audit.csv")

cat("Wrote scale-shape panel audits to ../output\n")

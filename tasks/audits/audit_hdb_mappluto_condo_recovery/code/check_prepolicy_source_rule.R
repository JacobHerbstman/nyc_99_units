# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

# Dated baselines record the pipeline immediately before the source-vintage change.
old_filings <- read_csv("prepolicy_baseline_filings_2026-09-22.csv", show_col_types = FALSE,
  col_types = cols(root_job_id = col_character()))
old_parents <- read_csv("prepolicy_baseline_parents_2026-09-22.csv", show_col_types = FALSE)
filings <- read_parquet("../input/constituent_filing_panel.parquet")
parents <- read_parquet("../input/parent_opportunity_panel.parquet")
hdb <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet")
members <- read_parquet("../input/symmetric_parent_membership.parquet")
stopifnot(!anyDuplicated(hdb$job_number), all(hdb$release == "23Q4"),
  max(hdb$date_updated, na.rm = TRUE) <= as.Date("2024-01-12"))

historical <- filings |> filter(sample == "historical") |>
  left_join(hdb |> select(root_job_id = job_number, classa_prop, bbl, release),
    by = "root_job_id", relationship = "one-to-one")
stopifnot(!anyNA(historical$classa_prop), all(historical$constituent_units == historical$classa_prop),
  all(historical$hdb_release == "23Q4"), all(historical$filing_bbl == historical$bbl))
# Post-policy outcomes, exposure and covariates must survive the historical source switch.
post_filings <- filings |> filter(sample == "post_policy") |> select(all_of(names(old_filings))) |>
  arrange(root_job_id)
post_parents <- parents |> filter(sample == "post_policy") |> select(all_of(names(old_parents))) |>
  arrange(parent_id)
stopifnot(isTRUE(all.equal(as.data.frame(post_filings), as.data.frame(old_filings |>
  filter(sample == "post_policy") |> arrange(root_job_id)), check.attributes = FALSE)),
  isTRUE(all.equal(as.data.frame(post_parents), as.data.frame(old_parents |>
    filter(sample == "post_policy") |> arrange(parent_id)), check.attributes = FALSE)))

changes <- old_filings |> filter(sample == "historical") |>
  select(root_job_id, old_parent = parent_id, old_units = constituent_units) |>
  full_join(filings |> filter(sample == "historical") |>
    select(root_job_id, parent_id, constituent_units, historical_active, hdb_job_status),
    by = "root_job_id", relationship = "one-to-one") |>
  left_join(hdb |> select(root_job_id = job_number, archived_units = classa_prop,
    archived_active = historical_active, archived_status = job_status),
    by = "root_job_id", relationship = "one-to-one") |>
  mutate(sample_change = case_when(is.na(old_parent) ~ "added",
    is.na(parent_id) ~ "removed", TRUE ~ "retained"),
    units_changed = old_units != constituent_units,
    parent_changed = old_parent != parent_id)
summary <- bind_rows(old_parents |> mutate(version = "Before source correction"),
  parents |> select(all_of(names(old_parents))) |> mutate(version = "Pre-adoption source")) |>
  group_by(version, sample) |>
  summarise(parents = n(), filings = sum(n_components), units = sum(parent_total_units),
    exact99_parents = sum(parent_total_units == 99),
    weighting_parents = sum(included_ab & composition_eligible & parent_total_units >= 50), .groups = "drop")
status <- members |> filter(sample == "historical", cohort_year >= 2019, cohort_year <= 2022,
  full_window_observed) |>
  group_by(historical_active, hdb_job_status, filing_role) |>
  summarise(filings = n(), parents = n_distinct(parent_id),
    source_units = sum(units), additive_units = sum(units[additive_component]), .groups = "drop")
coverage <- hdb |> filter(job_type == "New Building", classa_prop >= 6,
    date_filed >= as.Date("2019-01-01"), date_filed <= as.Date("2022-12-31")) |>
  select(root_job_id = job_number, address, date_filed, classa_prop, historical_active, job_status) |>
  left_join(members |> filter(sample == "historical") |>
    select(root_job_id, parent_id, cohort_year, filing_role, additive_component),
    by = "root_job_id", relationship = "one-to-one") |>
  mutate(disposition = case_when(is.na(parent_id) ~ "Outside historical linkage coverage",
    cohort_year < 2019 ~ "Parent anchored before 2019",
    !additive_component ~ "Retained nonadditive source filing",
    root_job_id %in% filings$root_job_id[filings$sample == "historical"] ~ "Canonical additive constituent",
    TRUE ~ "Outside canonical cohort"))
# This compares active status inside the reconstructed parent sample; it does
# not pretend that dropping components is a separately reconstructed estimator.
active_comparison <- parents |> filter(sample == "historical") |>
  mutate(status_group = if_else(historical_all_active, "All components active", "Includes inactive component")) |>
  group_by(status_group, historical_all_source_active) |>
  summarise(parents = n(), units = sum(parent_total_units), exact99 = sum(parent_total_units == 99),
    weighting_parents = sum(included_ab & composition_eligible & parent_total_units >= 50), .groups = "drop")
SaveData(changes, "root_job_id", "../output/prepolicy_source_changes.csv")
SaveData(summary, c("version", "sample"), "../output/prepolicy_source_summary.csv")
SaveData(status, c("historical_active", "hdb_job_status", "filing_role"), "../output/prepolicy_source_status.csv")
SaveData(coverage, "root_job_id", "../output/prepolicy_source_coverage.csv")
SaveData(active_comparison, c("status_group", "historical_all_source_active"), "../output/prepolicy_active_comparison.csv")

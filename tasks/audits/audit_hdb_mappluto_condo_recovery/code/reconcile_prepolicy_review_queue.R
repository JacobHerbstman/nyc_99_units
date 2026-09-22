# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

old_scope <- read_csv("prepolicy_baseline_scope_2026-09-22.csv", show_col_types = FALSE)
old_filings <- read_csv("prepolicy_baseline_filings_2026-09-22.csv", show_col_types = FALSE,
  col_types = cols(root_job_id = col_character()))
members <- read_parquet("../input/symmetric_parent_membership.parquet")
scope <- read_csv("../output/parent_site_scope.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(old_scope$parent_id), !anyDuplicated(scope$parent_id),
  sum(old_scope$unresolved) == 111L)

# Shared source jobs connect the old and new parents even when the anchor ID changes.
# Multiple links are retained explicitly; a split or merger is not a resolved boundary.
old_jobs <- old_filings |> group_by(parent_id) |>
  summarise(old_jobs = paste(sort(root_job_id), collapse = ";"), .groups = "drop")
current_jobs <- members |> filter(additive_component) |> group_by(parent_id) |>
  summarise(current_jobs = paste(sort(root_job_id), collapse = ";"), .groups = "drop")
crosswalk <- old_filings |> select(sample, root_job_id, old_parent_id = parent_id) |>
  left_join(members |> select(sample, root_job_id, current_parent_id = parent_id),
    by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  distinct(old_parent_id, current_parent_id) |>
  left_join(old_jobs, by = c("old_parent_id" = "parent_id"), relationship = "many-to-one") |>
  left_join(current_jobs, by = c("current_parent_id" = "parent_id"), relationship = "many-to-one") |>
  left_join(scope |> select(current_parent_id = parent_id,
    current_unresolved = unresolved, current_status = status),
    by = "current_parent_id", relationship = "many-to-one")
old_outcomes <- crosswalk |> group_by(old_parent_id) |>
  summarise(current_parent_ids = paste(sort(unique(na.omit(current_parent_id))), collapse = ";"),
    current_parents_in_scope = sum(!is.na(current_unresolved)),
    membership_changed = any(coalesce(old_jobs != current_jobs, TRUE)),
    current_unresolved_parents = sum(current_unresolved, na.rm = TRUE), .groups = "drop")
review <- old_scope |> rename(old_parent_id = parent_id, old_unresolved = unresolved,
    old_status = status) |>
  left_join(old_outcomes, by = "old_parent_id", relationship = "one-to-one") |>
  mutate(transition = case_when(current_parents_in_scope == 0L ~ "Outside current review sample",
    current_unresolved_parents > 0L ~ "Flagged in current review sample",
    membership_changed ~ "Membership changed; current checks support new parent",
    TRUE ~ "Supported by current checks"))
stopifnot(!anyNA(review$transition))

previous_scope <- crosswalk |> semi_join(old_scope, by = c("old_parent_id" = "parent_id")) |>
  filter(!is.na(current_parent_id)) |> group_by(current_parent_id) |>
  summarise(previous_parent_ids = paste(sort(unique(old_parent_id)), collapse = ";"), .groups = "drop")
current <- scope |> select(sample, parent_id, unresolved, status) |>
  left_join(previous_scope, by = c("parent_id" = "current_parent_id"), relationship = "one-to-one") |>
  mutate(entered_review_sample = is.na(previous_parent_ids))
SaveData(review, "old_parent_id", "../output/prepolicy_old_review_queue.csv")
SaveData(current, "parent_id", "../output/prepolicy_current_review_queue.csv")
print(review |> filter(old_unresolved) |> count(sample, transition), n = Inf)
print(current |> count(sample, entered_review_sample, unresolved), n = Inf)

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_historical_parent_linkage/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(igraph)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(sample == "historical", full_window_observed) |>
  arrange(cohort_date, job_number)

links <- read_parquet("../input/symmetric_parent_links.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    sample == "historical",
    job_number_1 %in% membership$job_number,
    job_number_2 %in% membership$job_number
  ) |>
  mutate(
    nongeometry_link =
      same_filing_bbl |
      strict_lot_history_link |
      explicit_job_reference |
      same_project_code,
    adjacency_only_link =
      corroborated_exact_adjacency & !nongeometry_link
  ) |>
  arrange(date_filed_1, job_number_1, job_number_2)

filing_fields <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(job_number %in% membership$job_number) |>
  arrange(date_filed, job_number)

if (
  nrow(membership) == 0L ||
    anyDuplicated(membership$job_number) ||
    anyDuplicated(links[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(filing_fields$job_number) ||
    !setequal(membership$job_number, filing_fields$job_number) ||
    any(!links$enhanced_link) ||
    any(links$adjacency_only_link & !links$exact_polygon_touch)
) {
  stop("Historical parent-link audit inputs failed identifier or logic QC.")
}

parent_rows <- membership |>
  group_by(parent_id) |>
  summarise(
    cohort_year = first(cohort_year),
    parent_filings = n(),
    parent_units = first(parent_observed_units),
    geometry_complete = all(geometry_available),
    .groups = "drop"
  )

link_cohorts <- membership |>
  select(job_number_1 = job_number, cohort_year) |>
  left_join(
    links,
    by = "job_number_1",
    relationship = "one-to-many"
  ) |>
  filter(!is.na(job_number_2))

linkage_by_cohort <- parent_rows |>
  group_by(cohort_year) |>
  summarise(
    parents = n(),
    multi_filing_parents = sum(parent_filings > 1L),
    multi_filing_parent_share = mean(parent_filings > 1L),
    parents_at_least_99_units = sum(parent_units >= 99L),
    parents_above_100_units = sum(parent_units > 100L),
    parents_with_complete_geometry = sum(geometry_complete),
    .groups = "drop"
  ) |>
  left_join(
    link_cohorts |>
      group_by(cohort_year) |>
      summarise(
        accepted_link_edges = n(),
        nongeometry_link_edges = sum(nongeometry_link),
        adjacency_link_edges = sum(corroborated_exact_adjacency),
        adjacency_only_link_edges = sum(adjacency_only_link),
        adjacency_only_same_day_edges = sum(
          adjacency_only_link & filing_days_apart == 0L
        ),
        adjacency_only_within_7_day_edges = sum(
          adjacency_only_link & filing_days_apart <= 7L
        ),
        adjacency_only_same_owner_edges = sum(
          adjacency_only_link & same_owner_support
        ),
        .groups = "drop"
      ),
    by = "cohort_year",
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      ends_with("_edges"),
      ~ coalesce(as.integer(.x), 0L)
    )
  ) |>
  arrange(cohort_year)

link_signal_availability <- filing_fields |>
  group_by(filing_year) |>
  summarise(
    filings = n(),
    filing_bbl_share = mean(!is.na(filing_bbl)),
    pluto_owner_share = mean(!is.na(pluto_owner_match_key)),
    dob_owner_share = mean(!is.na(dob_owner_match_key)),
    description_share = mean(!is.na(description)),
    explicit_reference_share = mean(!is.na(description_referenced_jobs)),
    project_code_share = mean(!is.na(description_project_code)),
    archived_lot_history_share = mean(!is.na(archived_appbbl)),
    prefiling_coordinate_share = mean(
      !is.na(prefiling_xcoord) & !is.na(prefiling_ycoord)
    ),
    .groups = "drop"
  ) |>
  arrange(filing_year)

nongeometry_graph <- graph_from_data_frame(
  links |>
    filter(nongeometry_link) |>
    select(job_number_1, job_number_2),
  directed = FALSE,
  vertices = membership |>
    transmute(name = job_number)
)

nongeometry_components <- tibble(
  job_number = names(components(nongeometry_graph)$membership),
  nongeometry_component = unname(components(nongeometry_graph)$membership)
) |>
  left_join(
    membership |>
      select(job_number, parent_id, cohort_year, units),
    by = "job_number",
    relationship = "one-to-one"
  )

parent_geometry_dependence <- nongeometry_components |>
  group_by(parent_id, cohort_year) |>
  summarise(
    full_parent_filings = n(),
    nongeometry_components = n_distinct(nongeometry_component),
    geometry_dependent_parent = nongeometry_components > 1L,
    .groups = "drop"
  )

nongeometry_parent_rows <- nongeometry_components |>
  group_by(nongeometry_component) |>
  summarise(
    cohort_year = min(cohort_year),
    parent_units = sum(units),
    .groups = "drop"
  )

nongeometry_parent_component_rows <- nongeometry_components |>
  group_by(parent_id, cohort_year, nongeometry_component) |>
  summarise(
    component_units = sum(units),
    component_jobs = str_c(sort(job_number), collapse = ";"),
    .groups = "drop"
  )

geometry_dependent_parent_review <- nongeometry_parent_component_rows |>
  group_by(parent_id, cohort_year) |>
  summarise(
    full_parent_units = sum(component_units),
    full_parent_filings = sum(str_count(component_jobs, ";") + 1L),
    nongeometry_components = n(),
    nongeometry_component_units = str_c(
      sort(component_units),
      collapse = ";"
    ),
    nongeometry_component_jobs = str_c(
      component_jobs[order(component_units)],
      collapse = " | "
    ),
    full_parent_tail_count = as.integer(full_parent_units >= 99L),
    nongeometry_tail_count = sum(component_units >= 99L),
    tail_count_change_without_adjacency =
      nongeometry_tail_count - full_parent_tail_count,
    full_parent_exact_99_count = as.integer(full_parent_units == 99L),
    nongeometry_exact_99_count = sum(component_units == 99L),
    exact_99_count_change_without_adjacency =
      nongeometry_exact_99_count - full_parent_exact_99_count,
    .groups = "drop"
  ) |>
  filter(nongeometry_components > 1L) |>
  arrange(
    desc(abs(exact_99_count_change_without_adjacency)),
    desc(abs(tail_count_change_without_adjacency)),
    cohort_year,
    parent_id
  )

tail_relevant_reviews <- read_csv(
  "tail_relevant_parent_reviews.csv",
  show_col_types = FALSE
) |>
  arrange(cohort_year, parent_id)

tail_relevant_review_validation <- tail_relevant_reviews |>
  left_join(
    geometry_dependent_parent_review |>
      select(
        parent_id, current_cohort_year = cohort_year,
        full_parent_units, full_parent_filings,
        nongeometry_component_units, nongeometry_component_jobs,
        tail_count_change_without_adjacency,
        exact_99_count_change_without_adjacency
      ),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    matches_current_parent =
      !is.na(current_cohort_year) &
      cohort_year == current_cohort_year &
      tail_count_change_without_adjacency != 0L
  ) |>
  select(-current_cohort_year)

linkage_geometry_dependence <- parent_rows |>
  group_by(cohort_year) |>
  summarise(
    full_link_parents = n(),
    full_link_multi_filing_parents = sum(parent_filings > 1L),
    full_link_tail_parents = sum(parent_units >= 99L),
    .groups = "drop"
  ) |>
  left_join(
    parent_geometry_dependence |>
      group_by(cohort_year) |>
      summarise(
        geometry_dependent_parents = sum(geometry_dependent_parent),
        geometry_dependent_multi_filing_parents = sum(
          geometry_dependent_parent & full_parent_filings > 1L
        ),
        .groups = "drop"
      ),
    by = "cohort_year",
    relationship = "one-to-one"
  ) |>
  left_join(
    nongeometry_parent_rows |>
      group_by(cohort_year) |>
      summarise(
        nongeometry_link_parents = n(),
        nongeometry_link_tail_parents = sum(parent_units >= 99L),
        .groups = "drop"
      ),
    by = "cohort_year",
    relationship = "one-to-one"
  ) |>
  mutate(
    geometry_dependent_share_of_multi_filing_parents = if_else(
      full_link_multi_filing_parents > 0L,
      geometry_dependent_multi_filing_parents /
        full_link_multi_filing_parents,
      NA_real_
    ),
    parent_count_change_without_adjacency =
      nongeometry_link_parents - full_link_parents,
    tail_count_change_without_adjacency =
      nongeometry_link_tail_parents - full_link_tail_parents
  ) |>
  arrange(cohort_year)

filing_review_fields <- filing_fields |>
  select(
    job_number, units, pluto_version_used,
    pluto_owner_name, dob_owner_name, description
  )

adjacency_only_review <- link_cohorts |>
  filter(adjacency_only_link) |>
  left_join(
    filing_review_fields |>
      rename_with(~ paste0(.x, "_1"), -job_number) |>
      rename(job_number_1 = job_number),
    by = "job_number_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    filing_review_fields |>
      rename_with(~ paste0(.x, "_2"), -job_number) |>
      rename(job_number_2 = job_number),
    by = "job_number_2",
    relationship = "many-to-one"
  ) |>
  mutate(
    timing_support = case_when(
      filing_days_apart == 0L ~ "same_day",
      filing_days_apart <= 7L ~ "within_7_days",
      filing_days_apart <= 30L ~ "within_30_days",
      TRUE ~ "same_owner_only"
    ),
    manual_review_priority = case_when(
      filing_days_apart > 30L ~ "review_owner_only",
      filing_days_apart > 7L & !same_owner_support ~ "review_timing_only",
      TRUE ~ "standard_review"
    )
  ) |>
  select(
    cohort_year, job_number_1, job_number_2,
    date_filed_1, date_filed_2, filing_days_apart,
    filing_bbl_1, filing_bbl_2,
    units_1, units_2,
    pluto_version_used_1, pluto_version_used_2,
    same_owner_support, timing_support, manual_review_priority,
    pluto_owner_name_1, pluto_owner_name_2,
    dob_owner_name_1, dob_owner_name_2,
    description_1, description_2
  ) |>
  arrange(cohort_year, manual_review_priority, date_filed_1, job_number_1)

if (
  anyDuplicated(linkage_by_cohort$cohort_year) ||
    anyDuplicated(link_signal_availability$filing_year) ||
    anyDuplicated(linkage_geometry_dependence$cohort_year) ||
    anyDuplicated(adjacency_only_review[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(geometry_dependent_parent_review$parent_id) ||
    anyDuplicated(tail_relevant_reviews$parent_id) ||
    any(!tail_relevant_review_validation$matches_current_parent) ||
    any(tail_relevant_review_validation$review_decision != "confirm_parent") ||
    any(linkage_geometry_dependence$parent_count_change_without_adjacency < 0L)
) {
  stop("Historical parent-link audit outputs failed final QC.")
}

write_csv_if_changed(
  linkage_by_cohort,
  "../output/linkage_by_cohort.csv"
)
write_csv_if_changed(
  link_signal_availability,
  "../output/link_signal_availability_by_filing_year.csv"
)
write_csv_if_changed(
  linkage_geometry_dependence,
  "../output/linkage_geometry_dependence_by_cohort.csv"
)
write_csv_if_changed(
  adjacency_only_review,
  "../output/adjacency_only_link_review.csv"
)
write_csv_if_changed(
  geometry_dependent_parent_review,
  "../output/geometry_dependent_parent_review.csv"
)
write_csv_if_changed(
  tail_relevant_review_validation,
  "../output/tail_relevant_parent_review_validation.csv"
)

cat("Wrote historical parent-link audit outputs to ../output\n")

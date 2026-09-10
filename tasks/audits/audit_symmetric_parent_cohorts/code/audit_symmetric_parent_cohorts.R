# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_cohorts/code")
# post_cohort_year <- 2025L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(stringr)
  library(tibble)
})

source("../../../shared/code/source_pipeline_utils.R")

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

dob_initial <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_parent_reviews <- read_csv(
  "../input/post_parent_reviews.csv",
  show_col_types = FALSE
)

post_link_reviews <- read_csv(
  "../input/pair_decisions.csv",
  show_col_types = FALSE
)

post_link_reviews <- post_link_reviews |> filter(sample == "post_policy")

post_filing_roles <- read_csv(
  "../input/post_parent_filing_roles.csv",
  show_col_types = FALSE
)

if (
  nrow(membership) == 0L ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    anyDuplicated(links[c("sample", "job_number_1", "job_number_2")]) ||
    anyDuplicated(dob_initial$job_filing_number) ||
    anyDuplicated(post_parent_reviews$reviewed_parent_id) ||
    anyDuplicated(post_link_reviews[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(post_filing_roles$job_number)
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
    parent_source_filings = first(parent_source_filings),
    parent_observed_filings = first(parent_observed_filings),
    parent_source_units = first(parent_source_units),
    parent_observed_units = first(parent_observed_units),
    parent_source_units_dob_i1 = first(parent_source_units_dob_i1),
    parent_observed_units_dob_i1 = first(parent_observed_units_dob_i1),
    parent_source_exact_99_filings = first(
      parent_source_exact_99_filings
    ),
    parent_exact_99_filings = first(parent_exact_99_filings),
    parent_source_exact_99_filings_dob_i1 = first(
      parent_source_exact_99_filings_dob_i1
    ),
    parent_exact_99_filings_dob_i1 =
      first(parent_exact_99_filings_dob_i1),
    distinct_filing_bbls = n_distinct(filing_bbl[!is.na(filing_bbl)]),
    distinct_site_linkage_bbls = n_distinct(
      site_linkage_bbl[!is.na(site_linkage_bbl)]
    ),
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
    component_filing_roles = paste(filing_role, collapse = ";"),
    component_replacement_jobs = paste(
      coalesce(replacement_job_number, "none"),
      collapse = ";"
    ),
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

post_site_linkage_bbl_links <- links |>
  filter(
    sample == "post_policy",
    same_site_linkage_bbl,
    !same_filing_bbl
  ) |>
  left_join(
    membership |>
      filter(sample == "post_policy") |>
      select(
        job_number_1 = job_number,
        parent_id_1 = parent_id,
        units_1 = hdb_priority_units
      ),
    by = "job_number_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    membership |>
      filter(sample == "post_policy") |>
      select(
        job_number_2 = job_number,
        parent_id_2 = parent_id,
        units_2 = hdb_priority_units
      ),
    by = "job_number_2",
    relationship = "many-to-one"
  ) |>
  left_join(
    dob_initial |>
      select(
        job_number_1 = job_filing_number,
        filing_status_1 = filing_status,
        address_1 = address,
        borough_1 = borough_name,
        block_1 = block,
        lot_1 = lot,
        bbl_field_relation_1 = bbl_field_relation,
        bin_1 = bin,
        owner_1 = owner_business_name,
        applicant_1 = applicant_business_name,
        proposed_stories_1 = proposed_stories,
        construction_floor_area_1 = total_construction_floor_area,
        job_description_1 = job_description
      ),
    by = "job_number_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    dob_initial |>
      select(
        job_number_2 = job_filing_number,
        filing_status_2 = filing_status,
        address_2 = address,
        borough_2 = borough_name,
        block_2 = block,
        lot_2 = lot,
        bbl_field_relation_2 = bbl_field_relation,
        bin_2 = bin,
        owner_2 = owner_business_name,
        applicant_2 = applicant_business_name,
        proposed_stories_2 = proposed_stories,
        construction_floor_area_2 = total_construction_floor_area,
        job_description_2 = job_description
      ),
    by = "job_number_2",
    relationship = "many-to-one"
  ) |>
  mutate(
    same_applicant_support =
      !is.na(applicant_1) & !is.na(applicant_2) &
      !str_to_upper(applicant_1) %in% c("", "NOT APPLICABLE") &
      !str_to_upper(applicant_2) %in% c("", "NOT APPLICABLE") &
      str_to_upper(applicant_1) == str_to_upper(applicant_2),
    same_bin = !is.na(bin_1) & !is.na(bin_2) & bin_1 == bin_2,
    same_filing_block =
      !is.na(borough_1) & !is.na(borough_2) &
      !is.na(block_1) & !is.na(block_2) &
      borough_1 == borough_2 & block_1 == block_2,
    consecutive_filing_lots =
      same_filing_block & !is.na(lot_1) & !is.na(lot_2) &
      abs(lot_1 - lot_2) == 1L,
    same_address =
      !is.na(address_1) & !is.na(address_2) &
      str_to_upper(address_1) == str_to_upper(address_2),
    manual_review_priority = case_when(
      (units_1 == 99L | units_2 == 99L) &
        !same_owner_support & !same_applicant_support &
        filing_days_apart > 30L ~ "exact_99_low_corroboration",
      units_1 == 99L | units_2 == 99L ~ "exact_99",
      !same_owner_support & !same_applicant_support &
        filing_days_apart > 30L ~ "low_corroboration",
      TRUE ~ "standard"
    )
  ) |>
  select(
    parent_id_1,
    parent_id_2,
    job_number_1,
    job_number_2,
    date_filed_1,
    date_filed_2,
    filing_days_apart,
    units_1,
    units_2,
    filing_bbl_1,
    filing_bbl_2,
    site_linkage_bbl_1,
    site_linkage_bbl_2,
    strict_lot_history_link,
    explicit_job_reference,
    same_project_code,
    same_owner_support,
    same_applicant_support,
    same_bin,
    same_filing_block,
    consecutive_filing_lots,
    same_address,
    corroborated_exact_adjacency,
    link_reason,
    manual_review_priority,
    filing_status_1,
    filing_status_2,
    address_1,
    address_2,
    borough_1,
    borough_2,
    block_1,
    block_2,
    lot_1,
    lot_2,
    bbl_field_relation_1,
    bbl_field_relation_2,
    bin_1,
    bin_2,
    owner_1,
    owner_2,
    applicant_1,
    applicant_2,
    proposed_stories_1,
    proposed_stories_2,
    construction_floor_area_1,
    construction_floor_area_2,
    job_description_1,
    job_description_2
  ) |>
  arrange(date_filed_1, job_number_1, date_filed_2, job_number_2)

post_site_linkage_bbl_parent_review <- membership |>
  filter(
    sample == "post_policy",
    parent_id %in% unique(post_site_linkage_bbl_links$parent_id_1)
  ) |>
  left_join(
    dob_initial |>
      select(
        job_number = job_filing_number,
        filing_status,
        address,
        bbl_field_relation,
        owner_business_name,
        applicant_business_name,
        job_description
      ),
    by = "job_number",
    relationship = "many-to-one"
  ) |>
  arrange(parent_id, date_filed, job_number) |>
  group_by(parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    source_filings = n(),
    observed_filings = first(parent_observed_filings),
    observed_units = first(parent_observed_units),
    exact_99_filings = sum(
      hdb_priority_units == 99L & additive_component,
      na.rm = TRUE
    ),
    component_jobs = paste(job_number, collapse = ";"),
    component_dates = paste(date_filed, collapse = ";"),
    component_units = paste(hdb_priority_units, collapse = ";"),
    component_filing_roles = paste(filing_role, collapse = ";"),
    component_replacement_jobs = paste(
      coalesce(replacement_job_number, "none"),
      collapse = ";"
    ),
    filing_bbls = paste(filing_bbl, collapse = ";"),
    site_linkage_bbls = paste(site_linkage_bbl, collapse = ";"),
    bbl_field_relations = paste(bbl_field_relation, collapse = ";"),
    filing_statuses = paste(filing_status, collapse = ";"),
    addresses = paste(address, collapse = ";"),
    owners = paste(owner_business_name, collapse = ";"),
    applicants = paste(applicant_business_name, collapse = ";"),
    job_descriptions = paste(job_description, collapse = " | "),
    .groups = "drop"
  ) |>
  left_join(
    post_site_linkage_bbl_links |>
      group_by(parent_id = parent_id_1) |>
      summarise(
        reviewed_pair_count = n(),
        same_owner_pairs = sum(same_owner_support),
        same_applicant_pairs = sum(same_applicant_support),
        pairs_within_30_days = sum(filing_days_apart <= 30L),
        low_corroboration_pairs = sum(
          !same_owner_support & !same_applicant_support &
            filing_days_apart > 30L
        ),
        .groups = "drop"
      ),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    manual_review_priority = case_when(
      exact_99_filings > 0L & low_corroboration_pairs > 0L ~
        "exact_99_low_corroboration",
      exact_99_filings > 0L ~ "exact_99",
      low_corroboration_pairs > 0L ~ "low_corroboration",
      TRUE ~ "standard"
    )
  ) |>
  arrange(
    factor(
      manual_review_priority,
      c(
        "exact_99_low_corroboration",
        "exact_99",
        "low_corroboration",
        "standard"
      )
    ),
    cohort_date,
    parent_id
  )

signals <- c(
  "same_filing_bbl",
  "same_site_linkage_bbl",
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
    "reviewed_post_parents",
    "accepted_post_parent_groupings",
    "rejected_post_parent_groupings",
    "unresolved_post_parent_groupings",
    "superseded_post_filings",
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
    nrow(post_parent_reviews),
    sum(post_parent_reviews$review_decision == "accept"),
    sum(post_parent_reviews$review_decision == "reject"),
    sum(post_parent_reviews$review_decision == "unresolved"),
    nrow(post_filing_roles),
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

write_csv_atomic(
  cohort_inventory,
  "../output/symmetric_parent_cohort_inventory.csv"
)
write_csv_atomic(
  exact_99_paths,
  "../output/symmetric_parent_2025_exact_99_paths.csv"
)
write_csv_atomic(
  exact_99_paths_dob_i1,
  "../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv"
)
write_csv_atomic(
  post_site_linkage_bbl_links,
  "../output/post_site_linkage_bbl_links.csv"
)
write_csv_atomic(
  post_site_linkage_bbl_parent_review,
  "../output/post_site_linkage_bbl_parent_review.csv"
)
write_csv_atomic(
  post_parent_reviews,
  "../output/post_parent_review_decisions.csv"
)
write_csv_atomic(
  link_summary,
  "../output/symmetric_parent_link_summary.csv"
)
write_csv_atomic(
  cohort_summary,
  "../output/symmetric_parent_cohort_summary.csv"
)
write_csv_atomic(
  cohort_qc,
  "../output/symmetric_parent_cohort_qc.csv"
)

cat("Wrote symmetric parent-cohort audit outputs to ../output\n")

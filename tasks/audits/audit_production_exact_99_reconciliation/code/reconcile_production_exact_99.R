# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_production_exact_99_reconciliation/code")
# threshold_units <- 100L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Expected one argument: the policy threshold in units.")
}

threshold_units <- as.integer(args[1])

if (is.na(threshold_units) || threshold_units < 2L) {
  stop("The policy threshold must be an integer of at least two units.")
}

bunching_units <- threshold_units - 1L
model_floor <- 6L

hdb_panel <- read_parquet(
  "../input/hdb_mappluto_training_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

model_scores <- read_parquet(
  "../input/enhanced_parent_2025_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble()

model_parameters <- read_csv(
  "../input/enhanced_parent_model_parameters.csv",
  show_col_types = FALSE
)

job_crosswalk <- read_parquet(
  "../input/developer_opportunity_job_crosswalk.parquet"
) |>
  as.data.frame() |>
  as_tibble()

casebook <- read_csv(
  "../input/developer_opportunity_exact_99_casebook.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

candidate_pairs <- read_csv(
  "../input/developer_opportunity_candidate_pairs.csv",
  show_col_types = FALSE
)

broad_membership <- read_parquet(
  "../input/provisional_parent_universal_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

broad_links <- read_parquet(
  "../input/provisional_parent_universal_links.parquet"
) |>
  as.data.frame() |>
  as_tibble()

symmetric_paths <- read_csv(
  "../input/symmetric_parent_2025_exact_99_paths.csv",
  show_col_types = FALSE
)

if (
  anyDuplicated(hdb_panel$job_number) ||
    anyDuplicated(post_panel$observation_id) ||
    anyDuplicated(model_scores$observation_id) ||
    anyDuplicated(job_crosswalk$root_job_id) ||
    anyDuplicated(casebook$root_job_id) ||
    anyDuplicated(broad_membership$root_job_id)
) {
  stop("An input expected to be unique by its parent or root-job key is duplicated.")
}

shock_sigma <- model_parameters |>
  filter(term == "shock_sigma") |>
  pull(estimate)

if (length(shock_sigma) != 1L || !is.finite(shock_sigma) || shock_sigma <= 0) {
  stop("The production model does not contain one valid shock sigma.")
}

production_exact_99 <- post_panel |>
  filter(model_eligible, units_hdb_priority == bunching_units) |>
  select(
    observation_id,
    production_parent_id = parent_id,
    production_first_filing_date = date_filed,
    production_last_filing_date = date_last_filed,
    production_component_filings = component_filings,
    production_component_jobs = component_jobs,
    hdb_priority_units = units_hdb_priority,
    production_dob_i1_units = units_dob_i1,
    production_dob_i1_complete = dob_i1_complete,
    production_feature_lots = feature_lots,
    lotarea,
    residfar,
    builtfar,
    borough,
    zone_detail,
    prior_site_use
  ) |>
  left_join(
    model_scores |>
      select(
        observation_id,
        observed_units,
        predicted_log_units,
        probability_observed,
        probability_exact_99,
        probability_at_least_100
      ),
    by = "observation_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    production_anchor_root_job = str_remove(
      production_parent_id,
      "^post_policy__enhanced_parent__"
    ),
    production_parent_classification = case_when(
      production_component_filings == 1L ~ "single_filing_parent",
      production_component_filings > 1L ~ "multi_filing_parent",
      TRUE ~ "unresolved"
    )
  )

if (
  nrow(production_exact_99) == 0L ||
    any(is.na(production_exact_99$observed_units)) ||
    any(production_exact_99$observed_units != bunching_units) ||
    anyDuplicated(production_exact_99$production_anchor_root_job)
) {
  stop("The production exact-99 sample failed definition or key QC.")
}

anchor_job_fields <- job_crosswalk |>
  transmute(
    production_anchor_root_job = root_job_id,
    dob_job_filing_number,
    dob_bin,
    filing_date,
    filing_status,
    current_status_date,
    approved_date,
    first_permit_date,
    dob_initial_units = proposed_units,
    dob_bbl,
    historical_appbbl,
    appbbl_date_min,
    address,
    owner_name,
    applicant_name,
    job_description,
    total_construction_floor_area,
    proposed_stories,
    proposed_height,
    crosswalk_eligible_site_status = eligible_site_status
  )

anchor_hdb_fields <- hdb_panel |>
  transmute(
    production_anchor_root_job = job_number,
    hdb_filing_bbl = bbl,
    hdb_pluto_feature_bbl = pluto_feature_bbl,
    hdb_pluto_match_method = pluto_match_method,
    hdb_pluto_feature_bbl_rows = pluto_feature_bbl_hdb_rows,
    hdb_pluto_version = pluto_version_used,
    hdb_primary_leakage_safe_sample = primary_leakage_safe_sample
  )

casebook_fields <- casebook |>
  transmute(
    production_anchor_root_job = root_job_id,
    casebook_review_priority = case_review_priority,
    casebook_candidate_parent_id = candidate_parent_opportunity_id,
    casebook_parent_structure = candidate_parent_structure,
    casebook_grouping_evidence_tier = grouping_evidence_tier,
    casebook_common_parent_assessment = common_parent_assessment,
    casebook_avoidance_assessment = avoidance_assessment,
    casebook_investigation_status = investigation_status,
    casebook_investigation_note = investigation_note,
    external_evidence_status,
    external_evidence_note,
    external_source_url,
    external_parent_source_url,
    external_context_source_url,
    legal_485x_site_status,
    rental_485x_eligibility_status,
    next_record_needed
  )

production_component_lists <- strsplit(
  post_panel$component_jobs,
  ";",
  fixed = TRUE
)

production_membership <- tibble(
  root_job_id = unlist(production_component_lists, use.names = FALSE),
  member_production_parent_id = rep(
    post_panel$parent_id,
    lengths(production_component_lists)
  )
)

if (anyDuplicated(production_membership$root_job_id)) {
  stop("A root job belongs to more than one production parent.")
}

broad_parent_jobs <- broad_membership |>
  left_join(
    job_crosswalk |>
      select(
        root_job_id,
        dob_job_filing_number,
        filing_status,
        approved_date,
        first_permit_date,
        total_construction_floor_area,
        proposed_stories
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    hdb_panel |>
      transmute(
        root_job_id = job_number,
        hdb_pluto_feature_bbl = pluto_feature_bbl
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    production_membership,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  arrange(provisional_parent_opportunity_id, filing_date, root_job_id) |>
  group_by(provisional_parent_opportunity_id) |>
  summarise(
    broad_parent_classification = first(parent_structure),
    broad_component_filings = n(),
    broad_component_jobs = paste(root_job_id, collapse = ";"),
    broad_component_filing_numbers = paste(
      dob_job_filing_number,
      collapse = ";"
    ),
    broad_component_units = paste(proposed_units, collapse = ";"),
    broad_component_filing_years = paste(filing_year, collapse = ";"),
    broad_parent_dob_units = sum(proposed_units),
    broad_exact_99_dob_filings = sum(proposed_units == bunching_units),
    broad_distinct_bbls = n_distinct(dob_bbl, na.rm = TRUE),
    broad_distinct_hdb_feature_bbls = n_distinct(
      hdb_pluto_feature_bbl,
      na.rm = TRUE
    ),
    broad_component_hdb_feature_bbls = paste(
      paste0(
        root_job_id,
        "=",
        if_else(
          is.na(hdb_pluto_feature_bbl),
          "not_in_hdb_panel",
          hdb_pluto_feature_bbl
        )
      ),
      collapse = ";"
    ),
    broad_components_in_production_panel = sum(
      !is.na(member_production_parent_id)
    ),
    broad_distinct_production_parents = n_distinct(
      member_production_parent_id,
      na.rm = TRUE
    ),
    broad_component_production_parent_map = paste(
      paste0(
        root_job_id,
        "=",
        if_else(
          is.na(member_production_parent_id),
          "not_in_production_panel",
          member_production_parent_id
        )
      ),
      collapse = ";"
    ),
    broad_first_filing_date = min(filing_date),
    broad_last_filing_date = max(filing_date),
    broad_component_filing_dates = paste(
      paste0(root_job_id, "=", filing_date),
      collapse = ";"
    ),
    broad_component_approval_dates = paste(
      paste0(
        root_job_id,
        "=",
        if_else(is.na(approved_date), "missing", as.character(approved_date))
      ),
      collapse = ";"
    ),
    broad_component_first_permit_dates = paste(
      paste0(
        root_job_id,
        "=",
        if_else(
          is.na(first_permit_date),
          "missing",
          as.character(first_permit_date)
        )
      ),
      collapse = ";"
    ),
    broad_component_statuses = paste(
      paste0(
        root_job_id,
        "=",
        if_else(is.na(filing_status), "missing", filing_status)
      ),
      collapse = ";"
    ),
    broad_total_construction_floor_area = if (
      all(is.na(total_construction_floor_area))
    ) {
      NA_real_
    } else {
      sum(total_construction_floor_area, na.rm = TRUE)
    },
    broad_component_stories = paste(
      paste0(
        root_job_id,
        "=",
        if_else(is.na(proposed_stories), "missing", as.character(proposed_stories))
      ),
      collapse = ";"
    ),
    .groups = "drop"
  ) |>
  mutate(
    broad_gross_sf_per_dob_unit =
      broad_total_construction_floor_area / broad_parent_dob_units,
    broad_production_alignment = case_when(
      broad_component_filings == 1L ~ "same_singleton",
      broad_components_in_production_panel < broad_component_filings ~
        "some_broad_components_not_in_production_panel",
      broad_distinct_production_parents > 1L ~
        "broad_components_split_across_production_parents",
      broad_distinct_production_parents == 1L ~
        "broad_components_already_share_production_parent",
      TRUE ~ "unresolved_production_alignment"
    )
  )

broad_link_edges <- broad_links |>
  left_join(
    broad_membership |>
      select(
        root_job_id_1 = root_job_id,
        provisional_parent_opportunity_id_1 = provisional_parent_opportunity_id
      ),
    by = "root_job_id_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    broad_membership |>
      select(
        root_job_id_2 = root_job_id,
        provisional_parent_opportunity_id_2 = provisional_parent_opportunity_id
      ),
    by = "root_job_id_2",
    relationship = "many-to-one"
  )

if (any(
  broad_link_edges$provisional_parent_opportunity_id_1 !=
    broad_link_edges$provisional_parent_opportunity_id_2
)) {
  stop("A broad parent link joins jobs assigned to different broad parents.")
}

broad_link_edges <- broad_link_edges |>
  rowwise() |>
  mutate(
    link_reason = paste(
      c(
        "same_filing_bbl",
        "same_lot_history_group",
        "same_owner_within_100m",
        "dob_description_cross_reference",
        "same_dob_project_code"
      )[c_across(c(
        same_filing_bbl,
        same_lot_history_group,
        same_owner_nearby,
        description_cross_reference,
        same_description_project_code
      ))],
      collapse = ";"
    ),
    edge_detail = paste0(
      root_job_id_1,
      "--",
      root_job_id_2,
      " [days=",
      filing_days_apart,
      ", distance_m=",
      if_else(is.na(distance_meters), "missing", format(round(distance_meters, 1), trim = TRUE)),
      ", reasons=",
      link_reason,
      "]"
    )
  ) |>
  ungroup() |>
  group_by(
    provisional_parent_opportunity_id = provisional_parent_opportunity_id_1
  ) |>
  summarise(
    broad_parent_link_edges = paste(edge_detail, collapse = " | "),
    broad_parent_link_edge_count = n(),
    broad_has_same_filing_bbl_link = any(same_filing_bbl),
    broad_has_same_lot_history_link = any(same_lot_history_group),
    broad_has_same_owner_nearby_link = any(same_owner_nearby),
    broad_has_description_cross_reference = any(description_cross_reference),
    broad_has_same_project_code = any(same_description_project_code),
    .groups = "drop"
  )

broad_parent_summary <- broad_parent_jobs |>
  left_join(
    broad_link_edges,
    by = "provisional_parent_opportunity_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    broad_parent_link_edge_count = coalesce(broad_parent_link_edge_count, 0L),
    broad_parent_link_edges = coalesce(broad_parent_link_edges, "none"),
    broad_has_same_filing_bbl_link = coalesce(
      broad_has_same_filing_bbl_link,
      FALSE
    ),
    broad_has_same_lot_history_link = coalesce(
      broad_has_same_lot_history_link,
      FALSE
    ),
    broad_has_same_owner_nearby_link = coalesce(
      broad_has_same_owner_nearby_link,
      FALSE
    ),
    broad_has_description_cross_reference = coalesce(
      broad_has_description_cross_reference,
      FALSE
    ),
    broad_has_same_project_code = coalesce(
      broad_has_same_project_code,
      FALSE
    ),
    broad_rule_evidence_tier = case_when(
      broad_parent_link_edge_count == 0L ~ "no_accepted_broad_link",
      broad_has_same_filing_bbl_link |
        broad_has_same_lot_history_link |
        broad_has_description_cross_reference |
        broad_has_same_project_code ~ "broad_direct_field_or_reference",
      broad_has_same_owner_nearby_link ~ "same_owner_proximity_only",
      TRUE ~ "unresolved_broad_link"
    )
  )

candidate_pair_endpoints <- bind_rows(
  candidate_pairs |>
    transmute(
      production_anchor_root_job = root_job_id_1,
      linked_job = root_job_id_2,
      filing_days_apart,
      distance_meters,
      strong_parent_link,
      candidate_reason,
      review_priority
    ),
  candidate_pairs |>
    transmute(
      production_anchor_root_job = root_job_id_2,
      linked_job = root_job_id_1,
      filing_days_apart,
      distance_meters,
      strong_parent_link,
      candidate_reason,
      review_priority
    )
) |>
  semi_join(
    production_exact_99 |>
      select(production_anchor_root_job),
    by = "production_anchor_root_job"
  ) |>
  distinct() |>
  arrange(production_anchor_root_job, desc(strong_parent_link), linked_job) |>
  mutate(
    candidate_pair_detail = paste0(
      linked_job,
      " [days=",
      filing_days_apart,
      ", distance_m=",
      if_else(is.na(distance_meters), "missing", format(round(distance_meters, 1), trim = TRUE)),
      ", accepted_by_casebook_rule=",
      strong_parent_link,
      ", reasons=",
      candidate_reason,
      ", priority=",
      review_priority,
      "]"
    )
  ) |>
  group_by(production_anchor_root_job) |>
  summarise(
    all_candidate_pair_details = paste(candidate_pair_detail, collapse = " | "),
    accepted_candidate_pairs = sum(strong_parent_link),
    review_only_candidate_pairs = sum(!strong_parent_link),
    .groups = "drop"
  )

broad_anchor_membership <- broad_membership |>
  transmute(
    production_anchor_root_job = root_job_id,
    broad_parent_id = provisional_parent_opportunity_id
  )

symmetric_path_fields <- symmetric_paths |>
  filter(unit_definition == "hdb_priority") |>
  semi_join(
    production_exact_99 |>
      select(production_anchor_root_job),
    by = c("exact_99_root_job_id" = "production_anchor_root_job")
  ) |>
  transmute(
    production_anchor_root_job = exact_99_root_job_id,
    symmetric_365_parent_id = parent_id,
    symmetric_365_parent_component_jobs = component_root_jobs,
    symmetric_365_parent_observed_filings = parent_observed_filings,
    symmetric_365_parent_observed_units = parent_observed_units,
    symmetric_365_direct_linked_jobs = directly_linked_jobs,
    symmetric_365_direct_link_reasons = direct_link_reasons,
    symmetric_365_cohort_date = cohort_date,
    symmetric_365_parent_last_filing_date = parent_last_filing_date,
    symmetric_365_source_end_date = source_end_date,
    symmetric_365_full_window_observed = full_window_observed,
    symmetric_365_analysis_status = analysis_status
  )

if (anyDuplicated(symmetric_path_fields$production_anchor_root_job)) {
  stop("The symmetric cohort audit is not unique for the production exact-99 roots.")
}

reconciliation <- production_exact_99 |>
  left_join(
    anchor_job_fields,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    anchor_hdb_fields,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    casebook_fields,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    broad_anchor_membership,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    broad_parent_summary,
    by = c(
      "broad_parent_id" = "provisional_parent_opportunity_id"
    ),
    relationship = "many-to-one"
  ) |>
  left_join(
    candidate_pair_endpoints,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  left_join(
    symmetric_path_fields,
    by = "production_anchor_root_job",
    relationship = "one-to-one"
  ) |>
  mutate(
    hdb_dob_initial_units_agree = hdb_priority_units == dob_initial_units,
    hdb_dob_filing_bbl_agree = hdb_filing_bbl == dob_bbl,
    anchor_forward_365_window_complete =
      filing_date + 365 <= symmetric_365_source_end_date,
    anchor_gross_sf_per_hdb_unit =
      total_construction_floor_area / hdb_priority_units,
    anchor_gross_sf_per_dob_unit =
      total_construction_floor_area / dob_initial_units,
    all_candidate_pair_details = coalesce(all_candidate_pair_details, "none"),
    accepted_candidate_pairs = coalesce(accepted_candidate_pairs, 0L),
    review_only_candidate_pairs = coalesce(review_only_candidate_pairs, 0L),
    legal_485x_site_status = coalesce(
      legal_485x_site_status,
      crosswalk_eligible_site_status,
      "not_legally_validated"
    ),
    rental_485x_eligibility_status = coalesce(
      rental_485x_eligibility_status,
      "not_validated"
    ),
    next_record_needed = case_when(
      !is.na(next_record_needed) ~ next_record_needed,
      !hdb_dob_initial_units_agree ~ paste(
        "Resolve HDB/DOB initial-unit disagreement;",
        "DOB amendment history; HPD registration/docket"
      ),
      TRUE ~ "HPD registration/docket; DOB zoning-lot plans"
    )
  )

floor_z <- (
  log(model_floor - 0.5) - reconciliation$predicted_log_units
) / shock_sigma
floor_cdf <- pnorm(floor_z)
conditioning_probability <- 1 - floor_cdf

reconciliation <- reconciliation |>
  mutate(
    model_no_notch_q10_units = pmax(
      model_floor,
      floor(exp(
        predicted_log_units + shock_sigma * qnorm(
          floor_cdf + 0.10 * conditioning_probability
        )
      ) + 0.5)
    ),
    model_no_notch_median_units = pmax(
      model_floor,
      floor(exp(
        predicted_log_units + shock_sigma * qnorm(
          floor_cdf + 0.50 * conditioning_probability
        )
      ) + 0.5)
    ),
    model_no_notch_q90_units = pmax(
      model_floor,
      floor(exp(
        predicted_log_units + shock_sigma * qnorm(
          floor_cdf + 0.90 * conditioning_probability
        )
      ) + 0.5)
    ),
    model_probability_n0_6_98 = (
      pnorm((log(98.5) - predicted_log_units) / shock_sigma) - floor_cdf
    ) / conditioning_probability,
    model_probability_n0_99 = probability_exact_99,
    model_probability_n0_100_119 = (
      pnorm((log(119.5) - predicted_log_units) / shock_sigma) -
        pnorm((log(99.5) - predicted_log_units) / shock_sigma)
    ) / conditioning_probability,
    model_probability_n0_120_149 = (
      pnorm((log(149.5) - predicted_log_units) / shock_sigma) -
        pnorm((log(119.5) - predicted_log_units) / shock_sigma)
    ) / conditioning_probability,
    model_probability_n0_150_plus = pnorm(
      (log(149.5) - predicted_log_units) / shock_sigma,
      lower.tail = FALSE
    ) / conditioning_probability,
    model_probability_bin_sum =
      model_probability_n0_6_98 +
      model_probability_n0_99 +
      model_probability_n0_100_119 +
      model_probability_n0_120_149 +
      model_probability_n0_150_plus,
    casebook_match_status = if_else(
      is.na(casebook_review_priority),
      "not_in_dob_exact_99_casebook",
      "matched_dob_exact_99_casebook"
    ),
    parent_definition_comparison = case_when(
      production_component_filings > 1L ~ "linked_in_production_definition",
      broad_component_filings > 1L &
        symmetric_365_parent_observed_filings > 1L ~
        "linked_by_broad_and_symmetric_365_definitions",
      broad_component_filings > 1L &
        symmetric_365_parent_observed_filings == 1L ~
        "linked_only_by_broad_sensitivity",
      broad_component_filings == 1L &
        symmetric_365_parent_observed_filings > 1L ~
        "linked_only_by_symmetric_365_definition",
      broad_component_filings == 1L &
        symmetric_365_parent_observed_filings == 1L ~
        "unlinked_by_both_audit_definitions",
      TRUE ~ "unresolved_definition_comparison"
    ),
    production_parent_reconciliation = case_when(
      production_component_filings > 1L ~
        "production_parent_already_multi_filing",
      symmetric_365_parent_observed_filings > 1L &
        broad_components_in_production_panel == broad_component_filings ~
        "symmetric_direct_parent_but_components_split_in_production",
      symmetric_365_parent_observed_filings > 1L &
        broad_components_in_production_panel < broad_component_filings ~
        "symmetric_direct_parent_has_components_outside_production",
      broad_component_filings > 1L ~
        "candidate_parent_only_under_broad_sensitivity",
      TRUE ~ "consistent_singleton_across_definitions"
    ),
    review_priority = case_when(
      broad_parent_classification == "repeated_99_parent" ~
        "1_broad_repeated_99_parent",
      broad_parent_classification == "one_99_with_other_jobs" ~
        "2_broad_parent_with_other_jobs",
      broad_parent_classification == "multiple_jobs_without_99" ~
        "3_hdb_dob_source_disagreement_parent",
      !symmetric_365_full_window_observed ~
        "4_unlinked_incomplete_365_window",
      review_only_candidate_pairs > 0L ~
        "5_unlinked_review_only_candidate",
      TRUE ~ "6_unlinked_complete_365_window"
    )
  ) |>
  select(
    review_priority,
    production_parent_id,
    production_anchor_root_job,
    production_component_jobs,
    production_component_filings,
    production_parent_classification,
    broad_parent_id,
    broad_parent_classification,
    broad_component_jobs,
    broad_component_filing_numbers,
    broad_component_filings,
    broad_component_units,
    broad_component_filing_years,
    broad_parent_dob_units,
    broad_exact_99_dob_filings,
    broad_distinct_bbls,
    broad_distinct_hdb_feature_bbls,
    broad_component_hdb_feature_bbls,
    broad_components_in_production_panel,
    broad_distinct_production_parents,
    broad_component_production_parent_map,
    broad_production_alignment,
    broad_parent_link_edge_count,
    broad_rule_evidence_tier,
    broad_has_same_filing_bbl_link,
    broad_has_same_lot_history_link,
    broad_has_same_owner_nearby_link,
    broad_has_description_cross_reference,
    broad_has_same_project_code,
    broad_parent_link_edges,
    all_candidate_pair_details,
    accepted_candidate_pairs,
    review_only_candidate_pairs,
    symmetric_365_parent_id,
    symmetric_365_parent_component_jobs,
    symmetric_365_parent_observed_filings,
    symmetric_365_parent_observed_units,
    symmetric_365_direct_linked_jobs,
    symmetric_365_direct_link_reasons,
    symmetric_365_cohort_date,
    symmetric_365_parent_last_filing_date,
    symmetric_365_source_end_date,
    symmetric_365_full_window_observed,
    symmetric_365_analysis_status,
    anchor_forward_365_window_complete,
    parent_definition_comparison,
    production_parent_reconciliation,
    dob_job_filing_number,
    dob_bin,
    filing_date,
    filing_status,
    current_status_date,
    approved_date,
    first_permit_date,
    broad_first_filing_date,
    broad_last_filing_date,
    broad_component_filing_dates,
    broad_component_approval_dates,
    broad_component_first_permit_dates,
    broad_component_statuses,
    hdb_priority_units,
    dob_initial_units,
    production_dob_i1_units,
    production_dob_i1_complete,
    hdb_dob_initial_units_agree,
    dob_bbl,
    hdb_filing_bbl,
    hdb_dob_filing_bbl_agree,
    hdb_pluto_feature_bbl,
    hdb_pluto_match_method,
    hdb_pluto_feature_bbl_rows,
    hdb_pluto_version,
    hdb_primary_leakage_safe_sample,
    historical_appbbl,
    appbbl_date_min,
    address,
    owner_name,
    applicant_name,
    total_construction_floor_area,
    proposed_stories,
    proposed_height,
    anchor_gross_sf_per_hdb_unit,
    anchor_gross_sf_per_dob_unit,
    broad_total_construction_floor_area,
    broad_component_stories,
    broad_gross_sf_per_dob_unit,
    production_feature_lots,
    lotarea,
    residfar,
    builtfar,
    borough,
    zone_detail,
    prior_site_use,
    predicted_log_units,
    model_no_notch_q10_units,
    model_no_notch_median_units,
    model_no_notch_q90_units,
    probability_observed,
    model_probability_n0_6_98,
    model_probability_n0_99,
    model_probability_n0_100_119,
    model_probability_n0_120_149,
    model_probability_n0_150_plus,
    probability_at_least_100,
    model_probability_bin_sum,
    casebook_match_status,
    casebook_review_priority,
    casebook_candidate_parent_id,
    casebook_parent_structure,
    casebook_grouping_evidence_tier,
    casebook_common_parent_assessment,
    casebook_avoidance_assessment,
    casebook_investigation_status,
    casebook_investigation_note,
    external_evidence_status,
    external_evidence_note,
    external_source_url,
    external_parent_source_url,
    external_context_source_url,
    legal_485x_site_status,
    rental_485x_eligibility_status,
    next_record_needed,
    job_description
  ) |>
  arrange(review_priority, filing_date, production_anchor_root_job)

if (
  nrow(reconciliation) != nrow(production_exact_99) ||
    anyDuplicated(reconciliation$production_parent_id) ||
    any(is.na(reconciliation$dob_initial_units)) ||
    any(is.na(reconciliation$hdb_pluto_feature_bbl)) ||
    any(is.na(reconciliation$broad_parent_id)) ||
    any(is.na(reconciliation$symmetric_365_analysis_status)) ||
    any(abs(reconciliation$model_probability_bin_sum - 1) > 1e-8)
) {
  stop("The final production exact-99 reconciliation failed row, join, or probability QC.")
}

casebook_unmatched <- reconciliation |>
  filter(casebook_match_status == "not_in_dob_exact_99_casebook")

if (
  nrow(casebook_unmatched) > 0L &&
    any(casebook_unmatched$hdb_dob_initial_units_agree)
) {
  stop("An HDB/DOB-agreeing exact-99 parent is unexpectedly absent from the DOB casebook.")
}

qc <- bind_rows(
  tibble(
    section = "sample",
    metric = c(
      "production_exact_99_parents",
      "unique_production_parent_ids",
      "single_filing_production_parents",
      "matched_anchor_jobs",
      "matched_dob_exact_99_casebook_rows",
      "hdb_dob_initial_unit_agreements",
      "hdb_dob_initial_unit_disagreements",
      "hdb_dob_filing_bbl_agreements",
      "hdb_dob_filing_bbl_disagreements"
    ),
    value = c(
      nrow(reconciliation),
      n_distinct(reconciliation$production_parent_id),
      sum(reconciliation$production_parent_classification == "single_filing_parent"),
      sum(!is.na(reconciliation$dob_initial_units)),
      sum(reconciliation$casebook_match_status == "matched_dob_exact_99_casebook"),
      sum(reconciliation$hdb_dob_initial_units_agree),
      sum(!reconciliation$hdb_dob_initial_units_agree),
      sum(reconciliation$hdb_dob_filing_bbl_agree),
      sum(!reconciliation$hdb_dob_filing_bbl_agree)
    )
  ),
  reconciliation |>
    count(broad_parent_classification, name = "value") |>
    transmute(
      section = "broad_parent_classification",
      metric = broad_parent_classification,
      value
    ),
  reconciliation |>
    count(symmetric_365_analysis_status, name = "value") |>
    transmute(
      section = "cohort_observability",
      metric = symmetric_365_analysis_status,
      value
    ),
  reconciliation |>
    count(parent_definition_comparison, name = "value") |>
    transmute(
      section = "parent_definition_comparison",
      metric = parent_definition_comparison,
      value
    ),
  reconciliation |>
    count(production_parent_reconciliation, name = "value") |>
    transmute(
      section = "production_parent_reconciliation",
      metric = production_parent_reconciliation,
      value
    ),
  tibble(
    section = "coverage",
    metric = c(
      "complete_symmetric_365_windows",
      "incomplete_symmetric_365_windows",
      "complete_anchor_forward_365_windows",
      "incomplete_anchor_forward_365_windows",
      "parents_with_broad_link_edges",
      "parents_with_review_only_candidate_pairs",
      "unlinked_parents_with_review_only_candidate_pairs",
      "distinct_broad_multi_parent_groups",
      "distinct_symmetric_multi_parent_groups",
      "anchor_jobs_approved",
      "anchor_jobs_with_first_permit",
      "missing_gross_floor_area",
      "missing_proposed_stories",
      "legally_validated_485x_sites",
      "probability_bins_sum_to_one"
    ),
    value = c(
      sum(reconciliation$symmetric_365_full_window_observed),
      sum(!reconciliation$symmetric_365_full_window_observed),
      sum(reconciliation$anchor_forward_365_window_complete),
      sum(!reconciliation$anchor_forward_365_window_complete),
      sum(reconciliation$broad_parent_link_edge_count > 0L),
      sum(reconciliation$review_only_candidate_pairs > 0L),
      sum(
        reconciliation$broad_component_filings == 1L &
          reconciliation$review_only_candidate_pairs > 0L
      ),
      n_distinct(
        reconciliation$broad_parent_id[
          reconciliation$broad_component_filings > 1L
        ]
      ),
      n_distinct(
        reconciliation$symmetric_365_parent_id[
          reconciliation$symmetric_365_parent_observed_filings > 1L
        ]
      ),
      sum(!is.na(reconciliation$approved_date)),
      sum(!is.na(reconciliation$first_permit_date)),
      sum(is.na(reconciliation$total_construction_floor_area)),
      sum(is.na(reconciliation$proposed_stories)),
      sum(reconciliation$legal_485x_site_status != "not_validated" &
        reconciliation$legal_485x_site_status != "not_legally_validated"),
      sum(abs(reconciliation$model_probability_bin_sum - 1) <= 1e-8)
    )
  )
)

write_csv_if_changed(
  reconciliation,
  "../output/production_exact_99_reconciliation.csv"
)
write_csv_if_changed(
  qc,
  "../output/production_exact_99_reconciliation_qc.csv"
)

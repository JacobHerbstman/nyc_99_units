# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_production_exact_99_reconciliation/code")
# threshold_units <- 100L
# post_year <- 2025L
# maturity_days <- 180L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected the policy threshold, post year, and maturity days.")
}

threshold_units <- as.integer(args[1])
post_year <- as.integer(args[2])
maturity_days <- as.integer(args[3])

if (
  is.na(threshold_units) || threshold_units < 2L ||
    is.na(post_year) ||
    is.na(maturity_days) || maturity_days < 1L || maturity_days >= 365L
) {
  stop("The policy threshold and post year are invalid.")
}

bunch_units <- threshold_units - 1L
model_floor <- 6L

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

if (
  anyDuplicated(post_panel$observation_id) ||
    anyDuplicated(model_scores$observation_id) ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    anyDuplicated(links[c("sample", "job_number_1", "job_number_2")]) ||
    anyDuplicated(job_crosswalk$root_job_id) ||
    anyDuplicated(casebook$root_job_id) ||
    anyDuplicated(broad_membership$root_job_id) ||
    anyDuplicated(broad_links[c("root_job_id_1", "root_job_id_2")])
) {
  stop("An exact-99 reconciliation input failed identifier QC.")
}

shock_sigma <- model_parameters |>
  filter(term == "shock_sigma") |>
  pull(estimate)

if (length(shock_sigma) != 1L || !is.finite(shock_sigma) || shock_sigma <= 0) {
  stop("The production model does not contain one valid shock sigma.")
}

post_followup <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(
    parent_id, cohort_date, source_end_date,
    left_window_observed
  ) |>
  mutate(observed_followup_days = as.integer(source_end_date - cohort_date))

if (
  anyDuplicated(post_followup$parent_id) ||
    any(is.na(post_followup$observed_followup_days))
) {
  stop("Post-policy follow-up is not unique and complete by parent.")
}

production_parents <- post_panel |>
  left_join(
    post_followup |>
      select(parent_id, observed_followup_days, left_window_observed),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(
    model_eligible,
    cohort_year == post_year,
    left_window_observed,
    observed_followup_days >= maturity_days,
    units_hdb_priority == bunch_units
  ) |>
  select(
    observation_id,
    production_parent_id = parent_id,
    analysis_status,
    cohort_date,
    date_last_filed,
    observed_followup_days,
    left_window_observed,
    component_filings,
    component_jobs,
    hdb_priority_units = units_hdb_priority,
    dob_i1_units = units_dob_i1,
    feature_lots,
    feature_methods,
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
  )

parent_members <- membership |>
  filter(sample == "post_policy") |>
  semi_join(
    production_parents |>
      select(parent_id = production_parent_id),
    by = "parent_id"
  ) |>
  left_join(
    job_crosswalk |>
      select(
        root_job_id,
        dob_job_filing_number,
        filing_status,
        current_status_date,
        approved_date,
        first_permit_date,
        dob_initial_units = proposed_units,
        dob_bbl,
        historical_appbbl,
        address,
        owner_name,
        applicant_name,
        job_description,
        total_construction_floor_area,
        proposed_stories,
        proposed_height,
        crosswalk_eligible_site_status = eligible_site_status
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    casebook |>
      transmute(
        root_job_id,
        casebook_match = TRUE,
        external_evidence_status,
        external_evidence_note,
        external_source_url,
        legal_485x_site_status,
        rental_485x_eligibility_status,
        next_record_needed
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  arrange(parent_id, date_filed, job_number)

parent_member_summary <- parent_members |>
  group_by(parent_id) |>
  summarise(
    component_root_jobs = paste(root_job_id, collapse = ";"),
    component_filing_ids = paste(job_number, collapse = ";"),
    component_units_hdb_priority = paste(hdb_priority_units, collapse = ";"),
    component_units_dob_i1 = paste(dob_i1_units, collapse = ";"),
    component_unit_sources = paste(unit_source, collapse = ";"),
    component_filing_bbls = paste(filing_bbl, collapse = ";"),
    component_filing_dates = paste(date_filed, collapse = ";"),
    component_approval_dates = paste(
      coalesce(as.character(approved_date), "missing"),
      collapse = ";"
    ),
    component_first_permit_dates = paste(
      coalesce(as.character(first_permit_date), "missing"),
      collapse = ";"
    ),
    component_statuses = paste(
      coalesce(filing_status, "missing"),
      collapse = ";"
    ),
    component_addresses = paste(
      coalesce(address, "missing"),
      collapse = " | "
    ),
    component_owners = paste(
      coalesce(owner_name, "missing"),
      collapse = " | "
    ),
    component_applicants = paste(
      coalesce(applicant_name, "missing"),
      collapse = " | "
    ),
    component_descriptions = paste(
      coalesce(job_description, "missing"),
      collapse = " | "
    ),
    component_stories = paste(
      coalesce(as.character(proposed_stories), "missing"),
      collapse = ";"
    ),
    total_construction_floor_area = if (
      all(is.na(total_construction_floor_area))
    ) {
      NA_real_
    } else {
      sum(total_construction_floor_area, na.rm = TRUE)
    },
    hdb_dob_component_unit_disagreements = sum(
      hdb_priority_units != dob_i1_units
    ),
    any_casebook_match = any(coalesce(casebook_match, FALSE)),
    external_evidence_status = paste(
      sort(unique(external_evidence_status[!is.na(external_evidence_status)])),
      collapse = ";"
    ),
    external_evidence_note = paste(
      sort(unique(external_evidence_note[!is.na(external_evidence_note)])),
      collapse = " | "
    ),
    external_source_url = paste(
      sort(unique(external_source_url[!is.na(external_source_url)])),
      collapse = ";"
    ),
    legal_485x_site_status = paste(
      sort(unique(legal_485x_site_status[!is.na(legal_485x_site_status)])),
      collapse = ";"
    ),
    rental_485x_eligibility_status = paste(
      sort(unique(
        rental_485x_eligibility_status[
          !is.na(rental_485x_eligibility_status)
        ]
      )),
      collapse = ";"
    ),
    next_record_needed = paste(
      sort(unique(next_record_needed[!is.na(next_record_needed)])),
      collapse = " | "
    ),
    .groups = "drop"
  )

parent_for_job <- membership |>
  filter(sample == "post_policy") |>
  select(job_number, parent_id)

parent_link_summary <- links |>
  filter(sample == "post_policy") |>
  left_join(
    parent_for_job |>
      rename(job_number_1 = job_number, parent_id_1 = parent_id),
    by = "job_number_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    parent_for_job |>
      rename(job_number_2 = job_number, parent_id_2 = parent_id),
    by = "job_number_2",
    relationship = "many-to-one"
  ) |>
  filter(parent_id_1 == parent_id_2) |>
  semi_join(
    production_parents |>
      select(parent_id_1 = production_parent_id),
    by = "parent_id_1"
  ) |>
  mutate(
    link_detail = paste0(
      job_number_1,
      "--",
      job_number_2,
      " [days=",
      filing_days_apart,
      ", reasons=",
      link_reason,
      "]"
    )
  ) |>
  group_by(parent_id = parent_id_1) |>
  summarise(
    accepted_link_count = n(),
    accepted_link_details = paste(link_detail, collapse = " | "),
    .groups = "drop"
  )

target_roots <- parent_members |>
  distinct(production_parent_id = parent_id, root_job_id)

broad_parent_summary <- target_roots |>
  left_join(
    broad_membership |>
      select(
        root_job_id,
        broad_parent_id = provisional_parent_opportunity_id,
        broad_parent_classification = parent_structure,
        broad_component_root_jobs = root_job_ids,
        broad_component_units = all_dob_proposed_units,
        broad_first_filing_date = first_filing_date,
        broad_last_filing_date = last_filing_date
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  group_by(production_parent_id) |>
  summarise(
    broad_parent_ids = paste(
      sort(unique(broad_parent_id[!is.na(broad_parent_id)])),
      collapse = ";"
    ),
    broad_parent_classifications = paste(
      sort(unique(
        broad_parent_classification[!is.na(broad_parent_classification)]
      )),
      collapse = ";"
    ),
    broad_component_root_jobs = paste(
      sort(unique(
        broad_component_root_jobs[!is.na(broad_component_root_jobs)]
      )),
      collapse = " | "
    ),
    broad_component_units = paste(
      sort(unique(broad_component_units[!is.na(broad_component_units)])),
      collapse = " | "
    ),
    broad_first_filing_date = min(
      broad_first_filing_date,
      na.rm = TRUE
    ),
    broad_last_filing_date = max(
      broad_last_filing_date,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

broad_link_summary <- broad_links |>
  left_join(
    broad_membership |>
      select(
        root_job_id_1 = root_job_id,
        broad_parent_id_1 = provisional_parent_opportunity_id
      ),
    by = "root_job_id_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    broad_membership |>
      select(
        root_job_id_2 = root_job_id,
        broad_parent_id_2 = provisional_parent_opportunity_id
      ),
    by = "root_job_id_2",
    relationship = "many-to-one"
  ) |>
  mutate(
    broad_link_reason = str_remove(
      paste0(
        if_else(same_filing_bbl, "same_filing_bbl;", ""),
        if_else(same_lot_history_group, "same_lot_history_group;", ""),
        if_else(same_owner_nearby, "same_owner_nearby;", ""),
        if_else(
          description_cross_reference,
          "description_cross_reference;",
          ""
        ),
        if_else(
          same_description_project_code,
          "same_description_project_code;",
          ""
        )
      ),
      ";$"
    ),
    broad_link_detail = paste0(
      root_job_id_1,
      "--",
      root_job_id_2,
      " [days=",
      filing_days_apart,
      ", distance_m=",
      if_else(
        is.na(distance_meters),
        "missing",
        as.character(round(distance_meters, 1))
      ),
      ", reasons=",
      broad_link_reason,
      "]"
    )
  ) |>
  group_by(broad_parent_id = broad_parent_id_1) |>
  summarise(
    broad_accepted_link_count = n(),
    broad_accepted_link_details = paste(
      broad_link_detail,
      collapse = " | "
    ),
    all_links_within_broad_parent = all(
      broad_parent_id_1 == broad_parent_id_2
    ),
    .groups = "drop"
  )

if (any(!broad_link_summary$all_links_within_broad_parent)) {
  stop("A broad accepted link crosses broad parent assignments.")
}

broad_link_summary_for_production <- target_roots |>
  left_join(
    broad_membership |>
      select(
        root_job_id,
        broad_parent_id = provisional_parent_opportunity_id
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  distinct(production_parent_id, broad_parent_id) |>
  left_join(
    broad_link_summary |>
      select(
        broad_parent_id,
        broad_accepted_link_count,
        broad_accepted_link_details
      ),
    by = "broad_parent_id",
    relationship = "many-to-one"
  ) |>
  group_by(production_parent_id) |>
  summarise(
    broad_accepted_link_count = sum(
      broad_accepted_link_count,
      na.rm = TRUE
    ),
    broad_accepted_link_details = paste(
      broad_accepted_link_details[!is.na(broad_accepted_link_details)],
      collapse = " | "
    ),
    .groups = "drop"
  )

candidate_link_summary <- bind_rows(
  candidate_pairs |>
    transmute(
      root_job_id = root_job_id_1,
      linked_root_job_id = root_job_id_2,
      filing_days_apart,
      distance_meters,
      strong_parent_link,
      candidate_reason,
      review_priority
    ),
  candidate_pairs |>
    transmute(
      root_job_id = root_job_id_2,
      linked_root_job_id = root_job_id_1,
      filing_days_apart,
      distance_meters,
      strong_parent_link,
      candidate_reason,
      review_priority
    )
) |>
  inner_join(
    target_roots,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    candidate_pair_id = paste(
      pmin(root_job_id, linked_root_job_id),
      pmax(root_job_id, linked_root_job_id),
      sep = "--"
    )
  ) |>
  distinct(
    production_parent_id,
    candidate_pair_id,
    .keep_all = TRUE
  ) |>
  mutate(
    candidate_link_detail = paste0(
      root_job_id,
      "--",
      linked_root_job_id,
      " [days=",
      filing_days_apart,
      ", distance_m=",
      if_else(
        is.na(distance_meters),
        "missing",
        as.character(round(distance_meters, 1))
      ),
      ", accepted_by_broad_rule=",
      strong_parent_link,
      ", reason=",
      candidate_reason,
      ", priority=",
      review_priority,
      "]"
    )
  ) |>
  group_by(production_parent_id) |>
  summarise(
    proposed_candidate_link_count = n(),
    proposed_candidate_link_details = paste(
      candidate_link_detail,
      collapse = " | "
    ),
    review_only_candidate_link_count = sum(
      !coalesce(strong_parent_link, FALSE)
    ),
    .groups = "drop"
  )

reconciliation <- production_parents |>
  left_join(
    parent_member_summary,
    by = c("production_parent_id" = "parent_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    parent_link_summary,
    by = c("production_parent_id" = "parent_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    broad_parent_summary,
    by = "production_parent_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    broad_link_summary_for_production,
    by = "production_parent_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    candidate_link_summary,
    by = "production_parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    parent_structure = if_else(
      component_filings == 1L,
      "single_filing_parent",
      "multi_filing_parent"
    ),
    accepted_link_count = coalesce(accepted_link_count, 0L),
    accepted_link_details = coalesce(accepted_link_details, "none"),
    broad_accepted_link_count = coalesce(
      broad_accepted_link_count,
      0L
    ),
    broad_accepted_link_details = if_else(
      broad_accepted_link_details == "" |
        is.na(broad_accepted_link_details),
      "none",
      broad_accepted_link_details
    ),
    proposed_candidate_link_count = coalesce(
      proposed_candidate_link_count,
      0L
    ),
    proposed_candidate_link_details = coalesce(
      proposed_candidate_link_details,
      "none"
    ),
    review_only_candidate_link_count = coalesce(
      review_only_candidate_link_count,
      0L
    ),
    gross_sf_per_hdb_unit =
      total_construction_floor_area / hdb_priority_units,
    hdb_dob_parent_units_agree = hdb_priority_units == dob_i1_units,
    legal_485x_site_status = na_if(legal_485x_site_status, ""),
    rental_485x_eligibility_status = na_if(
      rental_485x_eligibility_status,
      ""
    ),
    next_record_needed = if_else(
      next_record_needed == "" | is.na(next_record_needed),
      "HPD 485-x docket; DOB zoning-lot plans; commencement record",
      next_record_needed
    )
  )

floor_cdf <- pnorm(
  (log(model_floor - 0.5) - reconciliation$predicted_log_units) /
    shock_sigma
)
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
    )
  ) |>
  arrange(desc(component_filings), cohort_date, production_parent_id)

qc <- tibble(
  check = c(
    paste0("production_mature_", maturity_days, "_exact_99_parents"),
    "matched_model_scores",
    "single_filing_parents",
    "multi_filing_parents",
    "hdb_dob_parent_unit_disagreements",
    "parents_with_casebook_match",
    "parents_in_broad_multi_filing_classification",
    "parents_with_review_only_candidate_links",
    "parents_with_validated_legal_485x_site_status",
    "imputed_companions"
  ),
  value = c(
    nrow(reconciliation),
    sum(!is.na(reconciliation$predicted_log_units)),
    sum(reconciliation$component_filings == 1L),
    sum(reconciliation$component_filings > 1L),
    sum(!reconciliation$hdb_dob_parent_units_agree),
    sum(reconciliation$any_casebook_match),
    sum(str_detect(reconciliation$broad_component_root_jobs, ";")),
    sum(reconciliation$review_only_candidate_link_count > 0L),
    sum(
      !is.na(reconciliation$legal_485x_site_status) &
        !(reconciliation$legal_485x_site_status %in% c(
          "not_validated",
          "not_legally_validated",
          "unvalidated"
        ))
    ),
    0L
  )
)

if (
  nrow(reconciliation) == 0L ||
    nrow(reconciliation) != sum(model_scores$observed_units == bunch_units) ||
    anyDuplicated(reconciliation$production_parent_id) ||
    any(reconciliation$observed_units != bunch_units) ||
    any(is.na(reconciliation$predicted_log_units)) ||
    any(reconciliation$broad_parent_ids == "") ||
    sum(reconciliation$component_filings) != nrow(parent_members) ||
    any(reconciliation$accepted_link_count <
      reconciliation$component_filings - 1L)
) {
  stop("Production exact-99 reconciliation outputs failed final QC.")
}

write_csv_if_changed(
  reconciliation,
  "../output/production_exact_99_reconciliation.csv"
)
write_csv_if_changed(
  qc,
  "../output/production_exact_99_reconciliation_qc.csv"
)

cat("Wrote mature-cohort exact-99 reconciliation to ../output\n")

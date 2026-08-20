# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hpd_485x_registration_linkage/code")
# post_year <- 2025L
# bunching_units <- 99L
# threshold_units <- 100L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected arguments: post_year, bunching_units, threshold_units.")
}

post_year <- as.integer(args[1])
bunching_units <- as.integer(args[2])
threshold_units <- as.integer(args[3])

if (any(is.na(c(post_year, bunching_units, threshold_units)))) {
  stop("Audit arguments must be integers.")
}

hpd_registrations <- read_parquet("../input/hpd_485x_registrations.parquet")
dob_initial <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  mutate(
    job_number = str_squish(job_number),
    job_filing_number = str_squish(job_filing_number),
    bin = str_squish(bin)
  )
symmetric_membership <- read_parquet("../input/symmetric_parent_membership.parquet")
preferred_model_scores <- read_parquet("../input/enhanced_parent_2025_scores.parquet")
candidate_crosswalk <- read_parquet("../input/developer_opportunity_job_crosswalk.parquet")

if (anyDuplicated(hpd_registrations$response_number)) {
  stop("HPD response_number must be unique before linkage.")
}

if (anyDuplicated(dob_initial$job_number)) {
  stop("DOB initial job_number must be unique before linkage.")
}

if (anyDuplicated(preferred_model_scores$observation_id)) {
  stop("Preferred model scores must have one row per parent.")
}

dob_root_lookup <- dob_initial |>
  select(
    root_lookup_job_number = job_number,
    root_lookup_filing_number = job_filing_number,
    root_lookup_bin = bin
  )

dob_bin_lookup <- dob_initial |>
  filter(!is.na(bin), bin != "") |>
  group_by(bin) |>
  summarise(
    bin_initial_job_count = n_distinct(job_number),
    bin_unique_root_job_id = if_else(
      bin_initial_job_count == 1L,
      first(job_number),
      NA_character_
    ),
    .groups = "drop"
  )

if (anyDuplicated(dob_bin_lookup$bin)) {
  stop("DOB BIN lookup must have one row per BIN.")
}

registration_links <- hpd_registrations |>
  left_join(
    dob_root_lookup,
    by = c("dob_now_root_job_id" = "root_lookup_job_number"),
    relationship = "many-to-one"
  ) |>
  left_join(
    dob_bin_lookup,
    by = c("dob_bin" = "bin"),
    relationship = "many-to-one"
  ) |>
  mutate(
    root_job_matches = !is.na(root_lookup_filing_number),
    bin_uniquely_matches = bin_initial_job_count == 1L,
    root_and_bin_agree = root_job_matches & bin_uniquely_matches &
      dob_now_root_job_id == bin_unique_root_job_id,
    link_method = case_when(
      root_and_bin_agree ~ "dob_root_and_bin",
      root_job_matches & is.na(bin_initial_job_count) ~ "dob_root_only_bin_unmatched",
      root_job_matches & bin_initial_job_count > 1L ~ "dob_root_only_bin_nonunique",
      root_job_matches & bin_uniquely_matches ~ "identifier_conflict_unresolved",
      !root_job_matches & bin_uniquely_matches ~ "unique_bin_only",
      !root_job_matches & bin_initial_job_count > 1L ~ "nonunique_bin_unresolved",
      TRUE ~ "unmatched"
    ),
    matched_dob_root_job_id = case_when(
      link_method %in% c(
        "dob_root_and_bin",
        "dob_root_only_bin_unmatched",
        "dob_root_only_bin_nonunique"
      ) ~ dob_now_root_job_id,
      link_method == "unique_bin_only" ~ bin_unique_root_job_id,
      TRUE ~ NA_character_
    ),
    registration_building_key = case_when(
      !is.na(matched_dob_root_job_id) ~ paste0("matched_dob_now:", matched_dob_root_job_id),
      !is.na(dob_now_root_job_id) ~ paste0("reported_dob_now:", dob_now_root_job_id),
      !is.na(dob_bis_job_number) ~ paste0("reported_dob_bis:", dob_bis_job_number),
      TRUE ~ paste0("reported_bin:", dob_bin)
    ),
    intended_separate_sub100_treatment =
      reported_affordability_option == "OPTION B" & reported_units < threshold_units
  ) |>
  group_by(registration_building_key) |>
  arrange(desc(form_submission_timestamp), desc(response_number), .by_group = TRUE) |>
  mutate(
    building_response_count = n(),
    is_latest_building_response = row_number() == 1L
  ) |>
  ungroup() |>
  arrange(response_number)

dob_match_fields <- dob_initial |>
  select(
    matched_dob_root_job_id = job_number,
    matched_dob_filing_number = job_filing_number,
    matched_dob_filing_date = filing_date,
    matched_dob_bin = bin,
    matched_dob_bbl = bbl,
    matched_dob_address = address,
    matched_dob_units = proposed_dwelling_units,
    matched_dob_first_permit_date = first_permit_date
  )

registration_links <- registration_links |>
  left_join(
    dob_match_fields,
    by = "matched_dob_root_job_id",
    relationship = "many-to-one"
  ) |>
  select(
    response_number,
    form_submission_timestamp,
    registration_building_key,
    building_response_count,
    is_latest_building_response,
    link_method,
    matched_dob_root_job_id,
    dob_now_root_job_id,
    dob_bis_job_number,
    dob_bin,
    reported_dob_permit_sequence,
    reported_property_address,
    reported_borough_name,
    reported_bbl,
    presumed_bbl,
    reported_units,
    reported_restricted_units,
    reported_affordability_option,
    reported_commencement_date,
    reported_anticipated_completion_date,
    intended_separate_sub100_treatment,
    matched_dob_filing_number,
    matched_dob_filing_date,
    matched_dob_bin,
    matched_dob_bbl,
    matched_dob_address,
    matched_dob_units,
    matched_dob_first_permit_date,
    root_job_matches,
    bin_uniquely_matches,
    root_and_bin_agree
  )

latest_registration_by_job <- registration_links |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  select(
    matched_dob_root_job_id,
    hpd_response_number = response_number,
    hpd_form_submission_timestamp = form_submission_timestamp,
    hpd_link_method = link_method,
    hpd_reported_bin = dob_bin,
    hpd_reported_bbl = reported_bbl,
    hpd_presumed_bbl = presumed_bbl,
    hpd_reported_units = reported_units,
    hpd_reported_restricted_units = reported_restricted_units,
    hpd_reported_affordability_option = reported_affordability_option,
    hpd_reported_commencement_date = reported_commencement_date,
    hpd_reported_anticipated_completion_date = reported_anticipated_completion_date,
    intended_separate_sub100_treatment
  )

if (anyDuplicated(latest_registration_by_job$matched_dob_root_job_id)) {
  stop("Latest HPD registration must be unique by matched DOB root job.")
}

preferred_model_parents <- preferred_model_scores |>
  select(
    parent_id = observation_id,
    preferred_model_observed_units = observed_units,
    preferred_model_component_filings = component_filings
  )

post_membership_by_job <- symmetric_membership |>
  filter(sample == "post_policy") |>
  select(
    dob_root_job_id = root_job_id,
    symmetric_parent_id = parent_id,
    symmetric_parent_status = analysis_status,
    symmetric_parent_observed_units = parent_observed_units
  ) |>
  distinct() |>
  left_join(
    preferred_model_parents,
    by = c("symmetric_parent_id" = "parent_id"),
    relationship = "many-to-one"
  )

if (anyDuplicated(post_membership_by_job$dob_root_job_id)) {
  stop("Post-policy membership must have one row per DOB root job.")
}

exact_99_buildings <- dob_initial |>
  filter(
    filing_type == "I1",
    lubridate::year(filing_date) == post_year,
    proposed_dwelling_units == bunching_units
  ) |>
  select(
    dob_root_job_id = job_number,
    dob_filing_number = job_filing_number,
    dob_filing_date = filing_date,
    dob_first_permit_date = first_permit_date,
    dob_approved_date = approved_date,
    dob_bin = bin,
    dob_bbl = bbl,
    dob_address = address,
    dob_units = proposed_dwelling_units,
    total_construction_floor_area,
    proposed_stories
  ) |>
  left_join(
    post_membership_by_job,
    by = "dob_root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    latest_registration_by_job,
    by = c("dob_root_job_id" = "matched_dob_root_job_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    observed_in_public_hpd_registrations = !is.na(hpd_response_number),
    in_preferred_180_day_parent_sample = !is.na(preferred_model_observed_units),
    preferred_180_day_parent_exact_99 =
      preferred_model_observed_units == bunching_units,
    hpd_dob_units_agree = if_else(
      observed_in_public_hpd_registrations,
      hpd_reported_units == dob_units,
      NA
    ),
    descriptive_registration_status = case_when(
      !observed_in_public_hpd_registrations ~ "not_observed_in_public_snapshot",
      intended_separate_sub100_treatment & hpd_reported_units == bunching_units ~
        "intended_separate_sub100_treatment",
      intended_separate_sub100_treatment ~ "option_b_sub100_units_disagree",
      TRUE ~ "registered_other_treatment"
    )
  ) |>
  arrange(dob_filing_date, dob_root_job_id)

conservative_components <- symmetric_membership |>
  filter(sample == "post_policy") |>
  transmute(
    parent_definition = "symmetric_parent",
    parent_id,
    parent_status = analysis_status,
    root_job_id,
    filing_date = date_filed,
    filing_year,
    units,
    parent_component_order = member_order
  )

broad_components <- candidate_crosswalk |>
  mutate(
    parent_id = if_else(
      is.na(candidate_parent_opportunity_id),
      paste0("standalone__", root_job_id),
      candidate_parent_opportunity_id
    )
  ) |>
  group_by(parent_id) |>
  arrange(filing_date, root_job_id, .by_group = TRUE) |>
  mutate(parent_component_order = row_number()) |>
  ungroup() |>
  transmute(
    parent_definition = "broad_candidate_parent",
    parent_id,
    parent_status = if_else(
      str_starts(parent_id, "standalone__"),
      "standalone_building",
      "candidate_multi_building_parent"
    ),
    root_job_id,
    filing_date,
    filing_year,
    units = proposed_units,
    parent_component_order
  )

parent_components <- bind_rows(conservative_components, broad_components) |>
  left_join(
    latest_registration_by_job,
    by = c("root_job_id" = "matched_dob_root_job_id"),
    relationship = "many-to-one"
  ) |>
  group_by(parent_definition, parent_id) |>
  filter(any(filing_year == post_year & units == bunching_units)) |>
  ungroup()

parent_registration_summary <- parent_components |>
  arrange(parent_definition, parent_id, parent_component_order) |>
  group_by(parent_definition, parent_id) |>
  summarise(
    parent_status = first(parent_status),
    component_count = n(),
    dob_parent_units = sum(units),
    exact_99_component_count = sum(filing_year == post_year & units == bunching_units),
    registered_component_count = sum(!is.na(hpd_response_number)),
    registered_option_b_sub100_count = sum(
      intended_separate_sub100_treatment %in% TRUE,
      na.rm = TRUE
    ),
    registered_exact_99_option_b_count = sum(
      intended_separate_sub100_treatment %in% TRUE & hpd_reported_units == bunching_units,
      na.rm = TRUE
    ),
    hpd_registered_units = if_else(
      registered_component_count == 0L,
      NA_integer_,
      sum(hpd_reported_units, na.rm = TRUE)
    ),
    all_components_registered = registered_component_count == component_count,
    component_root_jobs = paste(root_job_id, collapse = ";"),
    component_dob_units = paste(units, collapse = ";"),
    hpd_response_numbers = paste(hpd_response_number[!is.na(hpd_response_number)], collapse = ";"),
    hpd_reported_units = paste(hpd_reported_units[!is.na(hpd_reported_units)], collapse = ";"),
    hpd_reported_options = paste(
      hpd_reported_affordability_option[!is.na(hpd_reported_affordability_option)],
      collapse = ";"
    ),
    .groups = "drop"
  ) |>
  left_join(
    preferred_model_parents,
    by = "parent_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    in_preferred_180_day_model_sample =
      parent_definition == "symmetric_parent" &
      !is.na(preferred_model_observed_units),
    preferred_180_day_exact_99_parent =
      in_preferred_180_day_model_sample &
      preferred_model_observed_units == bunching_units,
    descriptive_registration_pattern = case_when(
      registered_component_count == 0L ~ "no_public_registration_match",
      dob_parent_units >= threshold_units & registered_option_b_sub100_count >= 2L ~
        "multiple_sub100_option_b_registrations",
      component_count == 1L & registered_exact_99_option_b_count == 1L ~
        "single_exact99_option_b_registration",
      registered_component_count < component_count ~ "partial_parent_registration",
      registered_option_b_sub100_count == component_count ~
        "all_components_sub100_option_b",
      TRUE ~ "other_registered_pattern"
    ),
    maintained_assumption_interpretation = case_when(
      descriptive_registration_pattern == "multiple_sub100_option_b_registrations" ~
        "intended_split_into_multiple_sub100_sites",
      descriptive_registration_pattern == "single_exact99_option_b_registration" ~
        "single_sub100_site_intent",
      descriptive_registration_pattern == "partial_parent_registration" ~
        "incomplete_public_registration_coverage",
      descriptive_registration_pattern == "no_public_registration_match" ~
        "unobserved_in_public_snapshot",
      TRUE ~ "registered_pattern_requires_review"
    )
  ) |>
  arrange(parent_definition, desc(registered_component_count), parent_id)

write_csv(
  registration_links,
  "../output/hpd_485x_registration_dob_links.csv",
  na = ""
)
write_csv(
  exact_99_buildings,
  "../output/hpd_485x_exact_99_buildings.csv",
  na = ""
)
write_csv(
  parent_registration_summary,
  "../output/hpd_485x_parent_registration_summary.csv",
  na = ""
)

cat("Wrote descriptive HPD registration linkage outputs to ../output\n")

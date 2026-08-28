# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/build_parent_condo_tenure_panel/code")
# pre_start_year <- 2011L
# pre_end_year <- 2022L
# post_start_date_text <- "2023-01-01"
# min_units <- 6L
# prefiling_match_days <- 730L
# postfiling_match_days <- 1826L
# followup_days_text <- "190,365,730"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7L) {
  stop(
    "Expected pre-period years, post start date, minimum units, ",
    "plan-match windows, and fixed follow-up days."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_start_date_text <- args[3]
post_start_date <- as.Date(post_start_date_text)
min_units <- as.integer(args[4])
prefiling_match_days <- as.integer(args[5])
postfiling_match_days <- as.integer(args[6])
followup_days_text <- args[7]
followup_days <- as.integer(str_split(followup_days_text, ",")[[1]])

if (
  any(is.na(c(
    pre_start_year,
    pre_end_year,
    post_start_date,
    min_units,
    prefiling_match_days,
    postfiling_match_days,
    followup_days
  ))) ||
    pre_start_year > pre_end_year ||
    min_units < 1L ||
    prefiling_match_days < 0L ||
    postfiling_match_days < 1L ||
    any(followup_days < 1L) ||
    anyDuplicated(followup_days)
) {
  stop("Condo-panel arguments are not internally consistent.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

hdb <- read_parquet(
  "../input/dcp_housing_database_project_level_25q4.parquet"
) |>
  as.data.frame() |>
  as_tibble()

dob <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

historical_fields <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble()

ag_search_audit <- read_csv(
  "../input/nys_ag_offering_plan_search_audit.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA"),
  col_types = cols(
    .default = col_guess(),
    parent_id = col_character(),
    root_job_id = col_character()
  )
)

ag_matches <- read_csv(
  "../input/nys_ag_offering_plan_matches.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA"),
  col_types = cols(
    .default = col_guess(),
    parent_id = col_character(),
    root_job_id = col_character(),
    plan_id = col_character()
  )
)

hpd_links <- read_csv(
  "../input/hpd_485x_registration_dob_links.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA"),
  col_types = cols(
    .default = col_guess(),
    matched_dob_root_job_id = col_character()
  )
)

if (
  anyDuplicated(membership[c("sample", "root_job_id")]) ||
    anyDuplicated(hdb$job_number) ||
    anyDuplicated(dob$job_number) ||
    anyDuplicated(historical_fields$job_number) ||
    anyDuplicated(ag_search_audit[c("parent_id", "root_job_id")]) ||
    anyDuplicated(ag_matches[c("parent_id", "root_job_id", "plan_id")])
) {
  stop("A condo-panel source is not unique by its expected key.")
}

component_universe <- membership |>
  filter(
    (
      sample == "historical" &
        full_window_observed &
        cohort_year >= pre_start_year &
        cohort_year <= pre_end_year
    ) |
      (
        sample == "post_policy" &
          left_window_observed &
          cohort_date >= post_start_date
      ),
    parent_observed_units >= min_units
  ) |>
  select(
    sample,
    parent_id,
    root_job_id,
    member_order,
    cohort_date,
    cohort_year,
    parent_observed_units,
    units,
    filing_bbl,
    source_end_date
  )

hdb_fields <- hdb |>
  transmute(
    root_job_id = job_number,
    hdb_address = str_squish(address),
    hdb_borough_name = str_squish(borough_name),
    hdb_ownership_type = str_squish(ownership)
  )

dob_fields <- dob |>
  transmute(
    root_job_id = job_number,
    dob_address = str_squish(address),
    dob_borough_name = str_squish(borough_name),
    dob_owner_type = str_squish(owner_type),
    dob_owner_name = str_squish(case_when(
      !is.na(owner_business_name) &
        owner_business_name != "" &
        str_to_upper(owner_business_name) != "NOT APPLICABLE" ~
          owner_business_name,
      !is.na(owner_first_name) | !is.na(owner_last_name) ~
        str_squish(paste(owner_first_name, owner_last_name)),
      TRUE ~ NA_character_
    )),
    dob_job_description = str_squish(job_description)
  )

historical_job_fields <- historical_fields |>
  transmute(
    root_job_id = job_number,
    historical_dob_owner_name = str_squish(dob_owner_name),
    historical_pluto_owner_type = str_squish(pluto_owner_type),
    historical_pluto_owner_name = str_squish(pluto_owner_name),
    historical_job_description = str_squish(description)
  )

component_universe <- component_universe |>
  left_join(hdb_fields, by = "root_job_id", relationship = "many-to-one") |>
  left_join(dob_fields, by = "root_job_id", relationship = "many-to-one") |>
  left_join(
    historical_job_fields,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    address = coalesce(dob_address, hdb_address),
    borough_name = coalesce(dob_borough_name, hdb_borough_name),
    ownership_type = coalesce(
      dob_owner_type,
      hdb_ownership_type,
      historical_pluto_owner_type
    ),
    owner_name = coalesce(
      dob_owner_name,
      historical_dob_owner_name,
      historical_pluto_owner_name
    ),
    job_description = coalesce(
      dob_job_description,
      historical_job_description
    ),
    initial_filing_text = str_to_upper(str_squish(paste(
      coalesce(dob_owner_name, historical_dob_owner_name, ""),
      coalesce(dob_job_description, historical_job_description, "")
    ))),
    dob_initial_condo_text = str_detect(
      initial_filing_text,
      "\\bCONDO(MINIUM)?S?\\b"
    ),
    dob_initial_coop_text = str_detect(
      initial_filing_text,
      "\\bCO[ -]?OP(ERATIVE)?S?\\b"
    )
  )

if (
  nrow(component_universe) == 0L ||
    anyDuplicated(component_universe[c("sample", "root_job_id")]) ||
    any(is.na(component_universe$parent_id)) ||
    any(is.na(component_universe$parent_observed_units))
) {
  stop("The component condo universe failed row-level QC.")
}

parent_consistency <- component_universe |>
  group_by(parent_id) |>
  summarise(
    samples = n_distinct(sample),
    cohort_dates = n_distinct(cohort_date),
    cohort_years = n_distinct(cohort_year),
    parent_unit_values = n_distinct(parent_observed_units),
    source_end_dates = n_distinct(source_end_date),
    .groups = "drop"
  )

if (
  any(parent_consistency$samples != 1L) ||
    any(parent_consistency$cohort_dates != 1L) ||
    any(parent_consistency$cohort_years != 1L) ||
    any(parent_consistency$parent_unit_values != 1L) ||
    any(parent_consistency$source_end_dates != 1L)
) {
  stop("Parent-level cohort fields vary within a parent.")
}

parent_universe <- component_universe |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(as.Date(cohort_date)),
    cohort_year = first(cohort_year),
    parent_total_units = first(parent_observed_units),
    component_filings = n(),
    dob_source_end_date = first(as.Date(source_end_date)),
    component_jobs = paste(root_job_id, collapse = ";"),
    addresses = paste(sort(unique(na.omit(address))), collapse = ";"),
    boroughs = paste(sort(unique(na.omit(borough_name))), collapse = ";"),
    ownership_types = paste(
      sort(unique(na.omit(ownership_type))),
      collapse = ";"
    ),
    owner_names = paste(sort(unique(na.omit(owner_name))), collapse = ";"),
    job_descriptions = paste(
      sort(unique(na.omit(job_description))),
      collapse = ";"
    ),
    dob_initial_condo_text = any(dob_initial_condo_text),
    dob_initial_coop_text = any(dob_initial_coop_text),
    .groups = "drop"
  ) |>
  mutate(
    ownership_text = str_to_upper(str_squish(paste(
      ownership_types,
      owner_names
    ))),
    description_text = str_to_upper(job_descriptions),
    government_or_public_owner = str_detect(
      ownership_text,
      paste0(
        "GOVERNMENT|NYCHA|NEW YORK CITY HOUSING AUTHORITY|",
        "NYC AGENCY|CITY: HPD|CITY: HHC|",
        "HOUSING PRESERVATION AND DEVELOPMENT"
      )
    ),
    hotel_project = str_detect(description_text, "\\bHOTEL\\b"),
    ownership_unresolved = ownership_text == "",
    private_residential_status = case_when(
      government_or_public_owner ~ "government_or_public",
      hotel_project ~ "hotel_or_nonresidential",
      ownership_unresolved ~ "ownership_unresolved",
      TRUE ~ "private_residential"
    ),
    private_residential_main =
      private_residential_status == "private_residential",
    unit_threshold_group = if_else(
      parent_total_units < 100L,
      "6-99",
      "100+"
    ),
    unit_band = case_when(
      parent_total_units <= 98L ~ "6-98",
      parent_total_units == 99L ~ "99",
      parent_total_units <= 149L ~ "100-149",
      parent_total_units <= 197L ~ "150-197",
      parent_total_units == 198L ~ "198",
      TRUE ~ "199+"
    )
  )

if (anyDuplicated(parent_universe$parent_id)) {
  stop("The condo parent universe is not unique by parent_id.")
}

expected_searches <- component_universe |>
  filter(!is.na(address), address != "") |>
  distinct(parent_id, root_job_id)

observed_searches <- ag_search_audit |>
  distinct(parent_id, root_job_id)

if (
  nrow(anti_join(
    expected_searches,
    observed_searches,
    by = c("parent_id", "root_job_id")
  )) > 0L ||
    any(ag_search_audit$search_http_status != 200L)
) {
  stop("The Attorney General search audit does not cover the condo universe.")
}

ag_source_pull_dates <- unique(as.Date(ag_search_audit$source_pull_date))

if (length(ag_source_pull_dates) != 1L || is.na(ag_source_pull_dates)) {
  stop("The Attorney General source pull date is not unique and complete.")
}

ag_source_pull_date <- ag_source_pull_dates[1]

ag_search_parent <- component_universe |>
  select(parent_id, root_job_id, address) |>
  left_join(
    ag_search_audit |>
      select(
        parent_id,
        root_job_id,
        search_http_status,
        returned_plan_count
      ),
    by = c("parent_id", "root_job_id"),
    relationship = "one-to-one"
  ) |>
  group_by(parent_id) |>
  summarise(
    ag_queryable_components = sum(!is.na(address) & address != ""),
    ag_queries_completed = sum(!is.na(search_http_status)),
    ag_all_queries_succeeded = all(
      is.na(search_http_status) | search_http_status == 200L
    ),
    ag_returned_plans = sum(returned_plan_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    ag_screen_complete =
      ag_queries_completed == ag_queryable_components &
      ag_all_queries_succeeded
  )

ag_plan_candidates <- ag_matches |>
  inner_join(
    parent_universe |>
      select(parent_id, cohort_date),
    by = "parent_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    source_pull_date = as.Date(source_pull_date),
    submitted_date = as.Date(submitted_date),
    accepted_date = as.Date(accepted_date),
    effective_date = as.Date(effective_date),
    plan_prefix = str_sub(str_to_upper(plan_id), 1L, 2L),
    plan_type_upper = str_to_upper(str_squish(plan_type)),
    construction_type_upper = str_to_upper(str_squish(construction_type)),
    plan_kind = case_when(
      plan_type_upper == "CONDOMINIUM" & plan_prefix == "CD" ~
        "condo_offering_plan",
      plan_type_upper == "CONDOMINIUM" & plan_prefix == "CP" ~
        "condo_cps1_market_test",
      plan_type_upper == "COOPERATIVE" & plan_prefix == "CP" ~
        "cooperative_cps1_market_test",
      plan_type_upper == "COOPERATIVE" & plan_prefix != "NA" ~
        "cooperative_offering_plan",
      TRUE ~ "other_record"
    ),
    days_from_parent_filing = as.integer(submitted_date - cohort_date)
  ) |>
  filter(
    exact_address_phrase_match,
    construction_type_upper == "NEW",
    plan_kind != "other_record",
    !is.na(days_from_parent_filing),
    days_from_parent_filing >= -prefiling_match_days,
    days_from_parent_filing <= postfiling_match_days
  ) |>
  group_by(parent_id, plan_id) |>
  summarise(
    cohort_date = first(cohort_date),
    source_pull_date = first(source_pull_date),
    matched_component_jobs = paste(
      sort(unique(root_job_id)),
      collapse = ";"
    ),
    plan_name = first(plan_name),
    plan_address = first(plan_address),
    plan_borough = first(plan_borough),
    plan_type = first(plan_type_upper),
    plan_kind = first(plan_kind),
    construction_type = first(construction_type_upper),
    plan_units = first(plan_units),
    submitted_date = first(submitted_date),
    accepted_date = first(accepted_date),
    effective_date = first(effective_date),
    plan_action = first(plan_action),
    plan_source_url = first(plan_source_url),
    days_from_parent_filing = first(days_from_parent_filing),
    .groups = "drop"
  ) |>
  group_by(plan_id) |>
  arrange(
    abs(days_from_parent_filing),
    parent_id,
    .by_group = TRUE
  ) |>
  mutate(
    candidate_parent_count = n(),
    assignment_rank = row_number(),
    selected_assignment = assignment_rank == 1L
  ) |>
  ungroup()

condo_plan_parent_assignment_review <- ag_plan_candidates |>
  filter(candidate_parent_count > 1L) |>
  arrange(plan_id, assignment_rank) |>
  select(
    plan_id,
    plan_kind,
    submitted_date,
    accepted_date,
    plan_name,
    plan_address,
    parent_id,
    cohort_date,
    days_from_parent_filing,
    matched_component_jobs,
    candidate_parent_count,
    assignment_rank,
    selected_assignment,
    plan_source_url
  )

assigned_plans <- ag_plan_candidates |>
  filter(selected_assignment)

ag_parent_evidence <- assigned_plans |>
  group_by(parent_id) |>
  summarise(
    condo_offering_plan_ever = any(
      plan_kind == "condo_offering_plan"
    ),
    condo_cps1_ever = any(
      plan_kind == "condo_cps1_market_test"
    ),
    cooperative_plan_ever = any(
      plan_kind == "cooperative_offering_plan"
    ),
    cooperative_cps1_ever = any(
      plan_kind == "cooperative_cps1_market_test"
    ),
    condo_plan_submitted_by_initial_filing = any(
      plan_kind == "condo_offering_plan" &
        submitted_date <= cohort_date
    ),
    condo_cps1_by_initial_filing = any(
      plan_kind == "condo_cps1_market_test" &
        submitted_date <= cohort_date
    ),
    condo_plan_accepted_by_initial_filing = any(
      plan_kind == "condo_offering_plan" &
        !is.na(accepted_date) &
        accepted_date <= cohort_date
    ),
    condo_plan_submitted_after_initial_filing = any(
      plan_kind == "condo_offering_plan" &
        submitted_date > cohort_date
    ),
    condo_plan_accepted_after_initial_filing = any(
      plan_kind == "condo_offering_plan" &
        !is.na(accepted_date) &
        accepted_date > cohort_date
    ),
    condo_plan_first_submitted_date = suppressWarnings(min(
      submitted_date[plan_kind == "condo_offering_plan"],
      na.rm = TRUE
    )),
    condo_plan_first_accepted_date = suppressWarnings(min(
      accepted_date[plan_kind == "condo_offering_plan"],
      na.rm = TRUE
    )),
    condo_plan_ids = paste(
      sort(unique(plan_id[plan_kind == "condo_offering_plan"])),
      collapse = ";"
    ),
    condo_cps1_plan_ids = paste(
      sort(unique(plan_id[plan_kind == "condo_cps1_market_test"])),
      collapse = ";"
    ),
    condo_plan_source_urls = paste(
      sort(unique(plan_source_url[plan_kind == "condo_offering_plan"])),
      collapse = ";"
    ),
    .groups = "drop"
  ) |>
  mutate(
    condo_plan_first_submitted_date = as.Date(if_else(
      is.infinite(as.numeric(condo_plan_first_submitted_date)),
      NA_real_,
      as.numeric(condo_plan_first_submitted_date)
    ), origin = "1970-01-01"),
    condo_plan_first_accepted_date = as.Date(if_else(
      is.infinite(as.numeric(condo_plan_first_accepted_date)),
      NA_real_,
      as.numeric(condo_plan_first_accepted_date)
    ), origin = "1970-01-01")
  )

for (followup_day in followup_days) {
  submitted_name <- paste0(
    "condo_plan_submitted_within_",
    followup_day,
    "d"
  )
  accepted_name <- paste0(
    "condo_plan_accepted_within_",
    followup_day,
    "d"
  )

  fixed_followup_evidence <- assigned_plans |>
    group_by(parent_id) |>
    summarise(
      submitted_flag = any(
        plan_kind == "condo_offering_plan" &
          submitted_date <= cohort_date + followup_day
      ),
      accepted_flag = any(
        plan_kind == "condo_offering_plan" &
          !is.na(accepted_date) &
          accepted_date <= cohort_date + followup_day
      ),
      .groups = "drop"
    ) |>
    rename(
      "{submitted_name}" := submitted_flag,
      "{accepted_name}" := accepted_flag
    )

  ag_parent_evidence <- ag_parent_evidence |>
    full_join(
      fixed_followup_evidence,
      by = "parent_id",
      relationship = "one-to-one"
    )
}

latest_hpd_by_job <- hpd_links |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(
    root_job_id = matched_dob_root_job_id,
    hpd_response_number = response_number,
    hpd_submission_date = as.Date(form_submission_timestamp),
    hpd_option = str_to_upper(str_squish(
      reported_affordability_option
    ))
  )

if (anyDuplicated(latest_hpd_by_job$root_job_id)) {
  stop("Latest HPD evidence is not unique by DOB root job.")
}

hpd_parent_evidence <- component_universe |>
  select(parent_id, root_job_id) |>
  left_join(
    latest_hpd_by_job,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  group_by(parent_id) |>
  summarise(
    hpd_registered_components = sum(!is.na(hpd_response_number)),
    rental_confirmed_485x = any(hpd_option %in% c(
      "OPTION A",
      "OPTION B"
    )),
    homeownership_option_d = any(hpd_option == "OPTION D"),
    hpd_other_option = any(
      !is.na(hpd_option) &
        !hpd_option %in% c("OPTION A", "OPTION B", "OPTION D")
    ),
    hpd_options = paste(
      sort(unique(na.omit(hpd_option))),
      collapse = ";"
    ),
    .groups = "drop"
  )

parent_condo_tenure_panel <- parent_universe |>
  left_join(
    ag_search_parent,
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    ag_parent_evidence,
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    hpd_parent_evidence,
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      where(is.logical),
      ~ coalesce(.x, FALSE)
    ),
    ag_source_pull_date = ag_source_pull_date,
    ag_followup_days = as.integer(ag_source_pull_date - cohort_date),
    condo_intent_observable_by_initial_filing =
      dob_initial_condo_text |
      condo_plan_submitted_by_initial_filing |
      condo_cps1_by_initial_filing,
    condo_confirmed_ever =
      condo_plan_accepted_by_initial_filing |
      condo_plan_accepted_after_initial_filing,
    days_to_condo_plan_submission = as.integer(
      condo_plan_first_submitted_date - cohort_date
    ),
    days_to_condo_plan_acceptance = as.integer(
      condo_plan_first_accepted_date - cohort_date
    ),
    conflicting_rental_and_condo_evidence =
      rental_confirmed_485x & condo_confirmed_ever,
    tenure_status_ever_observed = case_when(
      conflicting_rental_and_condo_evidence ~
        "conflicting_rental_and_condo_evidence",
      condo_intent_observable_by_initial_filing ~
        "condo_intent_observable_by_initial_filing",
      condo_plan_accepted_after_initial_filing ~
        "condo_confirmed_after_initial_filing",
      condo_plan_submitted_after_initial_filing ~
        "condo_plan_submitted_after_initial_filing",
      condo_cps1_ever ~ "condo_market_test_only",
      rental_confirmed_485x ~ "rental_confirmed_485x",
      homeownership_option_d ~ "other_homeownership_option_d",
      cooperative_plan_ever | cooperative_cps1_ever ~
        "cooperative_evidence",
      TRUE ~ "unresolved"
    )
  )

for (followup_day in followup_days) {
  complete_name <- paste0("followup_", followup_day, "d_complete")
  submitted_name <- paste0(
    "condo_plan_submitted_within_",
    followup_day,
    "d"
  )
  accepted_name <- paste0(
    "condo_plan_accepted_within_",
    followup_day,
    "d"
  )

  parent_condo_tenure_panel[[complete_name]] <-
    parent_condo_tenure_panel$ag_followup_days >= followup_day
  parent_condo_tenure_panel[[submitted_name]] <- coalesce(
    parent_condo_tenure_panel[[submitted_name]],
    FALSE
  ) | parent_condo_tenure_panel$dob_initial_condo_text
  parent_condo_tenure_panel[[accepted_name]] <- coalesce(
    parent_condo_tenure_panel[[accepted_name]],
    FALSE
  )
}

parent_condo_tenure_panel <- parent_condo_tenure_panel |>
  select(
    sample,
    parent_id,
    cohort_date,
    cohort_year,
    parent_total_units,
    unit_threshold_group,
    unit_band,
    component_filings,
    component_jobs,
    addresses,
    boroughs,
    ownership_types,
    owner_names,
    job_descriptions,
    private_residential_status,
    private_residential_main,
    government_or_public_owner,
    hotel_project,
    ownership_unresolved,
    dob_initial_condo_text,
    dob_initial_coop_text,
    ag_source_pull_date,
    ag_followup_days,
    ag_queryable_components,
    ag_queries_completed,
    ag_all_queries_succeeded,
    ag_screen_complete,
    ag_returned_plans,
    condo_intent_observable_by_initial_filing,
    condo_plan_submitted_by_initial_filing,
    condo_cps1_by_initial_filing,
    condo_plan_accepted_by_initial_filing,
    condo_plan_submitted_after_initial_filing,
    condo_plan_accepted_after_initial_filing,
    condo_offering_plan_ever,
    condo_cps1_ever,
    condo_confirmed_ever,
    condo_plan_first_submitted_date,
    condo_plan_first_accepted_date,
    days_to_condo_plan_submission,
    days_to_condo_plan_acceptance,
    starts_with("followup_"),
    starts_with("condo_plan_submitted_within_"),
    starts_with("condo_plan_accepted_within_"),
    cooperative_plan_ever,
    cooperative_cps1_ever,
    hpd_registered_components,
    rental_confirmed_485x,
    homeownership_option_d,
    hpd_other_option,
    hpd_options,
    conflicting_rental_and_condo_evidence,
    tenure_status_ever_observed,
    condo_plan_ids,
    condo_cps1_plan_ids,
    condo_plan_source_urls,
    dob_source_end_date
  ) |>
  arrange(sample, cohort_date, parent_id)

logical_columns <- names(parent_condo_tenure_panel)[
  vapply(parent_condo_tenure_panel, is.logical, logical(1))
]

if (
  anyDuplicated(parent_condo_tenure_panel$parent_id) ||
    any(is.na(parent_condo_tenure_panel$private_residential_status)) ||
    any(is.na(parent_condo_tenure_panel$tenure_status_ever_observed)) ||
    any(vapply(
      parent_condo_tenure_panel[logical_columns],
      function(x) any(is.na(x)),
      logical(1)
    )) ||
    any(!parent_condo_tenure_panel$ag_screen_complete)
) {
  stop("The final parent condo tenure panel failed QC.")
}

summary_universe <- bind_rows(
  parent_condo_tenure_panel |>
    mutate(summary_unit_group = "all_6_plus"),
  parent_condo_tenure_panel |>
    mutate(summary_unit_group = unit_threshold_group)
) |>
  filter(private_residential_main)

parent_condo_counts_by_cohort_year <- summary_universe |>
  group_by(sample, cohort_year, summary_unit_group) |>
  summarise(
    measure = "condo_intent_by_initial_filing",
    followup_days = 0L,
    eligible_parents = n(),
    condo_parents = sum(condo_intent_observable_by_initial_filing),
    condo_share = condo_parents / eligible_parents,
    .groups = "drop"
  )

ever_observed_counts <- summary_universe |>
  group_by(sample, cohort_year, summary_unit_group) |>
  summarise(
    measure = "condo_plan_accepted_ever_observed",
    followup_days = NA_integer_,
    eligible_parents = n(),
    condo_parents = sum(condo_confirmed_ever),
    condo_share = condo_parents / eligible_parents,
    .groups = "drop"
  )

parent_condo_counts_by_cohort_year <- bind_rows(
  parent_condo_counts_by_cohort_year,
  ever_observed_counts
)

for (followup_day in followup_days) {
  complete_name <- paste0("followup_", followup_day, "d_complete")
  submitted_name <- paste0(
    "condo_plan_submitted_within_",
    followup_day,
    "d"
  )
  accepted_name <- paste0(
    "condo_plan_accepted_within_",
    followup_day,
    "d"
  )

  fixed_followup_universe <- summary_universe |>
    filter(.data[[complete_name]])

  submitted_counts <- fixed_followup_universe |>
    group_by(sample, cohort_year, summary_unit_group) |>
    summarise(
      measure = "condo_plan_submitted_by_fixed_followup",
      followup_days = followup_day,
      eligible_parents = n(),
      condo_parents = sum(.data[[submitted_name]]),
      condo_share = condo_parents / eligible_parents,
      .groups = "drop"
    )

  accepted_counts <- fixed_followup_universe |>
    group_by(sample, cohort_year, summary_unit_group) |>
    summarise(
      measure = "condo_plan_accepted_by_fixed_followup",
      followup_days = followup_day,
      eligible_parents = n(),
      condo_parents = sum(.data[[accepted_name]]),
      condo_share = condo_parents / eligible_parents,
      .groups = "drop"
    )

  parent_condo_counts_by_cohort_year <- bind_rows(
    parent_condo_counts_by_cohort_year,
    submitted_counts,
    accepted_counts
  )
}

parent_condo_counts_by_cohort_year <-
  parent_condo_counts_by_cohort_year |>
  arrange(
    cohort_year,
    summary_unit_group,
    measure,
    followup_days
  )

period_definitions <- tibble(
  period = c(
    "full_pre_2011_2022",
    "recent_pre_2019_2022",
    "gap_2023_2024",
    "post_485x_2025_current"
  ),
  sample = c(
    "historical",
    "historical",
    "post_policy",
    "post_policy"
  ),
  period_start_date = as.Date(c(
    "2011-01-01",
    "2019-01-01",
    "2023-01-01",
    "2025-01-01"
  )),
  period_end_date = as.Date(c(
    "2022-12-31",
    "2022-12-31",
    "2024-12-31",
    as.character(max(parent_condo_tenure_panel$dob_source_end_date))
  ))
)

period_count_rows <- list()
period_count_index <- 0L

for (period_index in seq_len(nrow(period_definitions))) {
  period_row <- period_definitions[period_index, ]
  period_parent_rows <- parent_condo_tenure_panel |>
    filter(
      sample == period_row$sample,
      cohort_date >= period_row$period_start_date,
      cohort_date <= period_row$period_end_date,
      private_residential_main
    )

  period_summary_universe <- bind_rows(
    period_parent_rows |>
      mutate(summary_unit_group = "all_6_plus"),
    period_parent_rows |>
      mutate(summary_unit_group = unit_threshold_group)
  )

  observed_years <- as.numeric(
    period_row$period_end_date - period_row$period_start_date + 1L
  ) / 365.25

  period_count_index <- period_count_index + 1L
  period_count_rows[[period_count_index]] <-
    period_summary_universe |>
    group_by(summary_unit_group) |>
    summarise(
      period = period_row$period,
      sample = period_row$sample,
      measure = "condo_intent_by_initial_filing",
      followup_days = 0L,
      period_start_date = period_row$period_start_date,
      eligible_cohort_end_date = period_row$period_end_date,
      observed_years = observed_years,
      eligible_parents = n(),
      condo_parents = sum(condo_intent_observable_by_initial_filing),
      annualized_eligible_parents = eligible_parents / observed_years,
      annualized_condo_parents = condo_parents / observed_years,
      condo_share = condo_parents / eligible_parents,
      .groups = "drop"
    )

  for (followup_day in followup_days) {
    eligible_cohort_end_date <- min(
      period_row$period_end_date,
      ag_source_pull_date - followup_day
    )

    if (eligible_cohort_end_date < period_row$period_start_date) {
      next
    }

    fixed_followup_years <- as.numeric(
      eligible_cohort_end_date - period_row$period_start_date + 1L
    ) / 365.25
    submitted_name <- paste0(
      "condo_plan_submitted_within_",
      followup_day,
      "d"
    )
    accepted_name <- paste0(
      "condo_plan_accepted_within_",
      followup_day,
      "d"
    )

    fixed_period_universe <- period_summary_universe |>
      filter(cohort_date <= eligible_cohort_end_date)

    period_count_index <- period_count_index + 1L
    period_count_rows[[period_count_index]] <-
      fixed_period_universe |>
      group_by(summary_unit_group) |>
      summarise(
        period = period_row$period,
        sample = period_row$sample,
        measure = "condo_plan_submitted_by_fixed_followup",
        followup_days = followup_day,
        period_start_date = period_row$period_start_date,
        eligible_cohort_end_date = eligible_cohort_end_date,
        observed_years = fixed_followup_years,
        eligible_parents = n(),
        condo_parents = sum(.data[[submitted_name]]),
        annualized_eligible_parents = eligible_parents /
          fixed_followup_years,
        annualized_condo_parents = condo_parents /
          fixed_followup_years,
        condo_share = condo_parents / eligible_parents,
        .groups = "drop"
      )

    period_count_index <- period_count_index + 1L
    period_count_rows[[period_count_index]] <-
      fixed_period_universe |>
      group_by(summary_unit_group) |>
      summarise(
        period = period_row$period,
        sample = period_row$sample,
        measure = "condo_plan_accepted_by_fixed_followup",
        followup_days = followup_day,
        period_start_date = period_row$period_start_date,
        eligible_cohort_end_date = eligible_cohort_end_date,
        observed_years = fixed_followup_years,
        eligible_parents = n(),
        condo_parents = sum(.data[[accepted_name]]),
        annualized_eligible_parents = eligible_parents /
          fixed_followup_years,
        annualized_condo_parents = condo_parents /
          fixed_followup_years,
        condo_share = condo_parents / eligible_parents,
        .groups = "drop"
      )
  }
}

parent_condo_counts_by_period <- bind_rows(period_count_rows) |>
  select(
    period,
    sample,
    summary_unit_group,
    measure,
    followup_days,
    period_start_date,
    eligible_cohort_end_date,
    observed_years,
    eligible_parents,
    condo_parents,
    annualized_eligible_parents,
    annualized_condo_parents,
    condo_share
  ) |>
  arrange(period, summary_unit_group, measure, followup_days)

parent_condo_tenure_qc <- tibble(
  metric = c(
    "component_filings",
    "economic_parents",
    "private_residential_parents",
    "government_or_public_parents",
    "hotel_or_nonresidential_parents",
    "ownership_unresolved_parents",
    "ag_address_queries",
    "ag_address_queries_successful",
    "raw_ag_plan_returns",
    "timing_eligible_homeownership_plan_candidates",
    "plans_with_multiple_candidate_parents",
    "dob_initial_condo_text_parents",
    "condo_intent_observable_by_initial_filing",
    "condo_offering_plan_parents",
    "condo_confirmed_ever_parents",
    "rental_confirmed_485x_parents",
    "conflicting_rental_and_condo_parents"
  ),
  value = c(
    nrow(component_universe),
    nrow(parent_condo_tenure_panel),
    sum(parent_condo_tenure_panel$private_residential_main),
    sum(parent_condo_tenure_panel$private_residential_status ==
      "government_or_public"),
    sum(parent_condo_tenure_panel$private_residential_status ==
      "hotel_or_nonresidential"),
    sum(parent_condo_tenure_panel$private_residential_status ==
      "ownership_unresolved"),
    nrow(ag_search_audit),
    sum(ag_search_audit$search_http_status == 200L),
    nrow(ag_matches),
    nrow(ag_plan_candidates),
    n_distinct(
      ag_plan_candidates$plan_id[
        ag_plan_candidates$candidate_parent_count > 1L
      ]
    ),
    sum(parent_condo_tenure_panel$dob_initial_condo_text),
    sum(
      parent_condo_tenure_panel$
        condo_intent_observable_by_initial_filing
    ),
    sum(parent_condo_tenure_panel$condo_offering_plan_ever),
    sum(parent_condo_tenure_panel$condo_confirmed_ever),
    sum(parent_condo_tenure_panel$rental_confirmed_485x),
    sum(
      parent_condo_tenure_panel$
        conflicting_rental_and_condo_evidence
    )
  )
)

write_csv_if_changed(
  parent_condo_tenure_panel,
  "../output/parent_condo_tenure_panel.csv"
)
write_csv_if_changed(
  parent_condo_counts_by_cohort_year,
  "../output/parent_condo_counts_by_cohort_year.csv"
)
write_csv_if_changed(
  parent_condo_counts_by_period,
  "../output/parent_condo_counts_by_period.csv"
)
write_csv_if_changed(
  condo_plan_parent_assignment_review,
  "../output/condo_plan_parent_assignment_review.csv"
)
write_csv_if_changed(
  parent_condo_tenure_qc,
  "../output/parent_condo_tenure_qc.csv"
)

cat(
  "Wrote ",
  nrow(parent_condo_tenure_panel),
  " parent proposals; ",
  sum(parent_condo_tenure_panel$private_residential_main),
  " are in the private residential main universe and ",
  sum(parent_condo_tenure_panel$condo_confirmed_ever),
  " have an accepted matched condo offering plan\n",
  sep = ""
)

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/classify_parent_485x_exposure/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

historical_evidence_cutoff <- as.Date("2024-01-12")

universe <- read_csv(
  "../output/parent_485x_exposure_universe.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA")
)

ag_search_audit <- read_csv(
  "../output/nys_ag_offering_plan_search_audit.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA")
)

ag_matches <- read_csv(
  "../output/nys_ag_offering_plan_matches.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA")
)

historical_ag_supplement <- bind_rows(
  read_csv(
    "../input/historical_ag_query_supplement_2019_2022.csv",
    show_col_types = FALSE, guess_max = Inf, na = c("", "NA")
  ),
  read_csv(
    "../input/historical_ag_query_supplement_2023_companions.csv",
    show_col_types = FALSE, guess_max = Inf, na = c("", "NA")
  )
)

hpd_links <- read_csv(
  "../input/hpd_485x_registration_dob_links.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA")
)

manual_reviews <- read_csv(
  "parent_exposure_manual_reviews.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

valid_statuses <- c(
  "exposed_ab",
  "exposed_option_d",
  "not_exposed",
  "unresolved"
)
valid_confidence <- c("high", "medium", "low")

if (
  anyDuplicated(universe[c("sample", "root_job_id")]) ||
    anyDuplicated(manual_reviews$parent_id) ||
    any(!manual_reviews$parent_id %in% universe$parent_id) ||
    any(!manual_reviews$exposure_status %in% valid_statuses) ||
    any(!manual_reviews$confidence %in% valid_confidence)
) {
  stop("An exposure-classification input failed identifier or value QC.")
}

# Search evidence belongs to a filing and its queried address, not an old parent ID.
current_queries <- universe |> select(sample, root_job_id, search_query = ag_search_query, parent_id)
stopifnot(!anyDuplicated(current_queries[c("sample", "root_job_id", "search_query")]))

supplement_counts <- historical_ag_supplement |>
  group_by(sample, root_job_id, search_query) |>
  summarise(
    recorded_count = first(returned_plan_count),
    recorded_count_values = n_distinct(returned_plan_count),
    returned_rows = sum(!is.na(plan_id)),
    http_status_values = n_distinct(search_http_status),
    .groups = "drop"
  )
if (
  anyNA(historical_ag_supplement[c("sample", "root_job_id", "search_query",
    "search_http_status", "returned_plan_count")]) ||
    any(historical_ag_supplement$sample != "historical") ||
    any(historical_ag_supplement$search_http_status != 200L) ||
    anyDuplicated(historical_ag_supplement[
      c("sample", "root_job_id", "search_query", "plan_id")
    ]) ||
    any(supplement_counts$recorded_count_values != 1L) ||
    any(supplement_counts$http_status_values != 1L) ||
    any(supplement_counts$recorded_count != supplement_counts$returned_rows)
) {
  stop("The dated historical AG supplement failed query or plan-count QC.")
}

ag_search_audit <- ag_search_audit |>
  mutate(sample = sub("__.*$", "", parent_id)) |> select(-parent_id)
ag_matches <- ag_matches |>
  mutate(sample = sub("__.*$", "", parent_id)) |> select(-parent_id)

ag_search_audit <- bind_rows(
  ag_search_audit,
  historical_ag_supplement |>
    select(all_of(names(ag_search_audit))) |>
    distinct()
)
ag_matches <- bind_rows(
  ag_matches,
  historical_ag_supplement |>
    filter(!is.na(plan_id)) |>
    select(all_of(names(ag_matches)))
)

stopifnot(!anyDuplicated(ag_search_audit[c("sample", "root_job_id", "search_query")]),
  !anyDuplicated(ag_matches[c("sample", "root_job_id", "search_query", "plan_id")]))
ag_search_audit <- ag_search_audit |>
  inner_join(current_queries, by = c("sample", "root_job_id", "search_query"), relationship = "one-to-one")
ag_matches <- ag_matches |>
  inner_join(current_queries, by = c("sample", "root_job_id", "search_query"), relationship = "many-to-one")

parent_universe <- universe |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(as.Date(cohort_date)),
    cohort_year = first(cohort_year),
    parent_total_units = first(parent_total_units),
    component_filings = n(),
    ag_queryable_components = sum(
      !is.na(ag_search_query) & ag_search_query != ""
    ),
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
    .groups = "drop"
  ) |>
  mutate(
    ownership_text = str_to_upper(str_squish(paste(
      ownership_types,
      owner_names
    ))),
    description_text = str_to_upper(str_squish(job_descriptions)),
    government_owner = str_detect(
      ownership_text,
      paste0(
        "GOVERNMENT|NYCHA|NEW YORK CITY HOUSING AUTHORITY|",
        "NYC AGENCY|OTHER GOVERNMENT|CITY: HPD|CITY: HHC"
      )
    ),
    nycha_owner = str_detect(
      ownership_text,
      "NYCHA|NEW YORK CITY HOUSING AUTHORITY"
    ),
    hotel_project = str_detect(description_text, "\\bHOTEL\\b"),
    missing_ownership = ownership_text == ""
  )

if (anyDuplicated(parent_universe$parent_id)) {
  stop("Parent exposure universe is not unique by parent_id.")
}

ag_search_parent <- ag_search_audit |>
  group_by(parent_id) |>
  summarise(
    ag_queries = n(),
    ag_all_queries_succeeded = all(search_http_status == 200L),
    ag_returned_plans = sum(returned_plan_count),
    .groups = "drop"
  )

ag_parent_evidence <- ag_matches |>
  inner_join(
    parent_universe |>
      select(parent_id, sample, cohort_date),
    by = c("parent_id", "sample"),
    relationship = "many-to-one"
  ) |>
  mutate(
    submitted_date = as.Date(submitted_date),
    accepted_date = as.Date(accepted_date),
    years_from_proposal = as.numeric(submitted_date - cohort_date) / 365.25,
    proposal_relevant_plan =
      exact_address_phrase_match &
      construction_type == "NEW" &
      (sample == "post_policy" |
        (!is.na(submitted_date) & submitted_date <= historical_evidence_cutoff)) &
      years_from_proposal >= -2 &
      years_from_proposal <= 5,
    plan_prefix = str_sub(str_to_upper(plan_id), 1L, 2L),
    market_homeownership_evidence =
      proposal_relevant_plan & plan_prefix %in% c("CD", "CP"),
    financing_condominium_evidence =
      proposal_relevant_plan & plan_prefix == "NA"
  ) |>
  group_by(parent_id) |>
  summarise(
    ag_market_homeownership = any(market_homeownership_evidence),
    ag_offering_plan = any(
      market_homeownership_evidence & plan_prefix == "CD"
    ),
    ag_accepted_offering_plan = any(
      market_homeownership_evidence &
        plan_prefix == "CD" &
        !is.na(accepted_date) &
        (sample == "post_policy" | accepted_date <= historical_evidence_cutoff)
    ),
    ag_cps1_market_test = any(
      market_homeownership_evidence & plan_prefix == "CP"
    ),
    ag_financing_condominium = any(financing_condominium_evidence),
    ag_market_plan_ids = paste(
      sort(unique(plan_id[market_homeownership_evidence])),
      collapse = ";"
    ),
    ag_financing_plan_ids = paste(
      sort(unique(plan_id[financing_condominium_evidence])),
      collapse = ";"
    ),
    ag_market_source_urls = paste(
      sort(unique(plan_source_url[market_homeownership_evidence])),
      collapse = ";"
    ),
    .groups = "drop"
  )

latest_hpd_by_job <- hpd_links |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(
    root_job_id = matched_dob_root_job_id,
    hpd_response_number = response_number,
    hpd_option = str_to_upper(str_squish(reported_affordability_option))
  )

if (anyDuplicated(latest_hpd_by_job$root_job_id)) {
  stop("Latest HPD registration evidence is not unique by DOB root job.")
}

hpd_parent_evidence <- universe |>
  filter(sample == "post_policy") |>
  select(parent_id, root_job_id) |>
  left_join(
    latest_hpd_by_job,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  group_by(parent_id) |>
  summarise(
    hpd_registered_components = sum(!is.na(hpd_response_number)),
    hpd_option_ab = any(hpd_option %in% c("OPTION A", "OPTION B")),
    hpd_option_d = any(hpd_option == "OPTION D"),
    hpd_other_option = any(
      !is.na(hpd_option) &
        !hpd_option %in% c("OPTION A", "OPTION B", "OPTION D")
    ),
    hpd_options = paste(sort(unique(na.omit(hpd_option))), collapse = ";"),
    .groups = "drop"
  )

parent_evidence <- parent_universe |>
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
      c(
        ag_market_homeownership,
        ag_offering_plan,
        ag_accepted_offering_plan,
        ag_cps1_market_test,
        ag_financing_condominium,
        hpd_option_ab,
        hpd_option_d,
        hpd_other_option
      ),
      ~ coalesce(.x, FALSE)
    ),
    ag_queries = coalesce(ag_queries, 0L),
    ag_returned_plans = coalesce(ag_returned_plans, 0L),
    ag_all_queries_succeeded = coalesce(ag_all_queries_succeeded, FALSE),
    ag_screen_complete =
      ag_queries == ag_queryable_components &
      (ag_queries == 0L | ag_all_queries_succeeded) &
      (sample == "post_policy" | ag_queryable_components == component_filings),
    hpd_registered_components = coalesce(hpd_registered_components, 0L),
    manhattan_parent = boroughs == "Manhattan",
    conflicting_hpd_options = hpd_option_ab & hpd_option_d
  ) |>
  left_join(
    manual_reviews |>
      rename(
        manual_exposure_status = exposure_status,
        manual_confidence = confidence,
        manual_classification_reason = classification_reason,
        manual_evidence_source = evidence_source,
        manual_source_url = source_url,
        manual_review_date = review_date,
        manual_notes = notes
      ),
    by = "parent_id",
    relationship = "one-to-one"
  )

parent_exposure <- parent_evidence |>
  mutate(
    exposure_status = case_when(
      !is.na(manual_exposure_status) ~ manual_exposure_status,
      conflicting_hpd_options ~ "unresolved",
      hpd_option_ab ~ "exposed_ab",
      hpd_option_d & manhattan_parent ~ "not_exposed",
      hpd_option_d ~ "exposed_option_d",
      hpd_other_option ~ "unresolved",
      hotel_project ~ "not_exposed",
      ag_market_homeownership & manhattan_parent ~ "not_exposed",
      ag_market_homeownership ~ "exposed_option_d",
      nycha_owner ~ "not_exposed",
      government_owner ~ "unresolved",
      missing_ownership ~ "unresolved",
      !ag_screen_complete ~ "unresolved",
      TRUE ~ "exposed_ab"
    ),
    confidence = case_when(
      !is.na(manual_confidence) ~ manual_confidence,
      conflicting_hpd_options | hpd_other_option ~ "low",
      hpd_option_ab | hpd_option_d ~ "high",
      hotel_project ~ "high",
      ag_accepted_offering_plan ~ "high",
      ag_offering_plan | ag_cps1_market_test ~ "medium",
      nycha_owner ~ "medium",
      government_owner | missing_ownership | !ag_screen_complete ~ "low",
      TRUE ~ "medium"
    ),
    classification_reason = case_when(
      !is.na(manual_classification_reason) ~ manual_classification_reason,
      conflicting_hpd_options ~ "Conflicting A/B and D registrations within parent",
      hpd_option_ab ~ "Matched HPD 485-x Option A or B registration",
      hpd_option_d & manhattan_parent ~ "Option D registration conflicts with Manhattan eligibility rule",
      hpd_option_d ~ "Matched HPD 485-x Option D registration",
      hpd_other_option ~ "Matched HPD registration does not establish A/B or D exposure",
      hotel_project & sample == "historical" ~
        "23Q4 Housing Database description identifies a hotel project",
      hotel_project ~ "DOB or HDB description identifies a hotel project",
      ag_market_homeownership & manhattan_parent ~ "Matched Manhattan condominium offering or market-testing record",
      ag_market_homeownership ~ "Matched outer-borough condominium offering or market-testing record",
      nycha_owner ~ "NYCHA ownership indicates tax-exempt public-housing property absent contrary evidence",
      government_owner ~ "Government ownership observed but final taxable ownership and tax program are unresolved",
      missing_ownership ~ "Ownership evidence is missing",
      !ag_screen_complete ~ "Attorney General homeownership screen is incomplete",
      TRUE ~ "Private or nonprofit multifamily proposal with no conflicting tenure or tax evidence"
    ),
    evidence_source = case_when(
      !is.na(manual_evidence_source) ~ manual_evidence_source,
      conflicting_hpd_options | hpd_option_ab | hpd_option_d |
        hpd_other_option ~ "HPD 485-x registration",
      hotel_project & sample == "historical" ~
        "23Q4 Housing Database filing description",
      hotel_project ~ "DOB or DCP Housing Database description",
      ag_market_homeownership ~ "NYS Attorney General Real Estate Finance Database",
      (nycha_owner | government_owner | missing_ownership) &
        sample == "historical" ~
        "23Q4 Housing Database ownership and archived MapPLUTO owner",
      nycha_owner | government_owner | missing_ownership ~ "DOB and DCP Housing Database ownership",
      !ag_screen_complete & sample == "historical" ~
        "23Q4 Housing Database and archived MapPLUTO; incomplete AG screen",
      !ag_screen_complete ~ "DOB and DCP Housing Database; incomplete Attorney General screen",
      sample == "historical" ~
        "23Q4 Housing Database and archived MapPLUTO; dated AG screen",
      TRUE ~ "DOB and DCP Housing Database; negative HPD and AG screen"
    ),
    source_url = case_when(
      !is.na(manual_source_url) ~ manual_source_url,
      hpd_registered_components > 0L ~ "https://data.cityofnewyork.us/d/rrtd-iyd7",
      ag_market_homeownership ~ ag_market_source_urls,
      TRUE ~ NA_character_
    ),
    # Only manual reviews have a review date; automatic rows stay missing.
    review_date = as.Date(manual_review_date),
    included_ab = exposure_status == "exposed_ab",
    included_ab_plus_d = exposure_status %in% c(
      "exposed_ab",
      "exposed_option_d"
    )
  ) |>
  select(
    sample,
    parent_id,
    cohort_date,
    cohort_year,
    parent_total_units,
    component_filings,
    ag_queryable_components,
    component_jobs,
    addresses,
    boroughs,
    ownership_types,
    owner_names,
    exposure_status,
    included_ab,
    included_ab_plus_d,
    confidence,
    classification_reason,
    evidence_source,
    source_url,
    review_date,
    government_owner,
    nycha_owner,
    hotel_project,
    ag_queries,
    ag_all_queries_succeeded,
    ag_screen_complete,
    ag_returned_plans,
    ag_market_homeownership,
    ag_offering_plan,
    ag_accepted_offering_plan,
    ag_cps1_market_test,
    ag_financing_condominium,
    ag_market_plan_ids,
    ag_financing_plan_ids,
    hpd_registered_components,
    hpd_options,
    manual_notes
  ) |>
  arrange(sample, cohort_date, parent_id)

if (
  anyDuplicated(parent_exposure$parent_id) ||
    any(!parent_exposure$exposure_status %in% valid_statuses) ||
    any(!parent_exposure$confidence %in% valid_confidence) ||
    any(is.na(parent_exposure$included_ab)) ||
    any(is.na(parent_exposure$included_ab_plus_d)) ||
    any(is.na(parent_exposure$ag_screen_complete)) ||
    any(
      parent_exposure$ag_queries > 0L &
        !parent_exposure$ag_all_queries_succeeded
    )
) {
  stop("Final parent exposure classifications failed QC.")
}

SaveData(parent_exposure, c("sample", "parent_id"), "../output/parent_485x_exposure.csv")

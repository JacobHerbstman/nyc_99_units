# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/classify_parent_485x_exposure/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})
source("../../shared/code/write_data_report.R")

# Plausible exposure to the 485-x Option A/B rental rules for each parent,
# from HPD registrations, Attorney General condominium and cooperative plans,
# ownership and project descriptions, and manual reviews. This screens for
# potential exposure; it is not confirmed program enrollment.
historical_evidence_cutoff <- as.Date("2024-01-12")

universe <- read_csv("../output/parent_485x_exposure_universe.csv", show_col_types = FALSE, guess_max = Inf)
manual_reviews <- read_csv("parent_exposure_manual_reviews.csv", show_col_types = FALSE)
statuses <- c("exposed_ab", "exposed_option_d", "not_exposed", "unresolved")
stopifnot(!anyDuplicated(universe[c("sample", "root_job_id")]), !anyDuplicated(manual_reviews$parent_id),
  all(manual_reviews$parent_id %in% universe$parent_id), all(manual_reviews$exposure_status %in% statuses),
  all(manual_reviews$confidence %in% c("high", "medium", "low")))

# Attorney General searches: the August 26 capture and the September 22
# historical supplement. A search belongs to a filing and the exact address
# queried, so it applies only where that address is still the filing's.
read_capture <- function(path) read_csv(path, show_col_types = FALSE, guess_max = Inf)
supplement <- bind_rows(read_capture("../input/historical_ag_query_supplement_2019_2022_20260922.csv"),
  read_capture("../input/historical_ag_query_supplement_2023_companions_20260922.csv"))
supplement_counts <- supplement |>
  group_by(sample, root_job_id, search_query) |>
  summarise(counts = n_distinct(returned_plan_count), statuses = n_distinct(search_http_status),
    recorded = first(returned_plan_count), returned = sum(!is.na(plan_id)), .groups = "drop")
stopifnot(!anyNA(supplement[c("sample", "root_job_id", "search_query", "search_http_status",
    "returned_plan_count")]), all(supplement$sample == "historical"), all(supplement$search_http_status == 200L),
  !anyDuplicated(supplement[c("sample", "root_job_id", "search_query", "plan_id")]),
  all(supplement_counts$counts == 1L), all(supplement_counts$statuses == 1L),
  all(supplement_counts$recorded == supplement_counts$returned))

searches <- read_capture("../input/nys_ag_offering_plan_search_audit_20260826.csv") |>
  mutate(sample = sub("__.*$", "", parent_id)) |>
  select(-parent_id)
searches <- bind_rows(searches, supplement |> select(all_of(names(searches))) |> distinct())
plans <- read_capture("../input/nys_ag_offering_plan_matches_20260826.csv") |>
  mutate(sample = sub("__.*$", "", parent_id)) |>
  select(-parent_id)
plans <- bind_rows(plans, supplement |> filter(!is.na(plan_id)) |> select(all_of(names(plans))))
stopifnot(all(searches$search_http_status == 200L),
  !anyDuplicated(searches[c("sample", "root_job_id", "search_query")]),
  !anyDuplicated(plans[c("sample", "root_job_id", "search_query", "plan_id")]))
queries <- universe |> select(sample, root_job_id, search_query = address, parent_id)
searches <- searches |> inner_join(queries, by = c("sample", "root_job_id", "search_query"),
  relationship = "one-to-one")
plans <- plans |> inner_join(queries, by = c("sample", "root_job_id", "search_query"),
  relationship = "many-to-one")

collapse <- function(x) paste(sort(unique(na.omit(x))), collapse = ";")
parents <- universe |>
  group_by(sample, parent_id) |>
  summarise(cohort_date = first(as.Date(cohort_date)), component_filings = n(),
    ag_queryable_components = sum(!is.na(address) & address != ""), boroughs = collapse(borough_name),
    ownership_text = str_to_upper(str_squish(paste(collapse(ownership_type), collapse(owner_name)))),
    description_text = str_to_upper(str_squish(collapse(job_description))), .groups = "drop") |>
  mutate(government_owner = str_detect(ownership_text,
      "GOVERNMENT|NYCHA|NEW YORK CITY HOUSING AUTHORITY|NYC AGENCY|OTHER GOVERNMENT|CITY: HPD|CITY: HHC"),
    nycha_owner = str_detect(ownership_text, "NYCHA|NEW YORK CITY HOUSING AUTHORITY"),
    hotel_project = str_detect(description_text, "\\bHOTEL\\b"), missing_ownership = ownership_text == "",
    manhattan_parent = boroughs == "Manhattan")

# A plan is evidence for a parent when its address matches exactly, it is new
# construction, and it was submitted from two years before to five years after
# the parent's first filing; historical plans also by the 23Q4 snapshot. CD
# and CP plans are condominium offerings and market tests.
ag_evidence <- plans |>
  inner_join(parents |> select(parent_id, cohort_date), by = "parent_id", relationship = "many-to-one") |>
  mutate(submitted_date = as.Date(submitted_date), accepted_date = as.Date(accepted_date),
    years_from_proposal = as.numeric(submitted_date - cohort_date) / 365.25,
    relevant = exact_address_phrase_match & construction_type == "NEW" &
      (sample == "post_policy" | coalesce(submitted_date <= historical_evidence_cutoff, FALSE)) &
      years_from_proposal >= -2 & years_from_proposal <= 5,
    prefix = str_sub(str_to_upper(plan_id), 1L, 2L),
    market = relevant & prefix %in% c("CD", "CP")) |>
  group_by(parent_id) |>
  summarise(ag_market_homeownership = any(market), ag_offering_plan = any(market & prefix == "CD"),
    ag_accepted_offering_plan = any(market & prefix == "CD" & !is.na(accepted_date) &
      (sample == "post_policy" | accepted_date <= historical_evidence_cutoff)),
    ag_cps1_market_test = any(market & prefix == "CP"),
    ag_market_plan_ids = paste(sort(unique(plan_id[market])), collapse = ";"),
    ag_market_source_urls = paste(sort(unique(plan_source_url[market])), collapse = ";"), .groups = "drop")

# The latest HPD registration response for each matched DOB job.
hpd <- read_csv("../input/hpd_485x_registration_dob_links.csv", show_col_types = FALSE, guess_max = Inf) |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(root_job_id = matched_dob_root_job_id, hpd_response_number = response_number,
    hpd_option = str_to_upper(str_squish(reported_affordability_option)))
stopifnot(!anyDuplicated(hpd$root_job_id))
hpd_evidence <- universe |>
  filter(sample == "post_policy") |>
  select(parent_id, root_job_id) |>
  left_join(hpd, by = "root_job_id", relationship = "one-to-one") |>
  group_by(parent_id) |>
  summarise(hpd_registered = any(!is.na(hpd_response_number)),
    hpd_option_ab = any(hpd_option %in% c("OPTION A", "OPTION B")), hpd_option_d = any(hpd_option == "OPTION D"),
    hpd_other_option = any(!is.na(hpd_option) & !hpd_option %in% c("OPTION A", "OPTION B", "OPTION D")),
    hpd_options = collapse(hpd_option), .groups = "drop")

# The Attorney General screen is complete when every addressed filing was
# searched and, historically, every filing had an address.
ag_queries <- searches |> count(parent_id, name = "ag_queries")
evidence <- parents |>
  left_join(ag_queries, by = "parent_id", relationship = "one-to-one") |>
  left_join(ag_evidence, by = "parent_id", relationship = "one-to-one") |>
  left_join(hpd_evidence, by = "parent_id", relationship = "one-to-one") |>
  mutate(across(c(ag_market_homeownership, ag_offering_plan, ag_accepted_offering_plan, ag_cps1_market_test,
      hpd_registered, hpd_option_ab, hpd_option_d, hpd_other_option), ~ coalesce(.x, FALSE)),
    ag_screen_complete = coalesce(ag_queries, 0L) == ag_queryable_components &
      (sample == "post_policy" | ag_queryable_components == component_filings),
    conflicting_hpd_options = hpd_option_ab & hpd_option_d) |>
  left_join(manual_reviews |> rename_with(~ paste0("manual_", .x), -parent_id), by = "parent_id",
    relationship = "one-to-one")

exposure <- evidence |>
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
      government_owner | missing_ownership | !ag_screen_complete ~ "unresolved",
      TRUE ~ "exposed_ab"),
    confidence = case_when(
      !is.na(manual_confidence) ~ manual_confidence,
      conflicting_hpd_options | hpd_other_option ~ "low",
      hpd_option_ab | hpd_option_d | hotel_project | ag_accepted_offering_plan ~ "high",
      ag_offering_plan | ag_cps1_market_test | nycha_owner ~ "medium",
      government_owner | missing_ownership | !ag_screen_complete ~ "low",
      TRUE ~ "medium"),
    classification_reason = case_when(
      !is.na(manual_classification_reason) ~ manual_classification_reason,
      conflicting_hpd_options ~ "Conflicting A/B and D registrations within parent",
      hpd_option_ab ~ "Matched HPD 485-x Option A or B registration",
      hpd_option_d & manhattan_parent ~ "Option D registration conflicts with Manhattan eligibility rule",
      hpd_option_d ~ "Matched HPD 485-x Option D registration",
      hpd_other_option ~ "Matched HPD registration does not establish A/B or D exposure",
      hotel_project & sample == "historical" ~ "23Q4 Housing Database description identifies a hotel project",
      hotel_project ~ "DOB or HDB description identifies a hotel project",
      ag_market_homeownership & manhattan_parent ~ "Matched Manhattan condominium offering or market-testing record",
      ag_market_homeownership ~ "Matched outer-borough condominium offering or market-testing record",
      nycha_owner ~ "NYCHA ownership indicates tax-exempt public-housing property absent contrary evidence",
      government_owner ~ "Government ownership observed but final taxable ownership and tax program are unresolved",
      missing_ownership ~ "Ownership evidence is missing",
      !ag_screen_complete ~ "Attorney General homeownership screen is incomplete",
      TRUE ~ "Private or nonprofit multifamily proposal with no conflicting tenure or tax evidence"),
    evidence_source = case_when(
      !is.na(manual_evidence_source) ~ manual_evidence_source,
      conflicting_hpd_options | hpd_option_ab | hpd_option_d | hpd_other_option ~ "HPD 485-x registration",
      hotel_project & sample == "historical" ~ "23Q4 Housing Database filing description",
      hotel_project ~ "DOB or DCP Housing Database description",
      ag_market_homeownership ~ "NYS Attorney General Real Estate Finance Database",
      (nycha_owner | government_owner | missing_ownership) & sample == "historical" ~
        "23Q4 Housing Database ownership and archived MapPLUTO owner",
      nycha_owner | government_owner | missing_ownership ~ "DOB and DCP Housing Database ownership",
      !ag_screen_complete & sample == "historical" ~
        "23Q4 Housing Database and archived MapPLUTO; incomplete AG screen",
      !ag_screen_complete ~ "DOB and DCP Housing Database; incomplete Attorney General screen",
      sample == "historical" ~ "23Q4 Housing Database and archived MapPLUTO; dated AG screen",
      TRUE ~ "DOB and DCP Housing Database; negative HPD and AG screen"),
    source_url = case_when(
      !is.na(manual_source_url) ~ manual_source_url,
      hpd_registered ~ "https://data.cityofnewyork.us/d/rrtd-iyd7",
      ag_market_homeownership ~ ag_market_source_urls),
    included_ab = exposure_status == "exposed_ab",
    included_ab_plus_d = exposure_status %in% c("exposed_ab", "exposed_option_d")) |>
  arrange(sample, cohort_date, parent_id) |>
  select(sample, parent_id, exposure_status, included_ab, included_ab_plus_d, confidence, classification_reason,
    evidence_source, source_url, government_owner, nycha_owner, hotel_project, ag_screen_complete,
    ag_market_plan_ids, hpd_options)
stopifnot(all(exposure$exposure_status %in% statuses), !anyNA(exposure$included_ab))

SaveData(exposure, c("sample", "parent_id"), "../output/parent_485x_exposure.csv")

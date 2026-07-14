# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_developer_opportunity_crosswalk/code")
# anchor_year <- 2025L
# companion_start_year <- 2024L
# companion_end_year <- 2026L
# min_companion_units <- 6L
# max_companion_units <- 1000L
# bunching_units <- 99L
# nearby_meters <- 100
# review_meters <- 250
# max_filing_days <- 365L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 9L) {
  stop("Expected nine arguments: anchor year, companion start year, companion end year, minimum companion units, maximum companion units, bunching units, nearby meters, review meters, and maximum filing days.")
}

anchor_year <- as.integer(args[1])
companion_start_year <- as.integer(args[2])
companion_end_year <- as.integer(args[3])
min_companion_units <- as.integer(args[4])
max_companion_units <- as.integer(args[5])
bunching_units <- as.integer(args[6])
nearby_meters <- as.numeric(args[7])
review_meters <- as.numeric(args[8])
max_filing_days <- as.integer(args[9])

if (
  any(is.na(c(
    anchor_year, companion_start_year, companion_end_year,
    min_companion_units, max_companion_units, bunching_units,
    nearby_meters, review_meters, max_filing_days
  ))) ||
    companion_start_year > anchor_year ||
    companion_end_year < anchor_year ||
    min_companion_units <= 0L ||
    min_companion_units > bunching_units ||
    bunching_units > max_companion_units ||
    nearby_meters <= 0 ||
    review_meters < nearby_meters ||
    max_filing_days < 0L
) {
  stop("Audit arguments are not internally consistent.")
}

dob_raw <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  as.data.frame() |>
  as_tibble()

dob_filing_history <- read_parquet("../input/dob_now_new_building_filings.parquet") |>
  as.data.frame() |>
  as_tibble()

hdb_dob_panel <- read_parquet("../input/developer_response_application_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

manual_case_evidence <- read_csv(
  "../input/manual_case_evidence.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

duplicate_manual_case_jobs <- manual_case_evidence |>
  count(root_job_id, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_manual_case_jobs) > 0L) {
  stop("Manual case evidence is not unique by root_job_id.")
}

manual_parent_investigation <- read_csv(
  "../input/manual_repeated_99_parent_investigation.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

duplicate_manual_parent_groups <- manual_parent_investigation |>
  count(candidate_parent_opportunity_id, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_manual_parent_groups) > 0L) {
  stop("Manual parent investigation is not unique by candidate parent opportunity.")
}

last_observed_filing_date <- max(dob_raw$filing_date, na.rm = TRUE)

appbbl_crosswalk <- read_csv(
  "../input/mappluto_appbbl_crosswalk.csv",
  show_col_types = FALSE,
  col_types = cols(
    current_bbl = col_character(),
    appbbl = col_character(),
    .default = col_guess()
  )
) |>
  mutate(
    current_bbl = normalize_bbl_field(current_bbl),
    appbbl = normalize_bbl_field(appbbl)
  )

duplicate_appbbl_keys <- appbbl_crosswalk |>
  count(current_bbl, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_appbbl_keys) > 0L) {
  stop("APPBBL crosswalk is not unique by current_bbl.")
}

job_inventory <- dob_raw |>
  mutate(
    observed_filing_year = as.integer(format(filing_date, "%Y")),
    integer_proposed_units = !is.na(proposed_dwelling_units) &
      abs(proposed_dwelling_units - round(proposed_dwelling_units)) < 1e-8,
    dob_bbl = normalize_bbl_field(bbl),
    owner_business_clean = na_if(str_squish(owner_business_name), ""),
    owner_business_clean = if_else(
      str_to_upper(owner_business_clean) %in% c("N/A", "NA", "NONE", "NOT APPLICABLE"),
      NA_character_,
      owner_business_clean
    ),
    owner_name = coalesce(
      owner_business_clean,
      na_if(str_squish(paste(owner_first_name, owner_last_name)), "")
    ),
    owner_match_key = str_squish(str_replace_all(str_to_upper(owner_name), "[^A-Z0-9]+", " ")),
    applicant_business_clean = na_if(str_squish(applicant_business_name), ""),
    applicant_business_clean = if_else(
      str_to_upper(applicant_business_clean) %in% c("N/A", "NA", "NONE", "NOT APPLICABLE"),
      NA_character_,
      applicant_business_clean
    ),
    applicant_name = coalesce(
      applicant_business_clean,
      na_if(str_squish(paste(applicant_first_name, applicant_last_name)), "")
    ),
    applicant_match_key = str_squish(str_replace_all(str_to_upper(applicant_name), "[^A-Z0-9]+", " ")),
    applicant_license = na_if(str_squish(applicant_license), "")
  ) |>
  filter(
    job_type == "New Building",
    observed_filing_year >= companion_start_year,
    observed_filing_year <= companion_end_year,
    integer_proposed_units,
    proposed_dwelling_units >= min_companion_units,
    proposed_dwelling_units <= max_companion_units
  ) |>
  transmute(
    root_job_id = str_squish(job_number),
    dob_job_filing_number = str_squish(job_filing_number),
    dob_bin = na_if(str_squish(bin), ""),
    filing_date,
    filing_year = observed_filing_year,
    filing_status,
    current_status_date,
    approved_date,
    first_permit_date,
    signoff_date,
    proposed_units = as.integer(round(proposed_dwelling_units)),
    is_anchor_bunching_job = filing_year == anchor_year & proposed_units == bunching_units,
    dob_bbl,
    borough_code = standardize_borough_code(borough_code),
    block = as.integer(block),
    lot = as.integer(lot),
    provisional_filing_bbl_site_id = if_else(
      is.na(dob_bbl),
      NA_character_,
      paste0("filing_bbl_", dob_bbl)
    ),
    address,
    latitude,
    longitude,
    owner_name,
    owner_match_key = na_if(owner_match_key, ""),
    applicant_name,
    applicant_match_key = na_if(applicant_match_key, ""),
    applicant_license,
    job_description,
    description_referenced_job_id = str_extract(str_to_upper(job_description), "[A-Z][0-9]{8}"),
    description_project_code = str_remove_all(
      str_extract(str_to_upper(job_description), "MPP\\s*[0-9]+"),
      "\\s"
    ),
    total_construction_floor_area,
    proposed_stories,
    proposed_height,
    initial_cost
  ) |>
  arrange(filing_date, root_job_id)

duplicate_root_jobs <- job_inventory |>
  count(root_job_id, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_root_jobs) > 0L) {
  stop("DOB root_job_id is not unique in the audit sample.")
}

if (any(is.na(job_inventory$root_job_id))) {
  stop("Audit sample contains a missing root_job_id.")
}

job_inventory <- job_inventory |>
  left_join(
    appbbl_crosswalk |>
      select(
        dob_bbl = current_bbl,
        appbbl_source_id = source_id,
        appbbl_vintage = vintage,
        historical_appbbl = appbbl,
        appbbl_evidence_rows = evidence_rows,
        appbbl_date_min = appdate_min,
        appbbl_date_max = appdate_max
      ),
    by = "dob_bbl",
    relationship = "many-to-one"
  ) |>
  mutate(
    lot_history_group_bbl = coalesce(historical_appbbl, dob_bbl),
    appbbl_change_after_filing = !is.na(appbbl_date_min) & appbbl_date_min > filing_date,
    eligible_site_status = "not_legally_validated"
  ) |>
  mutate(row_id = row_number(), .before = 1L)

if (nrow(job_inventory) < 2L) {
  stop("Audit sample needs at least two root jobs to construct candidate pairs.")
}

pair_index <- t(combn(seq_len(nrow(job_inventory)), 2L))

candidate_pairs <- bind_cols(
  job_inventory[pair_index[, 1L], ] |>
    select(
      row_id, root_job_id, filing_date, filing_year, proposed_units, is_anchor_bunching_job,
      dob_bbl, dob_bin, borough_code, block, lot, lot_history_group_bbl,
      address, latitude, longitude, owner_name, owner_match_key,
      applicant_name, applicant_match_key, applicant_license,
      description_referenced_job_id, description_project_code
    ) |>
    rename_with(~ paste0(.x, "_1")),
  job_inventory[pair_index[, 2L], ] |>
    select(
      row_id, root_job_id, filing_date, filing_year, proposed_units, is_anchor_bunching_job,
      dob_bbl, dob_bin, borough_code, block, lot, lot_history_group_bbl,
      address, latitude, longitude, owner_name, owner_match_key,
      applicant_name, applicant_match_key, applicant_license,
      description_referenced_job_id, description_project_code
    ) |>
    rename_with(~ paste0(.x, "_2"))
) |>
  mutate(
    filing_days_apart = abs(as.integer(filing_date_1 - filing_date_2)),
    distance_meters = 6371000 * pi / 180 * sqrt(
      ((longitude_2 - longitude_1) * cos((latitude_1 + latitude_2) * pi / 360))^2 +
        (latitude_2 - latitude_1)^2
    ),
    same_filing_bbl = !is.na(dob_bbl_1) & dob_bbl_1 == dob_bbl_2,
    same_lot_history_group = !is.na(lot_history_group_bbl_1) &
      lot_history_group_bbl_1 == lot_history_group_bbl_2,
    same_borough_block = !is.na(borough_code_1) & !is.na(block_1) &
      borough_code_1 == borough_code_2 & block_1 == block_2,
    same_owner = !is.na(owner_match_key_1) & owner_match_key_1 == owner_match_key_2,
    same_applicant_business = !is.na(applicant_match_key_1) &
      applicant_match_key_1 == applicant_match_key_2,
    same_applicant_license = !is.na(applicant_license_1) &
      applicant_license_1 == applicant_license_2,
    description_cross_references_pair =
      (!is.na(description_referenced_job_id_1) & description_referenced_job_id_1 == root_job_id_2) |
      (!is.na(description_referenced_job_id_2) & description_referenced_job_id_2 == root_job_id_1),
    same_description_project_code = !is.na(description_project_code_1) &
      description_project_code_1 == description_project_code_2,
    within_nearby_distance = !is.na(distance_meters) & distance_meters <= nearby_meters,
    within_review_distance = !is.na(distance_meters) & distance_meters <= review_meters,
    within_filing_window = filing_days_apart <= max_filing_days,
    strong_parent_link = within_filing_window & (
      same_filing_bbl |
        same_lot_history_group |
        description_cross_references_pair |
        same_description_project_code |
        (same_owner & within_nearby_distance)
    ),
    candidate_reason = case_when(
      same_filing_bbl ~ "same_filing_bbl",
      same_lot_history_group ~ "same_mappluto_lot_history_group",
      description_cross_references_pair ~ "dob_description_cross_reference",
      same_description_project_code ~ "same_dob_description_project_code",
      same_owner & within_nearby_distance ~ "same_owner_nearby",
      same_owner & within_review_distance ~ "same_owner_review_radius_only",
      same_borough_block & same_owner ~ "same_owner_same_block",
      same_borough_block & (same_applicant_business | same_applicant_license) ~ "same_applicant_same_block",
      same_borough_block ~ "same_block_only",
      TRUE ~ NA_character_
    ),
    review_priority = case_when(
      strong_parent_link ~ "linked_by_main_rule",
      proposed_units_1 == bunching_units & proposed_units_2 == bunching_units &
        same_borough_block & !is.na(distance_meters) & distance_meters <= nearby_meters ~
        "high_repeated_99_different_owner",
      same_borough_block & !is.na(distance_meters) & distance_meters <= 25 ~
        "high_adjacent_different_owner",
      same_owner & within_review_distance ~ "medium_same_owner_review_radius",
      same_borough_block & !is.na(distance_meters) & distance_meters <= nearby_meters ~
        "medium_same_block_nearby",
      TRUE ~ "low_same_block"
    )
  ) |>
  filter(
    is_anchor_bunching_job_1 | is_anchor_bunching_job_2,
    within_filing_window,
    same_filing_bbl |
      same_lot_history_group |
      description_cross_references_pair |
      same_description_project_code |
      same_borough_block |
      (same_owner & within_review_distance)
  ) |>
  arrange(desc(strong_parent_link), root_job_id_1, root_job_id_2)

unresolved_pair_review <- candidate_pairs |>
  filter(!strong_parent_link) |>
  arrange(review_priority, root_job_id_1, root_job_id_2)

component <- seq_len(nrow(job_inventory))
strong_links <- candidate_pairs |>
  filter(strong_parent_link) |>
  select(row_id_1, row_id_2)

if (nrow(strong_links) > 0L) {
  for (i in seq_len(nrow(strong_links))) {
    left_component <- component[strong_links$row_id_1[i]]
    right_component <- component[strong_links$row_id_2[i]]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <- merged_component
  }
}

component_lookup <- tibble(
  row_id = seq_len(nrow(job_inventory)),
  component
) |>
  left_join(
    job_inventory |>
      select(row_id, is_anchor_bunching_job),
    by = "row_id",
    relationship = "one-to-one"
  ) |>
  group_by(component) |>
  mutate(component_contains_bunching_job = any(is_anchor_bunching_job)) |>
  ungroup()

candidate_component_ids <- component_lookup |>
  filter(component_contains_bunching_job) |>
  distinct(component) |>
  arrange(component) |>
  mutate(candidate_parent_opportunity_id = sprintf("parent_candidate_%d_%03d", anchor_year, row_number()))

component_lookup <- component_lookup |>
  left_join(
    candidate_component_ids,
    by = "component",
    relationship = "many-to-one"
  )

job_link_evidence <- bind_rows(
  candidate_pairs |>
    filter(strong_parent_link) |>
    transmute(
      row_id = row_id_1,
      linked_job_id = root_job_id_2,
      same_filing_bbl,
      same_lot_history_group,
      same_owner_nearby = same_owner & within_nearby_distance,
      description_cross_references_pair,
      same_description_project_code
    ),
  candidate_pairs |>
    filter(strong_parent_link) |>
    transmute(
      row_id = row_id_2,
      linked_job_id = root_job_id_1,
      same_filing_bbl,
      same_lot_history_group,
      same_owner_nearby = same_owner & within_nearby_distance,
      description_cross_references_pair,
      same_description_project_code
    )
) |>
  group_by(row_id) |>
  summarise(
    strong_linked_jobs = n_distinct(linked_job_id),
    has_same_filing_bbl_link = any(same_filing_bbl),
    has_same_lot_history_group_link = any(same_lot_history_group),
    has_same_owner_nearby_link = any(same_owner_nearby),
    has_dob_description_cross_reference_link = any(description_cross_references_pair),
    has_same_description_project_code_link = any(same_description_project_code),
    .groups = "drop"
  )

job_crosswalk <- job_inventory |>
  left_join(
    component_lookup |>
      select(row_id, candidate_parent_opportunity_id, component_contains_bunching_job),
    by = "row_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    job_link_evidence,
    by = "row_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    strong_linked_jobs = coalesce(strong_linked_jobs, 0L),
    has_same_filing_bbl_link = coalesce(has_same_filing_bbl_link, FALSE),
    has_same_lot_history_group_link = coalesce(has_same_lot_history_group_link, FALSE),
    has_same_owner_nearby_link = coalesce(has_same_owner_nearby_link, FALSE),
    has_dob_description_cross_reference_link = coalesce(has_dob_description_cross_reference_link, FALSE),
    has_same_description_project_code_link = coalesce(has_same_description_project_code_link, FALSE),
    forward_search_window_complete = if_else(
      is_anchor_bunching_job,
      filing_date + max_filing_days <= last_observed_filing_date,
      NA
    )
  ) |>
  select(-component_contains_bunching_job, -row_id)

if (any(is.na(job_crosswalk$candidate_parent_opportunity_id[job_crosswalk$is_anchor_bunching_job]))) {
  stop("Every bunching job should belong to a candidate parent opportunity, including singleton candidates.")
}

candidate_groups <- job_crosswalk |>
  filter(!is.na(candidate_parent_opportunity_id)) |>
  group_by(candidate_parent_opportunity_id) |>
  summarise(
    root_jobs = n_distinct(root_job_id),
    bunching_jobs = sum(is_anchor_bunching_job),
    proposed_units_sum = sum(proposed_units),
    distinct_filing_bbls = n_distinct(dob_bbl, na.rm = TRUE),
    distinct_bins = n_distinct(dob_bin, na.rm = TRUE),
    distinct_filing_years = n_distinct(filing_year),
    distinct_owner_keys = n_distinct(owner_match_key, na.rm = TRUE),
    approved_or_permitted_jobs = sum(filing_status %in% c("Approved", "Permit Entire")),
    withdrawn_jobs = sum(filing_status == "Filing Withdrawn"),
    first_filing_date = min(filing_date),
    last_filing_date = max(filing_date),
    job_numbers = paste(sort(unique(root_job_id)), collapse = ";"),
    proposed_units = paste(proposed_units[order(root_job_id)], collapse = ";"),
    filing_bbls = paste(sort(unique(dob_bbl[!is.na(dob_bbl)])), collapse = ";"),
    owner_names = paste(sort(unique(owner_name[!is.na(owner_name)])), collapse = " | "),
    addresses = paste(sort(unique(address[!is.na(address)])), collapse = " | "),
    .groups = "drop"
  ) |>
  mutate(
    multiple_root_jobs = root_jobs > 1L,
    multiple_buildings = distinct_bins > 1L,
    multiple_filing_bbls = distinct_filing_bbls > 1L,
    review_status = if_else(multiple_buildings, "candidate_multi_building_review", "single_dob_building")
  ) |>
  arrange(desc(multiple_buildings), candidate_parent_opportunity_id)

anchor_job_ids <- job_crosswalk |>
  filter(is_anchor_bunching_job) |>
  pull(root_job_id)

paa_history <- dob_filing_history |>
  filter(
    job_number %in% anchor_job_ids,
    str_detect(filing_type, "^P[0-9]+$")
  )

paa_unit_conflicts <- paa_history |>
  group_by(job_number, job_filing_number) |>
  summarise(
    distinct_unit_values = n_distinct(proposed_dwelling_units, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(distinct_unit_values > 1L)

if (nrow(paa_unit_conflicts) > 0L) {
  stop("A PAA filing reports conflicting proposed dwelling-unit values.")
}

paa_latest_status <- paa_history |>
  arrange(
    job_number,
    desc(current_status_date),
    desc(filing_date),
    desc(source_row_number)
  ) |>
  distinct(job_number, .keep_all = TRUE) |>
  transmute(
    root_job_id = job_number,
    latest_paa_filing_number = job_filing_number,
    latest_paa_filing_date = filing_date,
    latest_paa_status = filing_status,
    latest_paa_status_date = current_status_date,
    latest_paa_units = proposed_dwelling_units
  )

filing_history_summary <- dob_filing_history |>
  filter(job_number %in% anchor_job_ids) |>
  group_by(job_number) |>
  summarise(
    observed_related_filing_numbers = n_distinct(job_filing_number),
    observed_subsequent_filing_numbers = n_distinct(
      job_filing_number[str_detect(filing_type, "^S[0-9]+$")]
    ),
    observed_paa_filing_numbers = n_distinct(
      job_filing_number[str_detect(filing_type, "^P[0-9]+$")]
    ),
    first_paa_filing_date = safe_min_date(
      filing_date[str_detect(filing_type, "^P[0-9]+$")]
    ),
    paa_unit_values = paste(
      sort(unique(proposed_dwelling_units[
        str_detect(filing_type, "^P[0-9]+$") & !is.na(proposed_dwelling_units)
      ])),
      collapse = ";"
    ),
    .groups = "drop"
  ) |>
  rename(root_job_id = job_number) |>
  mutate(
    paa_unit_values = na_if(paa_unit_values, ""),
    observed_paa = observed_paa_filing_numbers > 0L,
    all_observed_paa_units_remain_99 = observed_paa & paa_unit_values == as.character(bunching_units)
  ) |>
  left_join(
    paa_latest_status,
    by = "root_job_id",
    relationship = "one-to-one"
  )

hdb_case_fields <- hdb_dob_panel |>
  filter(job_number %in% anchor_job_ids) |>
  select(
    root_job_id = job_number,
    hdb_filing_date,
    hdb_job_status,
    hdb_units,
    hdb_bbl,
    hdb_bin,
    hdb_date_permit,
    hdb_date_completed,
    hdb_dob_units_agree = units_agree,
    hdb_dob_bbl_agree = bbl_agree,
    hdb_dob_bin_agree = bin_agree
  )

duplicate_hdb_case_jobs <- hdb_case_fields |>
  count(root_job_id, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_hdb_case_jobs) > 0L) {
  stop("HDB case fields are not unique by root job.")
}

high_priority_unresolved_pairs <- unresolved_pair_review |>
  filter(str_starts(review_priority, "high_"))

high_priority_unresolved_job_ids <- bind_rows(
  high_priority_unresolved_pairs |>
    filter(is_anchor_bunching_job_1) |>
    transmute(root_job_id = root_job_id_1),
  high_priority_unresolved_pairs |>
    filter(is_anchor_bunching_job_2) |>
    transmute(root_job_id = root_job_id_2)
) |>
  distinct(root_job_id) |>
  pull(root_job_id)

exact_99_casebook <- job_crosswalk |>
  filter(is_anchor_bunching_job) |>
  left_join(
    candidate_groups |>
      select(
        candidate_parent_opportunity_id,
        root_jobs,
        bunching_jobs,
        proposed_units_sum,
        distinct_filing_bbls,
        distinct_bins,
        multiple_buildings
      ),
    by = "candidate_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    filing_history_summary,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    hdb_case_fields,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    manual_case_evidence,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    manual_parent_investigation,
    by = "candidate_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    candidate_parent_structure = case_when(
      !multiple_buildings ~ "currently_unlinked_99_building",
      bunching_jobs == 1L ~ "one_99_with_non_99_companion_buildings",
      bunching_jobs >= 2L ~ "repeated_99_candidate_parent"
    ),
    grouping_evidence_tier = case_when(
      has_dob_description_cross_reference_link | has_same_description_project_code_link ~
        "direct_dob_project_reference",
      has_same_filing_bbl_link | has_same_lot_history_group_link ~
        "direct_tax_lot_or_lot_history_link",
      has_same_owner_nearby_link ~ "same_owner_within_main_radius",
      TRUE ~ "no_strong_companion_link"
    ),
    observed_unit_transition = case_when(
      observed_paa & all_observed_paa_units_remain_99 ~ "initial_99_observed_paa_still_99",
      observed_paa ~ "initial_99_observed_paa_changed_units",
      TRUE ~ "initial_99_no_paa_observed"
    ),
    legal_485x_site_status = "not_validated",
    rental_485x_eligibility_status = "not_validated",
    case_review_priority = case_when(
      candidate_parent_structure == "repeated_99_candidate_parent" ~
        "1_repeated_99_candidate_parent",
      root_job_id %in% high_priority_unresolved_job_ids ~
        "2_high_priority_different_owner_pair",
      candidate_parent_structure == "one_99_with_non_99_companion_buildings" ~
        "3_one_99_with_other_buildings",
      !forward_search_window_complete ~ "4_currently_unlinked_right_censored",
      TRUE ~ "5_currently_unlinked_full_window"
    ),
    next_record_needed = case_when(
      candidate_parent_structure == "repeated_99_candidate_parent" ~
        "HPD registration/docket; DOB zoning-lot plans; tax-lot history at commencement; Comptroller notice",
      root_job_id %in% high_priority_unresolved_job_ids ~
        "Beneficial ownership and common financing; DOB zoning-lot plans; HPD registration/docket",
      candidate_parent_structure == "one_99_with_non_99_companion_buildings" ~
        "DOB zoning-lot plans; tax-lot history at commencement; HPD registration/docket",
      !forward_search_window_complete ~
        "Refresh DOB companion search; establish rental tenure and 485-x participation; HPD registration/docket",
      TRUE ~
        "Establish rental tenure and 485-x participation; HPD registration/docket; zoning-lot confirmation"
    )
  ) |>
  select(
    case_review_priority,
    root_job_id,
    dob_job_filing_number,
    dob_bin,
    filing_date,
    filing_status,
    current_status_date,
    approved_date,
    first_permit_date,
    proposed_units,
    dob_bbl,
    historical_appbbl,
    appbbl_date_min,
    address,
    borough_code,
    block,
    lot,
    owner_name,
    applicant_name,
    candidate_parent_opportunity_id,
    candidate_parent_structure,
    grouping_evidence_tier,
    root_jobs_in_parent = root_jobs,
    buildings_in_parent = distinct_bins,
    bunching_jobs_in_parent = bunching_jobs,
    parent_proposed_units_sum = proposed_units_sum,
    parent_filing_bbls = distinct_filing_bbls,
    has_same_filing_bbl_link,
    has_same_lot_history_group_link,
    has_same_owner_nearby_link,
    has_dob_description_cross_reference_link,
    has_same_description_project_code_link,
    forward_search_window_complete,
    observed_related_filing_numbers,
    observed_subsequent_filing_numbers,
    observed_paa_filing_numbers,
    first_paa_filing_date,
    latest_paa_filing_number,
    latest_paa_filing_date,
    latest_paa_status,
    latest_paa_status_date,
    latest_paa_units,
    paa_unit_values,
    observed_unit_transition,
    hdb_filing_date,
    hdb_job_status,
    hdb_units,
    hdb_bbl,
    hdb_bin,
    hdb_date_permit,
    hdb_date_completed,
    hdb_dob_units_agree,
    hdb_dob_bbl_agree,
    hdb_dob_bin_agree,
    total_construction_floor_area,
    proposed_stories,
    proposed_height,
    job_description,
    external_evidence_status,
    external_evidence_note,
    external_source_url,
    investigation_status,
    common_parent_assessment,
    avoidance_assessment,
    investigation_note,
    external_parent_source_url,
    external_context_source_url,
    legal_485x_site_status,
    rental_485x_eligibility_status,
    next_record_needed
  ) |>
  arrange(case_review_priority, candidate_parent_opportunity_id, root_job_id)

if (nrow(exact_99_casebook) != 52L || n_distinct(exact_99_casebook$root_job_id) != 52L) {
  stop("Exact-99 casebook must contain 52 unique root jobs.")
}

repeated_99_parent_ids <- exact_99_casebook |>
  filter(candidate_parent_structure == "repeated_99_candidate_parent") |>
  distinct(candidate_parent_opportunity_id)

if (
  nrow(repeated_99_parent_ids) != 10L ||
    any(!repeated_99_parent_ids$candidate_parent_opportunity_id %in%
      manual_parent_investigation$candidate_parent_opportunity_id)
) {
  stop("Every repeated-99 candidate parent must have one manual investigation record.")
}

bunching_job_structure <- job_crosswalk |>
  filter(is_anchor_bunching_job) |>
  left_join(
    candidate_groups |>
      select(candidate_parent_opportunity_id, multiple_buildings, bunching_jobs),
    by = "candidate_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    bunching_structure = case_when(
      !multiple_buildings ~ "One 99-unit DOB building",
      bunching_jobs == 1L ~ "One 99-unit building plus other building(s)",
      bunching_jobs >= 2L ~ "Multiple 99-unit buildings in one candidate parent"
    )
  )

bunching_decomposition <- bind_rows(
  bunching_job_structure |>
    mutate(sample = "All 2025 99-unit jobs"),
  bunching_job_structure |>
    filter(forward_search_window_complete) |>
    mutate(sample = "Complete 365-day forward search window")
) |>
  group_by(sample, bunching_structure) |>
  summarise(
    bunching_jobs = n(),
    candidate_parent_opportunities = n_distinct(candidate_parent_opportunity_id),
    .groups = "drop"
  ) |>
  group_by(sample) |>
  mutate(share_of_bunching_jobs = bunching_jobs / sum(bunching_jobs)) |>
  ungroup() |>
  mutate(
    bunching_structure = factor(
      bunching_structure,
      levels = c(
        "One 99-unit DOB building",
        "One 99-unit building plus other building(s)",
        "Multiple 99-unit buildings in one candidate parent"
      )
    )
  ) |>
  arrange(sample, bunching_structure) |>
  mutate(bunching_structure = as.character(bunching_structure))

crosswalk_qc <- tibble(
  metric = c(
    "companion_universe_root_jobs",
    "unique_root_jobs",
    "first_companion_filing_year",
    "last_companion_filing_year",
    "bunching_jobs",
    "bunching_jobs_with_complete_forward_window",
    "withdrawn_bunching_jobs",
    "bunching_jobs_with_observed_paa",
    "bunching_jobs_with_paa_still_99",
    "bunching_jobs_with_paa_unit_change",
    "bunching_jobs_matched_to_hdb",
    "bunching_jobs_hdb_dob_bbl_disagree",
    "bunching_jobs_hdb_dob_bin_disagree",
    "bunching_filing_bbls",
    "missing_filing_bbl",
    "missing_bin",
    "missing_owner_match_key",
    "missing_applicant_match_key",
    "missing_coordinates",
    "jobs_with_appbbl_history",
    "appbbl_changes_dated_after_filing",
    "candidate_pairs",
    "strong_parent_links",
    "dob_description_cross_reference_pairs",
    "same_description_project_code_pairs",
    "unresolved_candidate_pairs",
    "high_priority_unresolved_pairs",
    "same_owner_pairs_in_review_radius_only",
    "bunching_anchored_candidate_groups",
    "multi_building_candidate_groups",
    "multi_bbl_candidate_groups"
  ),
  value = c(
    nrow(job_crosswalk),
    n_distinct(job_crosswalk$root_job_id),
    min(job_crosswalk$filing_year),
    max(job_crosswalk$filing_year),
    sum(job_crosswalk$is_anchor_bunching_job),
    sum(job_crosswalk$forward_search_window_complete, na.rm = TRUE),
    sum(job_crosswalk$is_anchor_bunching_job & job_crosswalk$filing_status == "Filing Withdrawn"),
    sum(exact_99_casebook$observed_paa_filing_numbers > 0L),
    sum(exact_99_casebook$observed_unit_transition == "initial_99_observed_paa_still_99"),
    sum(exact_99_casebook$observed_unit_transition == "initial_99_observed_paa_changed_units"),
    sum(!is.na(exact_99_casebook$hdb_units)),
    sum(!exact_99_casebook$hdb_dob_bbl_agree, na.rm = TRUE),
    sum(!exact_99_casebook$hdb_dob_bin_agree, na.rm = TRUE),
    n_distinct(job_crosswalk$dob_bbl[job_crosswalk$is_anchor_bunching_job], na.rm = TRUE),
    sum(is.na(job_crosswalk$dob_bbl)),
    sum(is.na(job_crosswalk$dob_bin)),
    sum(is.na(job_crosswalk$owner_match_key)),
    sum(is.na(job_crosswalk$applicant_match_key)),
    sum(is.na(job_crosswalk$latitude) | is.na(job_crosswalk$longitude)),
    sum(!is.na(job_crosswalk$historical_appbbl)),
    sum(job_crosswalk$appbbl_change_after_filing, na.rm = TRUE),
    nrow(candidate_pairs),
    sum(candidate_pairs$strong_parent_link),
    sum(candidate_pairs$description_cross_references_pair),
    sum(candidate_pairs$same_description_project_code),
    nrow(unresolved_pair_review),
    sum(str_starts(unresolved_pair_review$review_priority, "high_")),
    sum(candidate_pairs$same_owner & candidate_pairs$within_review_distance & !candidate_pairs$within_nearby_distance),
    nrow(candidate_groups),
    sum(candidate_groups$multiple_buildings),
    sum(candidate_groups$multiple_filing_bbls)
  )
)

write_parquet_if_changed(job_crosswalk, "../output/developer_opportunity_job_crosswalk.parquet")
write_csv_if_changed(candidate_pairs, "../output/developer_opportunity_candidate_pairs.csv")
write_csv_if_changed(unresolved_pair_review, "../output/developer_opportunity_unresolved_pair_review.csv")
write_csv_if_changed(candidate_groups, "../output/developer_opportunity_candidate_groups.csv")
write_csv_if_changed(exact_99_casebook, "../output/developer_opportunity_exact_99_casebook.csv")
write_csv_if_changed(bunching_decomposition, "../output/developer_opportunity_bunching_decomposition.csv")
write_csv_if_changed(crosswalk_qc, "../output/developer_opportunity_crosswalk_qc.csv")

cat("Wrote the developer opportunity crosswalk audit outputs.\n")

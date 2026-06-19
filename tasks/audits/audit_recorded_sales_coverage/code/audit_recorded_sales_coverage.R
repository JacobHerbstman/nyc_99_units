# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_recorded_sales_coverage/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

price_low_cutoff <- 250000
date_window_days <- 14
high_priority_price_cutoff <- 1000000

flat_character <- function(x) {
  if (is.list(x)) {
    return(vapply(
      x,
      function(value) {
        value <- as.character(value)
        value <- value[!is.na(value) & value != ""]
        paste(unique(value), collapse = ";")
      },
      character(1)
    ))
  }

  as.character(x)
}

summarise_coverage <- function(df) {
  df |>
    summarise(
      dof_primary_candidate_rows = n(),
      dof_primary_candidate_bbls = n_distinct(sale_bbl),
      dof_primary_candidate_value = sum(sale_price, na.rm = TRUE),
      matched_reviewed_acris_rows = sum(!is.na(event_id)),
      matched_primary_acris_rows = sum(match_status == "DOF_EXACT_ACRIS_EVENT_MATCH"),
      matched_excluded_acris_rows = sum(match_status == "DOF_MATCHES_ACRIS_EXCLUDED_BY_RULE"),
      price_conflict_rows = sum(match_status == "DOF_PRICE_CONFLICT"),
      dof_only_high_confidence_rows = sum(match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS"),
      dof_only_low_confidence_rows = sum(match_status == "DOF_ONLY_LOW_CONFIDENCE"),
      matched_reviewed_acris_value = sum(sale_price[!is.na(event_id)], na.rm = TRUE),
      dof_only_high_confidence_value = sum(sale_price[match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS"], na.rm = TRUE),
      match_rate_rows = round(matched_reviewed_acris_rows / dof_primary_candidate_rows, 4),
      match_rate_value = round(matched_reviewed_acris_value / dof_primary_candidate_value, 4),
      high_confidence_miss_rate_rows = round(dof_only_high_confidence_rows / dof_primary_candidate_rows, 4),
      .groups = "drop"
    )
}

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    opportunity_bbl = normalize_bbl_field(bbl),
    opportunity_borough = borough,
    opportunity_block = block,
    opportunity_lot = lot,
    opportunity_address = address,
    cd, zipcode, council,
    primary_opp50_850,
    lotarea,
    allowed_policy_res_sqft,
    residual_policy_res_sqft,
    capacity_units_850,
    capacity50_850,
    capacity100_850,
    capacity_exposure_pctile_citywide,
    capacity_exposure_quartile_citywide,
    capacity_exposure_pctile_borough,
    capacity_exposure_quartile_borough
  ) |>
  filter(primary_opp50_850, !is.na(opportunity_bbl), opportunity_borough != "5")

if (anyDuplicated(opportunity_lots$opportunity_bbl) > 0L) {
  stop("Frozen opportunity lots are not unique by BBL.")
}

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    sale_record_id = str_squish(as.character(sale_record_id)),
    sale_bbl = normalize_bbl_field(bbl),
    sale_borough_code = standardize_borough_code(borough_code),
    block_number,
    lot_number,
    sale_date = as.Date(sale_date),
    sale_year = as.integer(sale_year),
    sale_quarter_start = floor_date(sale_date, "quarter"),
    sale_price,
    positive_sale_price,
    sale_date_in_source_year,
    neighborhood,
    dof_address = address,
    building_class_category,
    tax_class_at_present,
    building_class_at_present,
    tax_class_at_time_of_sale,
    building_class_at_time_of_sale,
    residential_units,
    commercial_units,
    total_units,
    land_square_feet,
    gross_square_feet,
    year_built,
    source_year,
    source_borough,
    source_row_number
  )

if (anyDuplicated(dof_sales$sale_record_id) > 0L) {
  stop("DOF annualized sales are not unique by sale_record_id.")
}

dof_opportunity_sales <- dof_sales |>
  left_join(opportunity_lots, by = c("sale_bbl" = "opportunity_bbl"), relationship = "many-to-one") |>
  mutate(
    dof_exact_opportunity_bbl = !is.na(opportunity_borough),
    dof_non_staten_island = sale_borough_code != "5",
    dof_in_sales_window = !is.na(sale_date) & sale_date >= as.Date("2010-01-01") & sale_date <= as.Date("2025-12-31"),
    dof_positive_sale_price = !is.na(sale_price) & sale_price > 0,
    dof_above_low_price_cutoff = !is.na(sale_price) & sale_price > price_low_cutoff,
    dof_class_text = str_squish(str_to_upper(paste(
      building_class_category,
      tax_class_at_present,
      building_class_at_present,
      tax_class_at_time_of_sale,
      building_class_at_time_of_sale
    ))),
    dof_condo_or_unit_churn_like = coalesce(lot_number >= 7500L, FALSE) |
      str_detect(dof_class_text, regex("CONDO|CONDOMINIUM|COOP|CO-OP|COOPERATIVE|ONE FAMILY|TWO FAMILY|THREE FAMILY|TAX CLASS 1", ignore_case = TRUE)) |
      str_detect(str_to_upper(coalesce(building_class_at_time_of_sale, "")), "^R"),
    dof_broad_recorded_sale_candidate = dof_exact_opportunity_bbl &
      dof_non_staten_island &
      dof_in_sales_window &
      coalesce(sale_date_in_source_year, FALSE) &
      dof_positive_sale_price,
    dof_primary_recorded_sale_candidate = dof_broad_recorded_sale_candidate &
      dof_above_low_price_cutoff &
      !dof_condo_or_unit_churn_like,
    sale_price_bin = case_when(
      is.na(sale_price) ~ "missing",
      sale_price < high_priority_price_cutoff ~ "250k_to_1m",
      sale_price < 5000000 ~ "1m_to_5m",
      sale_price < 20000000 ~ "5m_to_20m",
      TRUE ~ "20m_plus"
    ),
    policy_period = case_when(
      sale_date < as.Date("2022-06-15") ~ "pre_2022_06_15",
      sale_date < as.Date("2024-01-01") ~ "transition_2022_06_15_to_2023",
      TRUE ~ "post_2024"
    )
  ) |>
  group_by(sale_borough_code, sale_date, sale_price) |>
  mutate(
    dof_same_borough_date_price_rows = n(),
    dof_same_borough_date_price_bbls = n_distinct(sale_bbl)
  ) |>
  ungroup()

dof_primary_sales <- dof_opportunity_sales |>
  filter(dof_primary_recorded_sale_candidate)

acris_events <- read_parquet("../input/acris_private_market_site_sale_events.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    event_id = str_squish(as.character(event_id)),
    event_date_primary = as.Date(event_date_primary),
    event_price_final,
    event_inclusion_status,
    event_primary_private_sale,
    event_strict_private_sale,
    event_broad_priced_transfer,
    event_primary_exclusion_reason,
    event_low_price_flag,
    event_low_opportunity_share_flag,
    event_very_low_opportunity_share_flag,
    unit_churn_flag,
    rights_only_flag,
    mixed_rights_flag,
    public_party_flag,
    hdfc_party_flag,
    housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag,
    trust_estate_party_flag,
    related_party_strong_flag,
    related_party_weak_flag,
    source_document_ids = flat_character(source_document_ids),
    crfns = flat_character(crfns),
    buyer_names = flat_character(buyer_names),
    seller_names = flat_character(seller_names),
    review_cluster_id,
    reviewer_final_ruling,
    manual_review_status,
    source_confidence
  )

if (anyDuplicated(acris_events$event_id) > 0L) {
  stop("Reviewed ACRIS private-market sale events are not unique by event_id.")
}

acris_incidence <- read_parquet("../input/acris_private_market_site_sale_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    acris_incidence_id = paste(str_squish(as.character(event_id)), normalize_bbl_field(opportunity_bbl), sep = "::"),
    event_id = str_squish(as.character(event_id)),
    opportunity_bbl = normalize_bbl_field(opportunity_bbl),
    opportunity_borough,
    opportunity_block,
    opportunity_lot,
    acris_address = address,
    event_date_primary = as.Date(event_date_primary),
    event_year = year(as.Date(event_date_primary)),
    event_quarter_start = as.Date(event_quarter_start),
    event_price_final,
    event_inclusion_status,
    event_primary_private_sale,
    event_strict_private_sale,
    event_broad_priced_transfer,
    event_primary_exclusion_reason,
    incidence_primary_exclusion_reason,
    event_low_price_flag,
    event_low_opportunity_share_flag,
    event_very_low_opportunity_share_flag,
    unit_churn_flag,
    rights_only_flag,
    mixed_rights_flag,
    public_party_flag,
    hdfc_party_flag,
    housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag,
    trust_estate_party_flag,
    related_party_strong_flag,
    related_party_weak_flag,
    source_document_ids = flat_character(source_document_ids),
    crfns = flat_character(crfns),
    buyer_names = flat_character(buyer_names),
    seller_names = flat_character(seller_names),
    review_cluster_id,
    reviewer_final_ruling,
    manual_review_status,
    source_confidence,
    lotarea,
    allowed_policy_res_sqft,
    residual_policy_res_sqft,
    capacity_units_850,
    capacity50_850,
    capacity100_850,
    capacity_exposure_pctile_citywide,
    capacity_exposure_quartile_citywide,
    price_per_allowed_res_sqft,
    price_per_lot_sqft
  ) |>
  filter(
    !is.na(opportunity_bbl),
    opportunity_borough != "5",
    !is.na(event_date_primary),
    !is.na(event_price_final)
  )

if (anyDuplicated(acris_incidence$acris_incidence_id) > 0L) {
  stop("Reviewed ACRIS sale incidence is not unique by event_id/opportunity_bbl.")
}

orphan_incidence_events <- setdiff(acris_incidence$event_id, acris_events$event_id)
if (length(orphan_incidence_events) > 0L) {
  stop("At least one ACRIS incidence event_id is missing from the event file.")
}

acris_by_bbl <- split(acris_incidence, acris_incidence$opportunity_bbl)
candidate_link_rows <- vector("list", nrow(dof_primary_sales))
nearest_same_bbl_rows <- vector("list", nrow(dof_primary_sales))

for (i in seq_len(nrow(dof_primary_sales))) {
  sale_row <- dof_primary_sales[i, ]
  bbl_events <- acris_by_bbl[[sale_row$sale_bbl]]

  if (is.null(bbl_events)) {
    next
  }

  same_bbl_events <- bbl_events |>
    mutate(
      sale_record_id = sale_row$sale_record_id,
      sale_bbl = sale_row$sale_bbl,
      sale_date = sale_row$sale_date,
      sale_year = sale_row$sale_year,
      sale_price = sale_row$sale_price,
      date_diff_days = abs(as.integer(event_date_primary - sale_row$sale_date)),
      price_diff_abs = abs(event_price_final - sale_row$sale_price),
      price_diff_pct = price_diff_abs / pmax(abs(event_price_final), abs(sale_row$sale_price)),
      price_close = price_diff_abs <= 1 | price_diff_pct <= 0.01,
      date_window_match = date_diff_days <= date_window_days,
      link_priority = case_when(
        price_close & event_primary_private_sale ~ 1L,
        price_close & event_broad_priced_transfer ~ 2L,
        price_close ~ 3L,
        TRUE ~ 4L
      )
    )

  nearest_same_bbl_rows[[i]] <- same_bbl_events |>
    arrange(date_diff_days, price_diff_pct, event_id, opportunity_bbl) |>
    slice_head(n = 1) |>
    transmute(
      sale_record_id,
      nearest_same_bbl_acris_incidence_id = acris_incidence_id,
      nearest_same_bbl_event_id = event_id,
      nearest_same_bbl_event_date = event_date_primary,
      nearest_same_bbl_event_price = event_price_final,
      nearest_same_bbl_days = date_diff_days,
      nearest_same_bbl_price_diff_pct = price_diff_pct,
      nearest_same_bbl_inclusion_status = event_inclusion_status,
      nearest_same_bbl_primary_private_sale = event_primary_private_sale,
      nearest_same_bbl_primary_exclusion_reason = event_primary_exclusion_reason
    )

  candidate_link_rows[[i]] <- same_bbl_events |>
    filter(date_window_match) |>
    select(
      sale_record_id, sale_bbl, sale_date, sale_year, sale_price,
      acris_incidence_id, event_id, opportunity_bbl,
      event_date_primary, event_year, event_price_final,
      date_diff_days, price_diff_abs, price_diff_pct, price_close,
      link_priority, event_inclusion_status,
      event_primary_private_sale, event_strict_private_sale,
      event_broad_priced_transfer, event_primary_exclusion_reason,
      incidence_primary_exclusion_reason, source_document_ids, crfns,
      buyer_names, seller_names, review_cluster_id,
      reviewer_final_ruling, manual_review_status, source_confidence
    )
}

candidate_links <- bind_rows(candidate_link_rows)

if (nrow(candidate_links) == 0L) {
  candidate_links <- tibble(
    sale_record_id = character(),
    sale_bbl = character(),
    sale_date = as.Date(character()),
    sale_year = integer(),
    sale_price = numeric(),
    acris_incidence_id = character(),
    event_id = character(),
    opportunity_bbl = character(),
    event_date_primary = as.Date(character()),
    event_year = integer(),
    event_price_final = numeric(),
    date_diff_days = integer(),
    price_diff_abs = numeric(),
    price_diff_pct = numeric(),
    price_close = logical(),
    link_priority = integer(),
    event_inclusion_status = character(),
    event_primary_private_sale = logical(),
    event_strict_private_sale = logical(),
    event_broad_priced_transfer = logical(),
    event_primary_exclusion_reason = character(),
    incidence_primary_exclusion_reason = character(),
    source_document_ids = character(),
    crfns = character(),
    buyer_names = character(),
    seller_names = character(),
    review_cluster_id = character(),
    reviewer_final_ruling = character(),
    manual_review_status = character(),
    source_confidence = character()
  )
}

nearest_same_bbl_links <- bind_rows(nearest_same_bbl_rows)

if (nrow(nearest_same_bbl_links) == 0L) {
  nearest_same_bbl_links <- tibble(
    sale_record_id = character(),
    nearest_same_bbl_acris_incidence_id = character(),
    nearest_same_bbl_event_id = character(),
    nearest_same_bbl_event_date = as.Date(character()),
    nearest_same_bbl_event_price = numeric(),
    nearest_same_bbl_days = integer(),
    nearest_same_bbl_price_diff_pct = numeric(),
    nearest_same_bbl_inclusion_status = character(),
    nearest_same_bbl_primary_private_sale = logical(),
    nearest_same_bbl_primary_exclusion_reason = character()
  )
}

if (anyDuplicated(nearest_same_bbl_links$sale_record_id) > 0L) {
  stop("Nearest same-BBL ACRIS links are not unique by DOF sale_record_id.")
}

best_links <- candidate_links |>
  arrange(sale_record_id, link_priority, date_diff_days, price_diff_pct, event_id, opportunity_bbl) |>
  group_by(sale_record_id) |>
  slice_head(n = 1) |>
  ungroup()

if (anyDuplicated(best_links$sale_record_id) > 0L) {
  stop("Best ACRIS links are not unique by DOF sale_record_id.")
}

dof_best_links <- dof_primary_sales |>
  left_join(best_links, by = "sale_record_id", relationship = "one-to-one", suffix = c("", "_acris")) |>
  left_join(nearest_same_bbl_links, by = "sale_record_id", relationship = "one-to-one") |>
  mutate(
    high_priority_site_sale_candidate = sale_price >= high_priority_price_cutoff |
      coalesce(capacity100_850, FALSE) |
      coalesce(capacity_exposure_quartile_citywide, 0) >= 3,
    match_status = case_when(
      !is.na(event_id) & price_close & event_primary_private_sale ~ "DOF_EXACT_ACRIS_EVENT_MATCH",
      !is.na(event_id) & price_close & !event_primary_private_sale ~ "DOF_MATCHES_ACRIS_EXCLUDED_BY_RULE",
      !is.na(event_id) & !price_close ~ "DOF_PRICE_CONFLICT",
      is.na(event_id) & high_priority_site_sale_candidate ~ "DOF_ONLY_HIGH_CONFIDENCE_MISS",
      TRUE ~ "DOF_ONLY_LOW_CONFIDENCE"
    ),
    match_notes = case_when(
      match_status == "DOF_EXACT_ACRIS_EVENT_MATCH" ~ "Same BBL, date within 14 days, price close, and ACRIS primary private-market event.",
      match_status == "DOF_MATCHES_ACRIS_EXCLUDED_BY_RULE" ~ "Same BBL, date within 14 days, and price close, but reviewed ACRIS rules exclude it from primary.",
      match_status == "DOF_PRICE_CONFLICT" ~ "Same BBL and date within 14 days, but DOF and reviewed ACRIS prices differ by more than 1 percent.",
      match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS" ~ "No reviewed ACRIS event within 14 days; high-priority due to price or development capacity.",
      TRUE ~ "No reviewed ACRIS event within 14 days; lower-priority DOF-only candidate."
    )
  )

if (anyDuplicated(dof_best_links$sale_record_id) > 0L) {
  stop("DOF best-link audit rows are not unique by sale_record_id.")
}

coverage_overall <- dof_best_links |>
  summarise_coverage() |>
  mutate(audit_scope = "non_si_primary_opportunity_dof_site_sale_candidates") |>
  select(audit_scope, everything())

coverage_by_year_borough <- dof_best_links |>
  group_by(sale_year, sale_borough_code) |>
  summarise_coverage() |>
  arrange(sale_year, sale_borough_code)

coverage_by_status <- dof_best_links |>
  group_by(match_status) |>
  summarise(
    dof_primary_candidate_rows = n(),
    dof_primary_candidate_bbls = n_distinct(sale_bbl),
    dof_primary_candidate_value = sum(sale_price, na.rm = TRUE),
    median_sale_price = median(sale_price, na.rm = TRUE),
    p90_sale_price = quantile(sale_price, 0.9, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(dof_primary_candidate_rows), match_status)

coverage_by_stratum <- bind_rows(
  dof_best_links |>
    mutate(stratum_type = "borough", stratum_value = sale_borough_code) |>
    group_by(stratum_type, stratum_value) |>
    summarise_coverage(),
  dof_best_links |>
    mutate(stratum_type = "capacity_quartile_citywide", stratum_value = as.character(capacity_exposure_quartile_citywide)) |>
    group_by(stratum_type, stratum_value) |>
    summarise_coverage(),
  dof_best_links |>
    mutate(stratum_type = "sale_price_bin", stratum_value = sale_price_bin) |>
    group_by(stratum_type, stratum_value) |>
    summarise_coverage(),
  dof_best_links |>
    mutate(stratum_type = "policy_period", stratum_value = policy_period) |>
    group_by(stratum_type, stratum_value) |>
    summarise_coverage()
) |>
  arrange(stratum_type, stratum_value)

high_priority_dof_only_cases <- dof_best_links |>
  filter(match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS") |>
  arrange(desc(sale_price), sale_date, sale_record_id) |>
  select(
    sale_record_id, sale_bbl, sale_borough_code, sale_date, sale_price,
    dof_address, neighborhood, building_class_category,
    tax_class_at_time_of_sale, building_class_at_time_of_sale,
    residential_units, commercial_units, total_units,
    land_square_feet, gross_square_feet,
    opportunity_address, cd, zipcode, council,
    lotarea, allowed_policy_res_sqft, capacity_units_850,
    capacity100_850, capacity_exposure_quartile_citywide,
    dof_same_borough_date_price_rows, dof_same_borough_date_price_bbls,
    nearest_same_bbl_event_id, nearest_same_bbl_event_date,
    nearest_same_bbl_event_price, nearest_same_bbl_days,
    nearest_same_bbl_price_diff_pct, nearest_same_bbl_inclusion_status,
    match_status, match_notes
  )

dof_only_case_examples <- dof_best_links |>
  arrange(match_status, desc(sale_price), sale_record_id) |>
  group_by(match_status) |>
  slice_head(n = 10) |>
  ungroup() |>
  select(
    match_status, sale_record_id, sale_bbl, sale_borough_code,
    sale_date, sale_price, dof_address, neighborhood,
    building_class_category, tax_class_at_time_of_sale,
    building_class_at_time_of_sale, total_units,
    opportunity_address, allowed_policy_res_sqft,
    capacity_units_850, capacity_exposure_quartile_citywide,
    dof_same_borough_date_price_rows, dof_same_borough_date_price_bbls,
    event_id, event_date_primary, event_price_final,
    event_inclusion_status, event_primary_exclusion_reason,
    date_diff_days, price_diff_pct, source_document_ids,
    nearest_same_bbl_event_id, nearest_same_bbl_event_date,
    nearest_same_bbl_event_price, nearest_same_bbl_days,
    nearest_same_bbl_price_diff_pct, nearest_same_bbl_inclusion_status,
    buyer_names, seller_names, match_notes
  )

matched_acris_incidence <- dof_best_links |>
  filter(!is.na(acris_incidence_id)) |>
  distinct(acris_incidence_id)

acris_only_cases <- acris_incidence |>
  anti_join(matched_acris_incidence, by = "acris_incidence_id") |>
  mutate(
    acris_only_status = case_when(
      event_primary_private_sale ~ "ACRIS_ONLY_PRIMARY_PRIVATE_EVENT",
      event_broad_priced_transfer ~ "ACRIS_ONLY_BROAD_PRICED_TRANSFER",
      TRUE ~ "ACRIS_ONLY_REVIEWED_EXCLUDED_EVENT"
    )
  ) |>
  arrange(desc(event_price_final), event_date_primary, event_id, opportunity_bbl) |>
  select(
    acris_only_status, event_id, opportunity_bbl, opportunity_borough,
    event_date_primary, event_price_final, event_inclusion_status,
    event_primary_exclusion_reason, incidence_primary_exclusion_reason,
    acris_address, allowed_policy_res_sqft, capacity_units_850,
    capacity_exposure_quartile_citywide, source_document_ids,
    crfns, buyer_names, seller_names, reviewer_final_ruling,
    manual_review_status, source_confidence
  )

hard_checks <- tibble(
  check = c(
    "opportunity_lots_unique_bbl",
    "dof_sales_unique_sale_record_id",
    "acris_events_unique_event_id",
    "acris_incidence_unique_event_bbl",
    "best_links_unique_sale_record_id",
    "nearest_same_bbl_links_unique_sale_record_id",
    "dof_best_rows_unique_sale_record_id",
    "no_staten_island_in_dof_primary_denominator",
    "all_dof_best_rows_have_match_status",
    "high_confidence_misses_are_unmatched",
    "candidate_links_within_date_window"
  ),
  passed = c(
    anyDuplicated(opportunity_lots$opportunity_bbl) == 0L,
    anyDuplicated(dof_sales$sale_record_id) == 0L,
    anyDuplicated(acris_events$event_id) == 0L,
    anyDuplicated(acris_incidence$acris_incidence_id) == 0L,
    anyDuplicated(best_links$sale_record_id) == 0L,
    anyDuplicated(nearest_same_bbl_links$sale_record_id) == 0L,
    anyDuplicated(dof_best_links$sale_record_id) == 0L,
    all(dof_best_links$sale_borough_code != "5"),
    all(!is.na(dof_best_links$match_status)),
    all(is.na(dof_best_links$event_id[dof_best_links$match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS"])),
    all(candidate_links$date_diff_days <= date_window_days)
  ),
  value = c(
    nrow(opportunity_lots),
    nrow(dof_sales),
    nrow(acris_events),
    nrow(acris_incidence),
    nrow(best_links),
    nrow(nearest_same_bbl_links),
    nrow(dof_best_links),
    sum(dof_best_links$sale_borough_code == "5"),
    sum(is.na(dof_best_links$match_status)),
    sum(!is.na(dof_best_links$event_id[dof_best_links$match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS"])),
    sum(candidate_links$date_diff_days > date_window_days)
  )
)

if (any(!hard_checks$passed)) {
  write_csv_if_changed(hard_checks, "../output/audit_recorded_sales_coverage_hard_checks.csv")
  stop("Recorded sales coverage audit failed at least one hard check.")
}

write_csv_if_changed(coverage_by_year_borough, "../output/dof_acris_coverage_by_year_borough.csv")
write_csv_if_changed(coverage_overall, "../output/dof_acris_coverage_overall.csv")
write_csv_if_changed(coverage_by_status, "../output/dof_acris_coverage_by_status.csv")
write_csv_if_changed(coverage_by_stratum, "../output/dof_acris_coverage_by_stratum.csv")
write_csv_if_changed(high_priority_dof_only_cases, "../output/high_priority_dof_only_cases.csv")
write_csv_if_changed(dof_only_case_examples, "../output/dof_only_case_examples.csv")
write_csv_if_changed(acris_only_cases, "../output/acris_only_cases.csv")
write_parquet_if_changed(dof_opportunity_sales, "../output/dof_opportunity_sale_candidates.parquet")
write_parquet_if_changed(candidate_links, "../output/dof_acris_link_candidates.parquet")
write_parquet_if_changed(dof_best_links, "../output/dof_acris_best_links.parquet")
write_parquet_if_changed(nearest_same_bbl_links, "../output/dof_nearest_same_bbl_acris_events.parquet")
write_csv_if_changed(hard_checks, "../output/audit_recorded_sales_coverage_hard_checks.csv")

cat("Wrote recorded sales coverage audit outputs to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/build_dof_only_sales_review_queue/code")

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
high_priority_price_cutoff <- 1000000

paste_unique <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & x != ""]
  if (length(x) == 0L) {
    return(NA_character_)
  }

  paste(unique(x), collapse = ";")
}

flag_any <- function(x) {
  any(coalesce(as.logical(x), FALSE))
}

collapse_amounts <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_character_)
  }

  paste(unique(format(round(x, 2), scientific = FALSE, trim = TRUE)), collapse = ";")
}

flat_character <- function(x) {
  if (is.list(x)) {
    return(vapply(
      x,
      function(value) {
        paste_unique(value)
      },
      character(1)
    ))
  }

  as.character(x)
}

dof_only <- read_parquet("../input/dof_acris_best_links.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(match_status == "DOF_ONLY_HIGH_CONFIDENCE_MISS") |>
  transmute(
    sale_record_id = str_squish(as.character(sale_record_id)),
    sale_bbl = normalize_bbl_field(sale_bbl),
    sale_borough_code = standardize_borough_code(sale_borough_code),
    sale_date = as.Date(sale_date),
    sale_year,
    sale_price,
    sale_price_bin,
    policy_period,
    dof_address,
    neighborhood,
    building_class_category,
    tax_class_at_time_of_sale,
    building_class_at_time_of_sale,
    residential_units,
    commercial_units,
    total_units,
    land_square_feet,
    gross_square_feet,
    opportunity_address,
    cd, zipcode, council,
    lotarea,
    allowed_policy_res_sqft,
    capacity_units_850,
    capacity100_850,
    capacity_exposure_quartile_citywide,
    dof_same_borough_date_price_rows,
    dof_same_borough_date_price_bbls,
    nearest_same_bbl_event_id,
    nearest_same_bbl_event_date = as.Date(nearest_same_bbl_event_date),
    nearest_same_bbl_event_price,
    nearest_same_bbl_days,
    nearest_same_bbl_price_diff_pct,
    nearest_same_bbl_inclusion_status,
    nearest_same_bbl_primary_private_sale,
    nearest_same_bbl_primary_exclusion_reason,
    match_status,
    match_notes
  ) |>
  arrange(desc(sale_price), sale_date, sale_record_id)

if (nrow(dof_only) == 0L) {
  stop("No high-priority DOF-only cases are available for review.")
}

if (anyDuplicated(dof_only$sale_record_id) > 0L) {
  stop("DOF-only review cases are not unique by sale_record_id.")
}

direct_deeds <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    direct_deed_bbl_id,
    document_id = str_squish(as.character(document_id)),
    crfn = str_squish(as.character(crfn)),
    doc_type,
    document_date = as.Date(document_date),
    document_amt,
    percent_trans,
    legal_bbl = normalize_bbl_field(legal_bbl),
    direct_legal_property_types,
    direct_legal_units,
    has_unit_legal_row,
    has_partial_lot_flag,
    has_easement_flag,
    has_air_rights_flag,
    has_subterranean_rights_flag,
    deed_positive_document_amt,
    deed_percent_trans_100
  ) |>
  filter(!is.na(legal_bbl), !is.na(document_date))

classified_docs <- read_parquet("../input/acris_deed_document_classified.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    document_id = str_squish(as.character(document_id)),
    classified_event_id = event_id,
    document_market_status,
    document_exclusion_codes,
    document_warning_codes,
    cluster_rule,
    duplicate_price_excluded_flag,
    ambiguous_same_buyer_date_amount_flag,
    same_bbl_date_buyer_repeated_flag,
    buyer_names = flat_character(buyer_names),
    seller_names = flat_character(seller_names),
    public_party_flag,
    hdfc_party_flag,
    housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag,
    trust_estate_party_flag,
    strong_related_party_flag,
    weak_related_party_flag,
    unit_churn_flag,
    rights_only_flag,
    local_site_flag,
    opportunity_share_primary_flag,
    n_all_legal_bbls,
    n_opportunity_legal_bbls,
    legal_bbls = flat_character(legal_bbls),
    opportunity_bbls = flat_character(opportunity_bbls)
  )

if (anyDuplicated(classified_docs$document_id) > 0L) {
  stop("Classified ACRIS documents are not unique by document_id.")
}

site_events <- read_parquet("../input/acris_site_events.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    site_event_id = event_id,
    source_document_ids = flat_character(source_document_ids),
    site_price_resolution_status = price_resolution_status,
    site_has_final_price = has_final_price,
    site_event_price_final = event_price_final,
    site_exclude_from_default_price_totals = exclude_from_default_price_totals,
    site_event_date_primary = as.Date(event_date_primary),
    site_event_count_resolution_status = event_count_resolution_status,
    site_ambiguity_type = ambiguity_type,
    site_review_priority = review_priority,
    site_manual_review_status = manual_review_status,
    site_reviewer_final_ruling = reviewer_final_ruling,
    site_price_rule = price_rule,
    site_source_confidence = source_confidence,
    site_reviewer_notes = reviewer_notes
  )

site_event_documents <- site_events |>
  select(site_event_id, source_document_ids) |>
  separate_rows(source_document_ids, sep = ";") |>
  mutate(document_id = str_squish(as.character(source_document_ids))) |>
  filter(!is.na(document_id), document_id != "") |>
  distinct(document_id, site_event_id)

if (anyDuplicated(site_event_documents$document_id) > 0L) {
  site_event_documents <- site_event_documents |>
    group_by(document_id) |>
    summarise(site_event_id = paste_unique(site_event_id), .groups = "drop")
}

site_event_by_document <- site_event_documents |>
  left_join(site_events |> select(-source_document_ids), by = "site_event_id", relationship = "many-to-one")

same_date_rows <- vector("list", nrow(dof_only))

for (i in seq_len(nrow(dof_only))) {
  sale_row <- dof_only[i, ]

  same_date_rows[[i]] <- direct_deeds |>
    filter(legal_bbl == sale_row$sale_bbl, document_date == sale_row$sale_date) |>
    mutate(
      sale_record_id = sale_row$sale_record_id,
      sale_bbl = sale_row$sale_bbl,
      sale_date = sale_row$sale_date,
      sale_price = sale_row$sale_price,
      acris_dof_price_diff_abs = abs(document_amt - sale_row$sale_price),
      acris_dof_price_diff_pct = acris_dof_price_diff_abs / pmax(abs(document_amt), abs(sale_row$sale_price)),
      acris_dof_price_close = !is.na(document_amt) &
        (acris_dof_price_diff_abs <= 1 | acris_dof_price_diff_pct <= 0.01)
    )
}

same_date_evidence <- bind_rows(same_date_rows)

if (nrow(same_date_evidence) == 0L) {
  same_date_evidence <- tibble(
    direct_deed_bbl_id = character(),
    document_id = character(),
    crfn = character(),
    doc_type = character(),
    document_date = as.Date(character()),
    document_amt = numeric(),
    percent_trans = numeric(),
    legal_bbl = character(),
    direct_legal_property_types = character(),
    direct_legal_units = numeric(),
    has_unit_legal_row = logical(),
    has_partial_lot_flag = logical(),
    has_easement_flag = logical(),
    has_air_rights_flag = logical(),
    has_subterranean_rights_flag = logical(),
    deed_positive_document_amt = logical(),
    deed_percent_trans_100 = logical(),
    sale_record_id = character(),
    sale_bbl = character(),
    sale_date = as.Date(character()),
    sale_price = numeric(),
    acris_dof_price_diff_abs = numeric(),
    acris_dof_price_diff_pct = numeric(),
    acris_dof_price_close = logical()
  )
}

same_date_evidence <- same_date_evidence |>
  left_join(classified_docs, by = "document_id", relationship = "many-to-one") |>
  left_join(site_event_by_document, by = "document_id", relationship = "many-to-one") |>
  arrange(sale_record_id, document_id, legal_bbl)

same_date_summary <- same_date_evidence |>
  group_by(sale_record_id) |>
  summarise(
    same_date_acris_deed_rows = n(),
    same_date_acris_document_ids = paste_unique(document_id),
    same_date_acris_crfns = paste_unique(crfn),
    same_date_acris_document_amounts = collapse_amounts(document_amt),
    same_date_acris_document_amt_sum = sum(document_amt, na.rm = TRUE),
    same_date_acris_document_amt_max = max(document_amt, na.rm = TRUE),
    same_date_acris_positive_deed_rows = sum(coalesce(document_amt, 0) > price_low_cutoff),
    same_date_acris_zero_deed_rows = sum(coalesce(document_amt, 0) == 0),
    same_date_acris_percent_zero_rows = sum(coalesce(percent_trans, 0) == 0),
    same_date_acris_percent_100_rows = sum(coalesce(percent_trans, 0) == 100),
    same_date_acris_price_close_rows = sum(coalesce(acris_dof_price_close, FALSE)),
    same_date_direct_property_types = paste_unique(direct_legal_property_types),
    same_date_has_unit_legal_row = flag_any(has_unit_legal_row),
    same_date_has_partial_lot_flag = flag_any(has_partial_lot_flag),
    same_date_has_easement_flag = flag_any(has_easement_flag),
    same_date_has_air_rights_flag = flag_any(has_air_rights_flag),
    same_date_has_subterranean_rights_flag = flag_any(has_subterranean_rights_flag),
    same_date_document_market_statuses = paste_unique(document_market_status),
    same_date_document_exclusion_codes = paste_unique(document_exclusion_codes),
    same_date_document_warning_codes = paste_unique(document_warning_codes),
    same_date_cluster_rules = paste_unique(cluster_rule),
    same_date_duplicate_price_excluded = flag_any(duplicate_price_excluded_flag),
    same_date_ambiguous_same_buyer_date_amount = flag_any(ambiguous_same_buyer_date_amount_flag),
    same_date_same_bbl_date_buyer_repeated = flag_any(same_bbl_date_buyer_repeated_flag),
    same_date_public_party_flag = flag_any(public_party_flag),
    same_date_hdfc_party_flag = flag_any(hdfc_party_flag),
    same_date_housing_public_or_regulated_party_flag = flag_any(housing_public_or_regulated_party_flag),
    same_date_nonprofit_religious_party_flag = flag_any(nonprofit_religious_party_flag),
    same_date_trust_estate_party_flag = flag_any(trust_estate_party_flag),
    same_date_strong_related_party_flag = flag_any(strong_related_party_flag),
    same_date_weak_related_party_flag = flag_any(weak_related_party_flag),
    same_date_unit_churn_flag = flag_any(unit_churn_flag),
    same_date_rights_only_flag = flag_any(rights_only_flag),
    same_date_buyer_names = paste_unique(buyer_names),
    same_date_seller_names = paste_unique(seller_names),
    same_date_site_event_ids = paste_unique(site_event_id),
    same_date_site_price_statuses = paste_unique(site_price_resolution_status),
    same_date_site_manual_review_statuses = paste_unique(site_manual_review_status),
    same_date_site_ambiguity_types = paste_unique(site_ambiguity_type),
    same_date_site_reviewer_rulings = paste_unique(site_reviewer_final_ruling),
    same_date_site_price_rules = paste_unique(site_price_rule),
    same_date_site_source_confidences = paste_unique(site_source_confidence),
    same_date_site_reviewer_notes = paste_unique(site_reviewer_notes),
    .groups = "drop"
  ) |>
  mutate(
    same_date_acris_document_amt_sum = if_else(same_date_acris_deed_rows > 0, same_date_acris_document_amt_sum, NA_real_),
    same_date_acris_document_amt_max = if_else(is.finite(same_date_acris_document_amt_max), same_date_acris_document_amt_max, NA_real_)
  )

all_bbl_direct_deed_summary <- direct_deeds |>
  filter(legal_bbl %in% dof_only$sale_bbl) |>
  group_by(legal_bbl) |>
  summarise(
    all_bbl_acris_direct_deed_rows = n(),
    all_bbl_acris_positive_deed_rows = sum(coalesce(document_amt, 0) > price_low_cutoff),
    all_bbl_acris_zero_deed_rows = sum(coalesce(document_amt, 0) == 0),
    all_bbl_acris_first_deed_date = min(document_date, na.rm = TRUE),
    all_bbl_acris_last_deed_date = max(document_date, na.rm = TRUE),
    .groups = "drop"
  )

regulated_party_terms <- regex(
  "AFFORDABLE|PRESERVATION|HOUSING|HDFC|HPD|HDC|NYCHA|URBAN DEVELOPMENT|COMMUNITY|NOT FOR PROFIT|NONPROFIT",
  ignore_case = TRUE
)

review_queue <- dof_only |>
  left_join(same_date_summary, by = "sale_record_id", relationship = "one-to-one") |>
  left_join(all_bbl_direct_deed_summary, by = c("sale_bbl" = "legal_bbl"), relationship = "many-to-one") |>
  mutate(
    same_date_acris_deed_rows = replace_na(same_date_acris_deed_rows, 0L),
    same_date_acris_positive_deed_rows = replace_na(same_date_acris_positive_deed_rows, 0L),
    same_date_acris_zero_deed_rows = replace_na(same_date_acris_zero_deed_rows, 0L),
    same_date_acris_percent_zero_rows = replace_na(same_date_acris_percent_zero_rows, 0L),
    same_date_acris_percent_100_rows = replace_na(same_date_acris_percent_100_rows, 0L),
    same_date_acris_price_close_rows = replace_na(same_date_acris_price_close_rows, 0L),
    same_date_has_any_acris_deed = same_date_acris_deed_rows > 0,
    same_date_has_positive_acris_deed = same_date_acris_positive_deed_rows > 0,
    same_date_has_zero_acris_deed = same_date_acris_zero_deed_rows > 0,
    same_date_all_zero_or_percent_zero = same_date_has_any_acris_deed &
      same_date_acris_positive_deed_rows == 0 &
      (same_date_acris_zero_deed_rows > 0 | same_date_acris_percent_zero_rows > 0),
    same_date_acris_price_matches_dof = same_date_acris_price_close_rows > 0,
    repeated_dof_borough_date_price_cluster = dof_same_borough_date_price_bbls > 1,
    has_nearest_same_bbl_reviewed_event = !is.na(nearest_same_bbl_event_id),
    nearest_same_bbl_reviewed_event_within_one_year = !is.na(nearest_same_bbl_days) & nearest_same_bbl_days <= 365,
    same_date_regulated_or_nonmarket_party_flag = coalesce(same_date_public_party_flag, FALSE) |
      coalesce(same_date_hdfc_party_flag, FALSE) |
      coalesce(same_date_housing_public_or_regulated_party_flag, FALSE) |
      coalesce(same_date_nonprofit_religious_party_flag, FALSE) |
      str_detect(coalesce(same_date_buyer_names, ""), regulated_party_terms) |
      str_detect(coalesce(same_date_seller_names, ""), regulated_party_terms),
    same_date_unresolved_or_ambiguous_site_event = str_detect(coalesce(same_date_site_price_statuses, ""), "unresolved") |
      str_detect(coalesce(same_date_site_manual_review_statuses, ""), "UNRESOLVED|NO_EXTERNAL") |
      str_detect(coalesce(same_date_site_ambiguity_types, ""), "multi_bbl|same_amount|ambiguous") |
      str_detect(coalesce(same_date_document_exclusion_codes, ""), "X_AMBIGUOUS_CLUSTER"),
    preliminary_review_bucket = case_when(
      same_date_has_positive_acris_deed & same_date_unresolved_or_ambiguous_site_event ~ "same_date_positive_acris_unresolved_cluster",
      same_date_has_positive_acris_deed & !same_date_unresolved_or_ambiguous_site_event ~ "same_date_positive_acris_rule_or_price_miss",
      same_date_all_zero_or_percent_zero & same_date_regulated_or_nonmarket_party_flag ~ "same_date_zero_regulated_or_nonmarket_candidate",
      same_date_all_zero_or_percent_zero ~ "same_date_zero_deed_dof_positive_price_reconciliation",
      repeated_dof_borough_date_price_cluster ~ "no_same_date_acris_repeated_dof_price_cluster",
      nearest_same_bbl_reviewed_event_within_one_year ~ "nearby_reviewed_acris_event_outside_14_day_window",
      TRUE ~ "no_same_date_acris_manual_lookup"
    ),
    preliminary_estimand_action = case_when(
      preliminary_review_bucket == "same_date_positive_acris_unresolved_cluster" ~ "verify_package_vs_additive_price_before_inclusion",
      preliminary_review_bucket == "same_date_positive_acris_rule_or_price_miss" ~ "verify_why_positive_acris_deed_not_in_primary_layer",
      preliminary_review_bucket == "same_date_zero_regulated_or_nonmarket_candidate" ~ "likely_exclude_from_private_market_site_sale_estimand_after_verification",
      preliminary_review_bucket == "same_date_zero_deed_dof_positive_price_reconciliation" ~ "verify_zero_acris_deed_against_positive_dof_price",
      preliminary_review_bucket == "no_same_date_acris_repeated_dof_price_cluster" ~ "verify_portfolio_or_repeated_price_cluster",
      preliminary_review_bucket == "nearby_reviewed_acris_event_outside_14_day_window" ~ "verify_timing_or_duplicate_transaction",
      TRUE ~ "manual_acris_dof_external_lookup_required"
    ),
    review_priority_order = case_when(
      preliminary_review_bucket %in% c(
        "same_date_positive_acris_unresolved_cluster",
        "same_date_positive_acris_rule_or_price_miss",
        "no_same_date_acris_manual_lookup"
      ) & sale_price >= high_priority_price_cutoff ~ 1L,
      preliminary_review_bucket %in% c(
        "same_date_zero_deed_dof_positive_price_reconciliation",
        "no_same_date_acris_repeated_dof_price_cluster"
      ) ~ 2L,
      preliminary_review_bucket == "nearby_reviewed_acris_event_outside_14_day_window" ~ 3L,
      preliminary_review_bucket == "same_date_zero_regulated_or_nonmarket_candidate" ~ 4L,
      TRUE ~ 5L
    ),
    chatgpt_verification_question = case_when(
      preliminary_review_bucket == "same_date_positive_acris_unresolved_cluster" ~ "Does public evidence or ACRIS document context show whether the same-date positive ACRIS deeds are one repeated package price or additive parcel prices?",
      preliminary_review_bucket == "same_date_positive_acris_rule_or_price_miss" ~ "Why did this same-date positive ACRIS deed miss the reviewed private-market layer, and should it enter as a primary site sale?",
      preliminary_review_bucket == "same_date_zero_regulated_or_nonmarket_candidate" ~ "Does the same-date zero-consideration ACRIS deed represent affordable/preservation/regulatory transfer outside the private-market land-sale estimand?",
      preliminary_review_bucket == "same_date_zero_deed_dof_positive_price_reconciliation" ~ "Can the positive DOF price be reconciled to the same-date zero-consideration ACRIS deed, or is this an entity/accounting transfer outside the estimand?",
      preliminary_review_bucket == "no_same_date_acris_repeated_dof_price_cluster" ~ "Is the repeated DOF borough/date/price cluster a portfolio/package record that should be grouped or excluded from independent BBL-level counts?",
      preliminary_review_bucket == "nearby_reviewed_acris_event_outside_14_day_window" ~ "Is the nearby reviewed ACRIS event the same economic transaction despite falling outside the 14-day match window?",
      TRUE ~ "Can public records or direct ACRIS lookup explain why this positive DOF sale has no same-date direct ACRIS deed in our pull?"
    ),
    verification_status = "pending",
    chatgpt_review_class = NA_character_,
    chatgpt_review_confidence = NA_character_,
    human_review_class = NA_character_,
    final_review_class = NA_character_,
    final_review_notes = NA_character_
  ) |>
  arrange(review_priority_order, desc(sale_price), sale_date, sale_record_id)

review_packet <- review_queue |>
  mutate(
    chatgpt_packet_text = paste0(
      "sale_record_id: ", sale_record_id,
      "; BBL: ", sale_bbl,
      "; DOF date: ", sale_date,
      "; DOF price: $", format(round(sale_price, 0), scientific = FALSE, big.mark = ","),
      "; address: ", dof_address,
      "; class: ", building_class_category,
      "; total_units: ", total_units,
      "; land_sqft: ", land_square_feet,
      "; gross_sqft: ", gross_square_feet,
      "; allowed_policy_res_sqft: ", round(allowed_policy_res_sqft, 1),
      "; same-date ACRIS docs: ", coalesce(same_date_acris_document_ids, "none"),
      "; same-date ACRIS amounts: ", coalesce(same_date_acris_document_amounts, "none"),
      "; same-date ACRIS market statuses: ", coalesce(same_date_document_market_statuses, "none"),
      "; same-date ACRIS exclusions: ", coalesce(same_date_document_exclusion_codes, "none"),
      "; buyers: ", coalesce(same_date_buyer_names, "none"),
      "; sellers: ", coalesce(same_date_seller_names, "none"),
      "; same-date site-event status: ", coalesce(same_date_site_price_statuses, "none"),
      "; same-date site-event ambiguity: ", coalesce(same_date_site_ambiguity_types, "none"),
      "; repeated DOF borough/date/price BBL count: ", dof_same_borough_date_price_bbls,
      "; nearest reviewed same-BBL event: ", coalesce(nearest_same_bbl_event_id, "none"),
      "; nearest reviewed days: ", coalesce(as.character(nearest_same_bbl_days), "NA"),
      "; preliminary bucket: ", preliminary_review_bucket,
      "; verification question: ", chatgpt_verification_question
    )
  ) |>
  select(
    sale_record_id,
    review_priority_order,
    preliminary_review_bucket,
    preliminary_estimand_action,
    chatgpt_verification_question,
    chatgpt_packet_text
  )

review_summary <- review_queue |>
  group_by(preliminary_review_bucket, preliminary_estimand_action, review_priority_order) |>
  summarise(
    cases = n(),
    bbls = n_distinct(sale_bbl),
    dof_value = sum(sale_price, na.rm = TRUE),
    median_dof_price = median(sale_price, na.rm = TRUE),
    p90_dof_price = quantile(sale_price, 0.9, na.rm = TRUE),
    cases_with_same_date_acris_deed = sum(same_date_has_any_acris_deed),
    cases_with_same_date_positive_acris_deed = sum(same_date_has_positive_acris_deed),
    cases_with_repeated_dof_price_cluster = sum(repeated_dof_borough_date_price_cluster),
    .groups = "drop"
  ) |>
  arrange(review_priority_order, desc(cases), preliminary_review_bucket)

hard_checks <- tibble(
  check = c(
    "dof_only_unique_sale_record_id",
    "review_queue_unique_sale_record_id",
    "review_queue_same_row_count_as_dof_only",
    "same_date_evidence_document_join_complete",
    "all_cases_have_preliminary_bucket",
    "all_cases_have_review_status_pending"
  ),
  passed = c(
    anyDuplicated(dof_only$sale_record_id) == 0L,
    anyDuplicated(review_queue$sale_record_id) == 0L,
    nrow(review_queue) == nrow(dof_only),
    all(is.na(same_date_evidence$document_id) | !is.na(same_date_evidence$document_market_status)),
    all(!is.na(review_queue$preliminary_review_bucket)),
    all(review_queue$verification_status == "pending")
  ),
  value = c(
    nrow(dof_only),
    nrow(review_queue),
    nrow(review_queue) - nrow(dof_only),
    sum(!is.na(same_date_evidence$document_id) & is.na(same_date_evidence$document_market_status)),
    sum(is.na(review_queue$preliminary_review_bucket)),
    sum(review_queue$verification_status != "pending")
  )
)

if (any(!hard_checks$passed)) {
  write_csv_if_changed(hard_checks, "../output/dof_only_review_queue_hard_checks.csv")
  stop("DOF-only sales review queue failed at least one hard check.")
}

write_csv_if_changed(review_queue, "../output/dof_only_high_priority_review_queue.csv")
write_csv_if_changed(review_summary, "../output/dof_only_high_priority_review_summary.csv")
write_csv_if_changed(review_packet, "../output/dof_only_high_priority_review_packet.csv")
write_csv_if_changed(same_date_evidence, "../output/dof_only_same_date_acris_document_evidence.csv")
write_csv_if_changed(hard_checks, "../output/dof_only_review_queue_hard_checks.csv")

cat("Wrote DOF-only high-priority sales review queue to ../output\n")

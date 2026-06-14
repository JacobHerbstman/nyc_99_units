# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/prepare_acris_site_event_review_packet/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

collapse_unique <- function(x) {
  values <- sort(unique(as.character(x[!is.na(x) & x != ""])))
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(values, collapse = ";")
}

collapse_in_order <- function(x) {
  values <- unique(as.character(x[!is.na(x) & x != ""]))
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(values, collapse = " | ")
}

documents <- read_parquet("../input/acris_deed_document_classified.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    representative_doc = !duplicate_price_excluded_flag,
    same_buyer_date_multidoc_flag = str_detect(coalesce(document_warning_codes, ""), "F_SAME_BUYER_DATE_MULTIDOC"),
    document_date_key = as.character(document_date),
    full_legal_bbl_set_key = if_else(is.na(legal_bbls) | legal_bbls == "", NA_character_, legal_bbls),
    site_date_key = if_else(
      is.na(full_legal_bbl_set_key),
      NA_character_,
      paste(recorded_borough, document_date_key, full_legal_bbl_set_key, sep = "__")
    ),
    amount_key = if_else(is.na(document_amt), "MISSING", as.character(round(document_amt))),
    positive_price_doc = !is.na(document_amt) & document_amt > 250000,
    partial_interest_doc = !is.na(percent_trans) & percent_trans > 0 & percent_trans < 100,
    review_cluster_seed = representative_doc &
      (same_buyer_date_multidoc_flag |
         ambiguous_same_buyer_date_amount_flag |
         same_bbl_date_buyer_repeated_flag |
         exact_duplicate_group_docs > 1L)
  )

legals <- read_parquet("../input/acris_direct_deed_all_legals.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    legal_address = str_squish(paste(
      coalesce(as.character(street_number), ""),
      coalesce(as.character(street_name), "")
    )),
    legal_address = if_else(legal_address == "", NA_character_, legal_address)
  )

parties <- read_parquet("../input/acris_direct_opportunity_deed_parties.parquet") |>
  as.data.frame() |>
  as_tibble()

document_bbls_long <- documents |>
  filter(review_cluster_seed) |>
  select(document_id, buyer_date_key, legal_bbls) |>
  separate_rows(legal_bbls, sep = ";") |>
  filter(!is.na(legal_bbls), legal_bbls != "")

bbl_repeat_summary <- document_bbls_long |>
  count(buyer_date_key, legal_bbls, name = "doc_bbl_count") |>
  group_by(buyer_date_key) |>
  summarise(
    any_repeated_bbl = any(doc_bbl_count > 1L),
    max_docs_per_bbl = max(doc_bbl_count),
    n_union_bbls = n_distinct(legal_bbls),
    repeated_bbls = collapse_unique(legal_bbls[doc_bbl_count > 1L]),
    .groups = "drop"
  )

legal_address_summary <- documents |>
  filter(review_cluster_seed) |>
  select(document_id, buyer_date_key) |>
  inner_join(
    legals |>
      filter(valid_legal_bbl) |>
      select(document_id, legal_bbl, legal_address, property_type, unit, direct_opportunity_bbl_match),
    by = "document_id",
    relationship = "one-to-many"
  ) |>
  group_by(buyer_date_key) |>
  summarise(
    site_addresses = collapse_unique(legal_address),
    property_types = collapse_unique(property_type),
    units = collapse_unique(unit),
    n_direct_opportunity_legal_rows = sum(direct_opportunity_bbl_match, na.rm = TRUE),
    .groups = "drop"
  )

base_review_clusters_all <- documents |>
  filter(review_cluster_seed) |>
  group_by(buyer_date_key, document_date, buyer_party_set_key) |>
  summarise(
    first_document_id = min(document_id),
    last_document_id = max(document_id),
    n_representative_docs = n(),
    n_source_docs = sum(exact_duplicate_group_docs),
    n_duplicate_docs = sum(exact_duplicate_group_docs - 1L),
    n_amounts = n_distinct(amount_key),
    n_seller_sets = n_distinct(seller_party_set_key),
    n_legal_sets = n_distinct(legal_bbls),
    n_zero_docs = sum(amount_class == "ZERO", na.rm = TRUE),
    n_nominal_docs = sum(amount_class == "NOMINAL", na.rm = TRUE),
    n_low_docs = sum(amount_class == "LOW", na.rm = TRUE),
    n_market_candidate_docs = sum(amount_class == "MARKET_CANDIDATE", na.rm = TRUE),
    n_positive_price_docs = sum(positive_price_doc, na.rm = TRUE),
    repeated_amount_flag = n_amounts == 1L & n() > 1L,
    any_exact_duplicate = any(exact_duplicate_group_docs > 1L),
    any_unit_churn = any(unit_churn_flag, na.rm = TRUE),
    any_rights_only = any(rights_only_flag, na.rm = TRUE),
    any_mixed_rights = any(mixed_rights_fee_flag, na.rm = TRUE),
    all_same_legal_set = n_distinct(legal_bbls) == 1L,
    all_same_seller_set = n_distinct(seller_party_set_key) == 1L,
    any_percent_not_100 = any(is.na(percent_trans) | percent_trans != 100, na.rm = TRUE),
    percent_trans_values = collapse_unique(as.character(percent_trans)),
    document_ids = collapse_unique(document_id),
    crfns = collapse_unique(crfn),
    source_document_counts = collapse_unique(as.character(exact_duplicate_group_docs)),
    document_amounts = collapse_unique(amount_key),
    positive_doc_amount_sum = sum(document_amt[positive_price_doc], na.rm = TRUE),
    positive_doc_amount_min = if (sum(positive_price_doc, na.rm = TRUE) > 0L) min(document_amt[positive_price_doc], na.rm = TRUE) else NA_real_,
    positive_doc_amount_max = if (sum(positive_price_doc, na.rm = TRUE) > 0L) max(document_amt[positive_price_doc], na.rm = TRUE) else NA_real_,
    buyer_names = collapse_unique(buyer_names),
    seller_names = collapse_in_order(seller_names),
    seller_party_keys = collapse_in_order(seller_party_set_key),
    legal_bbl_sets = collapse_in_order(legal_bbls),
    opportunity_bbl_sets = collapse_in_order(opportunity_bbls),
    document_exclusion_codes = collapse_unique(document_exclusion_codes),
    document_warning_codes = collapse_unique(document_warning_codes),
    .groups = "drop"
  ) |>
  left_join(bbl_repeat_summary, by = "buyer_date_key", relationship = "one-to-one") |>
  left_join(legal_address_summary, by = "buyer_date_key", relationship = "one-to-one") |>
  mutate(
    any_repeated_bbl = coalesce(any_repeated_bbl, FALSE),
    max_docs_per_bbl = coalesce(max_docs_per_bbl, 1L),
    n_union_bbls = coalesce(n_union_bbls, 0L),
    review_cluster_id = paste0("acris_site_cluster_", first_document_id),
    ambiguity_type = case_when(
      n_representative_docs == 1L & any_exact_duplicate ~ "exact_duplicate_only",
      n_representative_docs > 1L & n_zero_docs + n_nominal_docs == n_representative_docs ~ "zero_nominal_multidoc",
      n_representative_docs > 1L & any_unit_churn ~ "unit_churn_multidoc",
      n_representative_docs > 1L & any_rights_only ~ "rights_complex_multidoc",
      n_representative_docs > 1L & repeated_amount_flag & all_same_legal_set & any_repeated_bbl & !all_same_seller_set ~ "same_bbl_same_amount_different_sellers",
      n_representative_docs > 1L & repeated_amount_flag & all_same_legal_set & any_repeated_bbl & all_same_seller_set ~ "same_bbl_same_amount_same_seller",
      n_representative_docs > 1L & repeated_amount_flag & !all_same_legal_set & all_same_seller_set ~ "multi_bbl_same_amount_same_seller",
      n_representative_docs > 1L & repeated_amount_flag & !all_same_legal_set & !all_same_seller_set ~ "multi_bbl_same_amount_different_sellers",
      n_representative_docs > 1L & !repeated_amount_flag & any_repeated_bbl ~ "same_buyer_date_repeated_bbl_different_amounts",
      n_representative_docs > 1L & !repeated_amount_flag & !any_repeated_bbl ~ "same_buyer_date_multidoc_different_amounts",
      TRUE ~ "unclassified"
    ),
    first_layer_resolution_status = case_when(
      ambiguity_type == "exact_duplicate_only" ~ "MECHANICAL_RESOLVED_EXACT_DUPLICATE_PRICE_ONCE",
      TRUE ~ "REVIEW_REQUIRED"
    ),
    event_count_status_pre_review = case_when(
      ambiguity_type == "exact_duplicate_only" ~ "ONE_EVENT_RESOLVED",
      ambiguity_type %in% c(
        "same_bbl_same_amount_different_sellers",
        "same_bbl_same_amount_same_seller",
        "multi_bbl_same_amount_different_sellers",
        "multi_bbl_same_amount_same_seller"
      ) ~ "ONE_SITE_CANDIDATE_PRICE_UNRESOLVED",
      ambiguity_type %in% c("unit_churn_multidoc", "rights_complex_multidoc", "zero_nominal_multidoc") ~ "NON_SITE_OR_NO_PRICE_REVIEW",
      TRUE ~ "EVENT_COUNT_UNRESOLVED"
    ),
    event_price_status_pre_review = case_when(
      ambiguity_type == "exact_duplicate_only" & n_positive_price_docs > 0L ~ "FINAL_PRICE_RESOLVED",
      ambiguity_type == "exact_duplicate_only" ~ "NO_POSITIVE_PRICE",
      n_positive_price_docs > 0L ~ "PRICE_INTERVAL_ONLY",
      TRUE ~ "NO_POSITIVE_PRICE"
    ),
    event_price_final_pre_review = if_else(
      first_layer_resolution_status == "MECHANICAL_RESOLVED_EXACT_DUPLICATE_PRICE_ONCE",
      positive_doc_amount_sum,
      NA_real_
    ),
    price_lower_bound_pre_review = case_when(
      n_positive_price_docs == 0L ~ NA_real_,
      event_price_status_pre_review == "FINAL_PRICE_RESOLVED" ~ event_price_final_pre_review,
      TRUE ~ positive_doc_amount_max
    ),
    price_upper_bound_pre_review = case_when(
      n_positive_price_docs == 0L ~ NA_real_,
      event_price_status_pre_review == "FINAL_PRICE_RESOLVED" ~ event_price_final_pre_review,
      TRUE ~ positive_doc_amount_sum
    ),
    review_priority = case_when(
      first_layer_resolution_status != "REVIEW_REQUIRED" ~ "none_mechanical",
      n_positive_price_docs > 0L &
        ambiguity_type %in% c(
          "same_bbl_same_amount_different_sellers",
          "same_bbl_same_amount_same_seller",
          "multi_bbl_same_amount_different_sellers",
          "multi_bbl_same_amount_same_seller",
          "same_buyer_date_repeated_bbl_different_amounts"
        ) ~ "high_price_or_count_risk",
      n_positive_price_docs > 0L ~ "medium_positive_price",
      TRUE ~ "low_no_positive_price"
    ),
    expected_review_output = case_when(
      first_layer_resolution_status != "REVIEW_REQUIRED" ~ "no_review_needed",
      TRUE ~ "choose_final_event_count_and_price_rule"
    ),
    review_allowed_rulings = case_when(
      first_layer_resolution_status != "REVIEW_REQUIRED" ~ "MECHANICAL_RESOLVED",
      TRUE ~ "CONFIRM_SUM_DOCUMENT_AMOUNTS;CONFIRM_USE_REPEATED_AMOUNT_ONCE;CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS;CONFIRM_NO_SITE_PRICE;UNRESOLVED_AFTER_REVIEW"
    ),
    reviewer_final_ruling = NA_character_,
    reviewer_event_price_final = NA_real_,
    reviewer_event_count_final = NA_integer_,
    reviewer_source_urls = NA_character_,
    reviewer_notes = NA_character_
  ) |>
  arrange(first_document_id)

base_review_cluster_documents <- base_review_clusters_all |>
  filter(first_layer_resolution_status == "REVIEW_REQUIRED") |>
  select(base_review_cluster_id = review_cluster_id, buyer_date_key) |>
  inner_join(
    documents |>
      filter(review_cluster_seed) |>
      select(document_id, buyer_date_key, site_date_key),
    by = "buyer_date_key",
    relationship = "one-to-many"
  )

site_date_docs <- documents |>
  filter(representative_doc, !is.na(site_date_key), full_legal_bbl_set_key != "") |>
  left_join(
    base_review_cluster_documents |>
      select(document_id, base_review_cluster_id),
    by = "document_id",
    relationship = "one-to-one"
  )

site_date_legal_address_summary <- site_date_docs |>
  select(document_id, site_date_key) |>
  inner_join(
    legals |>
      filter(valid_legal_bbl) |>
      select(document_id, legal_address, property_type, unit, direct_opportunity_bbl_match),
    by = "document_id",
    relationship = "one-to-many"
  ) |>
  group_by(site_date_key) |>
  summarise(
    site_addresses = collapse_unique(legal_address),
    property_types = collapse_unique(property_type),
    units = collapse_unique(unit),
    n_direct_opportunity_legal_rows = sum(direct_opportunity_bbl_match, na.rm = TRUE),
    .groups = "drop"
  )

site_date_group_summary <- site_date_docs |>
  group_by(recorded_borough, document_date, site_date_key, full_legal_bbl_set_key) |>
  summarise(
    first_document_id = min(document_id),
    n_document_reps = n(),
    n_source_docs = sum(exact_duplicate_group_docs),
    n_buyer_keys = n_distinct(buyer_party_set_key),
    n_seller_keys = n_distinct(seller_party_set_key),
    n_base_review_clusters = n_distinct(base_review_cluster_id[!is.na(base_review_cluster_id)]),
    n_omitted_from_base_review = sum(is.na(base_review_cluster_id)),
    n_zero_docs = sum(amount_class == "ZERO", na.rm = TRUE),
    n_nominal_docs = sum(amount_class == "NOMINAL", na.rm = TRUE),
    n_positive_price_docs = sum(positive_price_doc, na.rm = TRUE),
    n_partial_docs = sum(partial_interest_doc, na.rm = TRUE),
    n_percent_missing = sum(is.na(percent_trans)),
    n_percent_100 = sum(percent_trans == 100, na.rm = TRUE),
    any_unit_churn = any(unit_churn_flag, na.rm = TRUE),
    any_rights_only = any(rights_only_flag, na.rm = TRUE),
    any_mixed_rights = any(mixed_rights_fee_flag, na.rm = TRUE),
    sum_percent_trans_raw = sum(percent_trans, na.rm = TRUE),
    percent_total_near_50_flag = abs(sum(percent_trans, na.rm = TRUE) - 50) <= 0.5,
    percent_total_near_55_flag = abs(sum(percent_trans, na.rm = TRUE) - 55) <= 0.5,
    percent_total_near_75_flag = abs(sum(percent_trans, na.rm = TRUE) - 75) <= 0.5,
    percent_total_near_100_flag = abs(sum(percent_trans, na.rm = TRUE) - 100) <= 0.5,
    percent_total_gt_100_flag = sum(percent_trans, na.rm = TRUE) > 100.5,
    document_ids = collapse_unique(document_id),
    crfns = collapse_unique(crfn),
    buyer_names = collapse_unique(buyer_names),
    seller_names = collapse_in_order(seller_names),
    buyer_party_keys = collapse_unique(buyer_party_set_key),
    seller_party_keys = collapse_in_order(seller_party_set_key),
    base_review_cluster_ids = collapse_unique(base_review_cluster_id),
    omitted_document_ids = collapse_unique(document_id[is.na(base_review_cluster_id)]),
    omitted_buyer_names = collapse_unique(buyer_names[is.na(base_review_cluster_id)]),
    omitted_document_amounts = collapse_unique(amount_key[is.na(base_review_cluster_id)]),
    omitted_percent_trans_values = collapse_unique(as.character(percent_trans[is.na(base_review_cluster_id)])),
    document_amounts = collapse_unique(amount_key),
    positive_doc_amount_sum = sum(document_amt[positive_price_doc], na.rm = TRUE),
    positive_doc_amount_max = if (sum(positive_price_doc, na.rm = TRUE) > 0L) max(document_amt[positive_price_doc], na.rm = TRUE) else NA_real_,
    percent_trans_values = collapse_unique(as.character(percent_trans)),
    legal_bbl_sets = collapse_in_order(legal_bbls),
    opportunity_bbl_sets = collapse_in_order(opportunity_bbls),
    document_exclusion_codes = collapse_unique(document_exclusion_codes),
    document_warning_codes = collapse_unique(document_warning_codes),
    .groups = "drop"
  ) |>
  left_join(
    site_date_legal_address_summary,
    by = "site_date_key",
    relationship = "one-to-one"
  ) |>
  mutate(
    salient_percent_total_flag = percent_total_near_50_flag |
      percent_total_near_55_flag |
      percent_total_near_75_flag |
      percent_total_near_100_flag,
    same_date_site_partial_interest_supercluster_flag = n_document_reps >= 2L &
      n_buyer_keys > 1L &
      n_partial_docs > 0L &
      n_positive_price_docs > 0L &
      !any_unit_churn &
      (
        n_base_review_clusters > 0L |
          n_seller_keys > 1L |
          salient_percent_total_flag
      ),
    underclustered_same_buyer_packet_flag = n_base_review_clusters > 0L &
      n_omitted_from_base_review > 0L &
      n_partial_docs > 0L
  )

same_date_site_superclusters <- site_date_group_summary |>
  filter(same_date_site_partial_interest_supercluster_flag) |>
  transmute(
    buyer_date_key = site_date_key,
    document_date,
    buyer_party_set_key = NA_character_,
    first_document_id,
    last_document_id = first_document_id,
    n_representative_docs = n_document_reps,
    n_source_docs,
    n_duplicate_docs = n_source_docs - n_document_reps,
    n_amounts = str_count(document_amounts, ";") + 1L,
    n_seller_sets = n_seller_keys,
    n_legal_sets = 1L,
    n_zero_docs,
    n_nominal_docs,
    n_low_docs = 0L,
    n_market_candidate_docs = n_positive_price_docs,
    n_positive_price_docs,
    repeated_amount_flag = FALSE,
    any_exact_duplicate = n_duplicate_docs > 0L,
    any_unit_churn,
    any_rights_only,
    any_mixed_rights,
    all_same_legal_set = TRUE,
    all_same_seller_set = n_seller_keys == 1L,
    any_percent_not_100 = n_partial_docs > 0L | n_percent_missing > 0L,
    percent_trans_values,
    document_ids,
    crfns,
    source_document_counts = NA_character_,
    document_amounts,
    positive_doc_amount_sum,
    positive_doc_amount_min = NA_real_,
    positive_doc_amount_max,
    buyer_names,
    seller_names,
    seller_party_keys,
    legal_bbl_sets,
    opportunity_bbl_sets,
    document_exclusion_codes,
    document_warning_codes,
    site_addresses,
    property_types,
    units,
    n_direct_opportunity_legal_rows,
    any_repeated_bbl = TRUE,
    max_docs_per_bbl = n_document_reps,
    n_union_bbls = str_count(full_legal_bbl_set_key, ";") + 1L,
    repeated_bbls = full_legal_bbl_set_key,
    review_cluster_id = paste0("acris_site_supercluster_", first_document_id),
    ambiguity_type = "same_date_site_partial_interest_supercluster",
    first_layer_resolution_status = "REVIEW_REQUIRED",
    event_count_status_pre_review = "EVENT_COUNT_UNRESOLVED",
    event_price_status_pre_review = "PRICE_INTERVAL_ONLY",
    event_price_final_pre_review = NA_real_,
    price_lower_bound_pre_review = positive_doc_amount_max,
    price_upper_bound_pre_review = positive_doc_amount_sum,
    review_priority = "high_price_or_count_risk",
    expected_review_output = "choose_final_event_count_and_price_rule",
    review_allowed_rulings = "CONFIRM_SUM_DOCUMENT_AMOUNTS;CONFIRM_USE_REPEATED_AMOUNT_ONCE;CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS;CONFIRM_NO_SITE_PRICE;UNRESOLVED_AFTER_REVIEW",
    reviewer_final_ruling = NA_character_,
    reviewer_event_price_final = NA_real_,
    reviewer_event_count_final = NA_integer_,
    reviewer_source_urls = NA_character_,
    reviewer_notes = NA_character_,
    site_date_key,
    full_legal_bbl_set_key,
    base_review_cluster_ids,
    n_buyer_keys,
    sum_percent_trans_raw,
    percent_total_near_50_flag,
    percent_total_near_55_flag,
    percent_total_near_75_flag,
    percent_total_near_100_flag,
    percent_total_gt_100_flag,
    underclustered_same_buyer_packet_flag
  )

suppressed_base_review_cluster_ids <- same_date_site_superclusters |>
  select(base_review_cluster_ids) |>
  separate_rows(base_review_cluster_ids, sep = ";") |>
  filter(!is.na(base_review_cluster_ids), base_review_cluster_ids != "") |>
  pull(base_review_cluster_ids) |>
  unique()

review_clusters_all <- bind_rows(
  base_review_clusters_all |>
    filter(!review_cluster_id %in% suppressed_base_review_cluster_ids),
  same_date_site_superclusters
) |>
  arrange(first_document_id, review_cluster_id)

if (any(review_clusters_all$ambiguity_type == "unclassified")) {
  stop("Unclassified ACRIS site-event review clusters remain.")
}

review_clusters <- review_clusters_all |>
  filter(first_layer_resolution_status == "REVIEW_REQUIRED") |>
  mutate(
    chatgpt_search_query = str_squish(paste(
      '"', buyer_names, '"',
      '"', coalesce(site_addresses, ""), '"',
      format(document_date, "%Y"),
      document_amounts,
      "NYC property sale"
    )),
    chatgpt_review_prompt = paste0(
      "We are reviewing an ACRIS multi-document site-sale ambiguity for an economics research dataset. ",
      "Goal: decide the economic event count and transaction price, using external evidence if available. ",
      "Do not infer from ACRIS alone when repeated amounts or repeated BBLs make the price ambiguous. ",
      "Allowed rulings: CONFIRM_SUM_DOCUMENT_AMOUNTS, CONFIRM_USE_REPEATED_AMOUNT_ONCE, ",
      "CONFIRM_EXTERNAL_TOTAL_PRICE, CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS, CONFIRM_NO_SITE_PRICE, ",
      "UNRESOLVED_AFTER_REVIEW. ",
      "Cluster ID: ", review_cluster_id, ". ",
      "Ambiguity type: ", ambiguity_type, ". ",
      "Date: ", as.character(document_date), ". ",
      "Buyer: ", buyer_names, ". ",
      "Sellers: ", seller_names, ". ",
      "Document IDs: ", document_ids, ". ",
      "CRFNs: ", crfns, ". ",
      "Document amounts: ", document_amounts, ". ",
      "Percent transferred values: ", percent_trans_values, ". ",
      if_else(
        ambiguity_type == "same_date_site_partial_interest_supercluster",
        paste0(
          "This is a same-date/site partial-interest supercluster created to catch possible buyer-SPV splits. ",
          "The documents share the same exact full legal BBL set and date but may have multiple buyer entities. ",
          "Raw percent_trans sum: ", coalesce(as.character(sum_percent_trans_raw), "NA"), ". ",
          "Source buyer-date packet IDs drawn from the earlier review layer: ", coalesce(base_review_cluster_ids, "none"), ". ",
          "Those source packet IDs can span other same-date sites for the same buyer; adjudicate only the listed document IDs and legal BBL set in this prompt. "
        ),
        ""
      ),
      "Legal BBL sets: ", legal_bbl_sets, ". ",
      "Site addresses from ACRIS legal rows: ", coalesce(site_addresses, "missing"), ". ",
      "Property types: ", coalesce(property_types, "missing"), ". ",
      "Units: ", coalesce(units, "missing"), ". ",
      "Pre-review price interval: [", coalesce(as.character(price_lower_bound_pre_review), "NA"), ", ",
      coalesce(as.character(price_upper_bound_pre_review), "NA"), "]. ",
      "Please search for news, press releases, broker reports, public filings, or other credible sources. ",
      "Return a ruling, final event count, final transaction price if supported, source URLs, and a short explanation."
    )
  )

if (anyDuplicated(review_clusters$review_cluster_id) > 0L) {
  stop("Review clusters are not unique by review_cluster_id.")
}

review_document_bridge_base <- review_clusters |>
  filter(ambiguity_type != "same_date_site_partial_interest_supercluster") |>
  select(review_cluster_id, ambiguity_type, first_layer_resolution_status, buyer_date_key) |>
  inner_join(
    documents |>
      select(
        event_id, document_id, crfn, recorded_borough, doc_type, document_date,
        document_amt, amount_class, percent_trans, representative_doc,
        exact_duplicate_group_docs, duplicate_price_excluded_flag,
        ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
        buyer_date_key, buyer_names, seller_names, legal_bbls, opportunity_bbls,
        n_all_legal_bbls, n_opportunity_legal_bbls, document_exclusion_codes,
        document_warning_codes
      ),
    by = "buyer_date_key",
    relationship = "one-to-many"
  ) |>
  arrange(review_cluster_id, document_id)

review_document_bridge_supercluster <- review_clusters |>
  filter(ambiguity_type == "same_date_site_partial_interest_supercluster") |>
  select(review_cluster_id, ambiguity_type, first_layer_resolution_status, site_date_key) |>
  inner_join(
    documents |>
      filter(representative_doc) |>
      select(
        event_id, document_id, crfn, recorded_borough, doc_type, document_date,
        document_amt, amount_class, percent_trans, representative_doc,
        exact_duplicate_group_docs, duplicate_price_excluded_flag,
        ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
        buyer_date_key, site_date_key, buyer_names, seller_names, legal_bbls, opportunity_bbls,
        n_all_legal_bbls, n_opportunity_legal_bbls, document_exclusion_codes,
        document_warning_codes
      ),
    by = "site_date_key",
    relationship = "one-to-many",
    suffix = c("_cluster", "")
  ) |>
  select(
    review_cluster_id, ambiguity_type, first_layer_resolution_status,
    event_id, document_id, crfn, recorded_borough, doc_type, document_date,
    document_amt, amount_class, percent_trans, representative_doc,
    exact_duplicate_group_docs, duplicate_price_excluded_flag,
    ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
    buyer_date_key,
    buyer_names, seller_names, legal_bbls, opportunity_bbls,
    n_all_legal_bbls, n_opportunity_legal_bbls, document_exclusion_codes,
    document_warning_codes
  ) |>
  arrange(review_cluster_id, document_id)

review_document_bridge <- bind_rows(
  review_document_bridge_base,
  review_document_bridge_supercluster
) |>
  arrange(review_cluster_id, document_id)

review_legals <- review_document_bridge |>
  select(review_cluster_id, ambiguity_type, document_id) |>
  inner_join(
    legals |>
      select(
        document_id, legal_borough, legal_block, legal_lot, legal_bbl,
        valid_legal_bbl, direct_opportunity_bbl_match, property_type,
        legal_address, unit, air_rights, easement, subterranean_rights,
        partial_lot, good_through_date
      ),
    by = "document_id",
    relationship = "one-to-many"
  ) |>
  arrange(review_cluster_id, document_id, legal_bbl)

review_parties <- review_document_bridge |>
  select(review_cluster_id, ambiguity_type, document_id) |>
  inner_join(
    parties |>
      select(
        document_id, party_type, party_name, address_1, address_2,
        country, city, state, zip, good_through_date
      ),
    by = "document_id",
    relationship = "one-to-many"
  ) |>
  arrange(review_cluster_id, document_id, party_type, party_name)

review_summary <- review_clusters_all |>
  group_by(
    ambiguity_type, first_layer_resolution_status,
    event_count_status_pre_review, event_price_status_pre_review,
    review_priority
  ) |>
  summarise(
    clusters = n(),
    representative_documents = sum(n_representative_docs),
    source_documents = sum(n_source_docs),
    duplicate_documents = sum(n_duplicate_docs),
    positive_price_clusters = sum(n_positive_price_docs > 0L),
    positive_price_documents = sum(n_positive_price_docs),
    positive_doc_amount_sum = sum(positive_doc_amount_sum, na.rm = TRUE),
    price_interval_lower_sum = sum(price_lower_bound_pre_review, na.rm = TRUE),
    price_interval_upper_sum = sum(price_upper_bound_pre_review, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(first_layer_resolution_status, ambiguity_type)

chatgpt_prompts <- review_clusters |>
  select(
    review_cluster_id, ambiguity_type, review_priority, document_date,
    buyer_names, seller_names, document_ids, crfns, document_amounts,
    legal_bbl_sets, site_addresses, property_types, units,
    price_lower_bound_pre_review, price_upper_bound_pre_review,
    review_allowed_rulings, chatgpt_search_query, chatgpt_review_prompt,
    reviewer_final_ruling, reviewer_event_price_final,
    reviewer_event_count_final, reviewer_source_urls, reviewer_notes
  ) |>
  arrange(review_priority, ambiguity_type, document_date, review_cluster_id)

audit_same_date_site_partial_interest_superclusters <- site_date_group_summary |>
  filter(n_document_reps >= 2L, n_partial_docs > 0L) |>
  select(
    site_date_key, document_date, full_legal_bbl_set_key,
    n_document_reps, n_buyer_keys, n_seller_keys,
    buyer_names, seller_names, document_ids, crfns, document_amounts,
    positive_doc_amount_sum, positive_doc_amount_max,
    sum_percent_trans_raw, percent_trans_values,
    n_percent_missing, n_partial_docs, n_percent_100,
    n_zero_docs, n_nominal_docs, n_positive_price_docs,
    any_unit_churn, any_rights_only, any_mixed_rights,
    percent_total_near_50_flag, percent_total_near_55_flag,
    percent_total_near_75_flag, percent_total_near_100_flag,
    percent_total_gt_100_flag, salient_percent_total_flag,
    same_date_site_partial_interest_supercluster_flag,
    underclustered_same_buyer_packet_flag,
    n_base_review_clusters, base_review_cluster_ids,
    n_omitted_from_base_review, omitted_document_ids,
    omitted_buyer_names, omitted_document_amounts,
    omitted_percent_trans_values
  ) |>
  arrange(desc(same_date_site_partial_interest_supercluster_flag), document_date, full_legal_bbl_set_key)

audit_underclustered_same_buyer_packets <- site_date_group_summary |>
  filter(underclustered_same_buyer_packet_flag) |>
  transmute(
    site_date_key,
    document_date,
    full_legal_bbl_set_key,
    base_review_cluster_ids,
    omitted_document_ids,
    omitted_buyer_names,
    omitted_document_amounts,
    omitted_percent_trans_values,
    combined_document_ids = document_ids,
    combined_buyer_names = buyer_names,
    combined_document_amounts = document_amounts,
    combined_sum_amount = positive_doc_amount_sum,
    combined_sum_percent_trans = sum_percent_trans_raw,
    undercluster_risk_reason = "same date and exact full legal BBL set has buyer-date review cluster plus omitted singleton or other buyer-key partial-interest document"
  ) |>
  arrange(document_date, site_date_key)

audit_review_cluster_superset_bridge <- same_date_site_superclusters |>
  select(supercluster_id = review_cluster_id, site_date_key, base_review_cluster_ids) |>
  inner_join(
    site_date_docs |>
      select(
        site_date_key, document_id, base_review_cluster_id, buyer_date_key,
        buyer_names, seller_names, document_amt, percent_trans
      ),
    by = "site_date_key",
    relationship = "one-to-many"
  ) |>
  mutate(
    included_in_old_packet_flag = !is.na(base_review_cluster_id),
    included_in_supercluster_flag = TRUE,
    reason_added_to_supercluster = if_else(
      included_in_old_packet_flag,
      "document already in lower-level buyer-date review cluster",
      "same-date exact full legal BBL partial-interest document omitted by lower-level buyer-date review cluster"
    )
  ) |>
  arrange(supercluster_id, document_id)

if (anyDuplicated(review_clusters_all$review_cluster_id) > 0L) {
  stop("Review cluster IDs are not unique.")
}

if (nrow(review_clusters) == 0L) {
  stop("No non-mechanical ACRIS site-event clusters were found for review.")
}

if (any(is.na(review_clusters$chatgpt_review_prompt) | review_clusters$chatgpt_review_prompt == "")) {
  stop("Every review-required cluster must have a ChatGPT review prompt.")
}

write_csv_if_changed(review_summary, "../output/acris_site_event_review_summary.csv")
write_csv_if_changed(review_clusters, "../output/acris_site_event_review_clusters.csv")
write_csv_if_changed(review_document_bridge, "../output/acris_site_event_review_documents.csv")
write_csv_if_changed(review_legals, "../output/acris_site_event_review_legals.csv")
write_csv_if_changed(review_parties, "../output/acris_site_event_review_parties.csv")
write_csv_if_changed(chatgpt_prompts, "../output/acris_site_event_review_chatgpt_prompts.csv")
write_csv_if_changed(audit_same_date_site_partial_interest_superclusters, "../output/audit_same_date_site_partial_interest_superclusters.csv")
write_csv_if_changed(audit_underclustered_same_buyer_packets, "../output/audit_underclustered_same_buyer_packets.csv")
write_csv_if_changed(audit_review_cluster_superset_bridge, "../output/audit_review_cluster_superset_bridge.csv")
cat("Wrote ACRIS site-event review packet to ../output\n")

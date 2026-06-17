# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_site_events/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../_lib/source_pipeline_utils.R")

positive_amount_classes <- c("MARKET_CANDIDATE", "LOW")
zero_nominal_amount_classes <- c("ZERO", "NOMINAL")

collapse_unique <- function(x) {
  values <- sort(unique(as.character(x[!is.na(x) & x != ""])))
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(values, collapse = ";")
}

paste_codes <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(unique(values), collapse = ";")
}

event_quarter <- function(x) {
  month_value <- suppressWarnings(as.integer(format(x, "%m")))
  quarter_value <- ((month_value - 1L) %/% 3L) + 1L
  out <- paste0(format(x, "%Y"), "Q", quarter_value)
  out[is.na(x)] <- NA_character_
  out
}

split_set_contains <- function(set_string, value) {
  values <- unlist(str_split(coalesce(set_string, ""), ";", simplify = FALSE))
  values <- values[!is.na(values) & values != ""]
  !is.na(value) && value %in% values
}

documents <- read_parquet("../input/acris_deed_document_classified.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  rename(event_id_market_universe = event_id) |>
  mutate(
    document_id = str_squish(as.character(document_id)),
    crfn = str_squish(as.character(crfn)),
    event_id_mechanical_source = event_id_market_universe,
    event_id_mechanical = str_replace(event_id_mechanical_source, "^acris_market_", "acris_site_mechanical_")
  )

review_clusters <- read_csv(
  "../input/acris_site_event_review_clusters.csv",
  col_types = cols(
    first_document_id = col_character(),
    last_document_id = col_character(),
    .default = col_guess()
  ),
  na = c("", "NA")
) |>
  mutate(review_cluster_id = str_squish(as.character(review_cluster_id)))

review_documents <- read_csv(
  "../input/acris_site_event_review_documents.csv",
  col_types = cols(
    document_id = col_character(),
    crfn = col_character(),
    .default = col_guess()
  ),
  na = c("", "NA")
) |>
  mutate(
    review_cluster_id = str_squish(as.character(review_cluster_id)),
    document_id = str_squish(as.character(document_id))
  ) |>
  select(review_cluster_id, ambiguity_type, document_id)

manual_decisions <- read_csv(
  "../input/acris_site_event_manual_review_decisions.csv",
  col_types = cols(review_cluster_id = col_character(), .default = col_guess()),
  na = c("", "NA")
) |>
  filter(!is.na(review_cluster_id)) |>
  mutate(review_cluster_id = str_squish(as.character(review_cluster_id))) |>
  select(-any_of("ambiguity_type"))

if (anyDuplicated(documents$document_id) > 0L) {
  stop("Classified ACRIS documents are not unique by document_id.")
}

if (anyDuplicated(review_documents$document_id) > 0L) {
  stop("A review-packet document appears in more than one review cluster.")
}

if (anyDuplicated(review_clusters$review_cluster_id) > 0L) {
  stop("Review clusters are not unique by review_cluster_id.")
}

if (anyDuplicated(manual_decisions$review_cluster_id) > 0L) {
  stop("Manual review decisions are not unique by review_cluster_id.")
}

missing_review_docs <- setdiff(review_documents$document_id, documents$document_id)
if (length(missing_review_docs) > 0L) {
  stop("Review-packet documents are missing from classified ACRIS documents.")
}

missing_decision_clusters <- setdiff(manual_decisions$review_cluster_id, review_clusters$review_cluster_id)
if (length(missing_decision_clusters) > 0L) {
  stop("Manual review decisions include unknown review clusters.")
}

review_clusters_for_task <- review_clusters |>
  select(
    review_cluster_id, ambiguity_type, review_priority, first_layer_resolution_status,
    n_representative_docs, n_source_docs, n_positive_price_docs, n_zero_docs,
    n_nominal_docs, n_low_docs, n_market_candidate_docs, positive_doc_amount_sum,
    positive_doc_amount_min, positive_doc_amount_max, document_ids, crfns,
    site_addresses, property_types, units
  ) |>
  left_join(manual_decisions, by = "review_cluster_id", relationship = "one-to-one") |>
  mutate(
    manual_review_status = if_else(is.na(manual_review_status), "NOT_REVIEWED", manual_review_status),
    reviewer_event_count_final = suppressWarnings(as.integer(reviewer_event_count_final)),
    event_records_to_create = case_when(
      reviewer_final_ruling == "UNRESOLVED_AFTER_REVIEW" & is.na(reviewer_event_count_final) ~ 1L,
      reviewer_final_ruling == "CONFIRM_NO_SITE_PRICE" & is.na(reviewer_event_count_final) ~ 1L,
      TRUE ~ reviewer_event_count_final
    ),
    completed_manual_review = manual_review_status != "NOT_REVIEWED"
  )

completed_clusters <- review_clusters_for_task |>
  filter(completed_manual_review)

unreviewed_clusters <- review_clusters_for_task |>
  filter(!completed_manual_review)

bad_completed <- completed_clusters |>
  filter(
    is.na(reviewer_final_ruling) |
      is.na(event_records_to_create) |
      event_records_to_create < 1L
  )
if (nrow(bad_completed) > 0L) {
  stop("Completed manual review clusters are missing final ruling or event count.")
}

priced_manual_rulings <- c(
  "CONFIRM_SUM_DOCUMENT_AMOUNTS",
  "CONFIRM_EXTERNAL_TOTAL_PRICE",
  "CONFIRM_USE_REPEATED_AMOUNT_ONCE"
)

bad_manual_price <- completed_clusters |>
  filter(
    reviewer_final_ruling %in% priced_manual_rulings,
    is.na(reviewer_event_price_final) | reviewer_event_price_final <= 0
  )
if (nrow(bad_manual_price) > 0L) {
  stop("Priced manual rulings must have a positive reviewer_event_price_final.")
}

review_doc_ids <- review_documents$document_id

mechanical_bridge <- documents |>
  filter(!document_id %in% review_doc_ids) |>
  transmute(
    event_id = event_id_mechanical,
    document_id,
    review_cluster_id = NA_character_,
    manual_event_index = NA_integer_,
    record_type = "resolved_site_event",
    event_construction_status = "mechanical_unambiguous",
    document_role = case_when(
      duplicate_price_excluded_flag ~ "exact_duplicate_source_excluded_from_price",
      amount_class %in% positive_amount_classes ~ "mechanical_price_document",
      amount_class %in% zero_nominal_amount_classes ~ "mechanical_zero_nominal_document",
      TRUE ~ "mechanical_source_document"
    ),
    price_anchor_document = !duplicate_price_excluded_flag & amount_class %in% positive_amount_classes,
    document_amt_included_in_final_price = price_anchor_document
  )

manual_review_docs <- review_documents |>
  inner_join(documents, by = "document_id", relationship = "many-to-one") |>
  left_join(
    review_clusters_for_task |>
      select(
        review_cluster_id, review_priority, manual_review_status, completed_manual_review,
        reviewer_final_ruling, reviewer_event_count_final, event_records_to_create,
        reviewer_event_price_final, price_rule, source_confidence, source_urls,
        reviewer_notes, reviewed_by, reviewed_date
      ),
    by = "review_cluster_id",
    relationship = "many-to-one"
  )

manual_one_event_bridge <- manual_review_docs |>
  filter(
    completed_manual_review,
    reviewer_final_ruling != "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS"
  ) |>
  mutate(
    manual_event_index = 1L,
    event_id = paste0("acris_site_manual_", review_cluster_id, "_01"),
    record_type = if_else(
      reviewer_final_ruling == "UNRESOLVED_AFTER_REVIEW",
      "unresolved_review_cluster_placeholder",
      "resolved_site_event"
    ),
    event_construction_status = "manual_completed",
    document_role = case_when(
      reviewer_final_ruling == "UNRESOLVED_AFTER_REVIEW" ~ "manual_unresolved_source",
      reviewer_final_ruling == "CONFIRM_NO_SITE_PRICE" ~ "manual_confirmed_no_price_source",
      amount_class %in% positive_amount_classes ~ "manual_positive_source",
      amount_class %in% zero_nominal_amount_classes ~ "manual_zero_nominal_companion",
      TRUE ~ "manual_source_document"
    ),
    price_anchor_document = FALSE,
    document_amt_included_in_final_price = reviewer_final_ruling == "CONFIRM_SUM_DOCUMENT_AMOUNTS" &
      amount_class %in% positive_amount_classes
  ) |>
  select(
    event_id, document_id, review_cluster_id, manual_event_index, record_type,
    event_construction_status, document_role, price_anchor_document,
    document_amt_included_in_final_price
  )

manual_keep_docs <- manual_review_docs |>
  filter(
    completed_manual_review,
    reviewer_final_ruling == "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS"
  )

manual_keep_anchors <- manual_keep_docs |>
  filter(amount_class %in% positive_amount_classes) |>
  arrange(review_cluster_id, document_id) |>
  group_by(review_cluster_id) |>
  mutate(
    manual_event_index = row_number(),
    event_id = paste0("acris_site_manual_", review_cluster_id, "_doc_", document_id)
  ) |>
  ungroup()

keep_anchor_counts <- manual_keep_anchors |>
  group_by(review_cluster_id) |>
  summarise(anchor_events = n(), .groups = "drop") |>
  left_join(
    completed_clusters |>
      filter(reviewer_final_ruling == "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS") |>
      select(review_cluster_id, event_records_to_create),
    by = "review_cluster_id",
    relationship = "one-to-one"
  )

if (nrow(keep_anchor_counts) > 0L && any(keep_anchor_counts$anchor_events != keep_anchor_counts$event_records_to_create)) {
  stop("Keep-separate manual clusters do not have one positive-price anchor per reviewed event.")
}

manual_keep_anchor_bridge <- manual_keep_anchors |>
  transmute(
    event_id, document_id, review_cluster_id, manual_event_index,
    record_type = "resolved_site_event",
    event_construction_status = "manual_completed",
    document_role = "manual_keep_separate_price_anchor",
    price_anchor_document = TRUE,
    document_amt_included_in_final_price = TRUE
  )

manual_keep_companion_rows <- list()
manual_keep_companions <- manual_keep_docs |>
  filter(!amount_class %in% positive_amount_classes) |>
  arrange(review_cluster_id, document_id)

if (nrow(manual_keep_companions) > 0L) {
  for (i in seq_len(nrow(manual_keep_companions))) {
    companion <- manual_keep_companions[i, ]
    cluster_anchors <- manual_keep_anchors |>
      filter(review_cluster_id == companion$review_cluster_id)

    direct_candidates <- cluster_anchors |>
      filter(
        buyer_party_set_key == companion$buyer_party_set_key,
        seller_party_set_key == companion$seller_party_set_key
      )

    chain_candidates <- cluster_anchors |>
      filter(seller_party_set_key == companion$buyer_party_set_key)

    if (nrow(direct_candidates) == 1L) {
      chosen_anchor <- direct_candidates
    } else if (nrow(chain_candidates) == 1L) {
      chosen_anchor <- chain_candidates
    } else if (nrow(cluster_anchors) == 1L) {
      chosen_anchor <- cluster_anchors
    } else {
      stop(paste0(
        "Could not deterministically attach keep-separate companion document ",
        companion$document_id,
        " in ",
        companion$review_cluster_id,
        "."
      ))
    }

    manual_keep_companion_rows[[length(manual_keep_companion_rows) + 1L]] <- tibble(
      event_id = chosen_anchor$event_id,
      document_id = companion$document_id,
      review_cluster_id = companion$review_cluster_id,
      manual_event_index = chosen_anchor$manual_event_index,
      record_type = "resolved_site_event",
      event_construction_status = "manual_completed",
      document_role = "manual_keep_separate_companion",
      price_anchor_document = FALSE,
      document_amt_included_in_final_price = FALSE
    )
  }
}

manual_keep_companion_bridge <- bind_rows(manual_keep_companion_rows)

manual_keep_bridge <- bind_rows(
  manual_keep_anchor_bridge,
  manual_keep_companion_bridge
)

unreviewed_bridge <- manual_review_docs |>
  filter(!completed_manual_review) |>
  transmute(
    event_id = paste0("acris_site_unreviewed_", review_cluster_id),
    document_id,
    review_cluster_id,
    manual_event_index = NA_integer_,
    record_type = "unresolved_review_cluster_placeholder",
    event_construction_status = "manual_required_unreviewed",
    document_role = case_when(
      amount_class %in% positive_amount_classes ~ "unreviewed_cluster_positive_source",
      amount_class %in% zero_nominal_amount_classes ~ "unreviewed_cluster_zero_nominal_source",
      TRUE ~ "unreviewed_cluster_source"
    ),
    price_anchor_document = FALSE,
    document_amt_included_in_final_price = FALSE
  )

event_document_bridge <- bind_rows(
  mechanical_bridge,
  manual_one_event_bridge,
  manual_keep_bridge,
  unreviewed_bridge
) |>
  arrange(event_id, document_id)

if (anyDuplicated(event_document_bridge$document_id) > 0L) {
  stop("A source document maps to more than one final site-event record.")
}

if (!setequal(event_document_bridge$document_id, documents$document_id)) {
  stop("The event-document bridge does not cover exactly the classified ACRIS documents.")
}

review_docs_mechanical <- event_document_bridge |>
  filter(document_id %in% review_doc_ids, event_construction_status == "mechanical_unambiguous")
if (nrow(review_docs_mechanical) > 0L) {
  stop("Review-cluster documents survived in mechanical events.")
}

event_document_details <- event_document_bridge |>
  left_join(documents, by = "document_id", relationship = "one-to-one") |>
  left_join(
    review_clusters_for_task |>
      select(
        review_cluster_id, ambiguity_type, review_priority, manual_review_status,
        completed_manual_review, reviewer_final_ruling, reviewer_event_count_final,
        event_records_to_create, reviewer_event_price_final, price_rule,
        source_confidence, source_urls, reviewer_notes, reviewed_by, reviewed_date
      ),
    by = "review_cluster_id",
    relationship = "many-to-one"
  )

events <- event_document_details |>
  group_by(event_id) |>
  summarise(
    record_type = first(record_type),
    event_construction_status = first(event_construction_status),
    review_cluster_id = first(review_cluster_id),
    ambiguity_type = first(ambiguity_type),
    review_priority = first(review_priority),
    manual_review_status = first(manual_review_status),
    reviewer_final_ruling = first(reviewer_final_ruling),
    reviewer_event_count_final = first(reviewer_event_count_final),
    event_records_to_create = first(event_records_to_create),
    reviewer_event_price_final = first(reviewer_event_price_final),
    price_rule = first(price_rule),
    source_confidence = first(source_confidence),
    source_urls = first(source_urls),
    reviewer_notes = first(reviewer_notes),
    reviewed_by = first(reviewed_by),
    reviewed_date = first(reviewed_date),
    event_date_min = if (all(is.na(document_date))) as.Date(NA) else min(document_date, na.rm = TRUE),
    event_date_max = if (all(is.na(document_date))) as.Date(NA) else max(document_date, na.rm = TRUE),
    event_date_primary = if (all(is.na(document_date))) as.Date(NA) else min(document_date, na.rm = TRUE),
    source_document_ids = collapse_unique(document_id),
    crfns = collapse_unique(crfn),
    n_source_documents = n_distinct(document_id),
    n_price_anchor_documents = sum(price_anchor_document, na.rm = TRUE),
    n_positive_price_documents = n_distinct(document_id[amount_class %in% positive_amount_classes]),
    n_zero_nominal_documents = n_distinct(document_id[amount_class %in% zero_nominal_amount_classes]),
    n_duplicate_documents = n_distinct(document_id[duplicate_price_excluded_flag]),
    raw_positive_document_amt_sum = sum(document_amt[amount_class %in% positive_amount_classes], na.rm = TRUE),
    raw_document_amt_sum = sum(document_amt, na.rm = TRUE),
    buyer_names = collapse_unique(buyer_names),
    seller_names = collapse_unique(seller_names),
    buyer_party_set_keys = collapse_unique(buyer_party_set_key),
    seller_party_set_keys = collapse_unique(seller_party_set_key),
    percent_trans_min = if (all(is.na(percent_trans))) NA_real_ else min(percent_trans, na.rm = TRUE),
    percent_trans_max = if (all(is.na(percent_trans))) NA_real_ else max(percent_trans, na.rm = TRUE),
    n_all_legal_bbls_source_max = max(n_all_legal_bbls, na.rm = TRUE),
    n_opportunity_bbls_source_max = max(n_opportunity_legal_bbls, na.rm = TRUE),
    legal_bbls = collapse_unique(legal_bbls),
    opportunity_bbls = collapse_unique(opportunity_bbls),
    all_legal_allowed_res_area_sum = max(all_legal_allowed_res_area_sum, na.rm = TRUE),
    opp_legal_allowed_res_area_sum = max(opp_legal_allowed_res_area_sum, na.rm = TRUE),
    all_legal_lotarea_sum = max(all_legal_lotarea_sum, na.rm = TRUE),
    opp_legal_lotarea_sum = max(opp_legal_lotarea_sum, na.rm = TRUE),
    event_opp_share_allowed_res_area = max(event_opp_share_allowed_res_area, na.rm = TRUE),
    event_opp_share_lotarea = max(event_opp_share_lotarea, na.rm = TRUE),
    unit_churn_flag = any(unit_churn_flag, na.rm = TRUE),
    rights_only_flag = any(rights_only_flag, na.rm = TRUE),
    mixed_rights_flag = any(mixed_rights_fee_flag, na.rm = TRUE),
    public_party_flag = any(public_party_flag, na.rm = TRUE),
    hdfc_party_flag = any(hdfc_party_flag, na.rm = TRUE),
    housing_public_or_regulated_party_flag = any(housing_public_or_regulated_party_flag, na.rm = TRUE),
    nonprofit_religious_party_flag = any(nonprofit_religious_party_flag, na.rm = TRUE),
    trust_estate_party_flag = any(trust_estate_party_flag, na.rm = TRUE),
    related_party_strong_flag = any(strong_related_party_flag, na.rm = TRUE),
    related_party_weak_flag = any(weak_related_party_flag, na.rm = TRUE),
    document_market_statuses = collapse_unique(document_market_status),
    document_exclusion_codes = collapse_unique(document_exclusion_codes),
    document_warning_codes = collapse_unique(document_warning_codes),
    .groups = "drop"
  ) |>
  mutate(
    event_date_span_days = as.integer(event_date_max - event_date_min),
    event_quarter = event_quarter(event_date_primary),
    event_price_final = case_when(
      event_construction_status == "mechanical_unambiguous" ~ raw_positive_document_amt_sum,
      event_construction_status == "manual_completed" &
        reviewer_final_ruling %in% priced_manual_rulings ~ reviewer_event_price_final,
      event_construction_status == "manual_completed" &
        reviewer_final_ruling == "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS" ~ raw_positive_document_amt_sum,
      TRUE ~ NA_real_
    ),
    event_price_final = if_else(!is.na(event_price_final) & event_price_final > 0, event_price_final, NA_real_),
    has_final_price = !is.na(event_price_final),
    price_resolution_status = case_when(
      event_construction_status == "mechanical_unambiguous" & has_final_price ~ "mechanical_positive_document_price",
      event_construction_status == "mechanical_unambiguous" & !has_final_price ~ "mechanical_no_positive_document_price",
      reviewer_final_ruling == "CONFIRM_SUM_DOCUMENT_AMOUNTS" ~ "manual_sum_document_amounts",
      reviewer_final_ruling == "CONFIRM_EXTERNAL_TOTAL_PRICE" ~ "manual_external_total_price",
      reviewer_final_ruling == "CONFIRM_USE_REPEATED_AMOUNT_ONCE" ~ "manual_repeated_amount_once",
      reviewer_final_ruling == "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS" ~ "manual_keep_separate_positive_document_price",
      reviewer_final_ruling == "CONFIRM_NO_SITE_PRICE" ~ "manual_confirmed_no_site_price",
      reviewer_final_ruling == "UNRESOLVED_AFTER_REVIEW" ~ "manual_unresolved_after_review",
      event_construction_status == "manual_required_unreviewed" &
        raw_positive_document_amt_sum > 0 ~ "unreviewed_positive_price_ambiguous",
      event_construction_status == "manual_required_unreviewed" ~ "unreviewed_no_positive_document_price",
      TRUE ~ "unknown_price_resolution"
    ),
    event_count_resolution_status = case_when(
      record_type == "unresolved_review_cluster_placeholder" ~ "cluster_placeholder_not_economic_event_count",
      reviewer_final_ruling == "CONFIRM_NO_SITE_PRICE" ~ "no_site_price_confirmed",
      TRUE ~ "resolved_event_count"
    ),
    exclude_from_default_price_totals = !has_final_price | record_type != "resolved_site_event",
    all_legal_allowed_res_area_sum = if_else(is.finite(all_legal_allowed_res_area_sum), all_legal_allowed_res_area_sum, NA_real_),
    opp_legal_allowed_res_area_sum = if_else(is.finite(opp_legal_allowed_res_area_sum), opp_legal_allowed_res_area_sum, NA_real_),
    all_legal_lotarea_sum = if_else(is.finite(all_legal_lotarea_sum), all_legal_lotarea_sum, NA_real_),
    opp_legal_lotarea_sum = if_else(is.finite(opp_legal_lotarea_sum), opp_legal_lotarea_sum, NA_real_),
    event_opp_share_allowed_res_area = if_else(is.finite(event_opp_share_allowed_res_area), event_opp_share_allowed_res_area, NA_real_),
    event_opp_share_lotarea = if_else(is.finite(event_opp_share_lotarea), event_opp_share_lotarea, NA_real_),
    n_all_legal_bbls_source_max = if_else(is.finite(n_all_legal_bbls_source_max), n_all_legal_bbls_source_max, NA_real_),
    n_opportunity_bbls_source_max = if_else(is.finite(n_opportunity_bbls_source_max), n_opportunity_bbls_source_max, NA_real_)
  ) |>
  arrange(event_date_primary, event_id)

if (anyDuplicated(events$event_id) > 0L) {
  stop("ACRIS site events are not unique by event_id.")
}

manual_event_counts <- events |>
  filter(event_construction_status == "manual_completed") |>
  group_by(review_cluster_id) |>
  summarise(n_events_created = n(), .groups = "drop") |>
  left_join(
    completed_clusters |> select(review_cluster_id, event_records_to_create),
    by = "review_cluster_id",
    relationship = "one-to-one"
  )

if (any(manual_event_counts$n_events_created != manual_event_counts$event_records_to_create)) {
  stop("Completed manual clusters do not create the reviewed number of final event records.")
}

if (any(events$event_construction_status == "manual_required_unreviewed" & events$has_final_price)) {
  stop("Unreviewed review-cluster placeholders must not carry final prices.")
}

external_price_missing_source <- events |>
  filter(
    reviewer_final_ruling == "CONFIRM_EXTERNAL_TOTAL_PRICE",
    is.na(source_urls) | source_urls == ""
  )
if (nrow(external_price_missing_source) > 0L) {
  stop("External-price manual events must carry source URLs.")
}

acris_site_event_documents <- event_document_details |>
  select(
    event_id, document_id, crfn, recorded_borough, doc_type, document_date,
    document_amt, amount_class, percent_trans, review_cluster_id,
    manual_event_index, record_type, event_construction_status,
    document_role, price_anchor_document, document_amt_included_in_final_price,
    document_market_status, document_exclusion_codes, document_warning_codes,
    cluster_rule, exact_duplicate_group_docs, duplicate_price_excluded_flag,
    ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
    buyer_names, seller_names, buyer_party_set_key, seller_party_set_key,
    legal_bbls, opportunity_bbls
  ) |>
  arrange(event_id, document_id)

if (anyDuplicated(paste(acris_site_event_documents$event_id, acris_site_event_documents$document_id, sep = "::")) > 0L) {
  stop("Event-document bridge is not unique by event_id/document_id.")
}

document_bbls <- documents |>
  transmute(document_id, legal_bbls, opportunity_bbls) |>
  separate_rows(legal_bbls, sep = ";") |>
  mutate(
    legal_bbl = normalize_bbl_field(legal_bbls),
    direct_opportunity_bbl_match = mapply(split_set_contains, opportunity_bbls, legal_bbl)
  ) |>
  filter(!is.na(legal_bbl)) |>
  distinct(document_id, legal_bbl, direct_opportunity_bbl_match)

acris_site_event_bbl_incidence <- acris_site_event_documents |>
  select(event_id, document_id) |>
  left_join(document_bbls, by = "document_id", relationship = "one-to-many") |>
  filter(!is.na(legal_bbl)) |>
  left_join(
    events |>
      select(
        event_id, record_type, event_construction_status, event_count_resolution_status,
        price_resolution_status, event_date_primary, event_quarter
      ),
    by = "event_id",
    relationship = "many-to-one"
  ) |>
  group_by(
    event_id, legal_bbl, record_type, event_construction_status,
    event_count_resolution_status, price_resolution_status, event_date_primary,
    event_quarter
  ) |>
  summarise(
    direct_opportunity_bbl_match = any(direct_opportunity_bbl_match, na.rm = TRUE),
    source_document_ids_for_bbl = collapse_unique(document_id),
    n_source_documents_for_bbl = n_distinct(document_id),
    .groups = "drop"
  ) |>
  mutate(
    legal_borough = str_sub(legal_bbl, 1L, 1L),
    legal_block = suppressWarnings(as.integer(str_sub(legal_bbl, 2L, 6L))),
    legal_lot = suppressWarnings(as.integer(str_sub(legal_bbl, 7L, 10L))),
    incidence_resolution_status = case_when(
      event_construction_status == "manual_required_unreviewed" ~ "unreviewed_cluster_union",
      record_type == "unresolved_review_cluster_placeholder" ~ "manual_unresolved_union",
      TRUE ~ "resolved_event_legal_bbl"
    ),
    bbl_set_rule = case_when(
      event_construction_status == "manual_required_unreviewed" ~ "union_unreviewed_cluster",
      event_construction_status == "manual_completed" ~ "union_manual_event_source_documents",
      TRUE ~ "union_mechanical_event_source_documents"
    )
  ) |>
  select(
    event_id, legal_bbl, legal_borough, legal_block, legal_lot,
    direct_opportunity_bbl_match, record_type, event_construction_status,
    event_count_resolution_status, price_resolution_status,
    incidence_resolution_status, bbl_set_rule, event_date_primary, event_quarter,
    source_document_ids_for_bbl, n_source_documents_for_bbl
  ) |>
  arrange(event_date_primary, event_id, legal_bbl)

if (anyDuplicated(paste(acris_site_event_bbl_incidence$event_id, acris_site_event_bbl_incidence$legal_bbl, sep = "::")) > 0L) {
  stop("Event-BBL incidence is not unique by event_id/legal_bbl.")
}

missing_incidence_events <- setdiff(
  events$event_id[!is.na(events$legal_bbls)],
  acris_site_event_bbl_incidence$event_id
)
if (length(missing_incidence_events) > 0L) {
  stop("Events with legal BBL source data are missing BBL incidence rows.")
}

incidence_counts <- acris_site_event_bbl_incidence |>
  group_by(event_id) |>
  summarise(
    n_all_legal_bbls = n_distinct(legal_bbl),
    n_opportunity_bbls = n_distinct(legal_bbl[direct_opportunity_bbl_match]),
    .groups = "drop"
  )

events <- events |>
  left_join(incidence_counts, by = "event_id", relationship = "one-to-one") |>
  mutate(
    n_all_legal_bbls = coalesce(n_all_legal_bbls, 0L),
    n_opportunity_bbls = coalesce(n_opportunity_bbls, 0L),
    has_opportunity_bbl = n_opportunity_bbls > 0L,
    has_nonopportunity_bbl = n_all_legal_bbls > n_opportunity_bbls
  ) |>
  select(
    event_id, record_type, event_construction_status, event_count_resolution_status,
    price_resolution_status, has_final_price, event_price_final,
    exclude_from_default_price_totals, event_date_primary, event_date_min,
    event_date_max, event_date_span_days, event_quarter, source_document_ids,
    crfns, n_source_documents, n_price_anchor_documents, n_positive_price_documents,
    n_zero_nominal_documents, n_duplicate_documents, raw_positive_document_amt_sum,
    raw_document_amt_sum, review_cluster_id, ambiguity_type, review_priority,
    manual_review_status, reviewer_final_ruling, reviewer_event_count_final,
    reviewer_event_price_final, price_rule, source_confidence, source_urls,
    reviewer_notes, reviewed_by, reviewed_date, buyer_names, seller_names,
    buyer_party_set_keys, seller_party_set_keys, percent_trans_min, percent_trans_max,
    n_all_legal_bbls, n_opportunity_bbls, has_opportunity_bbl, has_nonopportunity_bbl,
    legal_bbls, opportunity_bbls, all_legal_allowed_res_area_sum,
    opp_legal_allowed_res_area_sum, all_legal_lotarea_sum, opp_legal_lotarea_sum,
    event_opp_share_allowed_res_area, event_opp_share_lotarea, unit_churn_flag,
    rights_only_flag, mixed_rights_flag, public_party_flag, hdfc_party_flag,
    housing_public_or_regulated_party_flag, nonprofit_religious_party_flag,
    trust_estate_party_flag, related_party_strong_flag, related_party_weak_flag,
    document_market_statuses, document_exclusion_codes, document_warning_codes
  ) |>
  arrange(event_date_primary, event_id)

if (any(!events$has_final_price & !is.na(events$event_price_final))) {
  stop("Event price flag is inconsistent with event_price_final.")
}

write_parquet_if_changed(events, "../output/acris_site_events.parquet")
write_parquet_if_changed(acris_site_event_documents, "../output/acris_site_event_documents.parquet")
write_parquet_if_changed(acris_site_event_bbl_incidence, "../output/acris_site_event_bbl_incidence.parquet")
cat("Built ACRIS site-event layer to ../output\n")

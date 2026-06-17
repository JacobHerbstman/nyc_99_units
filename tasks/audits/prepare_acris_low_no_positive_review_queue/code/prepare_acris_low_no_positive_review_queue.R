# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/prepare_acris_low_no_positive_review_queue/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source("../../../_lib/source_pipeline_utils.R")

review_clusters <- read_csv("../input/acris_site_event_review_clusters.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(review_cluster_id = str_squish(as.character(review_cluster_id)))

review_documents <- read_csv(
  "../input/acris_site_event_review_documents.csv",
  col_types = cols(document_id = col_character(), crfn = col_character(), .default = col_guess()),
  na = c("", "NA")
) |>
  mutate(
    review_cluster_id = str_squish(as.character(review_cluster_id)),
    document_id = str_squish(as.character(document_id))
  )

review_legals <- read_csv(
  "../input/acris_site_event_review_legals.csv",
  col_types = cols(document_id = col_character(), .default = col_guess()),
  na = c("", "NA")
) |>
  mutate(
    review_cluster_id = str_squish(as.character(review_cluster_id)),
    document_id = str_squish(as.character(document_id))
  )

review_parties <- read_csv(
  "../input/acris_site_event_review_parties.csv",
  col_types = cols(document_id = col_character(), .default = col_guess()),
  na = c("", "NA")
) |>
  mutate(
    review_cluster_id = str_squish(as.character(review_cluster_id)),
    document_id = str_squish(as.character(document_id))
  )

chatgpt_prompts <- read_csv("../input/acris_site_event_review_chatgpt_prompts.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(review_cluster_id = str_squish(as.character(review_cluster_id)))

manual_decisions <- read_csv("../input/acris_site_event_manual_review_decisions.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(review_cluster_id = str_squish(as.character(review_cluster_id)))

if (anyDuplicated(review_clusters$review_cluster_id) > 0L) {
  stop("Review clusters are not unique by review_cluster_id.")
}

if (anyDuplicated(manual_decisions$review_cluster_id) > 0L) {
  stop("Manual decisions are not unique by review_cluster_id.")
}

queue <- review_clusters |>
  filter(
    review_priority == "low_no_positive_price",
    !review_cluster_id %in% manual_decisions$review_cluster_id
  ) |>
  arrange(
    desc(n_low_docs > 0L),
    desc(n_nominal_docs > 0L),
    desc(n_source_docs),
    document_date,
    review_cluster_id
  ) |>
  mutate(
    review_order = row_number(),
    review_block = case_when(
      review_order <= 25L ~ "block_01_highest_ambiguity",
      review_order <= 75L ~ "block_02_next50",
      TRUE ~ "block_03_remaining"
    ),
    review_queue_status = "READY_FOR_MANUAL_REVIEW"
  ) |>
  select(
    review_order, review_block, review_queue_status,
    review_cluster_id, ambiguity_type, document_date, buyer_names,
    seller_names, n_source_docs, n_representative_docs, n_positive_price_docs,
    n_zero_docs, n_nominal_docs, n_low_docs, n_market_candidate_docs,
    document_ids, crfns, document_amounts, percent_trans_values,
    positive_doc_amount_sum, positive_doc_amount_min, positive_doc_amount_max,
    price_lower_bound_pre_review, price_upper_bound_pre_review,
    legal_bbl_sets, opportunity_bbl_sets, site_addresses, property_types,
    units, document_exclusion_codes, document_warning_codes,
    event_count_status_pre_review, event_price_status_pre_review,
    review_allowed_rulings, chatgpt_search_query
  )

queue_ids <- queue$review_cluster_id

review_documents_out <- review_documents |>
  inner_join(queue |> select(review_order, review_block, review_cluster_id), by = "review_cluster_id", relationship = "many-to-one") |>
  arrange(review_order, document_id)

review_legals_out <- review_legals |>
  inner_join(queue |> select(review_order, review_block, review_cluster_id), by = "review_cluster_id", relationship = "many-to-one") |>
  arrange(review_order, document_id, legal_bbl)

review_parties_out <- review_parties |>
  inner_join(queue |> select(review_order, review_block, review_cluster_id), by = "review_cluster_id", relationship = "many-to-one") |>
  arrange(review_order, document_id, party_type, party_name)

chatgpt_prompts_out <- chatgpt_prompts |>
  inner_join(queue |> select(review_order, review_block, review_cluster_id), by = "review_cluster_id", relationship = "many-to-one") |>
  arrange(review_order)

decision_template <- queue |>
  transmute(
    review_cluster_id,
    ambiguity_type,
    reviewer_final_ruling = NA_character_,
    manual_review_status = NA_character_,
    reviewer_event_count_final = NA_integer_,
    reviewer_event_price_final = NA_real_,
    price_rule = NA_character_,
    source_confidence = NA_character_,
    source_urls = NA_character_,
    reviewer_notes = NA_character_,
    reviewed_by = "chatgpt_browser_review",
    reviewed_date = as.Date(Sys.Date())
  )

if (!setequal(queue_ids, chatgpt_prompts_out$review_cluster_id)) {
  stop("Prompt output does not cover exactly the low/no-positive review queue.")
}

write_csv_if_changed(queue, "../output/acris_low_no_positive_review_queue.csv")
write_csv_if_changed(review_documents_out, "../output/acris_low_no_positive_review_documents.csv")
write_csv_if_changed(review_legals_out, "../output/acris_low_no_positive_review_legals.csv")
write_csv_if_changed(review_parties_out, "../output/acris_low_no_positive_review_parties.csv")
write_csv_if_changed(chatgpt_prompts_out, "../output/acris_low_no_positive_review_chatgpt_prompts.csv")
write_csv_if_changed(decision_template, "../output/acris_low_no_positive_review_decision_template.csv")
cat("Prepared ACRIS low/no-positive review queue to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/define_acris_site_event_manual_review_decisions/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source("../../_lib/source_pipeline_utils.R")

allowed_rulings <- c(
  "CONFIRM_SUM_DOCUMENT_AMOUNTS",
  "CONFIRM_USE_REPEATED_AMOUNT_ONCE",
  "CONFIRM_EXTERNAL_TOTAL_PRICE",
  "CONFIRM_KEEP_SEPARATE_DOCUMENT_EVENTS",
  "CONFIRM_NO_SITE_PRICE",
  "UNRESOLVED_AFTER_REVIEW"
)

allowed_statuses <- c(
  "EXTERNAL_CONFIRMED",
  "EXTERNAL_CONFLICTING",
  "NO_EXTERNAL_EVIDENCE",
  "HUMAN_OVERRIDE"
)

allowed_confidence <- c("HIGH", "MEDIUM", "LOW")

decisions <- read_csv("acris_site_event_manual_review_decisions.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    review_cluster_id = str_squish(as.character(review_cluster_id)),
    ambiguity_type = str_squish(as.character(ambiguity_type)),
    reviewer_final_ruling = str_squish(as.character(reviewer_final_ruling)),
    manual_review_status = str_squish(as.character(manual_review_status)),
    reviewer_event_count_final = suppressWarnings(as.integer(reviewer_event_count_final)),
    reviewer_event_price_final = suppressWarnings(as.numeric(reviewer_event_price_final)),
    price_rule = str_squish(as.character(price_rule)),
    source_confidence = str_squish(as.character(source_confidence)),
    source_urls = str_squish(as.character(source_urls)),
    reviewer_notes = str_squish(as.character(reviewer_notes)),
    reviewed_by = str_squish(as.character(reviewed_by)),
    reviewed_date = as.Date(reviewed_date)
  )

if (any(is.na(decisions$review_cluster_id) | decisions$review_cluster_id == "")) {
  stop("Every manual review decision needs review_cluster_id.")
}

if (anyDuplicated(decisions$review_cluster_id) > 0L) {
  stop("Manual review decisions are not unique by review_cluster_id.")
}

if (any(!decisions$reviewer_final_ruling %in% allowed_rulings)) {
  stop("Manual review decision has an unsupported reviewer_final_ruling.")
}

if (any(!decisions$manual_review_status %in% allowed_statuses)) {
  stop("Manual review decision has an unsupported manual_review_status.")
}

if (any(!decisions$source_confidence %in% allowed_confidence)) {
  stop("Manual review decision has an unsupported source_confidence.")
}

resolved_price_decisions <- decisions |>
  filter(reviewer_final_ruling %in% c(
    "CONFIRM_SUM_DOCUMENT_AMOUNTS",
    "CONFIRM_USE_REPEATED_AMOUNT_ONCE",
    "CONFIRM_EXTERNAL_TOTAL_PRICE"
  ))

if (nrow(resolved_price_decisions) > 0L && any(is.na(resolved_price_decisions$reviewer_event_price_final) | resolved_price_decisions$reviewer_event_price_final <= 0)) {
  stop("Resolved price decisions need positive reviewer_event_price_final.")
}

if (nrow(resolved_price_decisions) > 0L && any(is.na(resolved_price_decisions$reviewer_event_count_final) | resolved_price_decisions$reviewer_event_count_final <= 0L)) {
  stop("Resolved price decisions need positive reviewer_event_count_final.")
}

if (nrow(resolved_price_decisions) > 0L && any(is.na(resolved_price_decisions$price_rule) | resolved_price_decisions$price_rule == "")) {
  stop("Resolved price decisions need price_rule.")
}

external_decisions <- decisions |>
  filter(manual_review_status %in% c("EXTERNAL_CONFIRMED", "EXTERNAL_CONFLICTING"))

if (nrow(external_decisions) > 0L && any(is.na(external_decisions$source_urls) | external_decisions$source_urls == "")) {
  stop("External manual review decisions need source_urls.")
}

if (any(is.na(decisions$reviewed_date))) {
  stop("Every manual review decision needs reviewed_date.")
}

write_csv_if_changed(decisions, "../output/acris_site_event_manual_review_decisions.csv")
cat("Wrote ACRIS site-event manual review decisions to ../output\n")

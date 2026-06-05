# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_recovered_sale_events/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

candidate_links <- read_parquet("../input/acris_dof_deed_candidate_links.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(!is.na(document_id), document_id != "")

opportunity_legals <- read_parquet("../input/acris_opportunity_legals.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

primary_opportunity_bbls <- opportunity_lots |>
  filter(primary_opp50_850, valid_bbl) |>
  transmute(
    legal_bbl = bbl,
    primary_opportunity_bbl = bbl
  ) |>
  distinct()

if (anyDuplicated(primary_opportunity_bbls$legal_bbl) > 0) {
  stop("Primary opportunity BBL crosswalk is not unique.")
}

document_legal_bbls <- opportunity_legals |>
  filter(valid_legal_bbl) |>
  distinct(document_id, legal_bbl)

if (anyDuplicated(paste(document_legal_bbls$document_id, document_legal_bbls$legal_bbl, sep = "::")) > 0) {
  stop("Document legal BBL table is not unique by document_id/legal_bbl.")
}

document_primary_bbls <- document_legal_bbls |>
  inner_join(primary_opportunity_bbls, by = "legal_bbl", relationship = "many-to-one")

document_legal_summary <- document_legal_bbls |>
  group_by(document_id) |>
  summarise(
    legal_bbl_count = n_distinct(legal_bbl),
    legal_bbls = paste(sort(unique(legal_bbl)), collapse = ";"),
    .groups = "drop"
  ) |>
  left_join(
    document_primary_bbls |>
      group_by(document_id) |>
      summarise(
        primary_opportunity_bbl_count = n_distinct(primary_opportunity_bbl),
        primary_opportunity_bbls = paste(sort(unique(primary_opportunity_bbl)), collapse = ";"),
        .groups = "drop"
      ),
    by = "document_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    primary_opportunity_bbl_count = coalesce(primary_opportunity_bbl_count, 0L),
    primary_opportunity_bbls = coalesce(primary_opportunity_bbls, "")
  )

candidate_classified <- candidate_links |>
  left_join(
    document_legal_bbls |>
      mutate(legal_contains_sale_bbl = TRUE),
    by = c("document_id", "sale_bbl" = "legal_bbl"),
    relationship = "many-to-one"
  ) |>
  left_join(document_legal_summary, by = "document_id", relationship = "many-to-one") |>
  mutate(
    legal_contains_sale_bbl = coalesce(legal_contains_sale_bbl, FALSE),
    legal_bbl_count = coalesce(legal_bbl_count, 0L),
    legal_bbls = coalesce(legal_bbls, ""),
    primary_opportunity_bbl_count = coalesce(primary_opportunity_bbl_count, 0L),
    primary_opportunity_bbls = coalesce(primary_opportunity_bbls, ""),
    legal_confirmed_candidate = legal_contains_sale_bbl & primary_opportunity_bbl_count > 0L
  ) |>
  group_by(sale_record_id) |>
  mutate(confirmed_docs_per_sale_record = n_distinct(document_id[legal_confirmed_candidate])) |>
  ungroup() |>
  mutate(unambiguous_legal_confirmed_candidate = legal_confirmed_candidate & confirmed_docs_per_sale_record == 1L)

recovered_sale_events <- candidate_classified |>
  filter(unambiguous_legal_confirmed_candidate) |>
  group_by(document_id) |>
  summarise(
    event_id = paste0("acris_deed_", first(document_id)),
    crfn = first(crfn),
    document_date = first(document_date),
    document_amt = first(document_amt),
    recorded_borough = first(recorded_borough),
    doc_type = first(doc_type),
    recorded_datetime = first(recorded_datetime),
    percent_trans = first(percent_trans),
    good_through_date = first(good_through_date),
    event_date = if (n_distinct(sale_date) == 1L) first(sale_date) else as.Date(NA),
    event_price = if (n_distinct(sale_price) == 1L) first(sale_price) else NA_real_,
    unique_sale_dates = n_distinct(sale_date),
    unique_sale_prices = n_distinct(sale_price),
    dof_sale_records_linked = n_distinct(sale_record_id),
    dof_sale_bbls_linked = n_distinct(sale_bbl),
    dof_sale_record_ids = paste(sort(unique(sale_record_id)), collapse = ";"),
    dof_sale_bbls = paste(sort(unique(sale_bbl)), collapse = ";"),
    seed_match_types = paste(sort(unique(seed_match_type)), collapse = "|"),
    exact_primary_seed_rows = sum(seed_match_type == "exact_primary_opportunity_bbl"),
    same_block_seed_rows = sum(seed_match_type == "same_block_unmatched_bbl"),
    legal_bbl_count = first(legal_bbl_count),
    legal_bbls = first(legal_bbls),
    primary_opportunity_bbl_count = first(primary_opportunity_bbl_count),
    primary_opportunity_bbls = first(primary_opportunity_bbls),
    price_source = "dof_annualized_sales_exact_key_legal_confirmed",
    recovery_method = "exact_borough_date_amount_and_acris_legal_bbl",
    .groups = "drop"
  ) |>
  mutate(
    production_recovered_event = unique_sale_dates == 1L & unique_sale_prices == 1L,
    exclusion_reason = if_else(production_recovered_event, NA_character_, "multiple_dof_dates_or_prices")
  ) |>
  filter(production_recovered_event) |>
  arrange(event_date, document_id)

if (nrow(recovered_sale_events) > 0 && anyDuplicated(recovered_sale_events$event_id) > 0) {
  stop("Recovered ACRIS sale event_id is not unique.")
}

if (nrow(recovered_sale_events) > 0 && any(is.na(recovered_sale_events$event_price) | recovered_sale_events$event_price <= 0)) {
  stop("Recovered ACRIS sale events must have positive event_price.")
}

write_parquet_if_changed(recovered_sale_events, "../output/acris_recovered_sale_events.parquet")
cat("Built ACRIS recovered sale events to ../output\n")

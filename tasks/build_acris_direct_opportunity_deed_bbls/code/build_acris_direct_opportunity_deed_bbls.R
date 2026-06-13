# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_direct_opportunity_deed_bbls/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

direct_legals <- read_parquet("../input/acris_direct_opportunity_legals.parquet") |>
  as.data.frame() |>
  as_tibble()

deed_master <- read_parquet("../input/acris_deed_master.parquet") |>
  as.data.frame() |>
  as_tibble()

if (anyDuplicated(deed_master$document_id) > 0) {
  stop("Staged ACRIS DEED master is not unique by document_id.")
}

direct_legal_bbl_summary <- direct_legals |>
  filter(valid_legal_bbl, direct_opportunity_bbl_match) |>
  group_by(document_id, legal_borough, legal_block, legal_lot, legal_bbl) |>
  summarise(
    direct_legal_rows = n(),
    direct_legal_property_types = paste(sort(unique(property_type[!is.na(property_type) & property_type != ""])), collapse = "|"),
    direct_legal_units = n_distinct(unit[!is.na(unit) & unit != "" & unit != "(-)"]),
    has_unit_legal_row = any(!is.na(unit) & unit != "" & unit != "(-)"),
    has_partial_lot_flag = any(!is.na(partial_lot) & partial_lot != "" & partial_lot != "E"),
    has_easement_flag = any(!is.na(easement) & easement != "" & easement != "N"),
    has_air_rights_flag = any(!is.na(air_rights) & air_rights != "" & air_rights != "N"),
    has_subterranean_rights_flag = any(!is.na(subterranean_rights) & subterranean_rights != "" & subterranean_rights != "N"),
    first_legal_good_through_date = if (all(is.na(good_through_date))) as.Date(NA) else min(good_through_date, na.rm = TRUE),
    latest_legal_good_through_date = if (all(is.na(good_through_date))) as.Date(NA) else max(good_through_date, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    direct_legal_property_types = if_else(direct_legal_property_types == "", NA_character_, direct_legal_property_types)
  )

if (anyDuplicated(paste(direct_legal_bbl_summary$document_id, direct_legal_bbl_summary$legal_bbl, sep = "::")) > 0) {
  stop("Direct legal BBL summary is not unique by document_id/legal_bbl.")
}

direct_deed_bbls <- direct_legal_bbl_summary |>
  inner_join(deed_master, by = "document_id", relationship = "many-to-one") |>
  mutate(
    direct_deed_bbl_id = paste(document_id, legal_bbl, sep = "::"),
    deed_positive_document_amt = !is.na(document_amt) & document_amt > 0,
    deed_percent_trans_100 = !is.na(percent_trans) & percent_trans == 100,
    deed_sales_window_2010_2025 = !is.na(document_date) & document_date >= as.Date("2010-01-01") & document_date <= as.Date("2025-12-31")
  ) |>
  select(
    direct_deed_bbl_id,
    document_id, crfn, record_type, recorded_borough, doc_type,
    document_date, document_date_key, document_amt, document_amt_key,
    recorded_datetime, modified_date, percent_trans, good_through_date,
    master_document_versions, master_document_amount_versions,
    master_document_conflicting_amount, selected_master_version_rule,
    legal_borough, legal_block, legal_lot, legal_bbl,
    direct_legal_rows, direct_legal_property_types, direct_legal_units,
    has_unit_legal_row, has_partial_lot_flag, has_easement_flag,
    has_air_rights_flag, has_subterranean_rights_flag,
    first_legal_good_through_date, latest_legal_good_through_date,
    deed_positive_document_amt, deed_percent_trans_100, deed_sales_window_2010_2025
  ) |>
  arrange(document_date, document_id, legal_borough, legal_block, legal_lot)

if (nrow(direct_deed_bbls) == 0) {
  stop("No direct ACRIS opportunity DEED BBL rows were created.")
}

if (anyDuplicated(direct_deed_bbls$direct_deed_bbl_id) > 0) {
  stop("Direct ACRIS opportunity DEED rows are not unique by document_id/legal_bbl.")
}

write_parquet_if_changed(direct_deed_bbls, "../output/acris_direct_opportunity_deed_bbls.parquet")
cat("Built direct ACRIS opportunity DEED BBL rows to ../output\n")

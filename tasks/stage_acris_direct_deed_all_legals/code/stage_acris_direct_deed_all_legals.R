# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_acris_direct_deed_all_legals/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv("../input/acris_direct_deed_all_legal_files.csv", show_col_types = FALSE, na = c("", "NA"))

legal_files <- file_manifest |>
  filter(file_role == "acris_direct_deed_all_legals", row_count > 0L, file.exists(raw_path)) |>
  arrange(query_chunk_id, page_number)

if (nrow(legal_files) == 0L) {
  stop("No direct DEED all-legal files are available to stage.")
}

direct_deed_documents <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(document_id = str_squish(as.character(document_id))) |>
  filter(!is.na(document_id), document_id != "") |>
  distinct() |>
  mutate(direct_deed_document_match = TRUE)

if (anyDuplicated(direct_deed_documents$document_id) > 0L) {
  stop("Direct DEED document list is not unique.")
}

opportunity_bbls <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850, valid_bbl, borough != "5") |>
  transmute(
    direct_opportunity_bbl = bbl,
    direct_opportunity_borough = borough,
    direct_opportunity_block = as.integer(block),
    direct_opportunity_lot = as.integer(lot)
  ) |>
  distinct()

if (anyDuplicated(opportunity_bbls$direct_opportunity_bbl) > 0L) {
  stop("Direct opportunity BBL list is not unique.")
}

legal_rows <- list()

for (i in seq_len(nrow(legal_files))) {
  raw_rows <- read_csv(legal_files$raw_path[i], show_col_types = FALSE, col_types = cols(.default = col_character()))
  names(raw_rows) <- normalize_names(names(raw_rows))

  required_columns <- c(
    "document_id", "record_type", "borough", "block", "lot", "easement",
    "partial_lot", "air_rights", "subterranean_rights", "property_type",
    "street_number", "street_name", "unit", "good_through_date"
  )

  missing_columns <- setdiff(required_columns, names(raw_rows))

  if (length(missing_columns) > 0L) {
    stop("Direct DEED all-legal file is missing columns: ", paste(missing_columns, collapse = ", "))
  }

  legal_rows[[i]] <- raw_rows |>
    mutate(
      source_id = "dof_acris_real_property_legals",
      source_raw_path = legal_files$raw_path[i],
      source_query_chunk_id = legal_files$query_chunk_id[i],
      source_page_number = legal_files$page_number[i],
      source_row_number = row_number(),
      all_legal_record_id = paste(source_query_chunk_id, source_page_number, source_row_number, sep = "_"),
      document_id = str_squish(as.character(document_id)),
      record_type = str_squish(as.character(record_type)),
      legal_borough = standardize_borough_code(borough),
      legal_block = suppressWarnings(as.integer(block)),
      legal_lot = suppressWarnings(as.integer(lot)),
      legal_bbl = build_bbl(legal_borough, legal_block, legal_lot),
      valid_legal_bbl = !is.na(legal_bbl),
      easement = str_squish(as.character(easement)),
      partial_lot = str_squish(as.character(partial_lot)),
      air_rights = str_squish(as.character(air_rights)),
      subterranean_rights = str_squish(as.character(subterranean_rights)),
      property_type = str_to_upper(str_squish(as.character(property_type))),
      street_number = str_squish(as.character(street_number)),
      street_name = str_squish(as.character(street_name)),
      unit = str_squish(as.character(unit)),
      good_through_date = parse_mixed_date(good_through_date)
    ) |>
    select(
      source_id, source_raw_path, source_query_chunk_id, source_page_number,
      source_row_number, all_legal_record_id,
      document_id, record_type, legal_borough, legal_block, legal_lot, legal_bbl,
      valid_legal_bbl, easement, partial_lot, air_rights, subterranean_rights,
      property_type, street_number, street_name, unit, good_through_date
    )
}

all_legals <- bind_rows(legal_rows) |>
  filter(!is.na(document_id), document_id != "") |>
  left_join(direct_deed_documents, by = "document_id", relationship = "many-to-one") |>
  mutate(direct_deed_document_match = coalesce(direct_deed_document_match, FALSE)) |>
  left_join(
    opportunity_bbls,
    by = c("legal_bbl" = "direct_opportunity_bbl"),
    relationship = "many-to-one"
  ) |>
  mutate(direct_opportunity_bbl_match = !is.na(direct_opportunity_borough)) |>
  arrange(document_id, legal_borough, legal_block, legal_lot, unit, all_legal_record_id)

if (nrow(all_legals) == 0L) {
  stop("No staged direct DEED all-legal rows remain after cleaning.")
}

if (anyDuplicated(all_legals$all_legal_record_id) > 0L) {
  stop("Direct DEED all-legal record ID is not unique.")
}

if (any(!all_legals$direct_deed_document_match)) {
  stop("All-legal fetch returned documents outside the direct opportunity DEED document list.")
}

if (sum(all_legals$valid_legal_bbl, na.rm = TRUE) == 0L) {
  stop("No staged direct DEED all-legal rows have valid BBLs.")
}

if (sum(all_legals$direct_opportunity_bbl_match, na.rm = TRUE) == 0L) {
  stop("No staged direct DEED all-legal rows match frozen opportunity BBLs.")
}

all_legals <- all_legals |>
  select(
    source_id, source_raw_path, source_query_chunk_id, source_page_number,
    source_row_number, all_legal_record_id,
    document_id, record_type, legal_borough, legal_block, legal_lot, legal_bbl,
    valid_legal_bbl, direct_deed_document_match, direct_opportunity_bbl_match,
    direct_opportunity_borough, direct_opportunity_block, direct_opportunity_lot,
    easement, partial_lot, air_rights, subterranean_rights,
    property_type, street_number, street_name, unit, good_through_date
  )

write_parquet_if_changed(all_legals, "../output/acris_direct_deed_all_legals.parquet")
cat("Staged direct DEED all-legal records to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_acris_direct_opportunity_legals/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv("../input/acris_direct_opportunity_legal_files.csv", show_col_types = FALSE, na = c("", "NA"))

legal_files <- file_manifest |>
  filter(file_role == "acris_direct_opportunity_legals", row_count > 0, file.exists(raw_path)) |>
  arrange(query_chunk_id, page_number)

if (nrow(legal_files) == 0) {
  stop("No direct ACRIS opportunity legal-record files are available to stage.")
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

if (anyDuplicated(opportunity_bbls$direct_opportunity_bbl) > 0) {
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

  if (length(missing_columns) > 0) {
    stop("Direct ACRIS opportunity legal-record file is missing columns: ", paste(missing_columns, collapse = ", "))
  }

  legal_rows[[i]] <- raw_rows |>
    mutate(
      source_id = "dof_acris_real_property_legals",
      source_raw_path = legal_files$raw_path[i],
      source_query_chunk_id = legal_files$query_chunk_id[i],
      source_page_number = legal_files$page_number[i],
      source_row_number = row_number(),
      direct_legal_record_id = paste(source_query_chunk_id, source_page_number, source_row_number, sep = "_"),
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
      property_type = str_squish(as.character(property_type)),
      street_number = str_squish(as.character(street_number)),
      street_name = str_squish(as.character(street_name)),
      unit = str_squish(as.character(unit)),
      good_through_date = parse_mixed_date(good_through_date)
    ) |>
    select(
      source_id, source_raw_path, source_query_chunk_id, source_page_number,
      source_row_number, direct_legal_record_id,
      document_id, record_type, legal_borough, legal_block, legal_lot, legal_bbl,
      valid_legal_bbl, easement, partial_lot, air_rights, subterranean_rights,
      property_type, street_number, street_name, unit, good_through_date
    )
}

direct_legals <- bind_rows(legal_rows) |>
  filter(!is.na(document_id), document_id != "") |>
  left_join(
    opportunity_bbls,
    by = c("legal_bbl" = "direct_opportunity_bbl"),
    relationship = "many-to-one"
  ) |>
  mutate(direct_opportunity_bbl_match = !is.na(direct_opportunity_borough)) |>
  arrange(document_id, legal_borough, legal_block, legal_lot, unit, direct_legal_record_id)

if (nrow(direct_legals) == 0) {
  stop("No staged direct ACRIS opportunity legal rows remain after cleaning.")
}

if (anyDuplicated(direct_legals$direct_legal_record_id) > 0) {
  stop("Direct ACRIS legal record ID is not unique.")
}

if (any(direct_legals$valid_legal_bbl & !direct_legals$direct_opportunity_bbl_match)) {
  stop("Direct ACRIS legal fetch returned valid BBLs outside the frozen opportunity list.")
}

direct_legals <- direct_legals |>
  filter(direct_opportunity_bbl_match) |>
  select(
    source_id, source_raw_path, source_query_chunk_id, source_page_number,
    source_row_number, direct_legal_record_id,
    document_id, record_type, legal_borough, legal_block, legal_lot, legal_bbl,
    valid_legal_bbl, direct_opportunity_bbl_match,
    easement, partial_lot, air_rights, subterranean_rights,
    property_type, street_number, street_name, unit, good_through_date
  )

if (sum(direct_legals$valid_legal_bbl) == 0) {
  stop("No staged direct ACRIS opportunity legal rows have valid BBLs.")
}

write_parquet_if_changed(direct_legals, "../output/acris_direct_opportunity_legals.parquet")
cat("Staged direct ACRIS opportunity legal records to ../output\n")

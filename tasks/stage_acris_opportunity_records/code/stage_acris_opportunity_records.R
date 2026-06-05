# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_acris_opportunity_records/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv("../input/acris_opportunity_record_files.csv", show_col_types = FALSE, na = c("", "NA"))

legal_files <- file_manifest |>
  filter(file_role == "acris_candidate_document_legals", row_count > 0, file.exists(raw_path)) |>
  arrange(chunk_id)

if (nrow(legal_files) == 0) {
  stop("No ACRIS opportunity legal-record files are available to stage.")
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
    stop("ACRIS opportunity legal-record file is missing columns: ", paste(missing_columns, collapse = ", "))
  }

  legal_rows[[i]] <- raw_rows |>
    mutate(
      source_id = "dof_acris_real_property_legals",
      source_raw_path = legal_files$raw_path[i],
      source_chunk_id = legal_files$chunk_id[i],
      source_row_number = row_number(),
      legal_record_id = paste(source_chunk_id, source_row_number, sep = "_"),
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
      source_id, source_raw_path, source_chunk_id, source_row_number, legal_record_id,
      document_id, record_type, legal_borough, legal_block, legal_lot, legal_bbl,
      valid_legal_bbl, easement, partial_lot, air_rights, subterranean_rights,
      property_type, street_number, street_name, unit, good_through_date
    )
}

opportunity_legals <- bind_rows(legal_rows) |>
  filter(!is.na(document_id), document_id != "") |>
  arrange(document_id, legal_borough, legal_block, legal_lot, unit, legal_record_id)

if (nrow(opportunity_legals) == 0) {
  stop("No staged ACRIS opportunity legal rows remain after cleaning.")
}

if (anyDuplicated(opportunity_legals$legal_record_id) > 0) {
  stop("ACRIS opportunity legal_record_id is not unique.")
}

if (sum(opportunity_legals$valid_legal_bbl) == 0) {
  stop("No staged ACRIS opportunity legal rows have valid BBLs.")
}

write_parquet_if_changed(opportunity_legals, "../output/acris_opportunity_legals.parquet")
cat("Staged ACRIS opportunity legal records to ../output\n")

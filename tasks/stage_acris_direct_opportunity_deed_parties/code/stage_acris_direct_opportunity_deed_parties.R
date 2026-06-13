# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_acris_direct_opportunity_deed_parties/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv("../input/acris_direct_opportunity_deed_party_files.csv", show_col_types = FALSE, na = c("", "NA"))

party_files <- file_manifest |>
  filter(file_role == "acris_direct_opportunity_deed_parties", row_count > 0, file.exists(raw_path)) |>
  arrange(query_chunk_id, page_number)

if (nrow(party_files) == 0) {
  stop("No direct ACRIS opportunity DEED party files are available to stage.")
}

direct_deed_documents <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(document_id = str_squish(as.character(document_id))) |>
  filter(!is.na(document_id), document_id != "") |>
  distinct() |>
  mutate(direct_deed_document_match = TRUE)

if (anyDuplicated(direct_deed_documents$document_id) > 0) {
  stop("Direct opportunity DEED document list is not unique.")
}

party_rows <- list()

for (i in seq_len(nrow(party_files))) {
  raw_rows <- read_csv(party_files$raw_path[i], show_col_types = FALSE, col_types = cols(.default = col_character()))
  names(raw_rows) <- normalize_names(names(raw_rows))

  required_columns <- c("document_id", "party_type", "name")
  missing_columns <- setdiff(required_columns, names(raw_rows))

  if (length(missing_columns) > 0) {
    stop("Direct ACRIS opportunity DEED party file is missing columns: ", paste(missing_columns, collapse = ", "))
  }

  party_rows[[i]] <- raw_rows |>
    mutate(
      source_id = "dof_acris_real_property_parties",
      source_raw_path = party_files$raw_path[i],
      source_query_chunk_id = party_files$query_chunk_id[i],
      source_page_number = party_files$page_number[i],
      source_row_number = row_number(),
      direct_party_record_id = paste(source_query_chunk_id, source_page_number, source_row_number, sep = "_"),
      document_id = str_squish(as.character(document_id)),
      record_type = str_squish(pick_first_existing(raw_rows, "record_type")),
      party_type = str_to_upper(str_squish(as.character(party_type))),
      party_name = str_squish(as.character(name)),
      address_1 = str_squish(pick_first_existing(raw_rows, c("address_1", "address1", "addr1"))),
      address_2 = str_squish(pick_first_existing(raw_rows, c("address_2", "address2", "addr2"))),
      country = str_squish(pick_first_existing(raw_rows, "country")),
      city = str_squish(pick_first_existing(raw_rows, "city")),
      state = str_to_upper(str_squish(pick_first_existing(raw_rows, "state"))),
      zip = str_squish(pick_first_existing(raw_rows, c("zip", "zip_code", "zipcode"))),
      good_through_date = parse_mixed_date(pick_first_existing(raw_rows, "good_through_date"))
    ) |>
    select(
      source_id, source_raw_path, source_query_chunk_id, source_page_number,
      source_row_number, direct_party_record_id,
      document_id, record_type, party_type, party_name,
      address_1, address_2, country, city, state, zip, good_through_date
    )
}

direct_parties <- bind_rows(party_rows) |>
  filter(!is.na(document_id), document_id != "") |>
  left_join(
    direct_deed_documents,
    by = "document_id",
    relationship = "many-to-one"
  ) |>
  mutate(direct_deed_document_match = coalesce(direct_deed_document_match, FALSE)) |>
  arrange(document_id, party_type, party_name, direct_party_record_id)

if (nrow(direct_parties) == 0) {
  stop("No staged direct ACRIS opportunity DEED party rows remain after cleaning.")
}

if (anyDuplicated(direct_parties$direct_party_record_id) > 0) {
  stop("Direct ACRIS party record ID is not unique.")
}

if (any(!direct_parties$direct_deed_document_match)) {
  stop("Direct ACRIS party fetch returned documents outside the direct opportunity DEED document list.")
}

direct_parties <- direct_parties |>
  select(
    source_id, source_raw_path, source_query_chunk_id, source_page_number,
    source_row_number, direct_party_record_id,
    document_id, record_type, party_type, party_name,
    address_1, address_2, country, city, state, zip, good_through_date,
    direct_deed_document_match
  )

write_parquet_if_changed(direct_parties, "../output/acris_direct_opportunity_deed_parties.parquet")
cat("Staged direct ACRIS opportunity DEED parties to ../output\n")

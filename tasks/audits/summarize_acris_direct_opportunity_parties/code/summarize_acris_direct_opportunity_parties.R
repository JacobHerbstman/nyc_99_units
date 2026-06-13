# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_acris_direct_opportunity_parties/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

direct_deed_bbls <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble()

direct_parties <- read_parquet("../input/acris_direct_opportunity_deed_parties.parquet") |>
  as.data.frame() |>
  as_tibble()

if (anyDuplicated(direct_parties$direct_party_record_id) > 0) {
  stop("Direct party rows are not unique by direct_party_record_id.")
}

party_doc_counts <- direct_parties |>
  group_by(document_id) |>
  summarise(
    party_rows = n(),
    party_types = n_distinct(party_type),
    party_names = n_distinct(party_name[!is.na(party_name) & party_name != ""]),
    has_party1 = any(str_detect(party_type, "1|GRANTOR|SELLER|TRANSFEROR")),
    has_party2 = any(str_detect(party_type, "2|GRANTEE|BUYER|TRANSFEREE")),
    .groups = "drop"
  )

deed_document_boroughs <- direct_deed_bbls |>
  distinct(document_id, legal_borough)

coverage_by_borough <- deed_document_boroughs |>
  left_join(party_doc_counts, by = "document_id", relationship = "many-to-one") |>
  group_by(legal_borough) |>
  summarise(
    direct_deed_documents = n_distinct(document_id),
    direct_deed_documents_with_parties = n_distinct(document_id[!is.na(party_rows)]),
    direct_deed_documents_with_party1 = n_distinct(document_id[has_party1 %in% TRUE]),
    direct_deed_documents_with_party2 = n_distinct(document_id[has_party2 %in% TRUE]),
    party_rows = sum(party_rows, na.rm = TRUE),
    party_names = sum(party_names, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    party_document_coverage = round(direct_deed_documents_with_parties / direct_deed_documents, 4),
    party1_document_share = round(direct_deed_documents_with_party1 / direct_deed_documents, 4),
    party2_document_share = round(direct_deed_documents_with_party2 / direct_deed_documents, 4)
  ) |>
  arrange(legal_borough)

party_type_counts <- direct_parties |>
  mutate(party_type = if_else(is.na(party_type) | party_type == "", "missing_party_type", party_type)) |>
  count(party_type, name = "party_rows") |>
  arrange(desc(party_rows), party_type)

top_party_names <- direct_parties |>
  mutate(
    party_type = if_else(is.na(party_type) | party_type == "", "missing_party_type", party_type),
    party_name = str_squish(party_name),
    party_name = if_else(is.na(party_name) | party_name == "", "missing_party_name", party_name)
  ) |>
  count(party_name, party_type, name = "party_rows") |>
  arrange(desc(party_rows), party_name, party_type) |>
  slice_head(n = 200)

write_csv_if_changed(coverage_by_borough, "../output/acris_direct_opportunity_party_coverage_by_borough.csv")
write_csv_if_changed(party_type_counts, "../output/acris_direct_opportunity_party_type_counts.csv")
write_csv_if_changed(top_party_names, "../output/acris_direct_opportunity_top_party_names.csv")
cat("Wrote direct ACRIS opportunity party audit outputs to ../output\n")

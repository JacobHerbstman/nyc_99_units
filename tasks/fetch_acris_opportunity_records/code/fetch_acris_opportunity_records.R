# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_acris_opportunity_records/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

chunk_size <- 250L
page_limit <- 50000L

candidate_documents <- read_parquet("../input/acris_dof_deed_candidate_links.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(!is.na(document_id), document_id != "") |>
  distinct(document_id) |>
  arrange(document_id) |>
  mutate(chunk_id = ceiling(row_number() / chunk_size))

if (nrow(candidate_documents) == 0) {
  stop("No candidate ACRIS document IDs are available for legal-record fetch.")
}

pull_date <- resolve_raw_pull_date(list(
  dof_acris_real_property_legals = character()
))

dir.create(file.path("../../../data_raw/dof_acris_real_property_legals", pull_date), recursive = TRUE, showWarnings = FALSE)

legals_endpoint <- "https://data.cityofnewyork.us/resource/8h5j-fqxa.csv"
legals_select <- paste(
  c(
    "document_id", "record_type", "borough", "block", "lot", "easement",
    "partial_lot", "air_rights", "subterranean_rights", "property_type",
    "street_number", "street_name", "unit", "good_through_date"
  ),
  collapse = ","
)

fetch_rows <- list()

for (chunk_value in sort(unique(candidate_documents$chunk_id))) {
  chunk_documents <- candidate_documents |>
    filter(chunk_id == chunk_value)

  raw_path <- file.path(
    "../../../data_raw/dof_acris_real_property_legals",
    pull_date,
    sprintf("opportunity_candidate_legals_part_%06d.csv", chunk_value)
  )

  document_list <- paste0("'", paste(chunk_documents$document_id, collapse = "','"), "'")
  legals_where <- paste0("document_id in (", document_list, ")")

  query_url <- paste0(
    legals_endpoint,
    "?$select=", URLencode(legals_select, reserved = TRUE),
    "&$where=", URLencode(legals_where, reserved = TRUE),
    "&$order=", URLencode("document_id,borough,block,lot,unit", reserved = TRUE),
    "&$limit=", page_limit
  )

  status <- if (file.exists(raw_path)) {
    "already_present"
  } else {
    download_with_status(query_url, raw_path)
  }

  row_count <- if (file.exists(raw_path)) {
    nrow(read_csv(raw_path, show_col_types = FALSE, col_types = cols(.default = col_character())))
  } else {
    0L
  }

  if (status == "download_failed") {
    stop("ACRIS legal-record chunk failed to download: ", chunk_value)
  }

  if (row_count >= page_limit) {
    stop("ACRIS legal-record chunk hit page limit and may be truncated: ", chunk_value)
  }

  fetch_rows[[length(fetch_rows) + 1L]] <- tibble(
    source_id = "dof_acris_real_property_legals",
    file_role = "acris_candidate_document_legals",
    pull_date = pull_date,
    chunk_id = chunk_value,
    candidate_documents = nrow(chunk_documents),
    row_count = row_count,
    raw_path = raw_path,
    status = status,
    query_url = query_url
  )
}

file_manifest <- bind_rows(fetch_rows)

if (sum(file_manifest$row_count, na.rm = TRUE) == 0) {
  stop("No ACRIS legal rows were fetched for candidate documents.")
}

write_csv_if_changed(file_manifest, "../output/acris_opportunity_record_files.csv")
cat("Wrote ACRIS opportunity legal-record fetch manifest to ../output\n")

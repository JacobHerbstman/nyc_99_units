# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_acris_direct_deed_all_legals/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

page_limit <- 50000L
max_query_url_chars <- 7000L

source_catalog <- read_csv("../input/source_catalog.csv", show_col_types = FALSE, na = c("", "NA"))

legals_source <- source_catalog |>
  filter(source_id == "dof_acris_real_property_legals")

if (nrow(legals_source) != 1L) {
  stop("Source catalog must contain exactly one dof_acris_real_property_legals row.")
}

direct_deed_documents <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(document_id = str_squish(as.character(document_id))) |>
  filter(!is.na(document_id), document_id != "") |>
  distinct() |>
  arrange(document_id)

if (nrow(direct_deed_documents) == 0L) {
  stop("No direct opportunity DEED documents are available for all-legal fetch.")
}

legals_endpoint <- "https://data.cityofnewyork.us/resource/8h5j-fqxa.csv"
legals_select <- paste(
  c(
    "document_id", "record_type", "borough", "block", "lot", "easement",
    "partial_lot", "air_rights", "subterranean_rights", "property_type",
    "street_number", "street_name", "unit", "good_through_date"
  ),
  collapse = ","
)

make_query_url <- function(where_clause, offset_value) {
  paste0(
    legals_endpoint,
    "?$select=", URLencode(legals_select, reserved = TRUE),
    "&$where=", URLencode(where_clause, reserved = TRUE),
    "&$order=", URLencode("document_id,borough,block,lot,unit", reserved = TRUE),
    "&$limit=", page_limit,
    "&$offset=", offset_value
  )
}

query_chunks <- list()
chunk_id <- 1L
current_documents <- character()

for (i in seq_len(nrow(direct_deed_documents))) {
  proposed_documents <- c(current_documents, direct_deed_documents$document_id[i])
  proposed_where <- paste0(
    "document_id in ('",
    paste(str_replace_all(proposed_documents, "'", "''"), collapse = "','"),
    "')"
  )
  proposed_url <- make_query_url(proposed_where, 0L)

  if (length(current_documents) > 0L && nchar(proposed_url, type = "bytes") > max_query_url_chars) {
    query_chunks[[length(query_chunks) + 1L]] <- tibble(
      query_chunk_id = chunk_id,
      document_count = length(current_documents),
      where_clause = paste0(
        "document_id in ('",
        paste(str_replace_all(current_documents, "'", "''"), collapse = "','"),
        "')"
      )
    )
    chunk_id <- chunk_id + 1L
    current_documents <- direct_deed_documents$document_id[i]
  } else {
    current_documents <- proposed_documents
  }
}

if (length(current_documents) > 0L) {
  query_chunks[[length(query_chunks) + 1L]] <- tibble(
    query_chunk_id = chunk_id,
    document_count = length(current_documents),
    where_clause = paste0(
      "document_id in ('",
      paste(str_replace_all(current_documents, "'", "''"), collapse = "','"),
      "')"
    )
  )
}

query_chunks <- bind_rows(query_chunks)

if (nrow(query_chunks) == 0L) {
  stop("No ACRIS all-legal query chunks were created.")
}

if (any(nchar(make_query_url(query_chunks$where_clause, 0L), type = "bytes") > max_query_url_chars)) {
  stop("At least one ACRIS all-legal query exceeds the configured URL length.")
}

pull_date <- resolve_raw_pull_date(list(
  dof_acris_real_property_legals = character()
))

dir.create(file.path("../../../data_raw/dof_acris_real_property_legals", pull_date), recursive = TRUE, showWarnings = FALSE)

fetch_rows <- list()

for (i in seq_len(nrow(query_chunks))) {
  offset_value <- 0L
  page_number <- 1L
  keep_fetching <- TRUE

  while (keep_fetching) {
    raw_path <- file.path(
      "../../../data_raw/dof_acris_real_property_legals",
      pull_date,
      sprintf("direct_deed_all_legals_chunk_%05d_page_%04d.csv", query_chunks$query_chunk_id[i], page_number)
    )

    query_url <- make_query_url(query_chunks$where_clause[i], offset_value)

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
      stop("Direct DEED all-legal chunk failed to download: ", query_chunks$query_chunk_id[i], ", page ", page_number)
    }

    fetch_rows[[length(fetch_rows) + 1L]] <- tibble(
      source_id = "dof_acris_real_property_legals",
      file_role = "acris_direct_deed_all_legals",
      pull_date = pull_date,
      query_chunk_id = query_chunks$query_chunk_id[i],
      document_count = query_chunks$document_count[i],
      page_number = page_number,
      row_count = row_count,
      socrata_limit = page_limit,
      socrata_offset = offset_value,
      raw_path = raw_path,
      status = status,
      query_url = query_url
    )

    keep_fetching <- row_count == page_limit
    offset_value <- offset_value + page_limit
    page_number <- page_number + 1L
  }
}

file_manifest <- bind_rows(fetch_rows) |>
  arrange(query_chunk_id, page_number)

if (sum(file_manifest$row_count, na.rm = TRUE) == 0L) {
  stop("No all-legal ACRIS rows were fetched for direct opportunity DEED documents.")
}

write_csv_if_changed(file_manifest, "../output/acris_direct_deed_all_legal_files.csv")
cat("Wrote direct DEED all-legal fetch manifest to ../output\n")

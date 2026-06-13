# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_acris_direct_opportunity_legals/code")

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
excluded_boroughs <- "5"

source_catalog <- read_csv("../input/source_catalog.csv", show_col_types = FALSE, na = c("", "NA"))

legals_source <- source_catalog |>
  filter(source_id == "dof_acris_real_property_legals")

if (nrow(legals_source) != 1) {
  stop("Source catalog must contain exactly one dof_acris_real_property_legals row.")
}

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850, valid_bbl, !borough %in% excluded_boroughs) |>
  transmute(
    bbl,
    borough,
    block = as.integer(block),
    lot = as.integer(lot)
  ) |>
  distinct() |>
  arrange(borough, block, lot)

if (nrow(opportunity_lots) == 0) {
  stop("No non-Staten Island frozen primary opportunity lots are available.")
}

if (anyDuplicated(opportunity_lots$bbl) > 0) {
  stop("Frozen primary opportunity lots are not unique by BBL.")
}

if (any(is.na(opportunity_lots$borough) | is.na(opportunity_lots$block) | is.na(opportunity_lots$lot))) {
  stop("Direct ACRIS legal fetch requires non-missing borough, block, and lot.")
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

block_lot_groups <- opportunity_lots |>
  group_by(borough, block) |>
  summarise(
    lot_values = paste(sort(unique(lot)), collapse = "','"),
    bbl_count = n_distinct(bbl),
    .groups = "drop"
  ) |>
  mutate(
    where_clause = paste0(
      "(borough='", borough, "' AND block='", block,
      "' AND lot in ('", lot_values, "'))"
    )
  ) |>
  arrange(borough, block)

query_chunks <- list()
chunk_id <- 1L

for (borough_value in sort(unique(block_lot_groups$borough))) {
  borough_groups <- block_lot_groups |>
    filter(borough == borough_value)

  current_clauses <- character()
  current_blocks <- integer()
  current_bbl_count <- 0L

  for (i in seq_len(nrow(borough_groups))) {
    proposed_clauses <- c(current_clauses, borough_groups$where_clause[i])
    proposed_where <- paste0("(", paste(proposed_clauses, collapse = " OR "), ")")
    proposed_url <- make_query_url(proposed_where, 0L)

    if (length(current_clauses) > 0 && nchar(proposed_url, type = "bytes") > max_query_url_chars) {
      query_chunks[[length(query_chunks) + 1L]] <- tibble(
        query_chunk_id = chunk_id,
        borough = borough_value,
        block_count = length(current_blocks),
        bbl_count = current_bbl_count,
        where_clause = paste0("(", paste(current_clauses, collapse = " OR "), ")")
      )
      chunk_id <- chunk_id + 1L
      current_clauses <- borough_groups$where_clause[i]
      current_blocks <- borough_groups$block[i]
      current_bbl_count <- borough_groups$bbl_count[i]
    } else {
      current_clauses <- proposed_clauses
      current_blocks <- c(current_blocks, borough_groups$block[i])
      current_bbl_count <- current_bbl_count + borough_groups$bbl_count[i]
    }
  }

  if (length(current_clauses) > 0) {
    query_chunks[[length(query_chunks) + 1L]] <- tibble(
      query_chunk_id = chunk_id,
      borough = borough_value,
      block_count = length(current_blocks),
      bbl_count = current_bbl_count,
      where_clause = paste0("(", paste(current_clauses, collapse = " OR "), ")")
    )
    chunk_id <- chunk_id + 1L
  }
}

query_chunks <- bind_rows(query_chunks)

if (nrow(query_chunks) == 0) {
  stop("No ACRIS legal query chunks were created.")
}

if (any(nchar(make_query_url(query_chunks$where_clause, 0L), type = "bytes") > max_query_url_chars)) {
  stop("At least one direct ACRIS legal query exceeds the configured URL length.")
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
      sprintf("direct_opportunity_legals_chunk_%05d_page_%04d.csv", query_chunks$query_chunk_id[i], page_number)
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
      stop("Direct ACRIS legal-record chunk failed to download: ", query_chunks$query_chunk_id[i], ", page ", page_number)
    }

    fetch_rows[[length(fetch_rows) + 1L]] <- tibble(
      source_id = "dof_acris_real_property_legals",
      file_role = "acris_direct_opportunity_legals",
      pull_date = pull_date,
      query_chunk_id = query_chunks$query_chunk_id[i],
      borough = query_chunks$borough[i],
      block_count = query_chunks$block_count[i],
      bbl_count = query_chunks$bbl_count[i],
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

if (sum(file_manifest$row_count, na.rm = TRUE) == 0) {
  stop("No direct ACRIS legal rows were fetched for opportunity BBLs.")
}

write_csv_if_changed(file_manifest, "../output/acris_direct_opportunity_legal_files.csv")
cat("Wrote direct ACRIS opportunity legal fetch manifest to ../output\n")

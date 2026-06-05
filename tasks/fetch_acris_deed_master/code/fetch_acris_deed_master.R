# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_acris_deed_master/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

start_date <- as.Date("2010-01-01")
end_date <- as.Date("2025-12-31")
page_limit <- 50000L

source_catalog <- read_csv("../input/source_catalog.csv", show_col_types = FALSE, na = c("", "NA"))

acris_master_source <- source_catalog |>
  filter(source_id == "dof_acris_real_property_master")

acris_doc_code_source <- source_catalog |>
  filter(source_id == "acris_document_control_codes")

if (nrow(acris_master_source) != 1) {
  stop("Source catalog must contain exactly one dof_acris_real_property_master row.")
}

if (nrow(acris_doc_code_source) != 1) {
  stop("Source catalog must contain exactly one acris_document_control_codes row.")
}

pull_date <- resolve_raw_pull_date(list(
  dof_acris_real_property_master = character(),
  acris_document_control_codes = "acris_document_control_codes.csv"
))

dir.create(file.path("../../../data_raw/dof_acris_real_property_master", pull_date), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("../../../data_raw/acris_document_control_codes", pull_date), recursive = TRUE, showWarnings = FALSE)

master_endpoint <- "https://data.cityofnewyork.us/resource/bnx9-e6tj.csv"
master_select <- paste(
  c(
    "document_id", "record_type", "crfn", "recorded_borough", "doc_type",
    "document_date", "document_amt", "recorded_datetime", "modified_date",
    "percent_trans", "good_through_date"
  ),
  collapse = ","
)
master_where <- paste0(
  "document_date between '", format(start_date, "%Y-%m-%d"), "T00:00:00' and '",
  format(end_date, "%Y-%m-%d"), "T23:59:59' and doc_type = 'DEED'"
)

master_rows <- list()
offset_value <- 0L
page_number <- 1L
keep_fetching <- TRUE

while (keep_fetching) {
  raw_path <- file.path(
    "../../../data_raw/dof_acris_real_property_master",
    pull_date,
    sprintf("deed_master_2010_2025_part_%06d.csv", page_number)
  )

  query_url <- paste0(
    master_endpoint,
    "?$select=", URLencode(master_select, reserved = TRUE),
    "&$where=", URLencode(master_where, reserved = TRUE),
    "&$order=", URLencode("document_id", reserved = TRUE),
    "&$limit=", page_limit,
    "&$offset=", offset_value
  )

  status <- if (file.exists(raw_path)) {
    "already_present"
  } else {
    download_with_status(query_url, raw_path)
  }

  page_row_count <- if (file.exists(raw_path)) {
    nrow(read_csv(raw_path, show_col_types = FALSE, col_types = cols(.default = col_character())))
  } else {
    0L
  }

  master_rows[[page_number]] <- tibble(
    source_id = "dof_acris_real_property_master",
    file_role = "acris_master_deed_partition",
    pull_date = pull_date,
    part_number = page_number,
    row_count = page_row_count,
    socrata_limit = page_limit,
    socrata_offset = offset_value,
    raw_path = raw_path,
    status = status,
    query_url = query_url
  )

  if (status == "download_failed") {
    stop("ACRIS DEED master partition failed to download at offset ", offset_value, ".")
  }

  keep_fetching <- page_row_count == page_limit
  offset_value <- offset_value + page_limit
  page_number <- page_number + 1L
}

doc_code_path <- file.path(
  "../../../data_raw/acris_document_control_codes",
  pull_date,
  "acris_document_control_codes.csv"
)

doc_code_status <- if (file.exists(doc_code_path)) {
  "already_present"
} else {
  download_with_status(acris_doc_code_source$official_url[1], doc_code_path)
}

doc_code_row_count <- if (file.exists(doc_code_path)) {
  nrow(read_csv(doc_code_path, show_col_types = FALSE, col_types = cols(.default = col_character())))
} else {
  0L
}

if (doc_code_status == "download_failed") {
  stop("ACRIS document control-code table failed to download.")
}

file_manifest <- bind_rows(master_rows) |>
  bind_rows(tibble(
    source_id = "acris_document_control_codes",
    file_role = "acris_document_control_codes",
    pull_date = pull_date,
    part_number = NA_integer_,
    row_count = doc_code_row_count,
    socrata_limit = NA_integer_,
    socrata_offset = NA_integer_,
    raw_path = doc_code_path,
    status = doc_code_status,
    query_url = acris_doc_code_source$official_url[1]
  ))

if (sum(file_manifest$file_role == "acris_master_deed_partition" & file_manifest$row_count > 0) == 0) {
  stop("No ACRIS DEED master rows were fetched.")
}

write_csv_if_changed(file_manifest, "../output/acris_deed_master_files.csv")
cat("Wrote ACRIS DEED master fetch manifest to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dcp_housing_database/code")
# vintage <- "25Q4"

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  vintage <- args[1]
}

if (!vintage %in% c("23Q4", "25Q4")) {
  stop("Expected Housing Database vintage 23Q4 or 25Q4.")
}

row <- read_csv("../input/dcp_housing_database_files.csv", show_col_types = FALSE) |>
  filter(file_role == "project_level_csv_zip", .data$vintage == .env$vintage)
stopifnot(nrow(row) == 1L)

if (vintage == "23Q4") {
  zip_path <- "../input/nychousingdb_23q4_csv.zip"
  csv_inside_zip <- "HousingDB_post2010_inactive_included.csv"
  active_csv_inside_zip <- "HousingDB_post2010.csv"
  zip_listing <- unzip(zip_path, list = TRUE)$Name
  stopifnot(all(c(csv_inside_zip, active_csv_inside_zip,
    "Housing_Database_Data_Dictionary.xlsx") %in% zip_listing))

  raw_df <- read_csv(
    unz(zip_path, csv_inside_zip),
    col_types = cols(.default = col_character())
  )
  active_df <- read_csv(
    unz(zip_path, active_csv_inside_zip),
    col_types = cols(.default = col_character())
  )
  names(raw_df) <- normalize_names(names(raw_df))
  names(active_df) <- normalize_names(names(active_df))
  stopifnot(
    !anyNA(raw_df$job_number),
    !anyDuplicated(raw_df$job_number),
    !anyNA(active_df$job_number),
    !anyDuplicated(active_df$job_number),
    all(raw_df$version == "23Q4"),
    all(active_df$version == "23Q4"),
    all(active_df$job_number %in% raw_df$job_number),
    identical(
      active_df$classaprop,
      raw_df$classaprop[match(active_df$job_number, raw_df$job_number)]
    )
  )
  raw_df$historical_active <- raw_df$job_number %in% active_df$job_number
  raw_output <- "../output/dcp_housing_database_project_level_raw_23q4.parquet"
  raw_manifest_output <- "../output/dcp_housing_database_raw_files_23q4.csv"
  staged_output <- "../output/dcp_housing_database_project_level_23q4.parquet"
  staged_manifest_output <- "../output/dcp_housing_database_files_23q4.csv"
} else {
  zip_path <- "../input/nychdb_25q4_csv.zip"
  zip_listing <- unzip(zip_path, list = TRUE)
  csv_candidates <- zip_listing$Name[grepl("\\.csv$", zip_listing$Name, ignore.case = TRUE)]
  project_csv_candidates <- csv_candidates[
    str_detect(tolower(basename(csv_candidates)), "^(housingdb|nychdb).*[.]csv$")
  ]
  stopifnot(length(project_csv_candidates) == 1L)
  csv_inside_zip <- project_csv_candidates[[1]]
  extracted_csv <- unzip(zip_path, files = csv_inside_zip, exdir = tempdir(), overwrite = TRUE)
  raw_df <- read_csv(extracted_csv, show_col_types = FALSE, guess_max = 50000)
  names(raw_df) <- normalize_names(names(raw_df))
  raw_output <- "../output/dcp_housing_database_project_level_raw_25q4.parquet"
  raw_manifest_output <- "../output/dcp_housing_database_raw_files.csv"
  staged_output <- "../output/dcp_housing_database_project_level_25q4.parquet"
  staged_manifest_output <- "../output/dcp_housing_database_files.csv"
}

raw_df <- raw_df |>
  mutate(
    source_id = row$source_id,
    vintage = row$vintage,
    source_raw_path = row$raw_path
  ) |>
  select(source_id, vintage, source_raw_path, everything())

SaveData(raw_df, if (vintage == "23Q4") "job_number" else NULL, raw_output)
SaveData(
  tibble(
    source_id = row$source_id, vintage = row$vintage, raw_path = row$raw_path,
    csv_inside_zip = csv_inside_zip,
    raw_parquet_path = raw_output,
    status = "loaded"
  ),
  c("source_id", "vintage"),
  raw_manifest_output
)

staged_df <- tibble(
  source_id = row$source_id,
  release = row$vintage,
  job_number = suppressWarnings(as.character(raw_df$job_number)),
  job_type = as.character(raw_df$job_type),
  job_status = as.character(raw_df$job_status),
  permit_year = suppressWarnings(as.integer(raw_df$permityear)),
  completion_year = suppressWarnings(as.integer(raw_df$compltyear)),
  classa_init = suppressWarnings(as.numeric(raw_df$classainit)),
  classa_prop = suppressWarnings(as.numeric(raw_df$classaprop)),
  classa_net = suppressWarnings(as.numeric(raw_df$classanet)),
  units_co = suppressWarnings(as.numeric(raw_df$units_co)),
  borough_code = standardize_borough_code(raw_df$boro),
  borough_name = standardize_borough_name(raw_df$boro),
  bin = as.character(raw_df$bin),
  bbl = as.character(raw_df$bbl),
  house_number = as.character(raw_df$addressnum),
  street_name = as.character(raw_df$addressst),
  address = combine_address(raw_df$addressnum, raw_df$addressst),
  ownership = as.character(raw_df$ownership),
  community_district = standardize_community_district(raw_df$boro, raw_df$commntydst),
  council_district = standardize_council_district(raw_df$councildst),
  date_filed = parse_mixed_date(raw_df$datefiled),
  date_permit = parse_mixed_date(raw_df$datepermit),
  date_updated = parse_mixed_date(raw_df$datelstupd),
  date_completed = parse_mixed_date(raw_df$datecomplt),
  geom_source = as.character(raw_df$geomsource),
  dcp_edited = as.character(raw_df$dcpedited),
  version = as.character(raw_df$version),
  source_raw_path = row$raw_path
)

if (vintage == "23Q4") {
  staged_df$historical_active <- raw_df$historical_active
}

SaveData(staged_df, if (vintage == "23Q4") "job_number" else NULL, staged_output)
SaveData(
  tibble(
    source_id = row$source_id, vintage = row$vintage, raw_path = row$raw_path,
    raw_parquet_path = raw_output,
    parquet_path = staged_output,
    status = "staged"
  ),
  c("source_id", "vintage"),
  staged_manifest_output
)

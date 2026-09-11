# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dcp_housing_database/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

row <- read_csv("../input/dcp_housing_database_files.csv", show_col_types = FALSE) |>
  filter(file_role == "project_level_csv_zip", vintage == "25Q4")
stopifnot(nrow(row) == 1L)

zip_listing <- unzip("../input/nychdb_25q4_csv.zip", list = TRUE)
csv_candidates <- zip_listing$Name[grepl("\\.csv$", zip_listing$Name, ignore.case = TRUE)]
project_csv_candidates <- csv_candidates[
  str_detect(tolower(basename(csv_candidates)), "^(housingdb|nychdb).*[.]csv$")
]

stopifnot(length(project_csv_candidates) == 1L)

csv_inside_zip <- project_csv_candidates[[1]]
extracted_csv <- unzip("../input/nychdb_25q4_csv.zip", files = csv_inside_zip, exdir = tempdir(), overwrite = TRUE)
raw_df <- read_csv(extracted_csv, show_col_types = FALSE, guess_max = 50000)
names(raw_df) <- normalize_names(names(raw_df))

raw_df <- raw_df |>
  mutate(
    source_id = row$source_id,
    vintage = row$vintage,
    source_raw_path = row$raw_path
  ) |>
  select(source_id, vintage, source_raw_path, everything())

write_parquet_atomic(raw_df, "../output/dcp_housing_database_project_level_raw_25q4.parquet")
write_csv_atomic(tibble(
  source_id = row$source_id, vintage = row$vintage, raw_path = row$raw_path,
  csv_inside_zip = csv_inside_zip,
  raw_parquet_path = "../output/dcp_housing_database_project_level_raw_25q4.parquet",
  status = "loaded"
), "../output/dcp_housing_database_raw_files.csv")

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

write_parquet_atomic(staged_df, "../output/dcp_housing_database_project_level_25q4.parquet")
write_csv_atomic(tibble(
  source_id = row$source_id, vintage = row$vintage, raw_path = row$raw_path,
  raw_parquet_path = "../output/dcp_housing_database_project_level_raw_25q4.parquet",
  parquet_path = "../output/dcp_housing_database_project_level_25q4.parquet",
  status = "staged"
), "../output/dcp_housing_database_files.csv")

write_data_report(
  readr::read_csv("../output/dcp_housing_database_files.csv", show_col_types = FALSE, guess_max = Inf),
  c("source_id", "vintage"), "../output/dcp_housing_database_files.csv", "../report/dcp_housing_database_files.txt")

write_data_report(
  arrow::read_parquet("../output/dcp_housing_database_project_level_25q4.parquet"),
  NULL, "../output/dcp_housing_database_project_level_25q4.parquet", "../report/dcp_housing_database_project_level_25q4.txt")

write_data_report(
  arrow::read_parquet("../output/dcp_housing_database_project_level_raw_25q4.parquet"),
  NULL, "../output/dcp_housing_database_project_level_raw_25q4.parquet", "../report/dcp_housing_database_project_level_raw_25q4.txt")

write_data_report(
  readr::read_csv("../output/dcp_housing_database_raw_files.csv", show_col_types = FALSE, guess_max = Inf),
  c("source_id", "vintage"), "../output/dcp_housing_database_raw_files.csv", "../report/dcp_housing_database_raw_files.txt")

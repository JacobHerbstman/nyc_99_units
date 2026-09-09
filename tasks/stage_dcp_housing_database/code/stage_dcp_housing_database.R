# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dcp_housing_database/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")

row <- read_csv("../input/dcp_housing_database_raw_files.csv", show_col_types = FALSE) |>
  filter(vintage == "25Q4", status == "loaded")
stopifnot(nrow(row) == 1L)

raw_df <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") %>%
  as.data.frame() %>%
  as_tibble()

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
  raw_parquet_path = row$raw_parquet_path,
  parquet_path = "../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet",
  status = "staged"
), "../output/dcp_housing_database_files.csv")

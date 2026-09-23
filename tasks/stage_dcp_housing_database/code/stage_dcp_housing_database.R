# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dcp_housing_database/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# Both releases share the staged field definitions.
stage_release <- function(raw_df, release, source_raw_path) {
  tibble(
    source_id = "dcp_housing_database_project_level",
    release = release,
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
    source_raw_path = source_raw_path
  )
}

# 23Q4: historical proposals. The inactive-inclusive file contains every
# proposal; historical_active marks jobs also in the active/completed file.
source_raw_path_23q4 <- "../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip"

raw_23q4 <- read_csv(
  unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010_inactive_included.csv"),
  col_types = cols(.default = col_character())
)
active_23q4 <- read_csv(
  unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010.csv"),
  col_types = cols(.default = col_character())
)
names(raw_23q4) <- normalize_names(names(raw_23q4))
names(active_23q4) <- normalize_names(names(active_23q4))

stopifnot(
  !anyNA(raw_23q4$job_number),
  !anyDuplicated(raw_23q4$job_number),
  !anyNA(active_23q4$job_number),
  !anyDuplicated(active_23q4$job_number),
  all(raw_23q4$version == "23Q4"),
  all(active_23q4$version == "23Q4"),
  all(active_23q4$job_number %in% raw_23q4$job_number),
  identical(
    active_23q4$classaprop,
    raw_23q4$classaprop[match(active_23q4$job_number, raw_23q4$job_number)]
  )
)

raw_23q4 <- raw_23q4 |>
  mutate(historical_active = job_number %in% active_23q4$job_number) |>
  mutate(
    source_id = "dcp_housing_database_project_level",
    vintage = "23Q4",
    source_raw_path = source_raw_path_23q4
  ) |>
  select(source_id, vintage, source_raw_path, everything())
SaveData(raw_23q4, "job_number", "../output/dcp_housing_database_project_level_raw_23q4.parquet")

staged_23q4 <- stage_release(raw_23q4, "23Q4", source_raw_path_23q4)
staged_23q4$historical_active <- raw_23q4$historical_active
SaveData(staged_23q4, "job_number", "../output/dcp_housing_database_project_level_23q4.parquet")

# 25Q4: post-policy units.
source_raw_path_25q4 <- "../../../data_raw/dcp_housing_database_project_level/25Q4/nychdb_25q4_csv.zip"

raw_25q4 <- read_csv(
  unz("../input/nychdb_25q4_csv.zip", "HousingDB_post2010.csv"),
  show_col_types = FALSE,
  guess_max = 50000
)
names(raw_25q4) <- normalize_names(names(raw_25q4))

raw_25q4 <- raw_25q4 |>
  mutate(
    source_id = "dcp_housing_database_project_level",
    vintage = "25Q4",
    source_raw_path = source_raw_path_25q4
  ) |>
  select(source_id, vintage, source_raw_path, everything())
SaveData(raw_25q4, NULL, "../output/dcp_housing_database_project_level_raw_25q4.parquet")

staged_25q4 <- stage_release(raw_25q4, "25Q4", source_raw_path_25q4)
SaveData(staged_25q4, NULL, "../output/dcp_housing_database_project_level_25q4.parquet")

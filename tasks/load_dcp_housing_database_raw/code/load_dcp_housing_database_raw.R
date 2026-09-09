# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/load_dcp_housing_database_raw/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")

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

raw_df <- raw_df %>%
  mutate(
    source_id = row$source_id,
    vintage = row$vintage,
    source_raw_path = row$raw_path
  ) %>%
  select(source_id, vintage, source_raw_path, everything())

write_parquet_atomic(raw_df, "../output/dcp_housing_database_project_level_raw_25q4.parquet")
write_csv_atomic(tibble(
  source_id = row$source_id, vintage = row$vintage, raw_path = row$raw_path,
  csv_inside_zip = csv_inside_zip,
  raw_parquet_path = "../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet",
  status = "loaded"
), "../output/dcp_housing_database_raw_files.csv")

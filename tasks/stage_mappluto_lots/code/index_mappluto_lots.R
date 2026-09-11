# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_mappluto_lots/code")
library(dplyr)
library(readr)
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

file_index <- read_csv("../output/mappluto_raw_files.csv", show_col_types = FALSE) |>
  filter(status == "loaded") |>
  mutate(parquet_path = paste0("../output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), ".parquet")) |>
  select(source_id, vintage, raw_path, raw_parquet_path, parquet_path,
         file_role, raw_file_release, fetch_status, raw_zip_valid, raw_status = status)
stopifnot(nrow(file_index) > 0L, !anyDuplicated(file_index[c("source_id", "vintage")]))
write_csv_atomic(file_index, "../output/mappluto_lot_files.csv")

write_data_report(
  readr::read_csv("../output/mappluto_lot_files.csv", show_col_types = FALSE, guess_max = Inf),
  c("source_id", "vintage"), "../output/mappluto_lot_files.csv",
  "../report/mappluto_lot_files.txt"
)

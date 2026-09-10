# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_mappluto_lots/code")
# dataset <- "dcp_mappluto_archive_18v1_1"
source("../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}
if (dataset == "mappluto_lot_files") {
  data <- readr::read_csv("../output/mappluto_lot_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("source_id", "vintage"), "../output/mappluto_lot_files.csv", "../report/mappluto_lot_files.txt")
} else if (dataset == "mappluto_raw_files") {
  data <- readr::read_csv("../output/mappluto_raw_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("source_id", "vintage"), "../output/mappluto_raw_files.csv", "../report/mappluto_raw_files.txt")
} else {
  stopifnot(grepl("^dcp_(mappluto|pluto)_archive_[a-z0-9_]+$", dataset))
  data <- arrow::read_parquet(paste0("../output/", dataset, ".parquet"))
  write_data_report(data, "bbl", paste0("../output/", dataset, ".parquet"),
    paste0("../report/", dataset, ".txt"), require_unique = FALSE)
}

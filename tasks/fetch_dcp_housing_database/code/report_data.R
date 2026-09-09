# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dcp_housing_database/code")
# dataset <- "dcp_housing_database_files"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "dcp_housing_database_files") {
  data <- readr::read_csv("../output/dcp_housing_database_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("source_id", "vintage", "file_role"), "../output/dcp_housing_database_files.csv", "../report/dcp_housing_database_files.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

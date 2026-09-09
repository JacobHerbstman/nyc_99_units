# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dob_now_new_building_filings/code")
# dataset <- "dob_now_new_building_filings"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "dob_now_new_building_filings") {
  data <- arrow::read_parquet("../output/dob_now_new_building_filings.parquet")
  write_data_report(data, c("source_pull_date", "source_row_number"), "../output/dob_now_new_building_filings.parquet", "../report/dob_now_new_building_filings.txt")
} else if (dataset == "dob_now_new_building_initial_filings") {
  data <- arrow::read_parquet("../output/dob_now_new_building_initial_filings.parquet")
  write_data_report(data, c("job_filing_number"), "../output/dob_now_new_building_initial_filings.parquet", "../report/dob_now_new_building_initial_filings.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

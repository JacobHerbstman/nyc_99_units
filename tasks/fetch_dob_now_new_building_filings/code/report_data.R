# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dob_now_new_building_filings/code")
# dataset <- "dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026") {
  data <- readr::read_csv("../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv", "../report/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.txt")
} else if (dataset == "dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026") {
  data <- readr::read_csv("../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv", "../report/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.txt")
} else if (dataset == "dob_now_new_building_filing_files") {
  data <- readr::read_csv("../output/dob_now_new_building_filing_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("file_role"), "../output/dob_now_new_building_filing_files.csv", "../report/dob_now_new_building_filing_files.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

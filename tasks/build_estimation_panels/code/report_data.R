# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_estimation_panels/code")
# dataset <- "parent_opportunity_panel"
source("../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) { stopifnot(length(args) == 1L); dataset <- args[1] }
if (dataset == "parent_opportunity_panel") {
  data <- arrow::read_parquet("../output/parent_opportunity_panel.parquet")
  write_data_report(data, c("sample", "parent_id"), "../output/parent_opportunity_panel.parquet", "../report/parent_opportunity_panel.txt")
} else if (dataset == "constituent_filing_panel") {
  data <- arrow::read_parquet("../output/constituent_filing_panel.parquet")
  write_data_report(data, c("sample", "root_job_id"), "../output/constituent_filing_panel.parquet", "../report/constituent_filing_panel.txt")
} else stop("Unknown dataset")

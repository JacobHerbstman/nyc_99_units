# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_parent_cohorts/code")
# dataset <- "symmetric_parent_links"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "symmetric_parent_links") {
  data <- arrow::read_parquet("../output/symmetric_parent_links.parquet")
  write_data_report(data, NULL, "../output/symmetric_parent_links.parquet", "../report/symmetric_parent_links.txt")
} else if (dataset == "symmetric_parent_membership") {
  data <- arrow::read_parquet("../output/symmetric_parent_membership.parquet")
  write_data_report(data, c("sample", "job_number"), "../output/symmetric_parent_membership.parquet", "../report/symmetric_parent_membership.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

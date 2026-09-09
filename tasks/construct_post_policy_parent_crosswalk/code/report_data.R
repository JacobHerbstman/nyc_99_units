# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_post_policy_parent_crosswalk/code")
# dataset <- "post_policy_filing_link_fields"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "post_policy_filing_link_fields") {
  data <- arrow::read_parquet("../output/post_policy_filing_link_fields.parquet")
  write_data_report(data, NULL, "../output/post_policy_filing_link_fields.parquet", "../report/post_policy_filing_link_fields.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

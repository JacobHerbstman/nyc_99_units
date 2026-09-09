# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_site_characteristics/code")
# dataset <- "historical_parent_site_characteristics"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "historical_parent_site_characteristics") {
  data <- arrow::read_parquet("../output/historical_parent_site_characteristics.parquet")
  write_data_report(data, c("parent_id"), "../output/historical_parent_site_characteristics.parquet", "../report/historical_parent_site_characteristics.txt")
} else if (dataset == "post_policy_parent_site_characteristics") {
  data <- arrow::read_parquet("../output/post_policy_parent_site_characteristics.parquet")
  write_data_report(data, c("parent_id"), "../output/post_policy_parent_site_characteristics.parquet", "../report/post_policy_parent_site_characteristics.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

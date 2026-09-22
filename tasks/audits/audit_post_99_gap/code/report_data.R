# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_post_99_gap/code")
# dataset <- "post_99_next_observed_unit_audit"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}
stopifnot(dataset %in% c("post_99_next_observed_unit_audit", "post_105_parent_cases"))
if (dataset == "post_99_next_observed_unit_audit") {
  data <- read_csv("../output/post_99_next_observed_unit_audit.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("unit_count"), "../output/post_99_next_observed_unit_audit.csv", "../report/post_99_next_observed_unit_audit.txt")
}
if (dataset == "post_105_parent_cases") {
  data <- read_csv("../output/post_105_parent_cases.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("parent_id"), "../output/post_105_parent_cases.csv", "../report/post_105_parent_cases.txt")
}

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_485x_exposure/code")
# dataset <- "parent_485x_exposure_summary"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}
stopifnot(dataset %in% c("parent_485x_exposure_summary", "parent_485x_exposure_by_unit", "parent_485x_exposure_review_queue"))
if (dataset == "parent_485x_exposure_summary") {
  data <- read_csv("../output/parent_485x_exposure_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "exposure_status", "confidence"), "../output/parent_485x_exposure_summary.csv", "../report/parent_485x_exposure_summary.txt")
}
if (dataset == "parent_485x_exposure_by_unit") {
  data <- read_csv("../output/parent_485x_exposure_by_unit.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "parent_total_units", "exposure_status"), "../output/parent_485x_exposure_by_unit.csv", "../report/parent_485x_exposure_by_unit.txt")
}
if (dataset == "parent_485x_exposure_review_queue") {
  data <- read_csv("../output/parent_485x_exposure_review_queue.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "parent_id"), "../output/parent_485x_exposure_review_queue.csv", "../report/parent_485x_exposure_review_queue.txt")
}

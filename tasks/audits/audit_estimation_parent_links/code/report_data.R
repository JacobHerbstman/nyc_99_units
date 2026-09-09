# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
# dataset <- "constituents"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- dataset
stopifnot(length(args) == 1, args[1] %in% c("constituents", "neighbors", "companions"))
dataset <- args[1]
if (dataset == "constituents") {
  data <- read_csv("../output/parent_constituents.csv", show_col_types = FALSE)
  write_data_report(data, c("sample", "root_job_id"), "../output/parent_constituents.csv", "../report/parent_constituents.txt")
} else if (dataset == "neighbors") {
  data <- read_csv("../output/nearby_filings.csv", show_col_types = FALSE)
  write_data_report(data, c("sample", "parent_id", "neighbor_job"), "../output/nearby_filings.csv", "../report/nearby_filings.txt")
}

if (dataset == "companions") {
  data <- read_csv("../output/companion_link_trace.csv", show_col_types = FALSE)
  write_data_report(data, "companion", "../output/companion_link_trace.csv", "../report/companion_link_trace.txt")
}

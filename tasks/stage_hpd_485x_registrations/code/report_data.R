# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_hpd_485x_registrations/code")
# dataset <- "hpd_485x_registrations"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "hpd_485x_registrations") {
  data <- arrow::read_parquet("../output/hpd_485x_registrations.parquet")
  write_data_report(data, NULL, "../output/hpd_485x_registrations.parquet", "../report/hpd_485x_registrations.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

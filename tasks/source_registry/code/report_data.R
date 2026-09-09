# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/source_registry/code")
# dataset <- "source_registry_checks"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "source_registry_checks") {
  data <- readr::read_csv("../output/source_registry_checks.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/source_registry_checks.csv", "../report/source_registry_checks.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

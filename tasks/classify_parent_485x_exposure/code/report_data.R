# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/classify_parent_485x_exposure/code")
# dataset <- "parent_485x_exposure"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "parent_485x_exposure") {
  data <- readr::read_csv("../output/parent_485x_exposure.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "parent_id"), "../output/parent_485x_exposure.csv", "../report/parent_485x_exposure.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

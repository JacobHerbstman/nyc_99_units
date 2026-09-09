# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_485x_exposure_universe/code")
# dataset <- "parent_485x_exposure_universe"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "parent_485x_exposure_universe") {
  data <- readr::read_csv("../output/parent_485x_exposure_universe.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "root_job_id"), "../output/parent_485x_exposure_universe.csv", "../report/parent_485x_exposure_universe.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

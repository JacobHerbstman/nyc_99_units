# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_mappluto_archive/code")
# dataset <- "mappluto_files"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "mappluto_files") {
  data <- readr::read_csv("../output/mappluto_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/mappluto_files.csv", "../report/mappluto_files.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

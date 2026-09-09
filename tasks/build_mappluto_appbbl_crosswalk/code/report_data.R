# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_mappluto_appbbl_crosswalk/code")
# dataset <- "mappluto_appbbl_crosswalk"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "mappluto_appbbl_crosswalk") {
  data <- readr::read_csv("../output/mappluto_appbbl_crosswalk.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("current_bbl"), "../output/mappluto_appbbl_crosswalk.csv", "../report/mappluto_appbbl_crosswalk.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

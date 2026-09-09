# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/define_mappluto_release_calendar/code")
# dataset <- "mappluto_release_calendar"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "mappluto_release_calendar") {
  data <- readr::read_csv("../output/mappluto_release_calendar.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/mappluto_release_calendar.csv", "../report/mappluto_release_calendar.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

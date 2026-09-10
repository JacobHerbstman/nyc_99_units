# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")
# dataset <- "hdb_mappluto_site_panel"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "hdb_mappluto_site_panel") {
  data <- arrow::read_parquet("../output/hdb_mappluto_site_panel.parquet")
  write_data_report(data, NULL, "../output/hdb_mappluto_site_panel.parquet", "../report/hdb_mappluto_site_panel.txt")
} else if (dataset == "mappluto_appbbl_crosswalk") {
  data <- readr::read_csv("../output/mappluto_appbbl_crosswalk.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("current_bbl"), "../output/mappluto_appbbl_crosswalk.csv", "../report/mappluto_appbbl_crosswalk.txt")
} else if (dataset == "mappluto_release_calendar") {
  data <- readr::read_csv("../output/mappluto_release_calendar.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/mappluto_release_calendar.csv", "../report/mappluto_release_calendar.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

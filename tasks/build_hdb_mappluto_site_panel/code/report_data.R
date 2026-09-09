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
} else {
  stop("Unknown dataset: ", dataset)
}

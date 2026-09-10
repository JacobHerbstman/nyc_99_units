# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_historical_parent_links/code")
# dataset <- "historical_parent_candidate_pairs"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "historical_parent_candidate_pairs") {
  data <- arrow::read_parquet("../output/historical_parent_candidate_pairs.parquet")
  write_data_report(data, NULL, "../output/historical_parent_candidate_pairs.parquet", "../report/historical_parent_candidate_pairs.txt")
} else if (dataset == "historical_parent_filing_link_fields") {
  data <- arrow::read_parquet("../output/historical_parent_filing_link_fields.parquet")
  write_data_report(data, c("job_number"), "../output/historical_parent_filing_link_fields.parquet", "../report/historical_parent_filing_link_fields.txt")
} else if (dataset == "historical_polygon_adjacency_pairs") {
  data <- arrow::read_parquet("../output/historical_polygon_adjacency_pairs.parquet")
  write_data_report(data, NULL, "../output/historical_polygon_adjacency_pairs.parquet", "../report/historical_polygon_adjacency_pairs.txt")
} else if (dataset == "historical_polygon_geometry_coverage") {
  data <- arrow::read_parquet("../output/historical_polygon_geometry_coverage.parquet")
  write_data_report(data, NULL, "../output/historical_polygon_geometry_coverage.parquet", "../report/historical_polygon_geometry_coverage.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

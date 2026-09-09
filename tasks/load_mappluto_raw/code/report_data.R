# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/load_mappluto_raw/code")
# dataset <- "dcp_mappluto_archive_18v1_1_raw"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "dcp_mappluto_archive_18v1_1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v1_1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v1_1_raw.parquet", "../report/dcp_mappluto_archive_18v1_1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_18v2_1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v2_1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v2_1_raw.parquet", "../report/dcp_mappluto_archive_18v2_1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_18v2beta_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v2beta_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v2beta_raw.parquet", "../report/dcp_mappluto_archive_18v2beta_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_19v1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_19v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_19v1_raw.parquet", "../report/dcp_mappluto_archive_19v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_19v2_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_19v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_19v2_raw.parquet", "../report/dcp_mappluto_archive_19v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v1_raw.parquet", "../report/dcp_mappluto_archive_20v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v2_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v2_raw.parquet", "../report/dcp_mappluto_archive_20v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v3_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v3_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v3_raw.parquet", "../report/dcp_mappluto_archive_20v3_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v4_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v4_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v4_raw.parquet", "../report/dcp_mappluto_archive_20v4_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v5_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v5_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v5_raw.parquet", "../report/dcp_mappluto_archive_20v5_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v6_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v6_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v6_raw.parquet", "../report/dcp_mappluto_archive_20v6_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v7_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v7_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v7_raw.parquet", "../report/dcp_mappluto_archive_20v7_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v8_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v8_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v8_raw.parquet", "../report/dcp_mappluto_archive_20v8_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_21v1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_21v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_21v1_raw.parquet", "../report/dcp_mappluto_archive_21v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_21v3_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_21v3_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_21v3_raw.parquet", "../report/dcp_mappluto_archive_21v3_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_22v1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_22v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_22v1_raw.parquet", "../report/dcp_mappluto_archive_22v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_22v2_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_22v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_22v2_raw.parquet", "../report/dcp_mappluto_archive_22v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1_1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1_1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1_1_raw.parquet", "../report/dcp_mappluto_archive_23v1_1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1_2_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1_2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1_2_raw.parquet", "../report/dcp_mappluto_archive_23v1_2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1_raw.parquet", "../report/dcp_mappluto_archive_23v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v2_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v2_raw.parquet", "../report/dcp_mappluto_archive_23v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v3_1_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v3_1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v3_1_raw.parquet", "../report/dcp_mappluto_archive_23v3_1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v3_raw") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v3_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v3_raw.parquet", "../report/dcp_mappluto_archive_23v3_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_09v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_09v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_09v1_raw.parquet", "../report/dcp_pluto_archive_09v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_09v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_09v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_09v2_raw.parquet", "../report/dcp_pluto_archive_09v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_10v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_10v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_10v1_raw.parquet", "../report/dcp_pluto_archive_10v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_10v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_10v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_10v2_raw.parquet", "../report/dcp_pluto_archive_10v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_11v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_11v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_11v1_raw.parquet", "../report/dcp_pluto_archive_11v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_11v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_11v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_11v2_raw.parquet", "../report/dcp_pluto_archive_11v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_12v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_12v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_12v1_raw.parquet", "../report/dcp_pluto_archive_12v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_12v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_12v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_12v2_raw.parquet", "../report/dcp_pluto_archive_12v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_13v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_13v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_13v1_raw.parquet", "../report/dcp_pluto_archive_13v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_13v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_13v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_13v2_raw.parquet", "../report/dcp_pluto_archive_13v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_14v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_14v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_14v1_raw.parquet", "../report/dcp_pluto_archive_14v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_14v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_14v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_14v2_raw.parquet", "../report/dcp_pluto_archive_14v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_15v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_15v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_15v1_raw.parquet", "../report/dcp_pluto_archive_15v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_16v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_16v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_16v1_raw.parquet", "../report/dcp_pluto_archive_16v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_16v2_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_16v2_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_16v2_raw.parquet", "../report/dcp_pluto_archive_16v2_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_17v1_1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_17v1_1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_17v1_1_raw.parquet", "../report/dcp_pluto_archive_17v1_1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_17v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_17v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_17v1_raw.parquet", "../report/dcp_pluto_archive_17v1_raw.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_18v1_raw") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_18v1_raw.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_18v1_raw.parquet", "../report/dcp_pluto_archive_18v1_raw.txt", require_unique = FALSE)
} else if (dataset == "mappluto_raw_files") {
  data <- readr::read_csv("../output/mappluto_raw_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("source_id", "vintage"), "../output/mappluto_raw_files.csv", "../report/mappluto_raw_files.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

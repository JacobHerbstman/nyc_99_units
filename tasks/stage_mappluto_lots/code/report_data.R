# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_mappluto_lots/code")
# dataset <- "dcp_mappluto_archive_18v1_1"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "dcp_mappluto_archive_18v1_1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v1_1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v1_1.parquet", "../report/dcp_mappluto_archive_18v1_1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_18v2_1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v2_1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v2_1.parquet", "../report/dcp_mappluto_archive_18v2_1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_18v2beta") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_18v2beta.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_18v2beta.parquet", "../report/dcp_mappluto_archive_18v2beta.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_19v1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_19v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_19v1.parquet", "../report/dcp_mappluto_archive_19v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_19v2") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_19v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_19v2.parquet", "../report/dcp_mappluto_archive_19v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v1.parquet", "../report/dcp_mappluto_archive_20v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v2") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v2.parquet", "../report/dcp_mappluto_archive_20v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v3") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v3.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v3.parquet", "../report/dcp_mappluto_archive_20v3.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v4") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v4.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v4.parquet", "../report/dcp_mappluto_archive_20v4.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v5") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v5.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v5.parquet", "../report/dcp_mappluto_archive_20v5.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v6") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v6.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v6.parquet", "../report/dcp_mappluto_archive_20v6.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v7") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v7.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v7.parquet", "../report/dcp_mappluto_archive_20v7.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_20v8") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_20v8.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_20v8.parquet", "../report/dcp_mappluto_archive_20v8.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_21v1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_21v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_21v1.parquet", "../report/dcp_mappluto_archive_21v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_21v3") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_21v3.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_21v3.parquet", "../report/dcp_mappluto_archive_21v3.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_22v1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_22v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_22v1.parquet", "../report/dcp_mappluto_archive_22v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_22v2") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_22v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_22v2.parquet", "../report/dcp_mappluto_archive_22v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1.parquet", "../report/dcp_mappluto_archive_23v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1_1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1_1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1_1.parquet", "../report/dcp_mappluto_archive_23v1_1.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v1_2") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v1_2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v1_2.parquet", "../report/dcp_mappluto_archive_23v1_2.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v2") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v2.parquet", "../report/dcp_mappluto_archive_23v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v3") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v3.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v3.parquet", "../report/dcp_mappluto_archive_23v3.txt", require_unique = FALSE)
} else if (dataset == "dcp_mappluto_archive_23v3_1") {
  data <- arrow::read_parquet("../output/dcp_mappluto_archive_23v3_1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_mappluto_archive_23v3_1.parquet", "../report/dcp_mappluto_archive_23v3_1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_09v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_09v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_09v1.parquet", "../report/dcp_pluto_archive_09v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_09v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_09v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_09v2.parquet", "../report/dcp_pluto_archive_09v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_10v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_10v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_10v1.parquet", "../report/dcp_pluto_archive_10v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_10v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_10v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_10v2.parquet", "../report/dcp_pluto_archive_10v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_11v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_11v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_11v1.parquet", "../report/dcp_pluto_archive_11v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_11v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_11v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_11v2.parquet", "../report/dcp_pluto_archive_11v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_12v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_12v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_12v1.parquet", "../report/dcp_pluto_archive_12v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_12v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_12v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_12v2.parquet", "../report/dcp_pluto_archive_12v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_13v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_13v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_13v1.parquet", "../report/dcp_pluto_archive_13v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_13v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_13v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_13v2.parquet", "../report/dcp_pluto_archive_13v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_14v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_14v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_14v1.parquet", "../report/dcp_pluto_archive_14v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_14v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_14v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_14v2.parquet", "../report/dcp_pluto_archive_14v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_15v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_15v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_15v1.parquet", "../report/dcp_pluto_archive_15v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_16v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_16v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_16v1.parquet", "../report/dcp_pluto_archive_16v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_16v2") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_16v2.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_16v2.parquet", "../report/dcp_pluto_archive_16v2.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_17v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_17v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_17v1.parquet", "../report/dcp_pluto_archive_17v1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_17v1_1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_17v1_1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_17v1_1.parquet", "../report/dcp_pluto_archive_17v1_1.txt", require_unique = FALSE)
} else if (dataset == "dcp_pluto_archive_18v1") {
  data <- arrow::read_parquet("../output/dcp_pluto_archive_18v1.parquet")
  write_data_report(data, c("bbl"), "../output/dcp_pluto_archive_18v1.parquet", "../report/dcp_pluto_archive_18v1.txt", require_unique = FALSE)
} else if (dataset == "mappluto_lot_files") {
  data <- readr::read_csv("../output/mappluto_lot_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("source_id", "vintage"), "../output/mappluto_lot_files.csv", "../report/mappluto_lot_files.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

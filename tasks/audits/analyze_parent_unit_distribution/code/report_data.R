# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/analyze_parent_unit_distribution/code")
# dataset <- "parent_unit_distribution_80_120"

source("../../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "parent_unit_distribution_80_120") {
  data <- readr::read_csv("../output/parent_unit_distribution_80_120.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_80_120.csv", "../report/parent_unit_distribution_80_120.txt")
} else if (dataset == "parent_unit_distribution_annualized_50_300") {
  data <- readr::read_csv("../output/parent_unit_distribution_annualized_50_300.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_annualized_50_300.csv", "../report/parent_unit_distribution_annualized_50_300.txt")
} else if (dataset == "parent_unit_distribution_exposure_50_150") {
  data <- readr::read_csv("../output/parent_unit_distribution_exposure_50_150.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_exposure_50_150.csv", "../report/parent_unit_distribution_exposure_50_150.txt")
} else if (dataset == "parent_unit_distribution_exposure_80_120") {
  data <- readr::read_csv("../output/parent_unit_distribution_exposure_80_120.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_exposure_80_120.csv", "../report/parent_unit_distribution_exposure_80_120.txt")
} else if (dataset == "parent_unit_distribution_exposure_sample_summary") {
  data <- readr::read_csv("../output/parent_unit_distribution_exposure_sample_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_exposure_sample_summary.csv", "../report/parent_unit_distribution_exposure_sample_summary.txt")
} else if (dataset == "parent_unit_distribution_full") {
  data <- readr::read_csv("../output/parent_unit_distribution_full.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_full.csv", "../report/parent_unit_distribution_full.txt")
} else if (dataset == "parent_unit_distribution_full_histogram_bins") {
  data <- readr::read_csv("../output/parent_unit_distribution_full_histogram_bins.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_full_histogram_bins.csv", "../report/parent_unit_distribution_full_histogram_bins.txt")
} else if (dataset == "parent_unit_distribution_normalized_density_50_300_ab") {
  data <- readr::read_csv("../output/parent_unit_distribution_normalized_density_50_300_ab.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_normalized_density_50_300_ab.csv", "../report/parent_unit_distribution_normalized_density_50_300_ab.txt")
} else if (dataset == "parent_unit_distribution_sample_summary") {
  data <- readr::read_csv("../output/parent_unit_distribution_sample_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/parent_unit_distribution_sample_summary.csv", "../report/parent_unit_distribution_sample_summary.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

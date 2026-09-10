# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")
# dataset <- "parent_total_exact_distribution_50_300"
source("../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) { stopifnot(length(args) == 1L); dataset <- args[1] }
if (dataset == "parent_total_exact_distribution_50_300") {
  data <- readr::read_csv("../output/parent_total_exact_distribution_50_300.csv", show_col_types = FALSE)
  write_data_report(data, c("period", "parent_total_units"), "../output/parent_total_exact_distribution_50_300.csv", "../report/parent_total_exact_distribution_50_300.txt")
} else if (dataset == "preferred_parent_distribution_50_plus") {
  data <- readr::read_csv("../output/preferred_parent_distribution_50_plus.csv", show_col_types = FALSE)
  write_data_report(data, c("period", "unit_bin_order"), "../output/preferred_parent_distribution_50_plus.csv", "../report/preferred_parent_distribution_50_plus.txt")
} else stop("Unknown dataset")

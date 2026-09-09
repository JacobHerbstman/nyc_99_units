# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# dataset <- "bootstrap_draws"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "bootstrap_draws") {
  data <- readr::read_csv("../output/bootstrap_draws.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("replication", "statistic"), "../output/bootstrap_draws.csv", "../report/bootstrap_draws.txt")
} else if (dataset == "bootstrap_intervals") {
  data <- readr::read_csv("../output/bootstrap_intervals.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("statistic"), "../output/bootstrap_intervals.csv", "../report/bootstrap_intervals.txt")
} else if (dataset == "bootstrap_run_summary") {
  data <- readr::read_csv("../output/bootstrap_run_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/bootstrap_run_summary.csv", "../report/bootstrap_run_summary.txt")
} else if (dataset == "calibration_balance") {
  data <- readr::read_csv("../output/calibration_balance.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("balance_moment"), "../output/calibration_balance.csv", "../report/calibration_balance.txt")
} else if (dataset == "calibration_summary") {
  data <- readr::read_csv("../output/calibration_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/calibration_summary.csv", "../report/calibration_summary.txt")
} else if (dataset == "calibration_weights") {
  data <- readr::read_csv("../output/calibration_weights.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample", "parent_id"), "../output/calibration_weights.csv", "../report/calibration_weights.txt")
} else if (dataset == "constituent_count_distribution") {
  data <- readr::read_csv("../output/constituent_count_distribution.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "n_components"), "../output/constituent_count_distribution.csv", "../report/constituent_count_distribution.txt")
} else if (dataset == "constituent_filing_panel") {
  data <- arrow::read_parquet("../output/constituent_filing_panel.parquet")
  write_data_report(data, c("sample", "root_job_id"), "../output/constituent_filing_panel.parquet", "../report/constituent_filing_panel.txt")
} else if (dataset == "cumulative_99_diagnostics") {
  data <- readr::read_csv("../output/cumulative_99_diagnostics.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("unit_bin_order"), "../output/cumulative_99_diagnostics.csv", "../report/cumulative_99_diagnostics.txt")
} else if (dataset == "exact_198_vector_decomposition") {
  data <- readr::read_csv("../output/exact_198_vector_decomposition.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/exact_198_vector_decomposition.csv", "../report/exact_198_vector_decomposition.txt")
} else if (dataset == "exact_threshold_shares") {
  data <- readr::read_csv("../output/exact_threshold_shares.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "parent_total_units"), "../output/exact_threshold_shares.csv", "../report/exact_threshold_shares.txt")
} else if (dataset == "local_excess_deficit_moments") {
  data <- readr::read_csv("../output/local_excess_deficit_moments.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("outcome", "moment"), "../output/local_excess_deficit_moments.csv", "../report/local_excess_deficit_moments.txt")
} else if (dataset == "outcome_distribution_50_300") {
  data <- readr::read_csv("../output/outcome_distribution_50_300.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("outcome", "period", "unit_count"), "../output/outcome_distribution_50_300.csv", "../report/outcome_distribution_50_300.txt")
} else if (dataset == "parent_99xk_summary") {
  data <- readr::read_csv("../output/parent_99xk_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "pattern"), "../output/parent_99xk_summary.csv", "../report/parent_99xk_summary.txt")
} else if (dataset == "parent_opportunity_panel") {
  data <- arrow::read_parquet("../output/parent_opportunity_panel.parquet")
  write_data_report(data, c("sample", "parent_id"), "../output/parent_opportunity_panel.parquet", "../report/parent_opportunity_panel.txt")
} else if (dataset == "parent_response_categories") {
  data <- readr::read_csv("../output/parent_response_categories.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "response_category"), "../output/parent_response_categories.csv", "../report/parent_response_categories.txt")
} else if (dataset == "parent_share_difference") {
  data <- readr::read_csv("../output/parent_share_difference.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("unit_bin_order"), "../output/parent_share_difference.csv", "../report/parent_share_difference.txt")
} else if (dataset == "parent_total_exact_distribution_50_300") {
  data <- readr::read_csv("../output/parent_total_exact_distribution_50_300.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "parent_total_units"), "../output/parent_total_exact_distribution_50_300.csv", "../report/parent_total_exact_distribution_50_300.txt")
} else if (dataset == "preferred_parent_distribution_50_plus") {
  data <- readr::read_csv("../output/preferred_parent_distribution_50_plus.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("period", "unit_bin_order"), "../output/preferred_parent_distribution_50_plus.csv", "../report/preferred_parent_distribution_50_plus.txt")
} else if (dataset == "reweighted_constituent_count_distribution") {
  data <- readr::read_csv("../output/reweighted_constituent_count_distribution.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("series", "n_components"), "../output/reweighted_constituent_count_distribution.csv", "../report/reweighted_constituent_count_distribution.txt")
} else if (dataset == "reweighted_counterfactual_distributions") {
  data <- readr::read_csv("../output/reweighted_counterfactual_distributions.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("outcome", "series", "unit_bin_order"), "../output/reweighted_counterfactual_distributions.csv", "../report/reweighted_counterfactual_distributions.txt")
} else if (dataset == "sample_exposure_summary") {
  data <- readr::read_csv("../output/sample_exposure_summary.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("sample_scope", "period"), "../output/sample_exposure_summary.csv", "../report/sample_exposure_summary.txt")
} else if (dataset == "scale_shape_count_decomposition") {
  data <- readr::read_csv("../output/scale_shape_count_decomposition.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/scale_shape_count_decomposition.csv", "../report/scale_shape_count_decomposition.txt")
} else if (dataset == "scale_shape_decomposition") {
  data <- readr::read_csv("../output/scale_shape_decomposition.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("range_label"), "../output/scale_shape_decomposition.csv", "../report/scale_shape_decomposition.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

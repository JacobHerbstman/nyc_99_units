# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

source("../../_lib/source_pipeline_utils.R")

sample_summary <- read_csv(
  "../output/sample_exposure_summary.csv",
  show_col_types = FALSE
)
local_moments <- read_csv(
  "../output/local_excess_deficit_moments.csv",
  show_col_types = FALSE
)
bootstrap_intervals <- read_csv(
  "../output/bootstrap_intervals.csv",
  show_col_types = FALSE
)
exact_198 <- read_csv(
  "../output/exact_198_vector_decomposition.csv",
  show_col_types = FALSE
)
calibration_summary <- read_csv(
  "../output/calibration_summary.csv",
  show_col_types = FALSE
)
temporal_sensitivity <- read_csv(
  "../output/temporal_window_sensitivity.csv",
  show_col_types = FALSE
)
reweighted_components <- read_csv(
  "../output/reweighted_constituent_count_distribution.csv",
  show_col_types = FALSE
)
bootstrap_summary <- read_csv(
  "../output/bootstrap_run_summary.csv",
  show_col_types = FALSE
)

ab_sample <- sample_summary |>
  filter(sample_scope == "A/B rental opportunities")

pre_sample <- ab_sample |>
  filter(grepl("Pre", period))
post_sample <- ab_sample |>
  filter(grepl("Post", period))

parent_moments <- local_moments |>
  filter(outcome == "Parent total")

excess_99 <- parent_moments |>
  filter(moment == "excess_at_99") |>
  pull(estimate)
deficit_149 <- parent_moments |>
  filter(moment == "cumulative_deficit_100_149") |>
  pull(estimate)
excess_198 <- parent_moments |>
  filter(moment == "excess_at_198") |>
  pull(estimate)

interval_99 <- bootstrap_intervals |>
  filter(statistic == "parent_total__excess_at_99")
interval_deficit <- bootstrap_intervals |>
  filter(statistic == "parent_total__cumulative_deficit_100_149")
interval_198 <- bootstrap_intervals |>
  filter(statistic == "parent_total__excess_at_198")

exact_198_total <- unique(exact_198$exact_198_parents)
verified_198 <- exact_198 |>
  filter(splitting_verification_status == "verified_separate_485x_units") |>
  summarise(value = sum(parent_count)) |>
  pull(value)
suggestive_198 <- exact_198 |>
  filter(splitting_verification_status == "suggestive_separate_components") |>
  summarise(value = sum(parent_count)) |>
  pull(value)
unresolved_198 <- exact_198 |>
  filter(splitting_verification_status == "unable_to_verify") |>
  summarise(value = sum(parent_count)) |>
  pull(value)

historical_single_share <- reweighted_components |>
  filter(
    series == "Historical reweighted to post sites",
    n_components == 1L
  ) |>
  pull(share)
post_single_share <- reweighted_components |>
  filter(series == "Post observed", n_components == 1L) |>
  pull(share)

sensitivity_2021 <- temporal_sensitivity |>
  filter(
    historical_window == "2021-2022",
    moment == "excess_at_99"
  ) |>
  pull(estimate)

successful_bootstraps <- bootstrap_summary |>
  filter(status == "successful") |>
  summarise(value = sum(replications)) |>
  pull(value)
requested_bootstraps <- unique(bootstrap_summary$requested_replications)

latex_lines <- c(
  paste0("\\newcommand{\\PreParentsAllSixPlus}{", pre_sample$parent_opportunities, "}"),
  paste0("\\newcommand{\\PostParentsAllSixPlus}{", post_sample$parent_opportunities, "}"),
  paste0("\\newcommand{\\PostExposureYears}{", sprintf("%.3f", post_sample$exposure_years), "}"),
  paste0("\\newcommand{\\ExcessNinetyNine}{", sprintf("%.1f", 100 * excess_99), "}"),
  paste0("\\newcommand{\\ExcessNinetyNineLower}{", sprintf("%.1f", 100 * interval_99$percentile_lower), "}"),
  paste0("\\newcommand{\\ExcessNinetyNineUpper}{", sprintf("%.1f", 100 * interval_99$percentile_upper), "}"),
  paste0("\\newcommand{\\DeficitOneHundredOneFortyNine}{", sprintf("%.1f", 100 * deficit_149), "}"),
  paste0("\\newcommand{\\DeficitOneHundredOneFortyNineLower}{", sprintf("%.1f", 100 * interval_deficit$percentile_lower), "}"),
  paste0("\\newcommand{\\DeficitOneHundredOneFortyNineUpper}{", sprintf("%.1f", 100 * interval_deficit$percentile_upper), "}"),
  paste0("\\newcommand{\\ExcessOneNinetyEight}{", sprintf("%.1f", 100 * excess_198), "}"),
  paste0("\\newcommand{\\ExcessOneNinetyEightLower}{", sprintf("%.1f", 100 * interval_198$percentile_lower), "}"),
  paste0("\\newcommand{\\ExcessOneNinetyEightUpper}{", sprintf("%.1f", 100 * interval_198$percentile_upper), "}"),
  paste0("\\newcommand{\\ExactOneNinetyEightParents}{", exact_198_total, "}"),
  paste0("\\newcommand{\\VerifiedOneNinetyEight}{", verified_198, "}"),
  paste0("\\newcommand{\\SuggestiveOneNinetyEight}{", suggestive_198, "}"),
  paste0("\\newcommand{\\UnresolvedOneNinetyEight}{", unresolved_198, "}"),
  paste0("\\newcommand{\\CalibrationHistoricalParents}{", calibration_summary$historical_parents, "}"),
  paste0("\\newcommand{\\CalibrationPostParents}{", calibration_summary$post_parents, "}"),
  paste0("\\newcommand{\\CalibrationESS}{", sprintf("%.0f", calibration_summary$effective_sample_size), "}"),
  paste0("\\newcommand{\\MinimumCalibrationWeight}{", sprintf("%.2f", calibration_summary$minimum_weight), "}"),
  paste0("\\newcommand{\\MaximumCalibrationWeight}{", sprintf("%.2f", calibration_summary$maximum_weight), "}"),
  paste0("\\newcommand{\\HistoricalSingleShare}{", sprintf("%.1f", 100 * historical_single_share), "}"),
  paste0("\\newcommand{\\PostSingleShare}{", sprintf("%.1f", 100 * post_single_share), "}"),
  paste0("\\newcommand{\\SensitivityTwentyOneExcess}{", sprintf("%.1f", 100 * sensitivity_2021), "}"),
  paste0("\\newcommand{\\SuccessfulBootstraps}{", successful_bootstraps, "}"),
  paste0("\\newcommand{\\RequestedBootstraps}{", requested_bootstraps, "}")
)

temporary_tex <- tempfile(fileext = ".tex")
writeLines(latex_lines, temporary_tex)
copy_if_changed(
  temporary_tex,
  "../temp/scale_shape_splitting_figure_guide_values.tex"
)

cat("Wrote dynamic values for the figure guide.\n")

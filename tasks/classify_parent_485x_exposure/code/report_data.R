# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/classify_parent_485x_exposure/code")
# dataset <- "nys_ag_offering_plan_matches"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "nys_ag_offering_plan_matches") {
  data <- readr::read_csv("../output/nys_ag_offering_plan_matches.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/nys_ag_offering_plan_matches.csv", "../report/nys_ag_offering_plan_matches.txt")
} else if (dataset == "nys_ag_offering_plan_search_audit") {
  data <- readr::read_csv("../output/nys_ag_offering_plan_search_audit.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/nys_ag_offering_plan_search_audit.csv", "../report/nys_ag_offering_plan_search_audit.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

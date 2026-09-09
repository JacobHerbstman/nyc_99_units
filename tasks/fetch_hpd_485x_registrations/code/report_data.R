# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_hpd_485x_registrations/code")
# dataset <- "hpd_485x_registration_files"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "hpd_485x_registration_files") {
  data <- readr::read_csv("../output/hpd_485x_registration_files.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("file_role"), "../output/hpd_485x_registration_files.csv", "../report/hpd_485x_registration_files.txt")
} else if (dataset == "hpd_485x_registrations_20260820_hpd_485x_registrations") {
  data <- readr::read_csv("../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, NULL, "../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv", "../report/hpd_485x_registrations_20260820_hpd_485x_registrations.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

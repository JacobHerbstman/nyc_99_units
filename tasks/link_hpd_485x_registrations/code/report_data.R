# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/link_hpd_485x_registrations/code")
# dataset <- "hpd_485x_registration_dob_links"

source("../../shared/code/write_data_report.R")

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 1L)
  dataset <- args[1]
}

if (dataset == "hpd_485x_registration_dob_links") {
  data <- readr::read_csv("../output/hpd_485x_registration_dob_links.csv", show_col_types = FALSE, guess_max = Inf)
  write_data_report(data, c("response_number"), "../output/hpd_485x_registration_dob_links.csv", "../report/hpd_485x_registration_dob_links.txt")
} else {
  stop("Unknown dataset: ", dataset)
}

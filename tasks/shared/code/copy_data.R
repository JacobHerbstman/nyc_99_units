# Copy a received CSV without changing its bytes, and report on the saved data.
# Run from the receiving task's code/ directory.
# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dcp_housing_database/code")
# source_file <- "source_files.csv"
# output_file <- "../output/dcp_housing_database_files.csv"
# keys <- c("source_id", "vintage", "file_role")
source("../../shared/code/write_data_report.R")
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) >= 2L)
  source_file <- args[1]
  output_file <- args[2]
  keys <- args[-c(1, 2)]
}
data <- readr::read_csv(source_file, show_col_types = FALSE, guess_max = Inf)
report_file <- file.path("../report", sub("\\.csv$", ".txt", basename(output_file)))
write_data_report(data, keys, source_file, report_file)
stopifnot(file.copy(source_file, output_file, overwrite = TRUE))

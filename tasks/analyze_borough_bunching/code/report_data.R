# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_borough_bunching/code")
# dataset <- "geographic_filings"
suppressPackageStartupMessages({library(arrow); library(readr); library(dplyr)})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
dataset <- args[1]
stopifnot(dataset %in% c("geographic_filings", "borough_summary"))
if (dataset == "geographic_filings") {
  data <- read_parquet("../output/geographic_filings.parquet")
  stopifnot(!anyNA(data[c("sample", "root_job_id")]),
            !anyDuplicated(data[c("sample", "root_job_id")]))
} else {
  data <- read_csv("../output/borough_summary.csv", show_col_types = FALSE)
  stopifnot(!anyNA(data[c("measure", "borough_name", "sample")]),
            !anyDuplicated(data[c("measure", "borough_name", "sample")]))
}
sink(paste0("../report/", dataset, ".txt"))
cat(sprintf("%s\nRows: %d  Columns: %d\n", dataset, nrow(data), ncol(data)))
cat("MD5 of saved file: ", if (dataset == "geographic_filings") {
  unname(tools::md5sum("../output/geographic_filings.parquet"))
} else { unname(tools::md5sum("../output/borough_summary.csv")) }, "\n", sep = "")
for (column in names(data)) {
  x <- data[[column]]
  cat(column, "|", paste(class(x), collapse = "/"), "| nonmissing", sum(!is.na(x)),
      "| distinct", n_distinct(x, na.rm = TRUE))
  if (is.numeric(x) && any(!is.na(x))) {
    cat("| min/median/mean/max", paste(signif(c(min(x, na.rm = TRUE), median(x, na.rm = TRUE),
                                              mean(x, na.rm = TRUE), max(x, na.rm = TRUE)), 7), collapse = "/"))
  }
  cat("\n")
}
cat("\n")
if (dataset == "geographic_filings") {
  print(data |> count(sample, coordinate_status), n = Inf)
  print(data |> filter(constituent_units == 99) |> count(sample, borough_name, coordinate_status), n = Inf)
} else {
  print(as.data.frame(data), row.names = FALSE)
}
sink()

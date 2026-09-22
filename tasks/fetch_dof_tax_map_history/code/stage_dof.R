# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dof_tax_map_history/code")
# table_name <- "dtm_15"
suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
})
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  table_name <- args[1]
}
stopifnot(table_name %in% c(paste0("dtm_", c(0, 3, 4, 8, 9, 13, 14, 15)), "applications"))

# Each archive contains the unmodified, ordered API pages for one DOF table.
archive <- paste0("../output/", table_name, ".zip")
pages <- unzip(archive, list = TRUE)$Name
pages <- sort(pages[grepl("^page_", pages)])
data <- bind_rows(lapply(pages, function(page) {
  connection <- unz(archive, page)
  on.exit(close(connection))
  fromJSON(paste(readLines(connection, warn = FALSE), collapse = "\n"))$features$attributes
}))
stopifnot(nrow(data) > 0L, !anyNA(data$OBJECTID), !anyDuplicated(data$OBJECTID))
SaveData(data, "OBJECTID", paste0("../output/", table_name, ".parquet"))

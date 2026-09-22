# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_acs_construction_earnings/code")
# geography <- "puma"
suppressPackageStartupMessages(library(jsonlite))
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
geography <- args[1]
stopifnot(geography %in% c("puma", "community_district"))
if (geography == "puma") {
  data <- fromJSON("../output/nyc_puma_2020_2026-09-08.geojson")$features$properties
  stopifnot(nrow(data) == 55)
  write_data_report(data, "puma", "../output/nyc_puma_2020_2026-09-08.geojson", "../report/puma_boundaries.txt")
} else {
  data <- fromJSON("../output/community_districts_2026-09-08.geojson")$features$properties
  stopifnot(sum(as.integer(data$boro_cd) %% 100 < 20) == 59)
  write_data_report(data, "boro_cd", "../output/community_districts_2026-09-08.geojson", "../report/community_district_boundaries.txt")
}

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_nyc_borough_boundaries/code")
# source_file <- "../output/borough_boundaries_2026-09-08.geojson.part"
# output_file <- "../output/borough_boundaries_2026-09-08.geojson"
library(sf)
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 2L)
  source_file <- args[1]
  output_file <- args[2]
}
boroughs <- st_read(source_file, quiet = TRUE)
stopifnot(nrow(boroughs) == 5L, all(st_is_valid(boroughs)))
write_data_report(st_drop_geometry(boroughs), "borocode",
                  source_file, "../report/borough_boundaries.txt")
stopifnot(file.rename(source_file, output_file))

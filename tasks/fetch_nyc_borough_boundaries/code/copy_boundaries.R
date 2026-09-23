# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_nyc_borough_boundaries/code")
library(sf)
source("../../shared/code/write_data_report.R")

source_file <- "../../../data_raw/nyc_borough_boundaries/2026-09-08/borough_boundaries.geojson"
output_file <- "../output/borough_boundaries_2026-09-08.geojson"

boroughs <- st_read(source_file, quiet = TRUE)
stopifnot(nrow(boroughs) == 5L, all(st_is_valid(boroughs)))
write_data_report(st_drop_geometry(boroughs), "borocode",
                  source_file, "../report/borough_boundaries.txt")
stopifnot(file.copy(source_file, output_file, overwrite = TRUE))

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_nyc_borough_boundaries/code")
library(sf)
source("../../shared/code/write_data_report.R")

boroughs <- st_read("../output/borough_boundaries_2026-09-08.geojson", quiet = TRUE)
stopifnot(nrow(boroughs) == 5L, all(st_is_valid(boroughs)))
write_data_report(st_drop_geometry(boroughs), "borocode",
                  "../output/borough_boundaries_2026-09-08.geojson",
                  "../report/borough_boundaries.txt")

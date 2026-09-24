# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})
source("../../shared/code/write_data_report.R")

# The date each PLUTO or MapPLUTO release became available, from the manual
# table of archive evidence. Releases are ordered and their dates never fall.
calendar <- read_csv("mappluto_release_calendar_manual.csv", col_types = cols(
  release_order = col_integer(), safe_available_date = col_date(), usable_for_training = col_logical(),
  .default = col_character())) |>
  arrange(release_order)
stopifnot(!anyDuplicated(calendar[c("source_id", "vintage")]), !anyDuplicated(calendar$release_order),
  all(calendar$usable_for_training), !anyNA(calendar$safe_available_date), !anyNA(calendar$evidence_url),
  all(diff(calendar$safe_available_date) >= 0))

SaveData(calendar, NULL, "../output/mappluto_release_calendar.csv")

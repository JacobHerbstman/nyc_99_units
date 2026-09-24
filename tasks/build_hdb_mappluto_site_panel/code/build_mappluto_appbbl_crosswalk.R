# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# PLUTO 25v4 records, for each current tax lot, the former lot it replaced
# (APPBBL) and the date of that change.
pluto <- read_csv(unzip("../input/nyc_pluto_25v4_csv.zip", files = "pluto_25v4.csv", exdir = tempdir()),
  col_types = cols(.default = col_character()), lazy = FALSE)
names(pluto) <- normalize_names(names(pluto))

crosswalk <- pluto |>
  transmute(current_bbl = normalize_bbl_field(coalesce(na_if(bbl, ""), build_bbl(borough, block, lot))),
    appbbl = normalize_bbl_field(appbbl), appdate = parse_mixed_date(appdate)) |>
  filter(!is.na(current_bbl), !is.na(appbbl), current_bbl != appbbl) |>
  distinct() |>
  mutate(same_boro_block = substr(current_bbl, 1, 6) == substr(appbbl, 1, 6)) |>
  arrange(current_bbl)
stopifnot(!anyDuplicated(crosswalk$current_bbl))

SaveData(crosswalk, "current_bbl", "../output/mappluto_appbbl_crosswalk.csv")

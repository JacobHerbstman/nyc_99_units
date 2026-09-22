# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(dplyr)
library(readr)
library(sf)
library(stringr)
library(tidyr)
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/dof_geometry_comparison.csv", show_col_types = FALSE) |>
  filter(!mixed_vintages, base_mapped_lots < base_requested_lots)
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id))
# These are the physical filing/base lots already defined in the first pass.
# Search every requested ID, including lots absent from that pass's spatial read.
anchors <- parents |> select(parent_id, base_mapped_bbls, base_missing_bbls) |>
  pivot_longer(-parent_id, values_to = "bbl") |> filter(!is.na(bbl)) |>
  separate_longer_delim(bbl, ";") |> distinct(parent_id, bbl)
wanted <- sort(unique(anchors$bbl))
archives <- c(
  "18v1_1" = "../input/nyc_mappluto_18v1_1_arc_shp.zip",
  "18v2beta" = "../input/nyc_mappluto_18v2_arc_shp.zip",
  "18v2_1" = "../input/nyc_mappluto_18v2_1_arc_shp.zip",
  "19v1" = "../input/nyc_mappluto_19v1_arc_shp.zip",
  "19v2" = "../input/nyc_mappluto_19v2_arc_shp.zip",
  "20v1" = "../input/nyc_mappluto_20v1_arc_shp.zip",
  "20v2" = "../input/nyc_mappluto_20v2_arc_shp.zip",
  "20v3" = "../input/nyc_mappluto_20v3_arc_shp.zip",
  "20v4" = "../input/nyc_mappluto_20v4_arc_shp.zip",
  "20v5" = "../input/nyc_mappluto_20v5_arc_shp.zip",
  "20v6" = "../input/nyc_mappluto_20v6_arc_shp.zip",
  "20v7" = "../input/nyc_mappluto_20v7_arc_shp.zip",
  "20v8" = "../input/nyc_mappluto_20v8_arc_shp.zip",
  "21v1" = "../input/nyc_mappluto_21v1_arc_shp.zip",
  "21v3" = "../input/nyc_mappluto_21v3_arc_shp.zip",
  "22v1" = "../input/nyc_mappluto_22v1_arc_shp.zip",
  "22v2" = "../input/nyc_mappluto_22v2_arc_shp.zip",
  "23v1" = "../input/nyc_mappluto_23v1_arc_shp.zip",
  "23v1_1" = "../input/nyc_mappluto_23v1_1_arc_shp.zip",
  "23v1_2" = "../input/nyc_mappluto_23v1_2_arc_shp.zip",
  "23v2" = "../input/nyc_mappluto_23v2_arc_shp.zip",
  "23v3" = "../input/nyc_mappluto_23v3_arc_shp.zip",
  "23v3_1" = "../input/nyc_mappluto_23v3_1_arc_shp.zip"
)

maps <- list()
for (vintage in names(archives)) {
  message("Searching filing lots: ", vintage)
  archive <- archives[[vintage]]
  members <- unzip(archive, list = TRUE)$Name
  shape <- members[str_detect(members, regex("(^|/)MapPLUTO\\.shp$", ignore_case = TRUE))]
  stopifnot(length(shape) == 1L)
  files <- members[tools::file_path_sans_ext(members) == tools::file_path_sans_ext(shape)]
  directory <- paste0("../temp/filing_map_", vintage)
  status <- system2("unzip", c("-oq", shQuote(archive), shQuote(files), "-d", shQuote(directory)))
  stopifnot(status == 0L)
  layer <- tools::file_path_sans_ext(basename(shape))
  lots <- st_read(file.path(directory, shape), quiet = TRUE,
    query = paste0("SELECT BBL AS bbl, LotArea AS recorded_area_sqft FROM ", layer,
                   " WHERE BBL IN (", paste(wanted, collapse = ","), ")"))
  stopifnot(!anyDuplicated(lots$bbl), st_crs(lots)$epsg == 2263)
  lots$source_valid <- st_is_valid(lots)
  lots <- st_make_valid(lots)
  stopifnot(all(st_is_valid(lots)), !any(st_is_empty(lots)))
  maps[[vintage]] <- lots |>
    mutate(vintage, bbl = sprintf("%.0f", bbl), geometry_area_sqft = as.numeric(st_area(lots)),
           wkt = st_as_text(st_geometry(lots), digits = 17)) |>
    st_drop_geometry() |>
    select(vintage, bbl, recorded_area_sqft, source_valid, geometry_area_sqft, wkt)
  unlink(directory, recursive = TRUE)
}
maps <- bind_rows(maps) |> arrange(vintage, bbl)
stopifnot(setequal(maps$vintage, names(archives)), all(maps$geometry_area_sqft > 0))
SaveData(maps, c("vintage", "bbl"), "../output/dof_filing_map_lots.parquet")

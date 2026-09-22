# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)
library(stringr)
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/dof_parent_coverage.csv", show_col_types = FALSE) |>
  filter(composition_eligible)
parcels <- read_parquet("../output/dof_parent_parcels.parquet") |>
  semi_join(parents, by = "parent_id")
condos <- read_parquet("../output/dof_condo_links.parquet") |> filter(valid_bbl)
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id))

# Read the later filing parcels and all possible condominium base lots. Their
# IDs only limit this read; earlier overlaps are found by location, not BBL.
filing_bbls <- unique(unlist(strsplit(parents$filing_bbls, ";")))
later_bbls <- union(filing_bbls, condos$base_bbl[condos$filing_bbl %in% filing_bbls])
# MapPLUTO often draws a condominium under its billing BBL, not its base BBL.
later_bbls <- union(later_bbls, condos$filing_bbl[condos$base_bbl %in% later_bbls &
  as.integer(substr(condos$filing_bbl, 7, 10)) >= 7500])
archives <- c(
  "25v4" = "../input/nyc_mappluto_25v4_shp.zip",
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
  "23v3_1" = "../input/nyc_mappluto_23v3_1_arc_shp.zip"
)
# The four parents using the tabular PLUTO 18v1 release have no same-release
# polygon archive. Retain that geometry gap instead of substituting another map.
stopifnot(setequal(setdiff(unique(parcels$vintage), "18v1"), setdiff(names(archives), "25v4")))

# Extract one shapefile at a time for fast indexed reads of its large DBF.
# All archives use the shoreline-clipped MapPLUTO layer and feet (EPSG:2263).
maps <- list()
for (vintage in names(archives)) {
  message("Reading parcel geometry: ", vintage)
  archive <- archives[[vintage]]
  members <- unzip(archive, list = TRUE)$Name
  shape <- members[str_detect(members, regex("(^|/)MapPLUTO\\.shp$", ignore_case = TRUE))]
  stopifnot(length(shape) == 1L)
  stem <- tools::file_path_sans_ext(shape)
  files <- members[tools::file_path_sans_ext(members) == stem]
  directory <- paste0("../temp/geometry_", vintage)
  # System unzip supports the Deflate64 compression in some city archives.
  status <- system2("unzip", c("-oq", shQuote(archive), shQuote(files), "-d", shQuote(directory)))
  stopifnot(status == 0L)
  layer <- tools::file_path_sans_ext(basename(shape))
  query <- paste0("SELECT BBL AS bbl, LotArea AS recorded_area_sqft FROM ", layer)

  if (vintage == "25v4") {
    lots <- st_read(file.path(directory, shape),
      query = paste0(query, " WHERE BBL IN (", paste(later_bbls, collapse = ","), ")"), quiet = TRUE)
    search_boundary <- st_as_text(st_union(st_buffer(st_make_valid(st_geometry(lots)), 25)))
  } else {
    # The spatial search includes neighboring blocks and reused lot identifiers.
    nearby <- st_read(file.path(directory, shape), query = query,
                      wkt_filter = search_boundary, quiet = TRUE)
    wanted <- unique(parcels$bbl[parcels$vintage == vintage])
    referenced <- st_read(file.path(directory, shape),
      query = paste0(query, " WHERE BBL IN (", paste(wanted, collapse = ","), ")"), quiet = TRUE)
    # Both reads select the same source layer; keep one copy of repeated BBLs.
    lots <- bind_rows(referenced, nearby |> filter(!bbl %in% referenced$bbl))
  }
  stopifnot(!anyDuplicated(lots$bbl), st_crs(lots)$epsg == 2263)
  # Rebuild sf's geometry metadata after combining reads; WKB preserves every
  # coordinate. This avoids malformed sf metadata reaching the GEOS validator.
  st_geometry(lots) <- st_as_sfc(st_as_binary(st_geometry(lots)), crs = 2263)
  lots$source_valid <- st_is_valid(lots)
  lots$source_geometry_sqft <- as.numeric(st_area(lots))
  lots <- st_make_valid(lots)
  stopifnot(all(st_is_valid(lots)), !any(st_is_empty(lots)))
  maps[[vintage]] <- lots |>
    mutate(vintage, bbl = sprintf("%.0f", bbl),
           geometry_area_sqft = as.numeric(st_area(lots)),
           wkt = st_as_text(st_geometry(lots), digits = 17)) |>
    st_drop_geometry() |>
    select(vintage, bbl, recorded_area_sqft, source_valid,
           source_geometry_sqft, geometry_area_sqft, wkt)
  unlink(directory, recursive = TRUE)
}
geometry <- bind_rows(maps) |> arrange(vintage, bbl)
stopifnot(!anyDuplicated(geometry[c("vintage", "bbl")]), all(geometry$geometry_area_sqft > 0))
SaveData(geometry, c("vintage", "bbl"), "../output/dof_geometry_lots.parquet")

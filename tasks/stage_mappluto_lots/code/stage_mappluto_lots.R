# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_mappluto_lots/code")
# source_id <- "dcp_pluto_archive"
# vintage <- "18v1"

args <- commandArgs(trailingOnly = TRUE)
if (!interactive()) {
  stopifnot(length(args) == 2L)
  source_id <- args[1]
  vintage <- args[2]
}

suppressPackageStartupMessages({
  library(dplyr)
  library(foreign)
  library(readr)
  library(stringr)
  library(tibble)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# One parcel table per release: PLUTO releases ship CSV tables, MapPLUTO
# releases a shapefile whose attribute table is read from its DBF.
release <- read_csv("../input/source_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  filter(.data$source_id == .env$source_id, sanitize_file_stub(.data$vintage) == sanitize_file_stub(.env$vintage))
stopifnot(nrow(release) == 1L)
zip_path <- file.path("../input", basename(release$raw_path))

# Kept fields, with the alternative names some releases use.
fields <- c("bbl", "borough", "block", "lot", "address", "cd", "zipcode", "ct2010", "cb2010", "schooldist",
  "council", "zonedist1", "zonedist2", "zonedist3", "zonedist4", "overlay1", "overlay2", "spdist1",
  "spdist2", "spdist3", "ltdheight", "splitzone", "zonemap", "zmcode", "lotarea", "unitsres",
  "unitstotal", "comarea", "yearbuilt", "yearalter1", "yearalter2", "bldgarea", "resarea",
  "officearea", "retailarea", "garagearea", "strgearea", "factryarea", "otherarea", "areasource",
  "numbldgs", "numfloors", "lotfront", "lotdepth", "bldgfront", "bldgdepth", "appdate", "assessland",
  "assesstot", "exempttot", "histdist", "landmark", "builtfar", "maxallwfar", "residfar", "commfar",
  "facilfar", "firm07_flag", "pfirm15_flag", "landuse", "bldgclass")
alternative_names <- list(borough = c("borough", "boro_code", "borocode"),
  zipcode = c("zipcode", "zip_code", "zip"), ct2010 = c("ct2010", "tract2010"),
  schooldist = c("schooldist", "school_dist"))
csv_columns <- c("Borough", "BoroCode", "Block", "Lot", "BBL", "Address", "CD", "ZipCode", "CT2010",
  "Tract2010", "CT2000", "CB2010", "CB2000", "SchoolDist", "Council", "ZoneDist1", "ZoneDist2",
  "ZoneDist3", "ZoneDist4", "Overlay1", "Overlay2", "SPDist1", "SPDist2", "SPDist3", "LtdHeight",
  "SplitZone", "ZoneMap", "ZMCode", "LotArea", "UnitsRes", "UnitsTotal", "ComArea", "YearBuilt",
  "YearAlter1", "YearAlter2", "BldgArea", "ResArea", "OfficeArea", "RetailArea", "GarageArea",
  "StrgeArea", "FactryArea", "OtherArea", "AreaSource", "NumBldgs", "NumFloors", "LotFront", "LotDepth",
  "BldgFront", "BldgDepth", "APPDate", "AssessLand", "AssessTot", "ExemptTot", "HistDist", "Landmark",
  "BuiltFAR", "MaxAllwFAR", "ResidFAR", "CommFAR", "FacilFAR", "FIRM07_FLAG", "PFIRM15_FLAG", "LandUse",
  "BldgClass")

unzip_dir <- tempfile(pattern = "mappluto_")
dir.create(unzip_dir)
listing <- system2("unzip", c("-Z1", zip_path), stdout = TRUE)
tables <- listing[str_detect(tolower(listing), "\\.(csv|txt)$") &
  !str_detect(tolower(basename(listing)), "change|dictionary|readme|layout|lay|dates")]
stopifnot(!anyDuplicated(basename(tables)))
if (length(tables) > 0) {
  stopifnot(system2("unzip", c("-oj", zip_path, tables, "-d", unzip_dir), stdout = FALSE) == 0)
  pluto <- bind_rows(lapply(file.path(unzip_dir, basename(tables)), function(path) {
    header <- names(data.table::fread(path, nrows = 0L, showProgress = FALSE))
    data.table::fread(path, select = intersect(csv_columns, header), colClasses = "character",
      fill = TRUE, showProgress = FALSE) |>
      as_tibble()
  }))
} else {
  dbf <- listing[str_detect(tolower(listing), "\\.dbf$")][1]
  stopifnot(!is.na(dbf), system2("unzip", c("-oj", zip_path, dbf, "-d", unzip_dir), stdout = FALSE) == 0)
  pluto <- as_tibble(read.dbf(file.path(unzip_dir, basename(dbf)), as.is = TRUE))
}
unlink(unzip_dir, recursive = TRUE)
names(pluto) <- normalize_names(names(pluto))

lots <- as_tibble(lapply(setNames(fields, fields), function(field) {
  pick_first_existing(pluto, alternative_names[[field]] %||% field)
}))

text_field <- function(x) {
  out <- trimws(as.character(x))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  out
}
integer_field <- function(x) suppressWarnings(as.integer(text_field(x)))
numeric_field <- function(x) suppressWarnings(as.numeric(text_field(x)))
year_field <- function(x) {
  year <- integer_field(x)
  year[year < 1800L] <- NA_integer_
  year
}

# A valid recorded BBL is kept; otherwise it is built from borough, block and lot.
lots <- lots |>
  mutate(
    source_id = release$source_id, source_vintage = release$vintage, source_raw_path = release$raw_path,
    borough = standardize_borough_code(borough),
    across(c(block, lot, cd, schooldist, council, numbldgs), integer_field),
    bbl = if_else(str_detect(coalesce(text_field(bbl), ""), "^[1-5][0-9]{9}$"), text_field(bbl),
      build_bbl(borough, block, lot)),
    across(c(address, zipcode, ct2010, cb2010, zonedist1:zmcode, areasource, histdist, landmark,
      firm07_flag, pfirm15_flag, landuse, bldgclass), text_field),
    across(c(lotarea, bldgarea, comarea, resarea, officearea:otherarea, numfloors, unitsres, unitstotal,
      lotfront:bldgdepth, assessland:exempttot, builtfar:facilfar), numeric_field),
    across(c(yearbuilt, yearalter1, yearalter2), year_field),
    appdate = parse_mixed_date(appdate)
  ) |>
  select(source_id, source_vintage, source_raw_path, all_of(fields))

SaveData(lots, "bbl", paste0("../output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), ".parquet"),
  require_unique = FALSE)

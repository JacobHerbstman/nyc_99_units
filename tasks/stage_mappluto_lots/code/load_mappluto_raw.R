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
  library(sf)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")

mappluto_files <- read_csv("../input/source_files.csv", show_col_types = FALSE, na = c("", "NA"))

delimited_pluto_columns <- c(
  "Borough", "BoroCode", "Block", "Lot", "BBL", "Address", "CD", "ZipCode",
  "CT2010", "Tract2010", "CT2000", "CB2010", "CB2000", "SchoolDist", "Council",
  "ZoneDist1", "ZoneDist2", "ZoneDist3", "ZoneDist4", "Overlay1", "Overlay2",
  "SPDist1", "SPDist2", "SPDist3", "LtdHeight", "SplitZone", "ZoneMap", "ZMCode",
  "LotArea", "UnitsRes", "UnitsTotal", "ComArea", "YearBuilt", "YearAlter1",
  "YearAlter2", "BldgArea", "ResArea", "OfficeArea", "RetailArea", "GarageArea",
  "StrgeArea", "FactryArea", "OtherArea", "AreaSource", "NumBldgs", "NumFloors",
  "LotFront", "LotDepth", "BldgFront", "BldgDepth", "APPDate", "AssessLand",
  "AssessTot", "ExemptTot", "HistDist", "Landmark", "BuiltFAR", "MaxAllwFAR",
  "ResidFAR", "CommFAR", "FacilFAR", "FIRM07_FLAG", "PFIRM15_FLAG", "LandUse",
  "BldgClass"
)

row <- mappluto_files |>
  filter(.data$source_id == .env$source_id, sanitize_file_stub(.data$vintage) == sanitize_file_stub(.env$vintage))
stopifnot(nrow(row) == 1L)
raw_path <- file.path("../input", basename(row$raw_path))
stopifnot(grepl("[.]zip$", raw_path))

read_path <- raw_path
read_mode <- if (str_detect(tolower(raw_path), "\\.gpkg$")) "gpkg" else "dbf"
temp_dir <- NULL

if (str_detect(raw_path, "\\.zip$")) {
  temp_dir <- tempfile(pattern = "mappluto_")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  zip_listing <- suppressWarnings(system2("unzip", c("-Z1", raw_path), stdout = TRUE, stderr = FALSE))
  table_entries <- zip_listing[str_detect(tolower(zip_listing), "\\.(csv|txt)$")]
  table_entries <- table_entries[!str_detect(tolower(basename(table_entries)), "change|dictionary|readme|layout|lay|dates")]
  if (anyDuplicated(basename(table_entries)) > 0) {
    stop("PLUTO zip contains duplicate selected table basenames; unzip -oj would overwrite files in ", raw_path)
  }
  dbf_entry <- zip_listing[str_detect(tolower(zip_listing), "\\.dbf$")][1]
  gpkg_entry <- zip_listing[str_detect(tolower(zip_listing), "\\.gpkg$")][1]

  if (length(table_entries) > 0) {
    unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, table_entries, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
    if (!identical(unzip_status, 0L)) {
      stop("System unzip failed for PLUTO table files in ", raw_path)
    }
    read_path <- file.path(temp_dir, basename(table_entries))
    read_mode <- "delimited"
  } else if (!is.na(dbf_entry) && nzchar(dbf_entry)) {
    unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, dbf_entry, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
    if (!identical(unzip_status, 0L)) {
      stop("System unzip failed for DBF in ", raw_path)
    }
    read_path <- file.path(temp_dir, basename(dbf_entry))
    read_mode <- "dbf"
  } else if (!is.na(gpkg_entry) && nzchar(gpkg_entry)) {
    unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, gpkg_entry, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
    if (!identical(unzip_status, 0L)) {
      stop("System unzip failed for GPKG in ", raw_path)
    }
    read_path <- file.path(temp_dir, basename(gpkg_entry))
    read_mode <- "gpkg"
  } else {
    stop("No .csv, .txt, .dbf, or .gpkg found in ", raw_path)
  }
}

pluto <- if (read_mode == "dbf") {
  read.dbf(read_path, as.is = TRUE) |>
    as_tibble()
} else if (read_mode == "delimited") {
  bind_rows(lapply(read_path, function(path) {
    available_columns <- names(data.table::fread(
      path,
      nrows = 0L,
      showProgress = FALSE
    ))
    selected_columns <- intersect(
      delimited_pluto_columns,
      available_columns
    )
    data.table::fread(
      path,
      select = selected_columns,
      colClasses = "character",
      fill = TRUE,
      showProgress = FALSE
    ) |>
      as_tibble()
  }))
} else {
  st_read(read_path, quiet = TRUE, stringsAsFactors = FALSE) |>
    st_drop_geometry() |>
    as_tibble()
}

names(pluto) <- normalize_names(names(pluto))

has_bbl <- "bbl" %in% names(pluto)
has_borough_block_lot <- all(c("borough", "block", "lot") %in% names(pluto)) ||
  all(c("boro_code", "block", "lot") %in% names(pluto)) ||
  all(c("borocode", "block", "lot") %in% names(pluto))

if (!has_bbl && !has_borough_block_lot) {
  stop("PLUTO table lacks BBL and borough/block/lot identifier columns in ", raw_path)
}

lot_table <- tibble(
  bbl = pick_first_existing(pluto, c("bbl")),
  borough = pick_first_existing(pluto, c("borough", "boro_code", "borocode")),
  block = pick_first_existing(pluto, c("block")),
  lot = pick_first_existing(pluto, c("lot")),
  address = pick_first_existing(pluto, c("address")),
  cd = pick_first_existing(pluto, c("cd")),
  zipcode = pick_first_existing(pluto, c("zipcode", "zip_code", "zip")),
  ct2010 = pick_first_existing(pluto, c("ct2010", "tract2010")),
  cb2010 = pick_first_existing(pluto, c("cb2010")),
  schooldist = pick_first_existing(pluto, c("schooldist", "school_dist")),
  council = pick_first_existing(pluto, c("council")),
  zonedist1 = pick_first_existing(pluto, c("zonedist1")),
  zonedist2 = pick_first_existing(pluto, c("zonedist2")),
  zonedist3 = pick_first_existing(pluto, c("zonedist3")),
  zonedist4 = pick_first_existing(pluto, c("zonedist4")),
  overlay1 = pick_first_existing(pluto, c("overlay1")),
  overlay2 = pick_first_existing(pluto, c("overlay2")),
  spdist1 = pick_first_existing(pluto, c("spdist1")),
  spdist2 = pick_first_existing(pluto, c("spdist2")),
  spdist3 = pick_first_existing(pluto, c("spdist3")),
  ltdheight = pick_first_existing(pluto, c("ltdheight")),
  splitzone = pick_first_existing(pluto, c("splitzone")),
  zonemap = pick_first_existing(pluto, c("zonemap")),
  zmcode = pick_first_existing(pluto, c("zmcode")),
  lotarea = pick_first_existing(pluto, c("lotarea")),
  unitsres = pick_first_existing(pluto, c("unitsres")),
  unitstotal = pick_first_existing(pluto, c("unitstotal")),
  comarea = pick_first_existing(pluto, c("comarea")),
  yearbuilt = pick_first_existing(pluto, c("yearbuilt")),
  yearalter1 = pick_first_existing(pluto, c("yearalter1")),
  yearalter2 = pick_first_existing(pluto, c("yearalter2")),
  bldgarea = pick_first_existing(pluto, c("bldgarea")),
  resarea = pick_first_existing(pluto, c("resarea")),
  officearea = pick_first_existing(pluto, c("officearea")),
  retailarea = pick_first_existing(pluto, c("retailarea")),
  garagearea = pick_first_existing(pluto, c("garagearea")),
  strgearea = pick_first_existing(pluto, c("strgearea")),
  factryarea = pick_first_existing(pluto, c("factryarea")),
  otherarea = pick_first_existing(pluto, c("otherarea")),
  areasource = pick_first_existing(pluto, c("areasource")),
  numbldgs = pick_first_existing(pluto, c("numbldgs")),
  numfloors = pick_first_existing(pluto, c("numfloors")),
  lotfront = pick_first_existing(pluto, c("lotfront")),
  lotdepth = pick_first_existing(pluto, c("lotdepth")),
  bldgfront = pick_first_existing(pluto, c("bldgfront")),
  bldgdepth = pick_first_existing(pluto, c("bldgdepth")),
  appdate = pick_first_existing(pluto, c("appdate")),
  assessland = pick_first_existing(pluto, c("assessland")),
  assesstot = pick_first_existing(pluto, c("assesstot")),
  exempttot = pick_first_existing(pluto, c("exempttot")),
  histdist = pick_first_existing(pluto, c("histdist")),
  landmark = pick_first_existing(pluto, c("landmark")),
  builtfar = pick_first_existing(pluto, c("builtfar")),
  maxallwfar = pick_first_existing(pluto, c("maxallwfar")),
  residfar = pick_first_existing(pluto, c("residfar")),
  commfar = pick_first_existing(pluto, c("commfar")),
  facilfar = pick_first_existing(pluto, c("facilfar")),
  firm07_flag = pick_first_existing(pluto, c("firm07_flag")),
  pfirm15_flag = pick_first_existing(pluto, c("pfirm15_flag")),
  landuse = pick_first_existing(pluto, c("landuse")),
  bldgclass = pick_first_existing(pluto, c("bldgclass"))
)

missing_bbl <- is.na(lot_table$bbl)
lot_table$bbl[missing_bbl] <- build_bbl(lot_table$borough, lot_table$block, lot_table$lot)[missing_bbl]

lot_table <- lot_table |>
  mutate(source_id = row$source_id, source_vintage = row$vintage, source_raw_path = row$raw_path) |>
  select(source_id, source_vintage, source_raw_path, everything())
write_parquet_atomic(lot_table, paste0("../output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), "_raw.parquet"))
unlink(temp_dir, recursive = TRUE)

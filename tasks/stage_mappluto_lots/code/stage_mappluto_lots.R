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
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

mappluto_files <- read_csv("../input/source_files.csv", show_col_types = FALSE)

normalize_text_field <- function(x) {
  out <- trimws(as.character(x))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  out
}

normalize_integer_field <- function(x) {
  suppressWarnings(as.integer(normalize_text_field(x)))
}

normalize_numeric_field <- function(x) {
  suppressWarnings(as.numeric(normalize_text_field(x)))
}

normalize_year_field <- function(x) {
  x_int <- normalize_integer_field(x)
  x_int[x_int == 0L] <- NA_integer_
  x_int[x_int < 1800L] <- NA_integer_
  x_int
}

row <- mappluto_files |>
  filter(.data$source_id == .env$source_id, sanitize_file_stub(.data$vintage) == sanitize_file_stub(.env$vintage))
stopifnot(nrow(row) == 1L)

lot_table <- read_parquet(paste0("../output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), "_raw.parquet")) |>
  mutate(
    source_id = as.character(source_id),
    source_vintage = as.character(source_vintage),
    source_raw_path = as.character(source_raw_path),
    borough = standardize_borough_code(borough),
    block = normalize_integer_field(block),
    lot = normalize_integer_field(lot),
    bbl_raw = normalize_text_field(bbl),
    bbl_built = build_bbl(borough, block, lot),
    bbl = if_else(!is.na(bbl_raw) & str_detect(bbl_raw, "^[1-5][0-9]{9}$"), bbl_raw, bbl_built),
    address = normalize_text_field(address),
    cd = normalize_integer_field(cd),
    zipcode = normalize_text_field(zipcode),
    ct2010 = normalize_text_field(ct2010),
    cb2010 = normalize_text_field(cb2010),
    schooldist = normalize_integer_field(schooldist),
    council = normalize_integer_field(council),
    zonedist1 = normalize_text_field(zonedist1),
    zonedist2 = normalize_text_field(zonedist2),
    zonedist3 = normalize_text_field(zonedist3),
    zonedist4 = normalize_text_field(zonedist4),
    overlay1 = normalize_text_field(overlay1),
    overlay2 = normalize_text_field(overlay2),
    spdist1 = normalize_text_field(spdist1),
    spdist2 = normalize_text_field(spdist2),
    spdist3 = normalize_text_field(spdist3),
    ltdheight = normalize_text_field(ltdheight),
    splitzone = normalize_text_field(splitzone),
    zonemap = normalize_text_field(zonemap),
    zmcode = normalize_text_field(zmcode),
    lotarea = normalize_numeric_field(lotarea),
    bldgarea = normalize_numeric_field(bldgarea),
    comarea = normalize_numeric_field(comarea),
    resarea = normalize_numeric_field(resarea),
    officearea = normalize_numeric_field(officearea),
    retailarea = normalize_numeric_field(retailarea),
    garagearea = normalize_numeric_field(garagearea),
    strgearea = normalize_numeric_field(strgearea),
    factryarea = normalize_numeric_field(factryarea),
    otherarea = normalize_numeric_field(otherarea),
    areasource = normalize_text_field(areasource),
    numbldgs = normalize_integer_field(numbldgs),
    numfloors = normalize_numeric_field(numfloors),
    unitsres = normalize_numeric_field(unitsres),
    unitstotal = normalize_numeric_field(unitstotal),
    lotfront = normalize_numeric_field(lotfront),
    lotdepth = normalize_numeric_field(lotdepth),
    bldgfront = normalize_numeric_field(bldgfront),
    bldgdepth = normalize_numeric_field(bldgdepth),
    yearbuilt = normalize_year_field(yearbuilt),
    yearalter1 = normalize_year_field(yearalter1),
    yearalter2 = normalize_year_field(yearalter2),
    appdate = parse_mixed_date(appdate),
    assessland = normalize_numeric_field(assessland),
    assesstot = normalize_numeric_field(assesstot),
    exempttot = normalize_numeric_field(exempttot),
    histdist = normalize_text_field(histdist),
    landmark = normalize_text_field(landmark),
    builtfar = normalize_numeric_field(builtfar),
    maxallwfar = normalize_numeric_field(maxallwfar),
    residfar = normalize_numeric_field(residfar),
    commfar = normalize_numeric_field(commfar),
    facilfar = normalize_numeric_field(facilfar),
    firm07_flag = normalize_text_field(firm07_flag),
    pfirm15_flag = normalize_text_field(pfirm15_flag),
    landuse = normalize_text_field(landuse),
    bldgclass = normalize_text_field(bldgclass)
  ) |>
  select(-bbl_raw, -bbl_built)

SaveData(
  lot_table,
  "bbl",
  paste0("../output/", sanitize_file_stub(paste(source_id, vintage, sep = "_")), ".parquet"),
  require_unique = FALSE
)

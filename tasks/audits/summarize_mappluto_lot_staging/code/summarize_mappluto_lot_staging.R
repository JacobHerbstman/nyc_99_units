# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_mappluto_lot_staging/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))

required_columns <- c("source_id", "vintage", "parquet_path")
missing_columns <- setdiff(required_columns, names(mappluto_lot_files))

if (length(missing_columns) > 0) {
  stop("MapPLUTO lot index is missing required columns: ", paste(missing_columns, collapse = ", "))
}

jia_codes <- c(164L, 226L, 227L, 228L, 355L, 356L, 480L, 481L, 482L, 483L, 484L, 595L)
current_year <- as.integer(format(Sys.Date(), "%Y"))

field_nonmissing_share <- function(data, field) {
  if (!field %in% names(data)) {
    return(NA_real_)
  }

  mean(!is.na(data[[field]]))
}

safe_min_int <- function(x) {
  x <- suppressWarnings(as.integer(x))
  if (all(is.na(x))) {
    return(NA_integer_)
  }

  min(x, na.rm = TRUE)
}

safe_max_int <- function(x) {
  x <- suppressWarnings(as.integer(x))
  if (all(is.na(x))) {
    return(NA_integer_)
  }

  max(x, na.rm = TRUE)
}

if (nrow(mappluto_lot_files) == 0) {
  write_csv(tibble(), "../output/mappluto_lot_staging_qc.csv", na = "")
  quit(save = "no")
}

qc_rows <- list()

for (i in seq_len(nrow(mappluto_lot_files))) {
  row <- mappluto_lot_files[i, ]
  parquet_path <- file.path("..", "..", "..", "stage_mappluto_lots", "output", basename(as.character(row$parquet_path)))

  if (!file.exists(parquet_path)) {
    qc_rows[[i]] <- tibble(
      source_id = as.character(row$source_id),
      vintage = as.character(row$vintage),
      parquet_path = parquet_path,
      status = "missing_parquet",
      row_count = NA_integer_,
      nonmissing_bbl_share = NA_real_,
      unique_bbl_count = NA_integer_,
      duplicate_bbl_count = NA_integer_,
      nonmissing_lotarea_share = NA_real_,
      zero_or_negative_lotarea_count = NA_integer_,
      nonmissing_zonedist1_share = NA_real_,
      nonmissing_residfar_share = NA_real_,
      nonmissing_builtfar_share = NA_real_,
      nonmissing_unitsres_share = NA_real_,
      nonmissing_yearbuilt_share = NA_real_,
      nonmissing_cd_share = NA_real_,
      min_yearbuilt = NA_integer_,
      max_yearbuilt = NA_integer_,
      future_yearbuilt_count = NA_integer_,
      ordinary_cd_rows = NA_integer_,
      joint_interest_area_rows = NA_integer_
    )

    next
  }

  lot_table <- read_parquet(parquet_path) |>
    as.data.frame() |>
    as_tibble()

  bbl_values <- if ("bbl" %in% names(lot_table)) lot_table$bbl[!is.na(lot_table$bbl)] else character()
  lotarea_values <- if ("lotarea" %in% names(lot_table)) suppressWarnings(as.numeric(lot_table$lotarea)) else numeric()
  yearbuilt_values <- if ("yearbuilt" %in% names(lot_table)) suppressWarnings(as.integer(lot_table$yearbuilt)) else integer()
  cd_values <- if ("cd" %in% names(lot_table)) suppressWarnings(as.integer(lot_table$cd)) else integer()

  qc_rows[[i]] <- tibble(
    source_id = as.character(row$source_id),
    vintage = as.character(row$vintage),
    parquet_path = parquet_path,
    status = "summarized",
    row_count = nrow(lot_table),
    nonmissing_bbl_share = field_nonmissing_share(lot_table, "bbl"),
    unique_bbl_count = length(unique(bbl_values)),
    duplicate_bbl_count = sum(duplicated(bbl_values)),
    nonmissing_lotarea_share = field_nonmissing_share(lot_table, "lotarea"),
    zero_or_negative_lotarea_count = sum(!is.na(lotarea_values) & lotarea_values <= 0),
    nonmissing_zonedist1_share = field_nonmissing_share(lot_table, "zonedist1"),
    nonmissing_residfar_share = field_nonmissing_share(lot_table, "residfar"),
    nonmissing_builtfar_share = field_nonmissing_share(lot_table, "builtfar"),
    nonmissing_unitsres_share = field_nonmissing_share(lot_table, "unitsres"),
    nonmissing_yearbuilt_share = field_nonmissing_share(lot_table, "yearbuilt"),
    nonmissing_cd_share = field_nonmissing_share(lot_table, "cd"),
    min_yearbuilt = safe_min_int(yearbuilt_values),
    max_yearbuilt = safe_max_int(yearbuilt_values),
    future_yearbuilt_count = sum(yearbuilt_values > current_year, na.rm = TRUE),
    ordinary_cd_rows = sum(!is.na(cd_values) & !(cd_values %in% jia_codes)),
    joint_interest_area_rows = sum(!is.na(cd_values) & cd_values %in% jia_codes)
  )
}

write_csv(bind_rows(qc_rows), "../output/mappluto_lot_staging_qc.csv", na = "")
cat("Wrote MapPLUTO lot staging QC to ../output/mappluto_lot_staging_qc.csv\n")

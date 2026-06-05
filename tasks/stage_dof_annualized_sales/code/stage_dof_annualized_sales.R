# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dof_annualized_sales/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(readxl)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

parse_dof_number <- function(x) {
  raw_value <- str_squish(as.character(x))
  raw_value[raw_value == ""] <- NA_character_
  parse_number(raw_value, na = c("", "NA", "N/A", "-"))
}

parse_dof_sales_date <- function(x) {
  raw_value <- str_squish(as.character(x))
  raw_value[raw_value == ""] <- NA_character_
  numeric_value <- suppressWarnings(as.numeric(raw_value))
  out <- rep(as.Date(NA), length(raw_value))
  excel_date <- !is.na(numeric_value) & numeric_value >= 20000 & numeric_value <= 60000
  out[excel_date] <- as.Date(numeric_value[excel_date], origin = "1899-12-30")
  out[!excel_date] <- parse_mixed_date(raw_value[!excel_date])
  out
}

sales_file_index <- read_csv("../input/dof_annualized_sales_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  filter(file_role == "detailed_annualized_sales_xlsx", file.exists(raw_path)) |>
  arrange(year, borough)

if (nrow(sales_file_index) == 0) {
  stop("No downloaded DOF annualized sales files are available to stage.")
}

sale_rows <- list()
file_rows <- list()

for (i in seq_len(nrow(sales_file_index))) {
  raw_preview <- read_excel(
    sales_file_index$raw_path[i],
    sheet = 1,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "minimal"
  )

  header_row <- which(str_to_upper(str_squish(as.character(raw_preview[[1]]))) == "BOROUGH")[1]

  if (is.na(header_row)) {
    file_rows[[i]] <- sales_file_index[i, ] |>
      mutate(rows = 0L, status = "header_not_found")
    next
  }

  sales_raw <- read_excel(
    sales_file_index$raw_path[i],
    sheet = 1,
    skip = header_row - 1L,
    col_types = "text",
    .name_repair = "minimal"
  )
  names(sales_raw) <- normalize_names(names(sales_raw))

  if (!("tax_class_at_present" %in% names(sales_raw))) {
    tax_class_present_candidates <- names(sales_raw)[str_starts(names(sales_raw), "tax_class_as_of_final_roll")]
    if (length(tax_class_present_candidates) > 0) {
      sales_raw$tax_class_at_present <- sales_raw[[tax_class_present_candidates[1]]]
    }
  }

  if (!("building_class_at_present" %in% names(sales_raw))) {
    building_class_present_candidates <- names(sales_raw)[str_starts(names(sales_raw), "building_class_as_of_final_roll")]
    if (length(building_class_present_candidates) > 0) {
      sales_raw$building_class_at_present <- sales_raw[[building_class_present_candidates[1]]]
    }
  }

  expected_columns <- c(
    "borough", "neighborhood", "building_class_category", "tax_class_at_present",
    "block", "lot", "building_class_at_present", "address", "zip_code",
    "residential_units", "commercial_units", "total_units", "land_square_feet",
    "gross_square_feet", "year_built", "tax_class_at_time_of_sale",
    "building_class_at_time_of_sale", "sale_price", "sale_date"
  )

  missing_columns <- setdiff(expected_columns, names(sales_raw))

  if (length(missing_columns) > 0) {
    file_rows[[i]] <- sales_file_index[i, ] |>
      mutate(rows = 0L, status = paste0("missing_columns:", paste(missing_columns, collapse = "|")))
    next
  }

  staged_rows <- sales_raw |>
    filter(!is.na(borough), str_to_upper(str_squish(as.character(borough))) != "BOROUGH") |>
    mutate(
      source_id = "dof_annualized_sales",
      vintage = as.character(sales_file_index$year[i]),
      source_year = suppressWarnings(as.integer(sales_file_index$year[i])),
      source_borough = sales_file_index$borough[i],
      source_raw_path = sales_file_index$raw_path[i],
      source_row_number = row_number(),
      borough_code = standardize_borough_code(borough),
      block_number = suppressWarnings(as.integer(parse_dof_number(block))),
      lot_number = suppressWarnings(as.integer(parse_dof_number(lot))),
      bbl = build_bbl(borough_code, block_number, lot_number),
      sale_date = parse_dof_sales_date(sale_date),
      sale_year = suppressWarnings(as.integer(format(sale_date, "%Y"))),
      sale_price = parse_dof_number(sale_price),
      residential_units = parse_dof_number(residential_units),
      commercial_units = parse_dof_number(commercial_units),
      total_units = parse_dof_number(total_units),
      land_square_feet = parse_dof_number(land_square_feet),
      gross_square_feet = parse_dof_number(gross_square_feet),
      year_built = suppressWarnings(as.integer(parse_dof_number(year_built))),
      zip_code = str_squish(as.character(zip_code)),
      address = str_squish(as.character(address)),
      neighborhood = str_squish(as.character(neighborhood)),
      building_class_category = str_squish(as.character(building_class_category)),
      tax_class_at_present = str_squish(as.character(tax_class_at_present)),
      building_class_at_present = str_squish(as.character(building_class_at_present)),
      tax_class_at_time_of_sale = str_squish(as.character(tax_class_at_time_of_sale)),
      building_class_at_time_of_sale = str_squish(as.character(building_class_at_time_of_sale)),
      valid_bbl = !is.na(bbl),
      positive_sale_price = !is.na(sale_price) & sale_price > 0,
      sale_date_in_source_year = !is.na(sale_year) & sale_year == source_year,
      sale_record_id = paste(source_year, source_borough, source_row_number, sep = "_")
    ) |>
    select(
      source_id, vintage, source_year, source_borough, source_raw_path, source_row_number, sale_record_id,
      bbl, valid_bbl, borough_code, block_number, lot_number,
      sale_date, sale_year, sale_date_in_source_year, sale_price, positive_sale_price,
      neighborhood, building_class_category, tax_class_at_present, building_class_at_present,
      address, zip_code, residential_units, commercial_units, total_units, land_square_feet,
      gross_square_feet, year_built, tax_class_at_time_of_sale, building_class_at_time_of_sale,
      everything()
    )

  sale_rows[[i]] <- staged_rows
  file_rows[[i]] <- sales_file_index[i, ] |>
    mutate(rows = nrow(staged_rows), status = "staged")
}

staged_sales <- bind_rows(sale_rows)
file_manifest <- bind_rows(file_rows) |>
  select(source_id, vintage, year, borough, file_role, file_name, raw_path, status, rows, official_url)

if (nrow(staged_sales) == 0) {
  stop("No DOF annualized sales rows were staged.")
}

if (anyDuplicated(staged_sales$sale_record_id) > 0) {
  stop("DOF annualized sales sale_record_id is not unique.")
}

if (sum(!is.na(staged_sales$bbl)) == 0) {
  stop("No staged DOF annualized sales rows have valid BBLs.")
}

write_parquet_if_changed(staged_sales, "../output/dof_annualized_sales.parquet")
write_csv_if_changed(file_manifest, "../output/dof_annualized_sales_files.csv")
cat("Staged DOF annualized sales to ../output\n")

suppressPackageStartupMessages({
  library(arrow)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
})

normalize_names <- function(x) {
  x <- tolower(x)
  x <- str_replace_all(x, "[^a-z0-9]+", "_")
  x <- str_replace_all(x, "^_|_$", "")
  x
}

pick_first_existing <- function(df, candidates) {
  hits <- candidates[candidates %in% names(df)]

  if (length(hits) == 0) {
    return(rep(NA_character_, nrow(df)))
  }

  as.character(df[[hits[1]]])
}

standardize_borough_code <- function(x) {
  raw_value <- str_to_upper(str_squish(as.character(x)))
  out <- rep(NA_character_, length(raw_value))

  out[raw_value %in% c("1", "MN", "MANHATTAN")] <- "1"
  out[raw_value %in% c("2", "BX", "BRONX")] <- "2"
  out[raw_value %in% c("3", "BK", "K", "BROOKLYN")] <- "3"
  out[raw_value %in% c("4", "QN", "Q", "QUEENS")] <- "4"
  out[raw_value %in% c("5", "SI", "R", "STATEN ISLAND")] <- "5"

  numeric_hits <- suppressWarnings(as.integer(str_extract(raw_value, "^[1-5]$")))
  out[!is.na(numeric_hits)] <- as.character(numeric_hits[!is.na(numeric_hits)])
  out
}

standardize_borough_name <- function(x) {
  borough_code <- standardize_borough_code(x)
  out <- rep(NA_character_, length(borough_code))

  out[borough_code == "1"] <- "Manhattan"
  out[borough_code == "2"] <- "Bronx"
  out[borough_code == "3"] <- "Brooklyn"
  out[borough_code == "4"] <- "Queens"
  out[borough_code == "5"] <- "Staten Island"
  out
}

build_bbl <- function(borough, block, lot) {
  borough_num <- suppressWarnings(as.integer(standardize_borough_code(borough)))
  block_num <- suppressWarnings(as.integer(as.character(block)))
  lot_num <- suppressWarnings(as.integer(as.character(lot)))

  valid <- !is.na(borough_num) & !is.na(block_num) & !is.na(lot_num)
  out <- rep(NA_character_, length(valid))
  out[valid] <- sprintf("%01d%05d%04d", borough_num[valid], block_num[valid], lot_num[valid])
  out
}

normalize_bbl_field <- function(x) {
  out <- str_squish(as.character(x))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_

  numeric_value <- suppressWarnings(as.numeric(out))
  numeric_bbl <- !is.na(numeric_value) & numeric_value >= 1000000000 & numeric_value < 6000000000
  out[numeric_bbl] <- sprintf("%.0f", numeric_value[numeric_bbl])
  out[!str_detect(out, "^[1-5][0-9]{9}$")] <- NA_character_
  out
}

combine_address <- function(house_number, street_name) {
  house_number <- str_squish(ifelse(is.na(house_number), "", as.character(house_number)))
  street_name <- str_squish(ifelse(is.na(street_name), "", as.character(street_name)))
  address <- str_squish(str_trim(paste(house_number, street_name)))
  address[address == ""] <- NA_character_
  address
}

standardize_community_district <- function(borough, raw_cd) {
  borough_num <- suppressWarnings(as.integer(standardize_borough_code(borough)))
  raw_char <- str_to_upper(str_squish(as.character(raw_cd)))
  raw_num <- suppressWarnings(as.integer(str_extract(raw_char, "[0-9]{1,3}")))
  out <- rep(NA_integer_, length(raw_num))

  out[!is.na(raw_num) & raw_num >= 101 & raw_num <= 595] <- raw_num[!is.na(raw_num) & raw_num >= 101 & raw_num <= 595]

  small_flag <- !is.na(raw_num) & raw_num >= 1 & raw_num <= 18 & !is.na(borough_num)
  out[small_flag] <- borough_num[small_flag] * 100L + raw_num[small_flag]

  out
}

standardize_council_district <- function(raw_value) {
  council_num <- suppressWarnings(as.integer(str_extract(as.character(raw_value), "[0-9]{1,2}")))
  council_num[!is.na(council_num) & (council_num < 1 | council_num > 51)] <- NA_integer_
  council_num
}

parse_mixed_date <- function(x, latest_date = as.Date("2027-09-09")) {
  raw_value <- str_squish(as.character(x))
  raw_value[raw_value == ""] <- NA_character_
  out <- rep(as.Date(NA), length(raw_value))

  ymd_flag <- !is.na(raw_value) & str_detect(raw_value, "^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}")
  mdy_flag <- !is.na(raw_value) & str_detect(raw_value, "^[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}")

  if (any(ymd_flag)) {
    out[ymd_flag] <- suppressWarnings(as.Date(parse_date_time(
      raw_value[ymd_flag],
      orders = c("ymd HMS", "ymd HM", "ymd"),
      tz = "America/New_York"
    )))
  }

  if (any(mdy_flag)) {
    out[mdy_flag] <- suppressWarnings(as.Date(parse_date_time(
      raw_value[mdy_flag],
      orders = c("mdy HMS", "mdy HM", "mdy"),
      tz = "America/New_York"
    )))
  }

  remaining_flag <- is.na(out) & !is.na(raw_value)

  if (any(remaining_flag)) {
    out[remaining_flag] <- suppressWarnings(as.Date(parse_date_time(
      raw_value[remaining_flag],
      orders = c(
        "ymd HMS", "ymd HM", "ymd",
        "mdy HMS", "mdy HM", "mdy",
        "Ymd HMS", "Ymd HM", "Ymd"
      ),
      tz = "America/New_York"
    )))
  }

  out[!is.na(out) & out > latest_date] <- NA
  out
}

publish_file <- function(temp_path, out_path) {
  if (!file.rename(temp_path, out_path)) stop("Could not publish output: ", out_path)
  invisible(TRUE)
}

write_csv_atomic <- function(df, out_path) {
  temp_path <- tempfile(tmpdir = dirname(out_path), fileext = ".csv")
  write_csv(df, temp_path, na = "")
  publish_file(temp_path, out_path)
}

# File stubs follow the same rule as column names.
sanitize_file_stub <- normalize_names

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")
# hdb_release <- "23Q4"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  hdb_release <- args[1]
}
stopifnot(hdb_release %in% c("23Q4", "25Q4"))

# Housing Database New Building filings from 2010 through the release's year.
if (hdb_release == "23Q4") {
  hdb <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet")
  end_date <- as.Date("2023-12-31")
} else {
  hdb <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |> mutate(historical_active = NA)
  end_date <- as.Date("2025-12-31")
}
stopifnot(all(hdb$release == hdb_release), !anyDuplicated(hdb$job_number))

filings <- hdb |>
  filter(job_type == "New Building", date_filed >= as.Date("2010-01-01"), date_filed <= end_date) |>
  transmute(job_number, hdb_release = release, historical_active, job_status, date_filed,
    filing_year = as.integer(format(date_filed, "%Y")), bbl = normalize_bbl_field(bbl), bin = as.character(bin),
    address, hdb_borough_name = borough_name, classa_prop,
    classa_prop_integer = !is.na(classa_prop) & classa_prop > 0 & abs(classa_prop - round(classa_prop)) < 1e-8,
    valid_bbl = str_detect(bbl, "^[1-5][0-9]{9}$"))

# Each filing uses the parcel release one before the latest release available
# strictly before its filing date, so its parcel attributes predate the filing.
calendar <- read_csv("../output/mappluto_release_calendar.csv", show_col_types = FALSE) |> arrange(release_order)
available <- findInterval(filings$date_filed, calendar$safe_available_date, left.open = TRUE)
stopifnot(all(available >= 2))
filings <- filings |>
  mutate(pluto_source_id_used = calendar$source_id[available - 1],
    pluto_version_used = calendar$vintage[available - 1],
    pluto_safe_available_date_used = calendar$safe_available_date[available - 1])

# A filing whose own lot is missing from its release may use the former lot
# recorded for it in PLUTO 25v4, when that lot is on the same block and
# appears exactly once in the release.
crosswalk <- read_csv("../output/mappluto_appbbl_crosswalk.csv", col_types = cols(current_bbl = col_character(),
  appbbl = col_character(), appdate = col_date(), same_boro_block = col_logical()))
filings <- filings |>
  left_join(crosswalk |> rename(bbl = current_bbl), by = "bbl", relationship = "many-to-one") |>
  mutate(appbbl = if_else(valid_bbl, appbbl, NA_character_),
    appbbl_future_appdate_used_for_linkage = coalesce(valid_bbl & appdate > date_filed, FALSE))

# Lots appearing more than once in a release are not matched.
lots <- bind_rows(lapply(unique(paste(filings$pluto_source_id_used, filings$pluto_version_used)), function(release) {
  source_id <- word(release, 1)
  vintage <- word(release, 2)
  needed <- filings |>
    filter(pluto_source_id_used == source_id, pluto_version_used == vintage)
  read_parquet(paste0("../input/", sanitize_file_stub(paste(source_id, vintage)), ".parquet"),
    col_select = c(bbl, cd, zonedist1, landuse, lotarea, bldgarea, unitsres, builtfar, maxallwfar, residfar,
      commfar, facilfar)) |>
    filter(bbl %in% c(needed$bbl[needed$valid_bbl], needed$appbbl[coalesce(needed$same_boro_block, FALSE)])) |>
    add_count(bbl, name = "release_rows") |>
    mutate(pluto_source_id_used = source_id, pluto_version_used = vintage)
}))
lot_status <- lots |> distinct(pluto_source_id_used, pluto_version_used, bbl, release_rows)

panel <- filings |>
  left_join(lot_status, by = c("pluto_source_id_used", "pluto_version_used", "bbl"), relationship = "many-to-one") |>
  left_join(lot_status |> rename(appbbl = bbl, appbbl_rows = release_rows),
    by = c("pluto_source_id_used", "pluto_version_used", "appbbl"), relationship = "many-to-one") |>
  mutate(appbbl_recovery_used = valid_bbl & is.na(release_rows) & coalesce(same_boro_block, FALSE) &
      coalesce(appbbl_rows == 1L, FALSE),
    pluto_feature_bbl = if_else(appbbl_recovery_used, appbbl, bbl)) |>
  select(-release_rows, -appbbl_rows) |>
  left_join(lots |> rename(pluto_feature_bbl = bbl) |> filter(release_rows == 1L) |> select(-release_rows),
    by = c("pluto_source_id_used", "pluto_version_used", "pluto_feature_bbl"), relationship = "many-to-one") |>
  left_join(lot_status |> rename(pluto_feature_bbl = bbl),
    by = c("pluto_source_id_used", "pluto_version_used", "pluto_feature_bbl"), relationship = "many-to-one") |>
  mutate(
    exclusion_reason = case_when(
      !valid_bbl ~ "invalid_bbl",
      !classa_prop_integer ~ "invalid_classa_prop",
      coalesce(release_rows > 1L, FALSE) ~ "duplicate_mappluto_bbl",
      is.na(release_rows) ~ "no_mappluto_match",
      is.na(lotarea) | lotarea <= 0 ~ "nonpositive_lotarea",
      TRUE ~ "included_primary_sample"),
    primary_leakage_safe_sample = exclusion_reason == "included_primary_sample") |>
  select(job_number, hdb_release, historical_active, job_status, date_filed, filing_year, bbl, bin, address,
    hdb_borough_name, classa_prop, classa_prop_integer, valid_bbl, pluto_source_id_used, pluto_version_used,
    pluto_safe_available_date_used, pluto_feature_bbl, appbbl_recovery_used,
    appbbl_future_appdate_used_for_linkage, primary_leakage_safe_sample, exclusion_reason, pluto_cd = cd,
    zonedist1, landuse, lotarea, bldgarea, unitsres, builtfar, maxallwfar, residfar, commfar, facilfar)
stopifnot(nrow(panel) == nrow(filings))

SaveData(panel, "job_number", if (hdb_release == "23Q4") "../output/historical_hdb_mappluto_site_panel.parquet" else
  "../output/hdb_mappluto_site_panel.parquet")

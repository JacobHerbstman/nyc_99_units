# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_historical_parent_links/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# The historical linkage universe: Housing Database 23Q4 New Building filings
# from 2010 through 2023 with at least six Class A units and a matched
# pre-filing parcel. Filings in an accepted manual link are kept even without
# land data, so a documented companion cannot drop out.
accepted_jobs <- read_csv("../input/pair_decisions.csv", col_types = cols(.default = col_character())) |>
  filter(sample == "historical", review_decision == "accept")
accepted_jobs <- unique(c(accepted_jobs$job_number_1, accepted_jobs$job_number_2))

filings <- read_parquet("../input/historical_hdb_mappluto_site_panel.parquet") |>
  filter(filing_year >= 2010L, filing_year <= 2023L,
    (primary_leakage_safe_sample & !is.na(lotarea) & lotarea > 0) | job_number %in% accepted_jobs,
    classa_prop_integer, classa_prop >= 6) |>
  transmute(job_number = str_squish(job_number), date_filed, filing_year, units = as.integer(round(classa_prop)),
    hdb_release, historical_active, hdb_job_status = job_status, filing_bbl = normalize_bbl_field(bbl),
    prefiling_feature_bbl = normalize_bbl_field(pluto_feature_bbl), pluto_source_id_used, pluto_version_used,
    appbbl_recovery_used, appbbl_future_appdate_used_for_linkage) |>
  arrange(date_filed, job_number)
stopifnot(!anyDuplicated(filings$job_number), all(filings$hdb_release == "23Q4"))

hdb <- read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet") |>
  transmute(job_number = str_squish(as.character(job_number)), description = na_if(str_squish(job_desc), ""),
    hdb_latitude = as.numeric(latitude), hdb_longitude = as.numeric(longitude))
stopifnot(!anyDuplicated(hdb$job_number))

# Project references in the job description: other job numbers and MPP codes.
referenced_jobs <- function(description, own_job) {
  jobs <- str_remove(str_extract_all(str_to_upper(coalesce(description, "")),
    "(?<![A-Z0-9])(?:[BMQRSX][0-9]{8}|[1-5][0-9]{8})(?:-I[0-9]+)?")[[1]], "-I[0-9]+$")
  jobs <- sort(unique(jobs[jobs != own_job]))
  if (length(jobs) == 0L) NA_character_ else paste(jobs, collapse = ";")
}
filings <- filings |>
  left_join(hdb, by = "job_number", relationship = "one-to-one") |>
  mutate(description_referenced_jobs = mapply(referenced_jobs, description, job_number, USE.NAMES = FALSE),
    description_project_code = str_remove_all(str_extract(str_to_upper(description), "MPP\\s*[0-9]+"), "\\s"))

# Owner and former lot of each filing lot, from the filing's own pre-filing
# release: PLUTO CSV tables through 18v1, the MapPLUTO shapefile afterwards. A
# lot appearing twice in the release gets no owner.
read_owner_fields <- function(zip_path, bbls) {
  listing <- system2("unzip", c("-Z1", zip_path), stdout = TRUE)
  tables <- listing[str_detect(str_to_lower(listing), "[.](csv|txt)$") &
    !str_detect(str_to_lower(basename(listing)), "change|dictionary|readme|layout|lay|dates")]
  if (length(tables) > 0L) {
    unzip_dir <- tempfile("historical_parent_pluto_")
    stopifnot(system2("unzip", c("-oj", zip_path, tables, "-d", unzip_dir), stdout = FALSE) == 0)
    lots <- bind_rows(lapply(file.path(unzip_dir, basename(tables)), function(path) {
      header <- names(data.table::fread(path, nrows = 0L, showProgress = FALSE))
      data.table::fread(path, select = intersect(c("Borough", "BoroCode", "Block", "Lot", "BBL", "OwnerName",
        "APPBBL"), header), colClasses = "character", fill = TRUE, showProgress = FALSE) |>
        as_tibble()
    }))
    unlink(unzip_dir, recursive = TRUE)
  } else {
    shapefile <- listing[str_to_lower(basename(listing)) == "mappluto.shp"]
    stopifnot(length(shapefile) == 1L)
    lots <- st_read(paste0("/vsizip/", zip_path, "/", shapefile), quiet = TRUE, stringsAsFactors = FALSE,
      query = paste0("SELECT BBL, Borough, Block, Lot, OwnerName, APPBBL FROM MapPLUTO WHERE BBL IN (",
        paste(bbls, collapse = ","), ")")) |>
      st_drop_geometry() |>
      as_tibble()
  }
  names(lots) <- normalize_names(names(lots))
  tibble(bbl = pick_first_existing(lots, "bbl"), borough = pick_first_existing(lots, c("borough", "borocode")),
    block = pick_first_existing(lots, "block"), lot = pick_first_existing(lots, "lot"),
    owner_name = na_if(str_squish(pick_first_existing(lots, c("owner_name", "ownername"))), ""),
    appbbl = normalize_bbl_field(pick_first_existing(lots, "appbbl"))) |>
    mutate(bbl = coalesce(normalize_bbl_field(bbl), build_bbl(borough, block, lot))) |>
    filter(bbl %in% bbls) |>
    add_count(bbl) |>
    filter(n == 1L) |>
    select(bbl, owner_name, appbbl)
}

releases <- read_csv("../input/mappluto_files.csv", col_types = cols(.default = col_character())) |>
  filter((source_id == "dcp_pluto_archive" & file_role == "pluto_csv_zip") |
    (source_id == "dcp_mappluto_archive" & file_role == "mappluto_shapefile_zip")) |>
  select(pluto_source_id_used = source_id, pluto_version_used = vintage, raw_path) |>
  semi_join(filings, by = c("pluto_source_id_used", "pluto_version_used"))

owner_fields <- bind_rows(lapply(seq_len(nrow(releases)), function(k) {
  release_filings <- filings |> semi_join(releases[k, ], by = c("pluto_source_id_used", "pluto_version_used"))
  bbls <- unique(na.omit(release_filings$prefiling_feature_bbl))
  release_filings |>
    select(job_number, prefiling_feature_bbl) |>
    left_join(read_owner_fields(file.path("../input", basename(releases$raw_path[k])), bbls),
      by = c("prefiling_feature_bbl" = "bbl"), relationship = "many-to-one") |>
    select(job_number, pluto_owner_name = owner_name, archived_appbbl = appbbl)
}))
stopifnot(setequal(owner_fields$job_number, filings$job_number), !anyDuplicated(owner_fields$job_number))

owner_key <- function(x) {
  key <- str_squish(str_replace_all(str_to_upper(x), "[^A-Z0-9]+", " "))
  key[key %in% c("", "NA", "N A", "NONE", "UNKNOWN")] <- NA_character_
  key
}
filings <- filings |>
  left_join(owner_fields, by = "job_number", relationship = "one-to-one") |>
  mutate(pluto_owner_match_key = owner_key(pluto_owner_name),
    archived_lot_history_group = coalesce(archived_appbbl, prefiling_feature_bbl))

SaveData(filings, "job_number", "../output/historical_parent_filing_link_fields.parquet")

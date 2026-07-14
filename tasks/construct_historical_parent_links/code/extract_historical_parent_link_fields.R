# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_historical_parent_links/code")
# start_year <- 2019L
# end_year <- 2023L
# min_units <- 6L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected three arguments: start year, end year, and minimum units.")
}

start_year <- as.integer(args[1])
end_year <- as.integer(args[2])
min_units <- as.integer(args[3])

if (
  any(is.na(c(start_year, end_year, min_units))) ||
    start_year > end_year ||
    min_units < 1L
) {
  stop("Parent-link arguments are not internally consistent.")
}

normalize_match_key <- function(x) {
  out <- str_squish(str_replace_all(str_to_upper(x), "[^A-Z0-9]+", " "))
  out[out %in% c("", "NA", "N A", "NONE", "UNKNOWN")] <- NA_character_
  out
}

extract_reference_jobs <- function(description, own_job) {
  references <- str_extract_all(
    str_to_upper(coalesce(description, "")),
    "(?<![A-Z0-9])(?:[BMQRSX][0-9]{8}|[1-5][0-9]{8})(?:-I[0-9]+)?"
  )[[1]]
  references <- str_remove(references, "-I[0-9]+$")
  references <- sort(unique(references[references != own_job]))
  if (length(references) == 0L) NA_character_ else paste(references, collapse = ";")
}

read_pluto_link_fields <- function(raw_path, needed_bbls) {
  archive_listing <- system2(
    "unzip", c("-Z1", raw_path), stdout = TRUE, stderr = FALSE
  )
  table_entries <- archive_listing[
    str_detect(str_to_lower(archive_listing), "[.](csv|txt)$") &
      !str_detect(
        str_to_lower(basename(archive_listing)),
        "change|dictionary|readme|layout|lay|dates"
      )
  ]
  dbf_entry <- archive_listing[
    str_detect(str_to_lower(archive_listing), "mappluto[.]dbf$")
  ][1]
  shapefile_entry <- archive_listing[
    str_to_lower(basename(archive_listing)) == "mappluto.shp"
  ][1]

  extraction_directory <- tempfile("historical_parent_pluto_")
  dir.create(extraction_directory)
  on.exit(unlink(extraction_directory, recursive = TRUE), add = TRUE)

  if (length(table_entries) > 0L) {
    unzip_status <- system2(
      "unzip",
      c("-oj", raw_path, table_entries, "-d", extraction_directory),
      stdout = FALSE,
      stderr = FALSE
    )
    if (!identical(unzip_status, 0L)) {
      stop("Could not extract historical PLUTO tables from ", raw_path)
    }
    extracted_paths <- file.path(
      extraction_directory, basename(table_entries)
    )
    raw_table <- bind_rows(lapply(extracted_paths, function(path) {
      available_columns <- names(data.table::fread(
        path,
        nrows = 0L,
        showProgress = FALSE
      ))
      selected_columns <- intersect(
        c(
          "Borough", "BoroCode", "Block", "Lot", "BBL", "OwnerType",
          "OwnerName", "XCoord", "YCoord", "APPBBL", "APPDate",
          "PLUTOMapID"
        ),
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
  } else if (!is.na(dbf_entry) && nzchar(dbf_entry)) {
    if (is.na(shapefile_entry) || !nzchar(shapefile_entry)) {
      stop("MapPLUTO DBF has no matching shapefile in ", raw_path)
    }
    bbl_query <- paste(needed_bbls, collapse = ",")
    raw_table <- st_read(
      paste0("/vsizip/", raw_path, "/", shapefile_entry),
      query = paste0(
        "SELECT BBL, Borough, Block, Lot, OwnerType, OwnerName, ",
        "XCoord, YCoord, APPBBL, APPDate, PLUTOMapID FROM MapPLUTO ",
        "WHERE BBL IN (", bbl_query, ")"
      ),
      quiet = TRUE,
      stringsAsFactors = FALSE
    ) |>
      st_drop_geometry() |>
      as_tibble()
  } else {
    stop("No historical PLUTO table found in ", raw_path)
  }

  names(raw_table) <- normalize_names(names(raw_table))
  link_fields <- tibble(
    bbl = pick_first_existing(raw_table, "bbl"),
    borough = pick_first_existing(
      raw_table, c("borough", "boro_code", "borocode")
    ),
    block = pick_first_existing(raw_table, "block"),
    lot = pick_first_existing(raw_table, "lot"),
    owner_type = pick_first_existing(raw_table, c("owner_type", "ownertype")),
    owner_name = pick_first_existing(raw_table, c("owner_name", "ownername")),
    xcoord = pick_first_existing(raw_table, "xcoord"),
    ycoord = pick_first_existing(raw_table, "ycoord"),
    appbbl = pick_first_existing(raw_table, "appbbl"),
    appdate = pick_first_existing(raw_table, "appdate"),
    plutomapid = pick_first_existing(raw_table, "plutomapid")
  ) |>
    mutate(
      bbl = normalize_bbl_field(bbl),
      appbbl = normalize_bbl_field(appbbl),
      owner_name = na_if(str_squish(as.character(owner_name)), ""),
      owner_match_key = normalize_match_key(owner_name),
      xcoord = suppressWarnings(as.numeric(xcoord)),
      ycoord = suppressWarnings(as.numeric(ycoord)),
      appdate = parse_mixed_date(appdate)
    )

  missing_bbl <- is.na(link_fields$bbl)
  link_fields$bbl[missing_bbl] <- build_bbl(
    link_fields$borough,
    link_fields$block,
    link_fields$lot
  )[missing_bbl]

  duplicate_needed_bbls <- link_fields |>
    filter(bbl %in% needed_bbls) |>
    count(bbl, name = "raw_rows") |>
    filter(raw_rows > 1L)

  selected_fields <- link_fields |>
    filter(bbl %in% needed_bbls) |>
    anti_join(duplicate_needed_bbls, by = "bbl") |>
    select(
      bbl, owner_type, owner_name, owner_match_key,
      xcoord, ycoord, appbbl, appdate, plutomapid
    )

  selected_fields
}

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    filing_year >= start_year,
    filing_year <= end_year,
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= min_units,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  transmute(
    job_number = str_squish(job_number),
    date_filed = as.Date(date_filed),
    filing_year,
    units = as.integer(round(classa_prop)),
    filing_bbl = normalize_bbl_field(bbl),
    prefiling_feature_bbl = normalize_bbl_field(pluto_feature_bbl),
    pluto_source_id_used,
    pluto_version_used,
    pluto_safe_available_date = as.Date(pluto_safe_available_date_used),
    appbbl_recovery_used,
    appbbl_future_appdate_used_for_linkage
  ) |>
  arrange(date_filed, job_number)

if (nrow(panel) == 0L || anyDuplicated(panel$job_number)) {
  stop("Historical training sample failed job-number QC.")
}

hdb_raw <- read_parquet(
  "../input/dcp_housing_database_project_level_raw_25q4.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    job_number = str_squish(as.character(job_number)),
    hdb_description = na_if(str_squish(as.character(job_desc)), ""),
    hdb_latitude = suppressWarnings(as.numeric(latitude)),
    hdb_longitude = suppressWarnings(as.numeric(longitude))
  )

dob_now <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    job_number = str_squish(job_number),
    dob_now_match = TRUE,
    dob_owner_name = coalesce(
      na_if(str_squish(owner_business_name), ""),
      na_if(str_squish(paste(owner_first_name, owner_last_name)), "")
    ),
    dob_owner_match_key = normalize_match_key(dob_owner_name),
    dob_description = na_if(str_squish(job_description), "")
  )

if (anyDuplicated(hdb_raw$job_number) || anyDuplicated(dob_now$job_number)) {
  stop("HDB or DOB source is not unique by job number.")
}

filings <- panel |>
  left_join(hdb_raw, by = "job_number", relationship = "one-to-one") |>
  left_join(dob_now, by = "job_number", relationship = "one-to-one") |>
  mutate(
    dob_now_match = coalesce(dob_now_match, FALSE),
    description = coalesce(dob_description, hdb_description),
    description_referenced_jobs = mapply(
      extract_reference_jobs,
      description,
      job_number,
      USE.NAMES = FALSE
    ),
    description_project_code = str_remove_all(
      str_extract(str_to_upper(description), "MPP\\s*[0-9]+"),
      "\\s"
    )
  )

mappluto_files <- read_csv(
  "../input/mappluto_files.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  filter(
    (source_id == "dcp_pluto_archive" & file_role == "pluto_csv_zip") |
      (source_id == "dcp_mappluto_archive" &
        file_role == "mappluto_shapefile_zip")
  ) |>
  transmute(
    source_id,
    vintage,
    file_role,
    raw_path
  )

if (anyDuplicated(mappluto_files[c("source_id", "vintage")])) {
  stop("MapPLUTO file manifest is not unique by source and vintage.")
}

required_releases <- filings |>
  distinct(
    source_id = pluto_source_id_used,
    vintage = pluto_version_used
  ) |>
  left_join(
    mappluto_files,
    by = c("source_id", "vintage"),
    relationship = "one-to-one"
  )

if (any(is.na(required_releases$raw_path))) {
  stop("At least one selected historical PLUTO release lacks a raw archive.")
}

pluto_job_fields <- list()

for (release_row in seq_len(nrow(required_releases))) {
  source_id_value <- required_releases$source_id[release_row]
  vintage_value <- required_releases$vintage[release_row]
  release_jobs <- filings |>
    filter(
      pluto_source_id_used == source_id_value,
      pluto_version_used == vintage_value
    )
  needed_bbls <- unique(release_jobs$prefiling_feature_bbl)
  needed_bbls <- needed_bbls[!is.na(needed_bbls)]

  message(
    "Reading parent-link fields from ", source_id_value, " ", vintage_value,
    " for ", length(needed_bbls), " distinct filing lots."
  )

  release_extract <- read_pluto_link_fields(
    required_releases$raw_path[release_row], needed_bbls
  )

  pluto_job_fields[[release_row]] <- release_jobs |>
    select(job_number, prefiling_feature_bbl) |>
    left_join(
      release_extract,
      by = c("prefiling_feature_bbl" = "bbl"),
      relationship = "many-to-one"
    ) |>
    mutate(
      pluto_source_id_used = source_id_value,
      pluto_version_used = vintage_value
    )
}

pluto_job_fields <- bind_rows(pluto_job_fields) |>
  rename(
    pluto_owner_type = owner_type,
    pluto_owner_name = owner_name,
    pluto_owner_match_key = owner_match_key,
    prefiling_xcoord = xcoord,
    prefiling_ycoord = ycoord,
    archived_appbbl = appbbl,
    archived_appdate = appdate,
    prefiling_plutomapid = plutomapid
  )

if (anyDuplicated(pluto_job_fields$job_number)) {
  stop("Historical PLUTO field extraction is not unique by job number.")
}

filings <- filings |>
  left_join(
    pluto_job_fields |>
      select(
        job_number, pluto_owner_type, pluto_owner_name,
        pluto_owner_match_key, prefiling_xcoord, prefiling_ycoord,
        archived_appbbl, archived_appdate, prefiling_plutomapid
      ),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  mutate(
    archived_lot_history_group = coalesce(
      archived_appbbl, prefiling_feature_bbl
    ),
    archived_appdate_after_filing =
      !is.na(archived_appdate) & archived_appdate > date_filed
  )

if (anyDuplicated(filings$job_number)) {
  stop("Historical parent-link field extraction failed final QC.")
}

write_parquet_if_changed(
  filings,
  "../output/historical_parent_filing_link_fields.parquet"
)
cat("Wrote historical parent-link filing fields to ../output\n")

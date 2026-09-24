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

# Every pair of historical filings made within 365 days of each other, with
# the evidence that they belong to one development.
filings <- read_parquet("../output/historical_parent_filing_link_fields.parquet") |> arrange(date_filed, job_number)
stopifnot(!anyNA(filings$filing_bbl), !anyNA(filings$prefiling_feature_bbl))
last_partner <- findInterval(filings$date_filed + 365L, filings$date_filed)
left <- rep(seq_len(nrow(filings)), pmax(last_partner - seq_len(nrow(filings)), 0L))
right <- left + sequence(pmax(last_partner - seq_len(nrow(filings)), 0L))
a <- filings[left, ]
b <- filings[right, ]
same <- function(x, y) coalesce(x == y, FALSE)

distance_metres <- 6371000 * pi / 180 * sqrt(((b$hdb_longitude - a$hdb_longitude) *
  cos((a$hdb_latitude + b$hdb_latitude) * pi / 360))^2 + (b$hdb_latitude - a$hdb_latitude)^2)
pairs <- tibble(job_number_1 = a$job_number, job_number_2 = b$job_number,
    filing_days_apart = as.integer(b$date_filed - a$date_filed),
    same_filing_bbl = same(a$filing_bbl, b$filing_bbl),
    same_feature_bbl = same(a$prefiling_feature_bbl, b$prefiling_feature_bbl),
    # A former lot shared through the archived parcel history, when neither
    # filing's lot was recovered through the current crosswalk.
    same_archived_lot_history_group = same(a$archived_lot_history_group, b$archived_lot_history_group) &
      (!is.na(a$archived_appbbl) | !is.na(b$archived_appbbl)) & !a$appbbl_recovery_used & !b$appbbl_recovery_used,
    explicit_job_reference = str_detect(coalesce(a$description_referenced_jobs, ""), fixed(b$job_number)) |
      str_detect(coalesce(b$description_referenced_jobs, ""), fixed(a$job_number)),
    same_project_code = same(a$description_project_code, b$description_project_code),
    within_250_metres = coalesce(distance_metres <= 250, FALSE),
    # The same owner within 100 m, when neither lot relies on a crosswalk
    # recovery or a lot change recorded after filing.
    same_owner_support = same(a$pluto_owner_match_key, b$pluto_owner_match_key) &
      coalesce(distance_metres <= 100, FALSE) & !a$appbbl_recovery_used & !b$appbbl_recovery_used &
      !a$appbbl_future_appdate_used_for_linkage & !b$appbbl_future_appdate_used_for_linkage,
    uses_recovery = a$appbbl_recovery_used | b$appbbl_recovery_used,
    uses_post_filing_lot = a$appbbl_future_appdate_used_for_linkage | b$appbbl_future_appdate_used_for_linkage,
    bbl_low = pmin(a$prefiling_feature_bbl, b$prefiling_feature_bbl),
    bbl_high = pmax(a$prefiling_feature_bbl, b$prefiling_feature_bbl),
    # A pair's parcel map is the earlier filing's release.
    vintage = a$pluto_version_used, source_id = a$pluto_source_id_used) |>
  mutate(
    strict_lot_history_link = (same_feature_bbl & !uses_recovery & !uses_post_filing_lot) |
      same_archived_lot_history_group,
    later_lot_history_candidate = same_feature_bbl & (uses_recovery | uses_post_filing_lot),
    high_confidence_prefiling_signal = same_filing_bbl | strict_lot_history_link | explicit_job_reference |
      same_project_code,
    owner_supported_candidate = same_owner_support & !high_confidence_prefiling_signal)

# Exact polygon touching in MapPLUTO releases (2018 onward). For each release,
# the lots of the filings that used it are read and tested against each other.
shapefiles <- read_csv("../input/mappluto_files.csv", col_types = cols(.default = col_character())) |>
  filter(source_id == "dcp_mappluto_archive", file_role == "mappluto_shapefile_zip") |>
  select(vintage, raw_path)
read_release_lots <- function(zip_path, bbls) {
  inner_zips <- str_subset(system2("unzip", c("-Z1", zip_path), stdout = TRUE), "(?i)\\.zip$")
  if (length(inner_zips) > 0L) {
    unzip_dir <- tempfile("mappluto_")
    unzip(zip_path, files = inner_zips, exdir = unzip_dir)
    zip_paths <- file.path(unzip_dir, inner_zips)
  } else {
    zip_paths <- zip_path
  }
  do.call(rbind, lapply(zip_paths, function(path) {
    layers <- str_subset(system2("unzip", c("-Z1", path), stdout = TRUE), "(?i)(^|/)([a-z]{2})?mappluto\\.shp$")
    stopifnot(length(layers) > 0L)
    do.call(rbind, lapply(layers, function(layer) {
      name <- tools::file_path_sans_ext(basename(layer))
      borough <- recode(str_to_upper(str_sub(name, 1L, 2L)), MN = "1", BX = "2", BK = "3", QN = "4", SI = "5",
        .default = NA_character_)
      layer_bbls <- if (is.na(borough)) bbls else bbls[str_sub(bbls, 1L, 1L) == borough]
      if (length(layer_bbls) == 0L) return(NULL)
      st_read(paste0("/vsizip/", path, "/", layer), quiet = TRUE, stringsAsFactors = FALSE,
        query = paste0("SELECT BBL FROM ", name, " WHERE BBL IN (", paste(layer_bbls, collapse = ","), ")")) |>
        transmute(bbl = normalize_bbl_field(BBL))
    }))
  }))
}

touching <- bind_rows(lapply(intersect(unique(filings$pluto_version_used), shapefiles$vintage), function(v) {
  lots <- read_release_lots(file.path("../input", basename(shapefiles$raw_path[shapefiles$vintage == v])),
    sort(unique(filings$prefiling_feature_bbl[filings$pluto_version_used == v])))
  stopifnot(!is.null(lots), !anyDuplicated(lots$bbl), all(st_is_valid(lots)))
  touches <- st_touches(lots)
  tibble(i = rep(seq_along(touches), lengths(touches)), j = unlist(touches)) |>
    filter(i < j) |>
    transmute(vintage = v, bbl_low = pmin(lots$bbl[i], lots$bbl[j]), bbl_high = pmax(lots$bbl[i], lots$bbl[j]))
}))

# Touching lots join a pair when the filings are 30 days apart or less, or
# other evidence supports the link.
pairs <- pairs |>
  left_join(touching |> mutate(exact_polygon_touch = TRUE), by = c("vintage", "bbl_low", "bbl_high"),
    relationship = "many-to-one") |>
  mutate(exact_polygon_touch = coalesce(exact_polygon_touch, FALSE) & bbl_low != bbl_high,
    corroborated_exact_adjacency = exact_polygon_touch & (filing_days_apart <= 30L | same_owner_support |
      high_confidence_prefiling_signal),
    candidate = within_250_metres | same_filing_bbl | same_feature_bbl | same_archived_lot_history_group |
      explicit_job_reference | same_project_code) |>
  filter(candidate | exact_polygon_touch) |>
  # Parent construction applies links in this order: candidates, then pairs
  # found only by touching.
  arrange(!candidate, job_number_1, job_number_2) |>
  select(job_number_1, job_number_2, filing_days_apart, same_filing_bbl, strict_lot_history_link,
    later_lot_history_candidate, explicit_job_reference, same_project_code, same_owner_support,
    high_confidence_prefiling_signal, owner_supported_candidate, exact_polygon_touch,
    corroborated_exact_adjacency)

SaveData(pairs, c("job_number_1", "job_number_2"), "../output/historical_parent_pairs.parquet")

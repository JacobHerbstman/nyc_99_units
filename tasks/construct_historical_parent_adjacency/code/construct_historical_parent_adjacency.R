# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_historical_parent_adjacency/code")
# start_year <- 2010L
# end_year <- 2023L
# max_filing_days <- 365L
# corroboration_days <- 30L

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

if (length(args) != 4L) {
  stop(
    "Expected four arguments: start year, end year, maximum filing days, ",
    "and corroboration days."
  )
}

start_year <- as.integer(args[1])
end_year <- as.integer(args[2])
max_filing_days <- as.integer(args[3])
corroboration_days <- as.integer(args[4])

if (
  any(is.na(c(start_year, end_year, max_filing_days, corroboration_days))) ||
    start_year > end_year ||
    max_filing_days < 0L ||
    corroboration_days < 0L ||
    corroboration_days > max_filing_days
) {
  stop("Historical adjacency arguments are not internally consistent.")
}

filings <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(filing_year >= start_year, filing_year <= end_year) |>
  arrange(date_filed, job_number)

existing_pairs <- read_parquet(
  "../input/historical_parent_candidate_pairs.parquet"
) |>
  as.data.frame() |>
  as_tibble()

mappluto_files <- read_csv(
  "../input/mappluto_files.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  filter(
    source_id == "dcp_mappluto_archive",
    file_role == "mappluto_shapefile_zip"
  ) |>
  select(vintage, raw_path)

if (
  nrow(filings) == 0L ||
    any(is.na(filings$filing_bbl)) ||
    any(is.na(filings$prefiling_feature_bbl)) ||
    anyDuplicated(filings$job_number) ||
    anyDuplicated(existing_pairs[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(mappluto_files["vintage"])
) {
  stop("Historical adjacency inputs failed identifier QC.")
}

filing_rows <- seq_len(nrow(filings))
right_endpoints <- findInterval(
  filings$date_filed + max_filing_days,
  filings$date_filed
)
pair_counts <- pmax(right_endpoints - filing_rows, 0L)
left_rows <- rep(filing_rows, pair_counts)
right_rows <- unlist(
  Map(
    function(left_row, right_endpoint) {
      if (right_endpoint <= left_row) integer() else {
        seq.int(left_row + 1L, right_endpoint)
      }
    },
    filing_rows,
    right_endpoints
  ),
  use.names = FALSE
)

candidate_pairs <- tibble(
  job_number_1 = filings$job_number[left_rows],
  job_number_2 = filings$job_number[right_rows],
  date_filed_1 = filings$date_filed[left_rows],
  date_filed_2 = filings$date_filed[right_rows],
  filing_year_1 = filings$filing_year[left_rows],
  filing_year_2 = filings$filing_year[right_rows],
  units_1 = filings$units[left_rows],
  units_2 = filings$units[right_rows],
  filing_bbl_1 = filings$filing_bbl[left_rows],
  filing_bbl_2 = filings$filing_bbl[right_rows],
  geometry_bbl_1 = filings$prefiling_feature_bbl[left_rows],
  geometry_bbl_2 = filings$prefiling_feature_bbl[right_rows],
  common_source_id = filings$pluto_source_id_used[left_rows],
  common_vintage = filings$pluto_version_used[left_rows],
  common_snapshot_available_date =
    filings$pluto_safe_available_date[left_rows],
  filing_days_apart = as.integer(
    filings$date_filed[right_rows] - filings$date_filed[left_rows]
  )
) |>
  mutate(
    bbl_low = pmin(geometry_bbl_1, geometry_bbl_2),
    bbl_high = pmax(geometry_bbl_1, geometry_bbl_2)
  ) |>
  left_join(
    mappluto_files,
    by = c("common_vintage" = "vintage"),
    relationship = "many-to-one"
  ) |>
  filter(geometry_bbl_1 != geometry_bbl_2, !is.na(raw_path))

if (anyDuplicated(candidate_pairs[c("job_number_1", "job_number_2")])) {
  stop("Historical adjacency candidate pairs are not unique by job pair.")
}

release_edges <- list()
release_coverage <- list()

exact_releases <- filings |>
  distinct(
    common_source_id = pluto_source_id_used,
    common_vintage = pluto_version_used
  ) |>
  left_join(
    mappluto_files,
    by = c("common_vintage" = "vintage"),
    relationship = "many-to-one"
  ) |>
  filter(!is.na(raw_path))

for (release_row in seq_len(nrow(exact_releases))) {
  source_id_value <- exact_releases$common_source_id[release_row]
  vintage_value <- exact_releases$common_vintage[release_row]
  raw_path_value <- exact_releases$raw_path[release_row]

  release_pairs <- candidate_pairs |>
    filter(
      common_source_id == source_id_value,
      common_vintage == vintage_value
    )

  release_filings <- filings |>
    filter(
      pluto_source_id_used == source_id_value,
      pluto_version_used == vintage_value
    )

  needed_bbls <- sort(unique(release_filings$prefiling_feature_bbl))

  outer_archive_listing <- system2(
    "unzip",
    c("-Z1", raw_path_value),
    stdout = TRUE,
    stderr = FALSE
  )

  inner_zip_entries <- outer_archive_listing[
    str_detect(str_to_lower(outer_archive_listing), "\\.zip$")
  ]

  if (length(inner_zip_entries) > 0L) {
    release_temp_dir <- tempfile(paste0("mappluto_", vintage_value, "_"))
    dir.create(release_temp_dir)
    utils::unzip(
      raw_path_value,
      files = inner_zip_entries,
      exdir = release_temp_dir
    )
    geometry_zip_paths <- file.path(release_temp_dir, inner_zip_entries)
  } else {
    geometry_zip_paths <- raw_path_value
  }

  message(
    "Reading ", length(needed_bbls), " pre-filing feature BBLs from ",
    source_id_value, " ", vintage_value, "."
  )

  release_lot_parts <- list()
  release_lot_counter <- 0L

  for (geometry_zip_path in geometry_zip_paths) {
    geometry_archive_listing <- system2(
      "unzip",
      c("-Z1", geometry_zip_path),
      stdout = TRUE,
      stderr = FALSE
    )
    shapefile_entries <- geometry_archive_listing[
      str_detect(
        str_to_lower(basename(geometry_archive_listing)),
        "^(mappluto|[a-z]{2}mappluto)\\.shp$"
      )
    ]

    if (length(shapefile_entries) == 0L) {
      stop("MapPLUTO archive has no parcel shapefile: ", geometry_zip_path)
    }

    for (shapefile_entry in shapefile_entries) {
      layer_name <- tools::file_path_sans_ext(basename(shapefile_entry))
      borough_prefix <- str_to_upper(str_sub(layer_name, 1L, 2L))
      borough_digit <- recode(
        borough_prefix,
        MN = "1", BX = "2", BK = "3", QN = "4", SI = "5",
        .default = NA_character_
      )
      shapefile_bbls <- if (is.na(borough_digit)) {
        needed_bbls
      } else {
        needed_bbls[str_sub(needed_bbls, 1L, 1L) == borough_digit]
      }

      if (length(shapefile_bbls) == 0L) {
        next
      }

      release_lot_counter <- release_lot_counter + 1L
      release_lot_parts[[release_lot_counter]] <- st_read(
        paste0("/vsizip/", geometry_zip_path, "/", shapefile_entry),
        query = paste0(
          "SELECT BBL FROM ", layer_name, " WHERE BBL IN (",
          paste(shapefile_bbls, collapse = ","),
          ")"
        ),
        quiet = TRUE,
        stringsAsFactors = FALSE
      ) |>
        mutate(bbl = normalize_bbl_field(BBL)) |>
        select(bbl)
    }
  }

  release_lots <- do.call(rbind, release_lot_parts)

  if (is.null(release_lots)) {
    stop("MapPLUTO archive returned no filing-lot geometries: ", raw_path_value)
  }

  if (
    anyDuplicated(st_drop_geometry(release_lots)$bbl) ||
      any(!st_is_valid(release_lots))
  ) {
    stop(
      "MapPLUTO geometry failed BBL uniqueness or validity in ",
      source_id_value, " ", vintage_value, "."
    )
  }

  release_coverage[[release_row]] <- release_filings |>
    transmute(
      job_number,
      filing_bbl,
      geometry_bbl = prefiling_feature_bbl,
      pluto_source_id_used,
      pluto_version_used,
      geometry_available = geometry_bbl %in% release_lots$bbl
    )

  touch_index <- st_touches(release_lots)
  touch_rows <- rep(seq_len(nrow(release_lots)), lengths(touch_index))
  touch_columns <- unlist(touch_index, use.names = FALSE)

  exact_edges <- tibble(
    left_row = touch_rows,
    right_row = touch_columns
  ) |>
    filter(left_row < right_row) |>
    transmute(
      bbl_1 = release_lots$bbl[left_row],
      bbl_2 = release_lots$bbl[right_row],
      bbl_low = pmin(bbl_1, bbl_2),
      bbl_high = pmax(bbl_1, bbl_2)
    ) |>
    select(bbl_low, bbl_high)

  release_edges[[release_row]] <- release_pairs |>
    inner_join(
      exact_edges,
      by = c("bbl_low", "bbl_high"),
      relationship = "many-to-one"
    ) |>
    select(
      job_number_1, job_number_2, date_filed_1, date_filed_2,
      filing_year_1, filing_year_2, units_1, units_2,
      filing_bbl_1, filing_bbl_2, geometry_bbl_1, geometry_bbl_2,
      common_source_id, common_vintage, common_snapshot_available_date,
      filing_days_apart
    )
}

adjacency_pairs <- bind_rows(release_edges)
geometry_coverage <- bind_rows(
  release_coverage,
  filings |>
    filter(!pluto_version_used %in% mappluto_files$vintage) |>
    transmute(
      job_number,
      filing_bbl,
      geometry_bbl = prefiling_feature_bbl,
      pluto_source_id_used,
      pluto_version_used,
      geometry_available = FALSE
    )
) |>
  arrange(match(job_number, filings$job_number))

if (nrow(adjacency_pairs) == 0L) {
  stop("No exact historical polygon adjacencies were found.")
}

if (
  nrow(geometry_coverage) != nrow(filings) ||
    anyDuplicated(geometry_coverage$job_number) ||
    !setequal(geometry_coverage$job_number, filings$job_number)
) {
  stop("Historical geometry coverage is not one row per filing.")
}

adjacency_pairs <- adjacency_pairs |>
  left_join(
    existing_pairs |>
      select(
        job_number_1, job_number_2,
        same_filing_bbl, strict_prefiling_lot_link,
        same_archived_lot_history_group, explicit_job_reference,
        high_confidence_prefiling_signal,
        strict_prefiling_owner_nearby, dob_owner_nearby
      ),
    by = c("job_number_1", "job_number_2"),
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      c(
        same_filing_bbl, strict_prefiling_lot_link,
        same_archived_lot_history_group, explicit_job_reference,
        high_confidence_prefiling_signal,
        strict_prefiling_owner_nearby, dob_owner_nearby
      ),
      ~ coalesce(.x, FALSE)
    ),
    exact_polygon_touch = TRUE,
    corroborated_exact_adjacency =
      filing_days_apart <= corroboration_days |
      strict_prefiling_owner_nearby |
      dob_owner_nearby |
      high_confidence_prefiling_signal
  ) |>
  arrange(job_number_1, job_number_2)

if (anyDuplicated(adjacency_pairs[c("job_number_1", "job_number_2")])) {
  stop("Historical adjacency output is not unique by job pair.")
}

write_parquet_if_changed(
  adjacency_pairs,
  "../output/historical_polygon_adjacency_pairs.parquet"
)
write_parquet_if_changed(
  geometry_coverage,
  "../output/historical_polygon_geometry_coverage.parquet"
)

cat("Wrote historical polygon adjacency and geometry coverage to ../output\n")

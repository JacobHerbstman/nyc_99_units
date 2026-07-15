# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_historical_exact_parcel_adjacency/code")
# start_year <- 2019L
# end_year <- 2023L
# max_filing_days <- 365L
# corroboration_days <- 30L
# near_touch_meters <- 1

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
  library(units)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop(
    "Expected five arguments: start year, end year, maximum filing days, ",
    "corroboration days, and near-touch meters."
  )
}

start_year <- as.integer(args[1])
end_year <- as.integer(args[2])
max_filing_days <- as.integer(args[3])
corroboration_days <- as.integer(args[4])
near_touch_meters <- as.numeric(args[5])

if (
  any(is.na(c(
    start_year, end_year, max_filing_days,
    corroboration_days, near_touch_meters
  ))) ||
    start_year > end_year ||
    max_filing_days < 0L ||
    corroboration_days < 0L ||
    corroboration_days > max_filing_days ||
    near_touch_meters <= 0
) {
  stop("Audit arguments are not internally consistent.")
}

filings_all <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
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
  transmute(
    source_id,
    vintage,
    raw_path = str_replace(
      raw_path,
      "^[.][.]/[.][.]/[.][.]/",
      "../../../../"
    )
  )

if (
  nrow(filings_all) == 0L ||
    anyDuplicated(filings_all$job_number) ||
    anyDuplicated(existing_pairs[c("job_number_1", "job_number_2")]) ||
    anyDuplicated(mappluto_files[c("source_id", "vintage")])
) {
  stop("Historical adjacency inputs failed identifier QC.")
}

filings <- filings_all |>
  filter(filing_year >= start_year, filing_year <= end_year) |>
  arrange(date_filed, job_number)

if (nrow(filings) == 0L || any(is.na(filings$filing_bbl))) {
  stop("Historical adjacency sample is empty or has missing filing BBLs.")
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
  common_source_id = filings$pluto_source_id_used[left_rows],
  common_vintage = filings$pluto_version_used[left_rows],
  common_snapshot_available_date =
    filings$pluto_safe_available_date[left_rows],
  filing_days_apart = as.integer(
    filings$date_filed[right_rows] - filings$date_filed[left_rows]
  ),
  hdb_distance_meters = 6371000 * pi / 180 * sqrt(
    ((filings$hdb_longitude[right_rows] -
      filings$hdb_longitude[left_rows]) *
      cos((filings$hdb_latitude[left_rows] +
        filings$hdb_latitude[right_rows]) * pi / 360))^2 +
      (filings$hdb_latitude[right_rows] -
        filings$hdb_latitude[left_rows])^2
  )
) |>
  mutate(
    bbl_low = if_else(filing_bbl_1 <= filing_bbl_2, filing_bbl_1, filing_bbl_2),
    bbl_high = if_else(filing_bbl_1 <= filing_bbl_2, filing_bbl_2, filing_bbl_1),
    different_filing_bbl = filing_bbl_1 != filing_bbl_2
  ) |>
  left_join(
    mappluto_files,
    by = c("common_source_id" = "source_id", "common_vintage" = "vintage"),
    relationship = "many-to-one"
  ) |>
  mutate(common_snapshot_has_exact_geometry = !is.na(raw_path))

if (anyDuplicated(candidate_pairs[c("job_number_1", "job_number_2")])) {
  stop("Historical adjacency candidate pairs are not unique by job pair.")
}

release_edges <- list()
release_summaries <- list()

exact_releases <- candidate_pairs |>
  filter(common_snapshot_has_exact_geometry) |>
  distinct(common_source_id, common_vintage, raw_path)

for (release_row in seq_len(nrow(exact_releases))) {
  source_id_value <- exact_releases$common_source_id[release_row]
  vintage_value <- exact_releases$common_vintage[release_row]
  raw_path_value <- exact_releases$raw_path[release_row]

  release_pairs <- candidate_pairs |>
    filter(
      common_source_id == source_id_value,
      common_vintage == vintage_value
    )

  needed_bbls <- sort(unique(c(
    release_pairs$filing_bbl_1,
    release_pairs$filing_bbl_2
  )))
  needed_bbls <- needed_bbls[!is.na(needed_bbls)]

  archive_listing <- system2(
    "unzip",
    c("-Z1", raw_path_value),
    stdout = TRUE,
    stderr = FALSE
  )
  shapefile_entry <- archive_listing[
    str_to_lower(basename(archive_listing)) == "mappluto.shp"
  ][1]

  if (is.na(shapefile_entry) || !nzchar(shapefile_entry)) {
    stop("MapPLUTO archive has no MapPLUTO.shp: ", raw_path_value)
  }

  message(
    "Reading ", length(needed_bbls), " filing BBLs from ",
    source_id_value, " ", vintage_value, "."
  )

  release_lots <- st_read(
    paste0("/vsizip/", raw_path_value, "/", shapefile_entry),
    query = paste0(
      "SELECT BBL FROM MapPLUTO WHERE BBL IN (",
      paste(needed_bbls, collapse = ","),
      ")"
    ),
    quiet = TRUE,
    stringsAsFactors = FALSE
  ) |>
    mutate(bbl = normalize_bbl_field(BBL)) |>
    select(bbl)

  duplicate_bbls <- release_lots |>
    st_drop_geometry() |>
    count(bbl, name = "raw_rows") |>
    filter(raw_rows > 1L)

  if (nrow(duplicate_bbls) > 0L) {
    stop(
      "MapPLUTO geometry is not unique by BBL in ",
      source_id_value, " ", vintage_value, "."
    )
  }

  invalid_geometry <- !st_is_valid(release_lots)
  usable_lots <- release_lots[!invalid_geometry, ]

  touch_index <- st_touches(usable_lots)
  near_index <- st_is_within_distance(
    usable_lots,
    dist = set_units(near_touch_meters, "m")
  )
  overlap_index <- st_overlaps(usable_lots)

  touch_rows <- rep(seq_len(nrow(usable_lots)), lengths(touch_index))
  touch_columns <- unlist(touch_index, use.names = FALSE)
  near_rows <- rep(seq_len(nrow(usable_lots)), lengths(near_index))
  near_columns <- unlist(near_index, use.names = FALSE)
  overlap_rows <- rep(seq_len(nrow(usable_lots)), lengths(overlap_index))
  overlap_columns <- unlist(overlap_index, use.names = FALSE)

  exact_edges <- tibble(
    left_row = touch_rows,
    right_row = touch_columns
  ) |>
    filter(left_row < right_row) |>
    transmute(
      bbl_1 = usable_lots$bbl[left_row],
      bbl_2 = usable_lots$bbl[right_row],
      exact_polygon_touch = TRUE
    )

  near_edges <- tibble(
    left_row = near_rows,
    right_row = near_columns
  ) |>
    filter(left_row < right_row) |>
    transmute(
      bbl_1 = usable_lots$bbl[left_row],
      bbl_2 = usable_lots$bbl[right_row],
      within_near_touch_distance = TRUE
    )

  overlap_edges <- tibble(
    left_row = overlap_rows,
    right_row = overlap_columns
  ) |>
    filter(left_row < right_row) |>
    transmute(
      bbl_1 = usable_lots$bbl[left_row],
      bbl_2 = usable_lots$bbl[right_row],
      overlapping_polygons = TRUE
    )

  release_edge_rows <- full_join(
    exact_edges,
    near_edges,
    by = c("bbl_1", "bbl_2"),
    relationship = "one-to-one"
  ) |>
    full_join(
      overlap_edges,
      by = c("bbl_1", "bbl_2"),
      relationship = "one-to-one"
    ) |>
    transmute(
      common_source_id = source_id_value,
      common_vintage = vintage_value,
      bbl_low = if_else(bbl_1 <= bbl_2, bbl_1, bbl_2),
      bbl_high = if_else(bbl_1 <= bbl_2, bbl_2, bbl_1),
      exact_polygon_touch = coalesce(exact_polygon_touch, FALSE),
      within_near_touch_distance = coalesce(
        within_near_touch_distance,
        FALSE
      ),
      overlapping_polygons = coalesce(overlapping_polygons, FALSE)
    )

  if (
    anyDuplicated(
      release_edge_rows[c(
        "common_source_id", "common_vintage", "bbl_low", "bbl_high"
      )]
    )
  ) {
    stop("Historical adjacency edge construction produced duplicate keys.")
  }

  matched_bbls <- usable_lots$bbl
  release_pairs_evaluated <- release_pairs |>
    mutate(
      polygon_1_found = filing_bbl_1 %in% matched_bbls,
      polygon_2_found = filing_bbl_2 %in% matched_bbls,
      both_polygons_found = polygon_1_found & polygon_2_found
    ) |>
    left_join(
      release_edge_rows,
      by = c(
        "common_source_id", "common_vintage", "bbl_low", "bbl_high"
      ),
      relationship = "many-to-one"
    ) |>
    mutate(
      exact_polygon_touch = coalesce(exact_polygon_touch, FALSE),
      within_near_touch_distance = coalesce(
        within_near_touch_distance,
        FALSE
      ),
      overlapping_polygons = coalesce(overlapping_polygons, FALSE)
    )

  release_edges[[release_row]] <- release_pairs_evaluated |>
    filter(
      different_filing_bbl,
      both_polygons_found,
      exact_polygon_touch | within_near_touch_distance | overlapping_polygons
    ) |>
    select(
      job_number_1, job_number_2, date_filed_1, date_filed_2,
      filing_year_1, filing_year_2, units_1, units_2,
      filing_bbl_1, filing_bbl_2,
      common_source_id, common_vintage, common_snapshot_available_date,
      filing_days_apart, hdb_distance_meters,
      exact_polygon_touch, within_near_touch_distance, overlapping_polygons
    )

  release_summaries[[release_row]] <- tibble(
    common_source_id = source_id_value,
    common_vintage = vintage_value,
    candidate_pairs = nrow(release_pairs),
    distinct_needed_bbls = length(needed_bbls),
    matched_valid_bbls = length(unique(matched_bbls)),
    invalid_needed_bbls = sum(invalid_geometry),
    pairs_with_both_polygons = sum(
      release_pairs_evaluated$both_polygons_found
    ),
    exact_adjacent_pairs = sum(
      release_pairs_evaluated$different_filing_bbl &
        release_pairs_evaluated$exact_polygon_touch
    ),
    near_touch_pairs = sum(
      release_pairs_evaluated$different_filing_bbl &
        release_pairs_evaluated$within_near_touch_distance
    ),
    overlapping_polygon_pairs = sum(
      release_pairs_evaluated$different_filing_bbl &
        release_pairs_evaluated$overlapping_polygons
    )
  )
}

adjacency_pairs <- bind_rows(release_edges)
release_summary <- bind_rows(release_summaries)

if (nrow(adjacency_pairs) == 0L) {
  adjacency_pairs <- tibble(
    job_number_1 = character(),
    job_number_2 = character(),
    date_filed_1 = as.Date(character()),
    date_filed_2 = as.Date(character()),
    filing_year_1 = integer(),
    filing_year_2 = integer(),
    units_1 = integer(),
    units_2 = integer(),
    filing_bbl_1 = character(),
    filing_bbl_2 = character(),
    common_source_id = character(),
    common_vintage = character(),
    common_snapshot_available_date = as.Date(character()),
    filing_days_apart = integer(),
    hdb_distance_meters = numeric(),
    exact_polygon_touch = logical(),
    within_near_touch_distance = logical(),
    overlapping_polygons = logical()
  )
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
    prior_candidate_pair = !is.na(same_filing_bbl),
    across(
      c(
        same_filing_bbl, strict_prefiling_lot_link,
        same_archived_lot_history_group, explicit_job_reference,
        high_confidence_prefiling_signal,
        strict_prefiling_owner_nearby, dob_owner_nearby
      ),
      ~ coalesce(.x, FALSE)
    ),
    new_exact_adjacency_link =
      exact_polygon_touch & !high_confidence_prefiling_signal,
    corroborated_exact_adjacency =
      exact_polygon_touch &
      (
        filing_days_apart <= corroboration_days |
          strict_prefiling_owner_nearby |
          dob_owner_nearby |
          high_confidence_prefiling_signal
      ),
    new_corroborated_exact_adjacency_link =
      corroborated_exact_adjacency & !high_confidence_prefiling_signal,
    new_near_touch_link =
      within_near_touch_distance & !high_confidence_prefiling_signal
  ) |>
  arrange(job_number_1, job_number_2)

if (anyDuplicated(adjacency_pairs[c("job_number_1", "job_number_2")])) {
  stop("Historical adjacency output is not unique by job pair.")
}

summarize_grouping <- function(group_filings, link_rows, scope, definition) {
  component <- seq_len(nrow(group_filings))
  left_index <- match(link_rows$job_number_1, group_filings$job_number)
  right_index <- match(link_rows$job_number_2, group_filings$job_number)
  valid_links <- !is.na(left_index) & !is.na(right_index)
  left_index <- left_index[valid_links]
  right_index <- right_index[valid_links]

  for (link_row in seq_along(left_index)) {
    left_component <- component[left_index[link_row]]
    right_component <- component[right_index[link_row]]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <-
      merged_component
  }

  group_sizes <- tibble(component) |>
    count(component, name = "filings")

  tibble(
    scope,
    definition,
    filings = nrow(group_filings),
    parent_groups = nrow(group_sizes),
    multi_filing_groups = sum(group_sizes$filings > 1L),
    filings_in_multi_filing_groups = sum(
      group_sizes$filings[group_sizes$filings > 1L]
    ),
    share_filings_in_multi_filing_groups =
      filings_in_multi_filing_groups / nrow(group_filings),
    maximum_filings_in_group = max(group_sizes$filings)
  )
}

conservative_links <- existing_pairs |>
  filter(high_confidence_prefiling_signal) |>
  select(job_number_1, job_number_2)

exact_links <- adjacency_pairs |>
  filter(exact_polygon_touch) |>
  select(job_number_1, job_number_2)

corroborated_exact_links <- adjacency_pairs |>
  filter(corroborated_exact_adjacency) |>
  select(job_number_1, job_number_2)

near_touch_links <- adjacency_pairs |>
  filter(within_near_touch_distance) |>
  select(job_number_1, job_number_2)

conservative_plus_exact <- bind_rows(conservative_links, exact_links) |>
  distinct(job_number_1, job_number_2)

conservative_plus_corroborated_exact <- bind_rows(
  conservative_links,
  corroborated_exact_links
) |>
  distinct(job_number_1, job_number_2)

conservative_plus_near <- bind_rows(conservative_links, near_touch_links) |>
  distinct(job_number_1, job_number_2)

grouping_sensitivity <- bind_rows(
  summarize_grouping(
    filings,
    conservative_links,
    paste0(start_year, "-", end_year),
    "conservative_prefiling_links"
  ),
  summarize_grouping(
    filings,
    conservative_plus_corroborated_exact,
    paste0(start_year, "-", end_year),
    "conservative_plus_corroborated_exact_adjacency"
  ),
  summarize_grouping(
    filings,
    conservative_plus_exact,
    paste0(start_year, "-", end_year),
    "conservative_plus_exact_adjacency"
  ),
  summarize_grouping(
    filings,
    conservative_plus_near,
    paste0(start_year, "-", end_year),
    "conservative_plus_near_touch_sensitivity"
  ),
  summarize_grouping(
    filings_all,
    conservative_links,
    "full_training_sample",
    "conservative_prefiling_links"
  ),
  summarize_grouping(
    filings_all,
    conservative_plus_corroborated_exact,
    "full_training_sample",
    "conservative_plus_corroborated_exact_adjacency"
  ),
  summarize_grouping(
    filings_all,
    conservative_plus_exact,
    "full_training_sample",
    "conservative_plus_exact_adjacency"
  ),
  summarize_grouping(
    filings_all,
    conservative_plus_near,
    "full_training_sample",
    "conservative_plus_near_touch_sensitivity"
  )
)

geometry_unavailable_summary <- candidate_pairs |>
  filter(!common_snapshot_has_exact_geometry) |>
  summarise(
    common_source_id = "geometry_unavailable",
    common_vintage = "all",
    candidate_pairs = n(),
    distinct_needed_bbls = n_distinct(c(filing_bbl_1, filing_bbl_2)),
    matched_valid_bbls = 0L,
    invalid_needed_bbls = 0L,
    pairs_with_both_polygons = 0L,
    exact_adjacent_pairs = 0L,
    near_touch_pairs = 0L,
    overlapping_polygon_pairs = 0L
  )

release_summary <- bind_rows(
  geometry_unavailable_summary,
  release_summary
) |>
  arrange(common_source_id, common_vintage)

adjacency_qc <- tibble(
  check = c(
    "filings_in_adjacency_window",
    "candidate_pairs_within_filing_window",
    "candidate_pairs_with_exact_common_snapshot",
    "candidate_pairs_with_both_polygons",
    "exact_polygon_adjacency_pairs",
    "new_exact_polygon_adjacency_pairs",
    "corroborated_exact_adjacency_pairs",
    "new_corroborated_exact_adjacency_pairs",
    "near_touch_sensitivity_pairs",
    "new_near_touch_sensitivity_pairs",
    "overlapping_polygon_pairs",
    "invalid_needed_geometries",
    "common_snapshots_after_earlier_filing",
    "exact_touches_outside_near_touch_set",
    "corroborated_links_without_exact_touch",
    "exact_touches_missing_prior_coordinate_candidate"
  ),
  value = c(
    nrow(filings),
    nrow(candidate_pairs),
    sum(candidate_pairs$common_snapshot_has_exact_geometry),
    sum(release_summary$pairs_with_both_polygons),
    sum(adjacency_pairs$exact_polygon_touch),
    sum(adjacency_pairs$new_exact_adjacency_link),
    sum(adjacency_pairs$corroborated_exact_adjacency),
    sum(adjacency_pairs$new_corroborated_exact_adjacency_link),
    sum(adjacency_pairs$within_near_touch_distance),
    sum(adjacency_pairs$new_near_touch_link),
    sum(adjacency_pairs$overlapping_polygons),
    sum(release_summary$invalid_needed_bbls),
    sum(
      adjacency_pairs$common_snapshot_available_date >
        adjacency_pairs$date_filed_1
    ),
    sum(
      adjacency_pairs$exact_polygon_touch &
        !adjacency_pairs$within_near_touch_distance
    ),
    sum(
      adjacency_pairs$corroborated_exact_adjacency &
        !adjacency_pairs$exact_polygon_touch
    ),
    sum(
      adjacency_pairs$exact_polygon_touch &
        !adjacency_pairs$prior_candidate_pair
    )
  )
)

adjacency_characteristics <- adjacency_pairs |>
  filter(exact_polygon_touch) |>
  mutate(
    timing = case_when(
      filing_days_apart == 0L ~ "same_day",
      filing_days_apart <= corroboration_days ~ "within_corroboration_window",
      filing_days_apart <= 90L ~ "31_to_90_days",
      filing_days_apart <= 180L ~ "91_to_180_days",
      TRUE ~ "181_to_365_days"
    ),
    corroboration = case_when(
      high_confidence_prefiling_signal ~ "prior_high_confidence_link",
      strict_prefiling_owner_nearby | dob_owner_nearby ~
        "leakage_safe_owner_match",
      filing_days_apart <= corroboration_days ~ "filing_timing_only",
      TRUE ~ "adjacency_only"
    )
  ) |>
  count(timing, corroboration, name = "exact_adjacency_pairs") |>
  arrange(timing, corroboration)

if (
  any(release_summary$matched_valid_bbls > release_summary$distinct_needed_bbls) ||
    sum(release_summary$candidate_pairs) != nrow(candidate_pairs) ||
    nrow(grouping_sensitivity) != 8L ||
    nrow(adjacency_qc) != 16L ||
    any(adjacency_qc$value[13:16] != 0L) ||
    sum(adjacency_characteristics$exact_adjacency_pairs) !=
      sum(adjacency_pairs$exact_polygon_touch)
) {
  stop("Historical exact parcel adjacency outputs failed final QC.")
}

write_parquet_if_changed(
  adjacency_pairs,
  "../output/historical_polygon_adjacency_pairs.parquet"
)
write_csv_if_changed(
  adjacency_pairs |>
    filter(exact_polygon_touch),
  "../output/historical_exact_adjacency_pairs.csv"
)
write_csv_if_changed(
  adjacency_characteristics,
  "../output/historical_polygon_adjacency_characteristics.csv"
)
write_csv_if_changed(
  release_summary,
  "../output/historical_polygon_adjacency_release_summary.csv"
)
write_csv_if_changed(
  grouping_sensitivity,
  "../output/historical_polygon_adjacency_grouping_sensitivity.csv"
)
write_csv_if_changed(
  adjacency_qc,
  "../output/historical_polygon_adjacency_qc.csv"
)

cat("Wrote historical exact parcel adjacency audit outputs to ../output\n")

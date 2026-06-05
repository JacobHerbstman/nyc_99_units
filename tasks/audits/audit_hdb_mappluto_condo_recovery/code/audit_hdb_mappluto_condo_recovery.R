# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(foreign)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

candidate_min_classa_props <- c(50L, 60L, 70L)

parse_bbl_borough <- function(x) {
  substr(as.character(x), 1L, 1L)
}

parse_bbl_block <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 2L, 6L)))
}

parse_bbl_lot <- function(x) {
  suppressWarnings(as.integer(substr(as.character(x), 7L, 10L)))
}

paste_unique <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & as.character(x) != ""])))
  if (length(x) == 0) {
    return(NA_character_)
  }
  paste(x, collapse = ";")
}

min_date_value <- function(x) {
  if (all(is.na(x))) {
    return(as.Date(NA))
  }
  min(x, na.rm = TRUE)
}

max_date_value <- function(x) {
  if (all(is.na(x))) {
    return(as.Date(NA))
  }
  max(x, na.rm = TRUE)
}

normalize_text_field <- function(x) {
  out <- trimws(as.character(x))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  out
}

normalize_integer_field <- function(x) {
  suppressWarnings(as.integer(normalize_text_field(x)))
}

normalize_bbl_field <- function(x) {
  out <- normalize_text_field(x)
  numeric_value <- suppressWarnings(as.numeric(out))
  numeric_bbl <- !is.na(numeric_value) & numeric_value >= 1000000000 & numeric_value < 6000000000
  out[numeric_bbl] <- sprintf("%.0f", numeric_value[numeric_bbl])
  out[!str_detect(out, "^[1-5][0-9]{9}$")] <- NA_character_
  out
}

read_raw_condo_keys <- function(raw_path) {
  read_path <- raw_path
  read_mode <- if (str_detect(tolower(raw_path), "\\.dbf$")) "dbf" else "delimited"
  temp_dir <- NULL

  if (str_detect(tolower(raw_path), "\\.zip$")) {
    temp_dir <- tempfile(pattern = "condo_keys_")
    dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
    zip_listing <- suppressWarnings(system2("unzip", c("-Z1", raw_path), stdout = TRUE, stderr = FALSE))
    table_entries <- zip_listing[str_detect(tolower(zip_listing), "\\.(csv|txt)$")]
    table_entries <- table_entries[!str_detect(tolower(basename(table_entries)), "change|dictionary|readme|layout|lay|dates")]
    dbf_entry <- zip_listing[str_detect(tolower(zip_listing), "\\.dbf$")][1]

    if (length(table_entries) > 0) {
      unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, table_entries, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
      if (!identical(unzip_status, 0L)) {
        stop("System unzip failed for PLUTO table files in ", raw_path)
      }
      read_path <- file.path(temp_dir, basename(table_entries))
      read_mode <- "delimited"
    } else if (!is.na(dbf_entry) && nzchar(dbf_entry)) {
      unzip_status <- suppressWarnings(system2("unzip", c("-oj", raw_path, dbf_entry, "-d", temp_dir), stdout = FALSE, stderr = FALSE))
      if (!identical(unzip_status, 0L)) {
        stop("System unzip failed for DBF in ", raw_path)
      }
      read_path <- file.path(temp_dir, basename(dbf_entry))
      read_mode <- "dbf"
    } else {
      stop("No .csv, .txt, or .dbf found in ", raw_path)
    }
  }

  raw_table <- if (read_mode == "dbf") {
    read.dbf(read_path, as.is = TRUE) |>
      as_tibble()
  } else {
    bind_rows(lapply(read_path, function(path) {
      read_csv(
        path,
        show_col_types = FALSE,
        col_types = cols(.default = col_character()),
        lazy = FALSE
      )
    }))
  }

  names(raw_table) <- normalize_names(names(raw_table))

  out <- tibble(
    bbl = pick_first_existing(raw_table, c("bbl")),
    borough = pick_first_existing(raw_table, c("borough", "boro_code", "borocode")),
    block = pick_first_existing(raw_table, c("block")),
    lot = pick_first_existing(raw_table, c("lot")),
    condono = pick_first_existing(raw_table, c("condono", "condo_no")),
    appbbl = pick_first_existing(raw_table, c("appbbl", "app_bbl")),
    appdate = pick_first_existing(raw_table, c("appdate")),
    plutomapid = pick_first_existing(raw_table, c("plutomapid", "pluto_map_id"))
  )

  missing_bbl <- is.na(out$bbl) | out$bbl == ""
  out$bbl[missing_bbl] <- build_bbl(out$borough, out$block, out$lot)[missing_bbl]
  out
}

raw_panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

strict_bbl_match_status_for_audit <- if ("strict_pluto_match_status" %in% names(raw_panel)) {
  raw_panel$strict_pluto_match_status
} else {
  raw_panel$pluto_match_status
}

panel <- raw_panel |>
  mutate(
    hdb_row_id = job_number,
    hdb_bbl = as.character(bbl),
    hdb_borough = parse_bbl_borough(hdb_bbl),
    hdb_block = parse_bbl_block(hdb_bbl),
    hdb_lot = parse_bbl_lot(hdb_bbl),
    lot_ge_7500 = !is.na(hdb_lot) & hdb_lot >= 7500L,
    strict_bbl_match_status_for_audit = strict_bbl_match_status_for_audit
  )

unmatched_hdb_condo_audit <- panel |>
  filter(strict_bbl_match_status_for_audit == "no_mappluto_match") |>
  transmute(
    hdb_row_id,
    job_number,
    date_filed,
    filing_year,
    classa_prop,
    y100,
    hdb_bbl,
    hdb_borough,
    hdb_block,
    hdb_lot,
    lot_ge_7500,
    hdb_borough_name,
    address,
    pluto_source_id_used,
    pluto_version_used,
    pluto_timing_status,
    strict_bbl_match_status = strict_bbl_match_status_for_audit
  )

mappluto_files <- read_csv("../input/mappluto_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    raw_path = as.character(raw_path),
    file_role = as.character(file_role)
  ) |>
  filter(
    source_id == "dcp_pluto_current",
    file_role == "pluto_csv_zip",
    !is.na(raw_path)
  )

pluto_key_rows <- list()

for (i in seq_len(nrow(mappluto_files))) {
  raw_path <- file.path("..", "..", "..", "fetch_mappluto_archive", "code", mappluto_files$raw_path[i])

  if (!file.exists(raw_path)) {
    next
  }

  pluto_key_rows[[length(pluto_key_rows) + 1L]] <- read_raw_condo_keys(raw_path) |>
    mutate(
      source_id = mappluto_files$source_id[i],
      vintage = mappluto_files$vintage[i],
      bbl = normalize_bbl_field(bbl),
      appbbl = normalize_bbl_field(appbbl),
      condono = normalize_integer_field(condono),
      appdate = parse_mixed_date(appdate),
      plutomapid = normalize_integer_field(plutomapid),
      bbl_borough = parse_bbl_borough(bbl),
      bbl_block = parse_bbl_block(bbl),
      bbl_lot = parse_bbl_lot(bbl),
      appbbl_borough = parse_bbl_borough(appbbl),
      appbbl_block = parse_bbl_block(appbbl),
      appbbl_lot = parse_bbl_lot(appbbl)
    ) |>
    select(source_id, vintage, bbl, bbl_borough, bbl_block, bbl_lot, condono, appbbl, appbbl_borough, appbbl_block, appbbl_lot, appdate, plutomapid)
}

pluto_keys <- bind_rows(pluto_key_rows)

if (nrow(pluto_keys) == 0) {
  stop("No raw PLUTO/MapPLUTO key rows are available for condo recovery audit.")
}

crosswalk_evidence <- pluto_keys |>
  filter(
    bbl %in% unmatched_hdb_condo_audit$hdb_bbl,
    !is.na(appbbl),
    str_detect(appbbl, "^[1-5][0-9]{9}$"),
    appbbl != bbl
  ) |>
  group_by(condo_bbl = bbl, candidate_base_bbl = appbbl) |>
  summarise(
    evidence_sources = paste_unique(source_id),
    evidence_vintages = paste_unique(vintage),
    evidence_rows = n(),
    condono_values = paste_unique(condono),
    plutomapid_values = paste_unique(plutomapid),
    appdate_min = min_date_value(appdate),
    appdate_max = max_date_value(appdate),
    candidate_base_borough = first(appbbl_borough),
    candidate_base_block = first(appbbl_block),
    candidate_base_lot = first(appbbl_lot),
    .groups = "drop"
  )

candidate_rows <- list()

for (i in seq_len(nrow(unmatched_hdb_condo_audit))) {
  row_candidates <- crosswalk_evidence |>
    filter(condo_bbl == unmatched_hdb_condo_audit$hdb_bbl[i])

  if (nrow(row_candidates) == 0) {
    next
  }

  candidate_rows[[length(candidate_rows) + 1L]] <- row_candidates |>
    mutate(
      hdb_row_id = unmatched_hdb_condo_audit$hdb_row_id[i],
      job_number = unmatched_hdb_condo_audit$job_number[i],
      date_filed = unmatched_hdb_condo_audit$date_filed[i],
      filing_year = unmatched_hdb_condo_audit$filing_year[i],
      classa_prop = unmatched_hdb_condo_audit$classa_prop[i],
      y100 = unmatched_hdb_condo_audit$y100[i],
      hdb_bbl = unmatched_hdb_condo_audit$hdb_bbl[i],
      hdb_borough = unmatched_hdb_condo_audit$hdb_borough[i],
      hdb_block = unmatched_hdb_condo_audit$hdb_block[i],
      hdb_lot = unmatched_hdb_condo_audit$hdb_lot[i],
      lot_ge_7500 = unmatched_hdb_condo_audit$lot_ge_7500[i],
      hdb_borough_name = unmatched_hdb_condo_audit$hdb_borough_name[i],
      pluto_source_id_used = unmatched_hdb_condo_audit$pluto_source_id_used[i],
      pluto_version_used = unmatched_hdb_condo_audit$pluto_version_used[i],
      pluto_timing_status = unmatched_hdb_condo_audit$pluto_timing_status[i],
      .before = condo_bbl
    )
}

condo_crosswalk_candidates <- bind_rows(candidate_rows)

if (nrow(condo_crosswalk_candidates) == 0) {
  condo_crosswalk_candidates <- tibble(
    hdb_row_id = character(),
    job_number = character(),
    date_filed = as.Date(character()),
    filing_year = integer(),
    classa_prop = numeric(),
    y100 = logical(),
    hdb_bbl = character(),
    hdb_borough = character(),
    hdb_block = integer(),
    hdb_lot = integer(),
    lot_ge_7500 = logical(),
    hdb_borough_name = character(),
    pluto_source_id_used = character(),
    pluto_version_used = character(),
    pluto_timing_status = character(),
    condo_bbl = character(),
    candidate_base_bbl = character(),
    evidence_sources = character(),
    evidence_vintages = character(),
    evidence_rows = integer(),
    condono_values = character(),
    plutomapid_values = character(),
    appdate_min = as.Date(character()),
    appdate_max = as.Date(character()),
    candidate_base_borough = character(),
    candidate_base_block = integer(),
    candidate_base_lot = integer()
  )
}

needed_lagged_candidates <- condo_crosswalk_candidates |>
  filter(!is.na(pluto_source_id_used), !is.na(pluto_version_used), !is.na(candidate_base_bbl)) |>
  distinct(pluto_source_id_used, pluto_version_used, candidate_base_bbl)

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    parquet_path = as.character(parquet_path)
  ) |>
  inner_join(
    needed_lagged_candidates |>
      distinct(pluto_source_id_used, pluto_version_used),
    by = c("source_id" = "pluto_source_id_used", "vintage" = "pluto_version_used"),
    relationship = "one-to-one"
  ) |>
  filter(!is.na(parquet_path))

staged_bbl_count_rows <- list()

for (i in seq_len(nrow(mappluto_lot_files))) {
  staged_parquet_path <- file.path("..", "..", "..", "stage_mappluto_lots", "output", basename(mappluto_lot_files$parquet_path[i]))

  if (!file.exists(staged_parquet_path)) {
    next
  }

  needed_bbl <- needed_lagged_candidates |>
    filter(
      pluto_source_id_used == mappluto_lot_files$source_id[i],
      pluto_version_used == mappluto_lot_files$vintage[i]
    ) |>
    distinct(candidate_base_bbl)

  if (nrow(needed_bbl) == 0) {
    next
  }

  staged_bbl_count_rows[[length(staged_bbl_count_rows) + 1L]] <- open_dataset(staged_parquet_path) |>
    select(bbl) |>
    filter(bbl %in% needed_bbl$candidate_base_bbl) |>
    collect() |>
    mutate(
      source_id = mappluto_lot_files$source_id[i],
      vintage = mappluto_lot_files$vintage[i],
      bbl = as.character(bbl)
    ) |>
    count(source_id, vintage, bbl, name = "selected_lagged_bbl_count")
}

pluto_bbl_counts <- bind_rows(staged_bbl_count_rows)

if (nrow(pluto_bbl_counts) == 0) {
  pluto_bbl_counts <- tibble(
    source_id = character(),
    vintage = character(),
    bbl = character(),
    selected_lagged_bbl_count = integer()
  )
}

condo_crosswalk_candidates <- condo_crosswalk_candidates |>
  left_join(
    pluto_bbl_counts,
    by = c(
      "pluto_source_id_used" = "source_id",
      "pluto_version_used" = "vintage",
      "candidate_base_bbl" = "bbl"
    ),
    relationship = "many-to-one"
  ) |>
  mutate(
    selected_lagged_bbl_count = if_else(is.na(selected_lagged_bbl_count), 0L, selected_lagged_bbl_count),
    same_boro_block = hdb_borough == candidate_base_borough & hdb_block == candidate_base_block,
    candidate_in_lagged_pluto = selected_lagged_bbl_count > 0,
    candidate_unique_in_lagged_pluto = selected_lagged_bbl_count == 1,
    future_appdate_used_for_linkage = !is.na(appdate_max) & appdate_max > date_filed,
    candidate_status = case_when(
      !same_boro_block ~ "different_boro_block",
      selected_lagged_bbl_count == 1L ~ "same_block_unique_in_lagged_pluto",
      selected_lagged_bbl_count > 1L ~ "same_block_duplicate_in_lagged_pluto",
      TRUE ~ "same_block_not_in_lagged_pluto"
    )
  ) |>
  arrange(hdb_row_id, candidate_base_bbl)

candidate_resolution_counts <- condo_crosswalk_candidates |>
  group_by(hdb_row_id) |>
  summarise(
    n_crosswalk_candidates = n(),
    n_distinct_appbbl = n_distinct(candidate_base_bbl),
    n_same_boro_block_candidates = sum(same_boro_block),
    n_cross_boro_block_candidates = sum(!same_boro_block),
    n_unique_lagged_candidates = sum(same_boro_block & selected_lagged_bbl_count == 1L),
    n_duplicate_lagged_candidates = sum(same_boro_block & selected_lagged_bbl_count > 1L),
    n_not_in_lagged_candidates = sum(same_boro_block & selected_lagged_bbl_count == 0L),
    .groups = "drop"
  )

candidate_condo_matches <- condo_crosswalk_candidates |>
  filter(
    same_boro_block,
    selected_lagged_bbl_count == 1L
  ) |>
  group_by(hdb_row_id) |>
  filter(n_distinct(candidate_base_bbl) == 1L) |>
  summarise(
    job_number = first(job_number),
    date_filed = first(date_filed),
    filing_year = first(filing_year),
    classa_prop = first(classa_prop),
    y100 = first(y100),
    hdb_bbl = first(hdb_bbl),
    hdb_lot = first(hdb_lot),
    lot_ge_7500 = first(lot_ge_7500),
    candidate_feature_bbl = first(candidate_base_bbl),
    pluto_source_id_used = first(pluto_source_id_used),
    pluto_version_used = first(pluto_version_used),
    candidate_match_method = "pluto_appbbl_unique_same_block_lagged",
    evidence_sources = paste_unique(evidence_sources),
    evidence_vintages = paste_unique(evidence_vintages),
    condono_values = paste_unique(condono_values),
    appdate_min = min_date_value(appdate_min),
    appdate_max = max_date_value(appdate_max),
    future_appdate_used_for_linkage = any(future_appdate_used_for_linkage),
    .groups = "drop"
  )

candidate_feature_bbl_counts <- candidate_condo_matches |>
  count(candidate_feature_bbl, name = "candidate_feature_bbl_hdb_rows")

candidate_condo_matches <- candidate_condo_matches |>
  left_join(candidate_feature_bbl_counts, by = "candidate_feature_bbl", relationship = "many-to-one")

accepted_condo_matches <- candidate_condo_matches |>
  filter(candidate_feature_bbl_hdb_rows == 1L) |>
  transmute(
    hdb_row_id,
    job_number,
    date_filed,
    filing_year,
    classa_prop,
    y100,
    hdb_bbl,
    accepted_feature_bbl = candidate_feature_bbl,
    pluto_source_id_used,
    pluto_version_used,
    accepted_match_status = if_else(
      lot_ge_7500,
      "official_unique_appbbl_condo_lagged_match",
      "official_unique_appbbl_noncondo_lagged_match"
    ),
    match_method = candidate_match_method,
    evidence_sources,
    evidence_vintages,
    condono_values,
    appdate_min,
    appdate_max,
    future_appdate_used_for_linkage,
    candidate_feature_bbl_hdb_rows
  )

condo_match_resolution <- unmatched_hdb_condo_audit |>
  left_join(candidate_resolution_counts, by = "hdb_row_id", relationship = "one-to-one") |>
  left_join(
    candidate_condo_matches |>
      select(hdb_row_id, candidate_feature_bbl, candidate_match_method, candidate_feature_bbl_hdb_rows, future_appdate_used_for_linkage),
    by = "hdb_row_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    accepted_condo_matches |>
      transmute(hdb_row_id, accepted_feature_bbl, match_method, clean_accepted_match_status = accepted_match_status),
    by = "hdb_row_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    n_crosswalk_candidates = coalesce(n_crosswalk_candidates, 0L),
    n_distinct_appbbl = coalesce(n_distinct_appbbl, 0L),
    n_same_boro_block_candidates = coalesce(n_same_boro_block_candidates, 0L),
    n_cross_boro_block_candidates = coalesce(n_cross_boro_block_candidates, 0L),
    n_unique_lagged_candidates = coalesce(n_unique_lagged_candidates, 0L),
    n_duplicate_lagged_candidates = coalesce(n_duplicate_lagged_candidates, 0L),
    n_not_in_lagged_candidates = coalesce(n_not_in_lagged_candidates, 0L),
    future_appdate_used_for_linkage = coalesce(future_appdate_used_for_linkage, FALSE),
    candidate_feature_bbl_hdb_rows = coalesce(candidate_feature_bbl_hdb_rows, 0L),
    accepted_match_status = case_when(
      !is.na(accepted_feature_bbl) ~ clean_accepted_match_status,
      !is.na(candidate_feature_bbl) & candidate_feature_bbl_hdb_rows > 1L ~ "duplicate_feature_bbl_across_hdb_rows",
      n_crosswalk_candidates == 0L ~ "no_official_appbbl_candidate",
      n_unique_lagged_candidates > 1L ~ "ambiguous_multiple_lagged_candidates",
      n_distinct_appbbl > 1L ~ "ambiguous_multiple_appbbl",
      n_duplicate_lagged_candidates > 0L ~ "candidate_duplicate_in_lagged_pluto",
      n_same_boro_block_candidates > 0L ~ "official_appbbl_not_in_lagged_pluto",
      n_cross_boro_block_candidates > 0L ~ "only_cross_block_appbbl_candidate",
      TRUE ~ "unresolved"
    ),
    requires_aggregation = accepted_match_status %in% c("duplicate_feature_bbl_across_hdb_rows", "ambiguous_multiple_lagged_candidates", "ambiguous_multiple_appbbl"),
    manual_review_flag = !str_starts(accepted_match_status, "official_unique_appbbl_"),
    reason_not_accepted = if_else(str_starts(accepted_match_status, "official_unique_appbbl_"), NA_character_, accepted_match_status)
  ) |>
  arrange(hdb_row_id)

summary_rows <- list()

for (candidate_min_classa in c(NA_integer_, candidate_min_classa_props)) {
  if (is.na(candidate_min_classa)) {
    sample_rows <- panel |>
      filter(classa_prop_integer)
    cutoff_label <- "all_valid_classa"
  } else {
    sample_rows <- panel |>
      filter(classa_prop_integer, classa_prop >= candidate_min_classa)
    cutoff_label <- paste0(candidate_min_classa, "_plus")
  }

  sample_resolution <- condo_match_resolution |>
    filter(hdb_row_id %in% sample_rows$hdb_row_id)

  summary_rows[[length(summary_rows) + 1L]] <- tibble(
    candidate_cutoff = cutoff_label,
    total_hdb_rows = nrow(sample_rows),
    strict_matches = sum(sample_rows$primary_leakage_safe_sample & sample_rows$strict_bbl_match_status_for_audit == "matched_unique_bbl"),
    strict_no_matches = sum(sample_rows$strict_bbl_match_status_for_audit == "no_mappluto_match"),
    no_matches_lot_ge_7500 = sum(sample_rows$strict_bbl_match_status_for_audit == "no_mappluto_match" & sample_rows$lot_ge_7500),
    official_unique_appbbl_recovered = sum(str_starts(sample_resolution$accepted_match_status, "official_unique_appbbl_")),
    official_unique_condo_recovered = sum(sample_resolution$accepted_match_status == "official_unique_appbbl_condo_lagged_match"),
    official_unique_noncondo_recovered = sum(sample_resolution$accepted_match_status == "official_unique_appbbl_noncondo_lagged_match"),
    official_multi_base_aggregate_possible = sum(sample_resolution$requires_aggregation),
    duplicate_feature_bbl_across_hdb_rows = sum(sample_resolution$accepted_match_status == "duplicate_feature_bbl_across_hdb_rows"),
    ambiguous_multi_candidate = sum(sample_resolution$accepted_match_status %in% c("ambiguous_multiple_lagged_candidates", "ambiguous_multiple_appbbl")),
    official_appbbl_not_in_lagged_pluto = sum(sample_resolution$accepted_match_status == "official_appbbl_not_in_lagged_pluto"),
    still_unmatched = sum(!str_starts(sample_resolution$accepted_match_status, "official_unique_appbbl_")),
    future_appdate_used_for_linkage = sum(sample_resolution$future_appdate_used_for_linkage)
  )
}

condo_recovery_summary <- bind_rows(summary_rows)

comparison_rows <- list()

for (candidate_min_classa in candidate_min_classa_props) {
  strict_sample <- panel |>
    filter(classa_prop_integer, classa_prop >= candidate_min_classa, primary_leakage_safe_sample) |>
    mutate(recovery_group = "strict_bbl_match")

  recovered_sample <- condo_match_resolution |>
    filter(str_starts(accepted_match_status, "official_unique_appbbl_")) |>
    inner_join(
      panel |>
        select(hdb_row_id, classa_prop_integer),
      by = "hdb_row_id",
      relationship = "one-to-one"
    ) |>
    filter(classa_prop_integer, classa_prop >= candidate_min_classa) |>
    mutate(recovery_group = "official_unique_appbbl_recovered")

  comparison_rows[[length(comparison_rows) + 1L]] <- bind_rows(
    strict_sample |>
      transmute(candidate_min_classa_prop = candidate_min_classa, recovery_group, filing_year, hdb_borough_name, classa_prop, y100),
    recovered_sample |>
      transmute(candidate_min_classa_prop = candidate_min_classa, recovery_group, filing_year, hdb_borough_name, classa_prop, y100)
  ) |>
    group_by(candidate_min_classa_prop, recovery_group) |>
    summarise(
      rows = n(),
      y100_rows = sum(y100),
      y100_share = mean(y100),
      mean_classa_prop = mean(classa_prop),
      median_classa_prop = median(classa_prop),
      .groups = "drop"
    )
}

condo_recovered_sample_comparison <- bind_rows(comparison_rows) |>
  arrange(candidate_min_classa_prop, recovery_group)

window_definitions <- tibble(
  window = c("all_2010_2023", "model_2016_to_2022_0615", "current_2018_to_2022_0615"),
  window_start = as.Date(c("2010-01-01", "2016-01-01", "2018-01-01")),
  window_end = as.Date(c("2023-12-31", "2022-06-15", "2022-06-15"))
)

status_by_window_rows <- list()

for (window_i in seq_len(nrow(window_definitions))) {
  for (candidate_min_classa in candidate_min_classa_props) {
    window_resolution <- condo_match_resolution |>
      filter(
        date_filed >= window_definitions$window_start[window_i],
        date_filed <= window_definitions$window_end[window_i],
        classa_prop >= candidate_min_classa
      )

    status_by_window_rows[[length(status_by_window_rows) + 1L]] <- window_resolution |>
      group_by(accepted_match_status) |>
      summarise(
        rows = n(),
        y100_rows = sum(y100),
        y100_share = mean(y100),
        lot_ge_7500_rows = sum(lot_ge_7500),
        mean_classa_prop = mean(classa_prop),
        median_classa_prop = median(classa_prop),
        future_appdate_used_for_linkage = sum(future_appdate_used_for_linkage),
        .groups = "drop"
      ) |>
      mutate(
        window = window_definitions$window[window_i],
        window_start = window_definitions$window_start[window_i],
        window_end = window_definitions$window_end[window_i],
        candidate_min_classa_prop = candidate_min_classa,
        row_share = rows / sum(rows),
        .before = accepted_match_status
      )
  }
}

condo_recovery_status_by_window <- bind_rows(status_by_window_rows) |>
  arrange(window, candidate_min_classa_prop, desc(rows), accepted_match_status)

condo_recovery_status_by_year <- condo_match_resolution |>
  filter(classa_prop >= 50) |>
  group_by(filing_year, accepted_match_status) |>
  summarise(
    rows = n(),
    y100_rows = sum(y100),
    y100_share = mean(y100),
    mean_classa_prop = mean(classa_prop),
    median_classa_prop = median(classa_prop),
    .groups = "drop"
  ) |>
  arrange(filing_year, accepted_match_status)

condo_recovery_status_by_borough <- condo_match_resolution |>
  filter(classa_prop >= 50) |>
  group_by(hdb_borough_name, accepted_match_status) |>
  summarise(
    rows = n(),
    y100_rows = sum(y100),
    y100_share = mean(y100),
    mean_classa_prop = mean(classa_prop),
    median_classa_prop = median(classa_prop),
    .groups = "drop"
  ) |>
  arrange(hdb_borough_name, accepted_match_status)

duplicate_feature_bbl_groups <- condo_match_resolution |>
    filter(accepted_match_status == "duplicate_feature_bbl_across_hdb_rows") |>
  group_by(candidate_feature_bbl) |>
  summarise(
    hdb_rows = n(),
    job_numbers = paste_unique(job_number),
    hdb_bbls = paste_unique(hdb_bbl),
    boroughs = paste_unique(hdb_borough_name),
    filing_years = paste_unique(filing_year),
    addresses = paste_unique(address),
    total_classa_prop = sum(classa_prop),
    max_classa_prop = max(classa_prop),
    median_classa_prop = median(classa_prop),
    .groups = "drop"
  ) |>
  arrange(desc(hdb_rows), desc(total_classa_prop), candidate_feature_bbl)

large_unresolved_no_match_examples <- condo_match_resolution |>
  filter(classa_prop >= 50, !str_starts(accepted_match_status, "official_unique_appbbl_")) |>
  arrange(desc(classa_prop), accepted_match_status, hdb_row_id) |>
  transmute(
    hdb_row_id,
    job_number,
    date_filed,
    filing_year,
    hdb_borough_name,
    address,
    hdb_bbl,
    hdb_lot,
    classa_prop,
    y100,
    accepted_match_status,
    candidate_feature_bbl,
    candidate_feature_bbl_hdb_rows,
    n_crosswalk_candidates,
    n_same_boro_block_candidates,
    n_not_in_lagged_candidates,
    future_appdate_used_for_linkage
  )

write_csv_if_changed(condo_recovery_summary, "../output/condo_recovery_summary.csv")
write_csv_if_changed(unmatched_hdb_condo_audit, "../output/unmatched_hdb_condo_audit.csv")
write_csv_if_changed(condo_crosswalk_candidates, "../output/condo_crosswalk_candidates.csv")
write_csv_if_changed(condo_match_resolution, "../output/condo_match_resolution.csv")
write_csv_if_changed(accepted_condo_matches, "../output/accepted_condo_matches.csv")
write_csv_if_changed(condo_recovered_sample_comparison, "../output/condo_recovered_sample_comparison.csv")
write_csv_if_changed(condo_recovery_status_by_window, "../output/condo_recovery_status_by_window.csv")
write_csv_if_changed(condo_recovery_status_by_year, "../output/condo_recovery_status_by_year.csv")
write_csv_if_changed(condo_recovery_status_by_borough, "../output/condo_recovery_status_by_borough.csv")
write_csv_if_changed(duplicate_feature_bbl_groups, "../output/duplicate_feature_bbl_groups.csv")
write_csv_if_changed(large_unresolved_no_match_examples, "../output/large_unresolved_no_match_examples.csv")

cat("Wrote HDB-MapPLUTO condo recovery audit outputs to ../output\n")

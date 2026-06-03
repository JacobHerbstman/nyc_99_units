# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_hdb_mappluto_training_panel/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA"))
deadline_421a <- as.Date("2022-06-15")

missing_mappluto_columns <- setdiff(c("source_id", "vintage", "parquet_path"), names(mappluto_lot_files))

if (length(missing_mappluto_columns) > 0) {
  stop("MapPLUTO lot manifest is missing columns: ", paste(missing_mappluto_columns, collapse = ", "))
}

mappluto_lot_files <- mappluto_lot_files |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    parquet_path = as.character(parquet_path)
  )

make_filing_quarter <- function(date_values) {
  quarter_number <- ((as.integer(format(date_values, "%m")) - 1L) %/% 3L) + 1L
  ifelse(is.na(date_values), NA_character_, paste0(format(date_values, "%Y"), "Q", quarter_number))
}

make_y100_group <- function(y100_values) {
  case_when(
    y100_values %in% TRUE ~ "y100",
    y100_values %in% FALSE ~ "below100_valid_units",
    TRUE ~ "invalid_or_missing_classa_prop"
  )
}

make_unit_bin <- function(classa_prop_values, valid_classa_values) {
  case_when(
    !(valid_classa_values %in% TRUE) ~ "00_invalid_or_missing",
    classa_prop_values >= 1 & classa_prop_values <= 5 ~ "01_1_5",
    classa_prop_values >= 6 & classa_prop_values <= 20 ~ "02_6_20",
    classa_prop_values >= 21 & classa_prop_values <= 49 ~ "03_21_49",
    classa_prop_values >= 50 & classa_prop_values <= 79 ~ "04_50_79",
    classa_prop_values >= 80 & classa_prop_values <= 98 ~ "05_80_98",
    classa_prop_values == 99 ~ "06_99",
    classa_prop_values == 100 ~ "07_100",
    classa_prop_values >= 101 & classa_prop_values <= 149 ~ "08_101_149",
    classa_prop_values >= 150 & classa_prop_values <= 299 ~ "09_150_299",
    classa_prop_values >= 300 ~ "10_300_plus",
    TRUE ~ "00_invalid_or_missing"
  )
}

normalise_site_address <- function(address_values) {
  str_squish(str_replace_all(str_to_upper(coalesce(address_values, "")), "[^A-Z0-9]+", " "))
}

counts_by_year <- panel |>
  group_by(filing_year) |>
  summarise(
    candidate_rows = n(),
    candidate_valid_classa_rows = sum(classa_prop_integer, na.rm = TRUE),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    primary_leakage_safe_rows = sum(primary_leakage_safe_sample, na.rm = TRUE),
    post_filing_backfill_primary_rows = sum(primary_sample & pluto_timing_status == "post_filing_backfill", na.rm = TRUE),
    latest_pre_filing_no_lag_primary_rows = sum(primary_sample & pluto_timing_status == "latest_pre_filing_no_lag", na.rm = TRUE),
    y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    candidate_y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    primary_y100_rows = sum(primary_sample & y100 %in% TRUE, na.rm = TRUE),
    primary_leakage_safe_y100_rows = sum(primary_leakage_safe_sample & y100 %in% TRUE, na.rm = TRUE),
    post_filing_backfill_primary_y100_rows = sum(
      primary_sample & pluto_timing_status == "post_filing_backfill" & y100 %in% TRUE,
      na.rm = TRUE
    ),
    latest_pre_filing_no_lag_primary_y100_rows = sum(
      primary_sample & pluto_timing_status == "latest_pre_filing_no_lag" & y100 %in% TRUE,
      na.rm = TRUE
    ),
    excluded_rows = sum(!primary_sample, na.rm = TRUE),
    excluded_y100_rows = sum(!primary_sample & y100 %in% TRUE, na.rm = TRUE),
    invalid_bbl_rows = sum(exclusion_reason == "invalid_bbl", na.rm = TRUE),
    no_lagged_pluto_rows = sum(exclusion_reason == "no_lagged_pluto_available", na.rm = TRUE),
    no_pluto_release_assigned_rows = sum(exclusion_reason == "no_pluto_release_assigned", na.rm = TRUE),
    no_mappluto_match_rows = sum(exclusion_reason == "no_mappluto_match", na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    candidate_y100_share = if_else(candidate_rows > 0, candidate_y100_rows / candidate_rows, NA_real_),
    candidate_y100_share_valid_classa = if_else(
      candidate_valid_classa_rows > 0,
      candidate_y100_rows / candidate_valid_classa_rows,
      NA_real_
    ),
    primary_y100_share = if_else(primary_rows > 0, primary_y100_rows / primary_rows, NA_real_),
    primary_leakage_safe_y100_share = if_else(
      primary_leakage_safe_rows > 0,
      primary_leakage_safe_y100_rows / primary_leakage_safe_rows,
      NA_real_
    ),
    excluded_y100_share = if_else(excluded_rows > 0, excluded_y100_rows / excluded_rows, NA_real_)
  )

candidate_primary_y100 <- counts_by_year |>
  select(
    filing_year,
    candidate_rows,
    candidate_valid_classa_rows,
    candidate_y100_rows,
    candidate_y100_share,
    candidate_y100_share_valid_classa,
    primary_rows,
    primary_y100_rows,
    primary_y100_share,
    primary_leakage_safe_rows,
    primary_leakage_safe_y100_rows,
    primary_leakage_safe_y100_share,
    post_filing_backfill_primary_rows,
    post_filing_backfill_primary_y100_rows,
    latest_pre_filing_no_lag_primary_rows,
    latest_pre_filing_no_lag_primary_y100_rows,
    excluded_rows,
    excluded_y100_rows,
    excluded_y100_share
  )

exclusion_reasons <- panel |>
  count(filing_year, exclusion_reason, name = "rows") |>
  arrange(filing_year, desc(rows), exclusion_reason)

exclusion_reason_by_y100 <- panel |>
  mutate(y100_group = make_y100_group(y100)) |>
  count(filing_year, y100_group, primary_sample, exclusion_reason, name = "rows") |>
  arrange(filing_year, y100_group, primary_sample, desc(rows), exclusion_reason)

vintage_use <- panel |>
  count(
    filing_year,
    pluto_version_latest_pre_filing,
    pluto_version_used,
    pluto_timing_status,
    primary_sample,
    primary_leakage_safe_sample,
    exclusion_reason,
    name = "rows"
  ) |>
  arrange(filing_year, pluto_version_used, pluto_timing_status, primary_sample, exclusion_reason)

release_design_by_year <- panel |>
  mutate(y100_group = make_y100_group(y100)) |>
  count(
    filing_year,
    pluto_timing_status,
    post_filing_pluto,
    primary_sample,
    primary_leakage_safe_sample,
    y100_group,
    exclusion_reason,
    name = "rows"
  ) |>
  arrange(filing_year, pluto_timing_status, primary_sample, y100_group, desc(rows), exclusion_reason)

timing_distance_by_year <- panel |>
  filter(!is.na(pluto_days_relative_to_filing)) |>
  group_by(filing_year, pluto_timing_status) |>
  summarise(
    rows = n(),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    primary_y100_rows = sum(primary_sample & y100 %in% TRUE, na.rm = TRUE),
    post_filing_pluto_rows = sum(post_filing_pluto, na.rm = TRUE),
    min_days_relative_to_filing = min(pluto_days_relative_to_filing, na.rm = TRUE),
    p25_days_relative_to_filing = quantile(pluto_days_relative_to_filing, 0.25, na.rm = TRUE, names = FALSE),
    median_days_relative_to_filing = median(pluto_days_relative_to_filing, na.rm = TRUE),
    mean_days_relative_to_filing = mean(pluto_days_relative_to_filing, na.rm = TRUE),
    p75_days_relative_to_filing = quantile(pluto_days_relative_to_filing, 0.75, na.rm = TRUE, names = FALSE),
    max_days_relative_to_filing = max(pluto_days_relative_to_filing, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(filing_year, pluto_timing_status)

hdb_only_unit_bins <- panel |>
  mutate(unit_bin = make_unit_bin(classa_prop, classa_prop_integer)) |>
  group_by(filing_year, unit_bin) |>
  summarise(
    candidate_rows = n(),
    candidate_y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    primary_y100_rows = sum(primary_sample & y100 %in% TRUE, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(filing_year, unit_bin)

threshold_values <- 95:105
threshold_years <- sort(unique(panel$filing_year))
threshold_grid <- tibble(
  filing_year = rep(threshold_years, each = length(threshold_values)),
  classa_prop = rep(threshold_values, times = length(threshold_years))
)

threshold_95_105 <- panel |>
  filter(classa_prop_integer, classa_prop >= min(threshold_values), classa_prop <= max(threshold_values)) |>
  mutate(classa_prop = as.integer(classa_prop)) |>
  group_by(filing_year, classa_prop) |>
  summarise(
    candidate_rows = n(),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    .groups = "drop"
  ) |>
  right_join(threshold_grid, by = c("filing_year", "classa_prop")) |>
  mutate(
    candidate_rows = if_else(is.na(candidate_rows), 0L, candidate_rows),
    primary_rows = if_else(is.na(primary_rows), 0L, primary_rows)
  ) |>
  arrange(filing_year, classa_prop)

filing_quarter_y100 <- panel |>
  mutate(
    filing_quarter = make_filing_quarter(date_filed),
    after_421a_commencement_deadline = case_when(
      is.na(date_filed) ~ NA,
      date_filed > deadline_421a ~ TRUE,
      TRUE ~ FALSE
    )
  ) |>
  group_by(filing_year, filing_quarter, after_421a_commencement_deadline) |>
  summarise(
    candidate_rows = n(),
    candidate_valid_classa_rows = sum(classa_prop_integer, na.rm = TRUE),
    candidate_y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    primary_y100_rows = sum(primary_sample & y100 %in% TRUE, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    candidate_y100_share = if_else(candidate_rows > 0, candidate_y100_rows / candidate_rows, NA_real_),
    candidate_y100_share_valid_classa = if_else(
      candidate_valid_classa_rows > 0,
      candidate_y100_rows / candidate_valid_classa_rows,
      NA_real_
    ),
    primary_y100_share = if_else(primary_rows > 0, primary_y100_rows / primary_rows, NA_real_)
  ) |>
  arrange(filing_quarter, after_421a_commencement_deadline)

summarise_window <- function(window_name, window_rows) {
  primary_rows <- sum(window_rows$primary_sample, na.rm = TRUE)
  primary_y100_rows <- sum(window_rows$primary_sample & window_rows$y100 %in% TRUE, na.rm = TRUE)
  primary_leakage_safe_rows <- sum(window_rows$primary_leakage_safe_sample, na.rm = TRUE)
  primary_leakage_safe_y100_rows <- sum(window_rows$primary_leakage_safe_sample & window_rows$y100 %in% TRUE, na.rm = TRUE)
  post_filing_backfill_rows <- sum(
    window_rows$primary_sample & window_rows$pluto_timing_status == "post_filing_backfill",
    na.rm = TRUE
  )
  latest_pre_filing_no_lag_rows <- sum(
    window_rows$primary_sample & window_rows$pluto_timing_status == "latest_pre_filing_no_lag",
    na.rm = TRUE
  )

  tibble(
    window = window_name,
    candidate_rows = nrow(window_rows),
    candidate_valid_classa_rows = sum(window_rows$classa_prop_integer, na.rm = TRUE),
    candidate_y100_rows = sum(window_rows$y100 %in% TRUE, na.rm = TRUE),
    candidate_y100_share = if_else(nrow(window_rows) > 0, mean(window_rows$y100 %in% TRUE, na.rm = TRUE), NA_real_),
    primary_rows = primary_rows,
    primary_y100_rows = primary_y100_rows,
    primary_y100_share = if_else(primary_rows > 0, primary_y100_rows / primary_rows, NA_real_),
    primary_leakage_safe_rows = primary_leakage_safe_rows,
    primary_leakage_safe_y100_rows = primary_leakage_safe_y100_rows,
    primary_leakage_safe_y100_share = if_else(
      primary_leakage_safe_rows > 0,
      primary_leakage_safe_y100_rows / primary_leakage_safe_rows,
      NA_real_
    ),
    post_filing_backfill_primary_rows = post_filing_backfill_rows,
    latest_pre_filing_no_lag_primary_rows = latest_pre_filing_no_lag_rows,
    first_date_filed = safe_min_date(window_rows$date_filed),
    last_date_filed = safe_max_date(window_rows$date_filed)
  )
}

model_windows <- bind_rows(
  summarise_window(
    "expanded_backfill_train_2016_to_2022_06_15",
    panel |> filter(date_filed >= as.Date("2016-01-01"), date_filed <= deadline_421a)
  ),
  summarise_window(
    "primary_leakage_safe_train_pre_deadline",
    panel |> filter(primary_leakage_safe_sample, date_filed >= as.Date("2016-01-01"), date_filed <= deadline_421a)
  ),
  summarise_window(
    "transition_post_deadline_2022",
    panel |> filter(date_filed > deadline_421a, filing_year == 2022)
  ),
  summarise_window(
    "post_421a_gap_2023",
    panel |> filter(filing_year == 2023)
  )
)

feature_names <- c(
  "lotarea", "bldgarea", "resarea", "comarea", "unitsres", "unitstotal",
  "numbldgs", "numfloors", "yearbuilt", "builtfar", "residfar", "commfar",
  "facilfar", "assessland", "assesstot", "allowed_res_area", "residual_res_area",
  "zonedist1", "landuse", "bldgclass"
)

feature_missingness_rows <- list()

for (i in seq_along(feature_names)) {
  feature_name <- feature_names[i]
  feature_values <- panel[[feature_name]]

  feature_missingness_rows[[i]] <- tibble(
    feature = feature_name,
    candidate_rows = nrow(panel),
    candidate_missing_rows = sum(is.na(feature_values)),
    candidate_missing_share = mean(is.na(feature_values)),
    primary_rows = sum(panel$primary_sample, na.rm = TRUE),
    primary_missing_rows = sum(panel$primary_sample & is.na(feature_values), na.rm = TRUE),
    primary_missing_share = mean(is.na(feature_values[panel$primary_sample])),
    primary_pre_deadline_missing_share = mean(is.na(feature_values[panel$primary_sample & panel$date_filed <= deadline_421a])),
    primary_post_deadline_2022_missing_share = mean(is.na(feature_values[
      panel$primary_sample & panel$date_filed > deadline_421a & panel$filing_year == 2022
    ])),
    primary_2023_missing_share = mean(is.na(feature_values[panel$primary_sample & panel$filing_year == 2023]))
  )
}

feature_missingness <- bind_rows(feature_missingness_rows)

duplicate_bbl_jobs <- panel |>
  filter(!is.na(bbl), bbl != "") |>
  group_by(bbl) |>
  summarise(
    hdb_job_rows = n(),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    first_date_filed = safe_min_date(date_filed),
    last_date_filed = safe_max_date(date_filed),
    job_numbers = paste(sort(unique(job_number)), collapse = ";"),
    addresses = paste(sort(unique(na.omit(address))), collapse = ";"),
    y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(hdb_job_rows > 1) |>
  arrange(desc(hdb_job_rows), bbl)

comparison_features <- c(
  "classa_prop", "lotarea", "residfar", "allowed_res_area", "residual_res_area",
  "bldgarea", "resarea", "unitsres", "numfloors", "yearbuilt", "assessland"
)

comparison_rows <- list()
comparison_counter <- 0L

for (feature_name in comparison_features) {
  for (period_name in c(
    "pre_deadline_expanded_backfill",
    "pre_deadline_primary_leakage_safe",
    "post_deadline_2022_primary",
    "holdout_2023"
  )) {
    period_rows <- panel |>
      filter(
        case_when(
          period_name == "pre_deadline_expanded_backfill" ~ primary_sample & date_filed <= deadline_421a,
          period_name == "pre_deadline_primary_leakage_safe" ~ primary_leakage_safe_sample & date_filed <= deadline_421a,
          period_name == "post_deadline_2022_primary" ~ primary_sample & date_filed > deadline_421a & filing_year == 2022,
          TRUE ~ primary_sample & filing_year == 2023
        )
      )
    values <- period_rows[[feature_name]]

    comparison_counter <- comparison_counter + 1L
    comparison_rows[[comparison_counter]] <- tibble(
      period = period_name,
      feature = feature_name,
      rows = nrow(period_rows),
      nonmissing_rows = sum(!is.na(values)),
      mean_value = if (all(is.na(values))) NA_real_ else mean(values, na.rm = TRUE),
      median_value = if (all(is.na(values))) NA_real_ else median(values, na.rm = TRUE)
    )
  }
}

for (period_name in c(
  "pre_deadline_expanded_backfill",
  "pre_deadline_primary_leakage_safe",
  "post_deadline_2022_primary",
  "holdout_2023"
)) {
  period_rows <- panel |>
    filter(
      case_when(
        period_name == "pre_deadline_expanded_backfill" ~ primary_sample & date_filed <= deadline_421a,
        period_name == "pre_deadline_primary_leakage_safe" ~ primary_leakage_safe_sample & date_filed <= deadline_421a,
        period_name == "post_deadline_2022_primary" ~ primary_sample & date_filed > deadline_421a & filing_year == 2022,
        TRUE ~ primary_sample & filing_year == 2023
      )
    )

  comparison_counter <- comparison_counter + 1L
  comparison_rows[[comparison_counter]] <- tibble(
    period = period_name,
    feature = "y100",
    rows = nrow(period_rows),
    nonmissing_rows = sum(!is.na(period_rows$y100)),
    mean_value = mean(period_rows$y100, na.rm = TRUE),
    median_value = median(as.numeric(period_rows$y100), na.rm = TRUE)
  )
}

comparison_2023 <- bind_rows(comparison_rows) |>
  arrange(feature, period)

latest_lag_features <- c(
  "lotarea", "residfar", "builtfar", "bldgarea", "resarea", "unitsres",
  "numfloors", "yearbuilt", "assessland", "zonedist1", "landuse", "bldgclass"
)

latest_feature_rows <- list()
latest_versions <- panel |>
  filter(
    primary_sample,
    !is.na(pluto_version_latest_pre_filing),
    !is.na(pluto_version_used),
    pluto_version_latest_pre_filing != pluto_version_used
  ) |>
  distinct(pluto_version_latest_pre_filing) |>
  arrange(pluto_version_latest_pre_filing)

for (i in seq_len(nrow(latest_versions))) {
  latest_version <- latest_versions$pluto_version_latest_pre_filing[i]
  latest_path <- mappluto_lot_files |>
    filter(source_id == "dcp_mappluto_archive", vintage == latest_version) |>
    pull(parquet_path)

  if (length(latest_path) != 1) {
    next
  }

  parquet_path <- file.path("..", "..", "..", "stage_mappluto_lots", "output", basename(latest_path))

  if (!file.exists(parquet_path)) {
    next
  }

  needed_bbl <- panel |>
    filter(primary_sample, pluto_version_latest_pre_filing == latest_version) |>
    distinct(bbl)

  latest_lots <- read_parquet(parquet_path) |>
    as.data.frame() |>
    as_tibble() |>
    mutate(bbl = as.character(bbl)) |>
    filter(bbl %in% needed_bbl$bbl) |>
    add_count(bbl, name = "mappluto_bbl_rows") |>
    filter(mappluto_bbl_rows == 1) |>
    select(bbl, all_of(latest_lag_features)) |>
    rename_with(~ paste0("latest_", .x), all_of(latest_lag_features))

  latest_feature_rows[[i]] <- panel |>
    filter(primary_sample, pluto_version_latest_pre_filing == latest_version) |>
    select(
      job_number, bbl, pluto_version_used, pluto_version_latest_pre_filing,
      all_of(latest_lag_features)
    ) |>
    left_join(latest_lots, by = "bbl", relationship = "many-to-one")
}

latest_lag_panel <- if (length(latest_feature_rows) == 0) {
  tibble()
} else {
  bind_rows(latest_feature_rows)
}

latest_vs_lag_rows <- list()

for (i in seq_along(latest_lag_features)) {
  feature_name <- latest_lag_features[i]

  if (nrow(latest_lag_panel) == 0) {
    latest_vs_lag_rows[[i]] <- tibble(
      feature = feature_name,
      compared_rows = 0L,
      rows_with_latest_match = 0L,
      differing_rows = NA_integer_,
      differing_share = NA_real_,
      mean_abs_difference = NA_real_
    )
    next
  }

  lag_values <- latest_lag_panel[[feature_name]]
  latest_values <- latest_lag_panel[[paste0("latest_", feature_name)]]
  comparable <- !is.na(lag_values) & !is.na(latest_values)

  if (is.numeric(lag_values)) {
    difference_flag <- comparable & abs(lag_values - latest_values) > 1e-8
    mean_abs_difference <- if (sum(comparable) == 0) NA_real_ else mean(abs(lag_values[comparable] - latest_values[comparable]), na.rm = TRUE)
  } else {
    difference_flag <- comparable & as.character(lag_values) != as.character(latest_values)
    mean_abs_difference <- NA_real_
  }

  latest_vs_lag_rows[[i]] <- tibble(
    feature = feature_name,
    compared_rows = nrow(latest_lag_panel),
    rows_with_latest_match = sum(comparable),
    differing_rows = sum(difference_flag, na.rm = TRUE),
    differing_share = if (sum(comparable) == 0) NA_real_ else mean(difference_flag[comparable]),
    mean_abs_difference = mean_abs_difference
  )
}

latest_vs_lag <- bind_rows(latest_vs_lag_rows)

latest_2023_candidates <- panel |>
  filter(filing_year == 2023) |>
  select(
    job_number,
    date_filed,
    bbl,
    classa_prop,
    classa_prop_integer,
    y100,
    valid_bbl,
    primary_sample,
    exclusion_reason,
    pluto_version_used,
    pluto_version_latest_pre_filing
  )

latest_2023_match_rows <- list()
latest_2023_versions <- latest_2023_candidates |>
  filter(!is.na(pluto_version_latest_pre_filing)) |>
  distinct(pluto_version_latest_pre_filing) |>
  arrange(pluto_version_latest_pre_filing)

for (i in seq_len(nrow(latest_2023_versions))) {
  latest_version <- latest_2023_versions$pluto_version_latest_pre_filing[i]
  latest_path <- mappluto_lot_files |>
    filter(source_id == "dcp_mappluto_archive", vintage == latest_version) |>
    pull(parquet_path)

  needed_bbl <- latest_2023_candidates |>
    filter(pluto_version_latest_pre_filing == latest_version, valid_bbl) |>
    distinct(bbl) |>
    mutate(pluto_version_latest_pre_filing = latest_version)

  if (length(latest_path) != 1) {
    latest_2023_match_rows[[i]] <- needed_bbl |>
      mutate(
        latest_match_status = "latest_pluto_file_missing",
        latest_lotarea = NA_real_,
        latest_mappluto_bbl_rows = NA_integer_
      )
    next
  }

  parquet_path <- file.path("..", "..", "..", "stage_mappluto_lots", "output", basename(latest_path))

  if (!file.exists(parquet_path)) {
    latest_2023_match_rows[[i]] <- needed_bbl |>
      mutate(
        latest_match_status = "latest_pluto_file_missing",
        latest_lotarea = NA_real_,
        latest_mappluto_bbl_rows = NA_integer_
      )
    next
  }

  latest_status <- read_parquet(parquet_path) |>
    as.data.frame() |>
    as_tibble() |>
    mutate(bbl = as.character(bbl)) |>
    filter(bbl %in% needed_bbl$bbl) |>
    group_by(bbl) |>
    summarise(
      latest_mappluto_bbl_rows = n(),
      latest_lotarea = if_else(n() == 1L, as.numeric(first(lotarea)), NA_real_),
      latest_match_status = if_else(n() == 1L, "matched_unique", "duplicate_mappluto_bbl"),
      .groups = "drop"
    ) |>
    mutate(pluto_version_latest_pre_filing = latest_version)

  latest_2023_match_rows[[i]] <- needed_bbl |>
    left_join(latest_status, by = c("pluto_version_latest_pre_filing", "bbl"), relationship = "many-to-one") |>
    mutate(
      latest_match_status = if_else(is.na(latest_match_status), "no_mappluto_match", latest_match_status)
    )
}

latest_2023_matches <- if (length(latest_2023_match_rows) == 0) {
  tibble(
    pluto_version_latest_pre_filing = character(),
    bbl = character(),
    latest_match_status = character(),
    latest_lotarea = numeric(),
    latest_mappluto_bbl_rows = integer()
  )
} else {
  bind_rows(latest_2023_match_rows)
}

latest_2023_panel <- latest_2023_candidates |>
  left_join(latest_2023_matches, by = c("pluto_version_latest_pre_filing", "bbl"), relationship = "many-to-one") |>
  mutate(
    latest_match_status = case_when(
      is.na(pluto_version_latest_pre_filing) ~ NA_character_,
      !(valid_bbl %in% TRUE) ~ NA_character_,
      is.na(latest_match_status) ~ "no_mappluto_match",
      TRUE ~ latest_match_status
    ),
    latest_primary_sample = valid_bbl %in% TRUE &
      classa_prop_integer %in% TRUE &
      !is.na(pluto_version_latest_pre_filing) &
      latest_match_status == "matched_unique" &
      !is.na(latest_lotarea) &
      latest_lotarea > 0,
    latest_exclusion_reason = case_when(
      !(valid_bbl %in% TRUE) ~ "invalid_bbl",
      !(classa_prop_integer %in% TRUE) ~ "invalid_classa_prop",
      is.na(pluto_version_latest_pre_filing) ~ "no_pre_filing_pluto_release",
      latest_match_status == "latest_pluto_file_missing" ~ "latest_pluto_file_missing",
      latest_match_status == "duplicate_mappluto_bbl" ~ "duplicate_mappluto_bbl",
      latest_match_status == "no_mappluto_match" ~ "no_mappluto_match",
      is.na(latest_lotarea) | latest_lotarea <= 0 ~ "nonpositive_lotarea",
      TRUE ~ "included_latest_pre_filing_sample"
    ),
    y100_group = make_y100_group(y100)
  )

latest_vs_lag1_2023_summary <- tibble(
  vintage_rule = c("one_release_lag", "latest_pre_filing"),
  candidate_rows = nrow(latest_2023_panel),
  included_rows = c(
    sum(latest_2023_panel$primary_sample, na.rm = TRUE),
    sum(latest_2023_panel$latest_primary_sample, na.rm = TRUE)
  ),
  included_y100_rows = c(
    sum(latest_2023_panel$primary_sample & latest_2023_panel$y100 %in% TRUE, na.rm = TRUE),
    sum(latest_2023_panel$latest_primary_sample & latest_2023_panel$y100 %in% TRUE, na.rm = TRUE)
  )
) |>
  mutate(
    included_y100_share = if_else(included_rows > 0, included_y100_rows / included_rows, NA_real_)
  )

latest_vs_lag1_2023_inclusion <- latest_2023_panel |>
  count(
    primary_sample,
    latest_primary_sample,
    y100_group,
    exclusion_reason,
    latest_exclusion_reason,
    name = "rows"
  ) |>
  arrange(primary_sample, latest_primary_sample, y100_group, desc(rows), exclusion_reason, latest_exclusion_reason)

site_base <- panel |>
  filter(classa_prop_integer) |>
  mutate(
    filing_quarter = make_filing_quarter(date_filed),
    bbl_block = if_else(valid_bbl, substr(bbl, 1, 6), NA_character_),
    address_normalized = normalise_site_address(address),
    bbl_site_key = if_else(valid_bbl, bbl, NA_character_),
    address_site_key = if_else(
      address_normalized == "",
      NA_character_,
      paste0(coalesce(as.character(hdb_borough_code), "missing_borough"), ":", address_normalized)
    ),
    block_site_key = if_else(valid_bbl, bbl_block, NA_character_)
  )

site_methods <- c(
  bbl_quarter = "bbl_site_key",
  address_quarter = "address_site_key",
  block_quarter = "block_site_key"
)

site_cluster_rows <- list()

for (i in seq_along(site_methods)) {
  site_method <- names(site_methods)[i]
  key_column <- site_methods[i]

  site_cluster_rows[[i]] <- site_base |>
    filter(!is.na(.data[[key_column]]), .data[[key_column]] != "", !is.na(filing_quarter)) |>
    group_by(filing_year, filing_quarter, site_key = .data[[key_column]]) |>
    summarise(
      cluster_rows = n(),
      primary_rows = sum(primary_sample, na.rm = TRUE),
      site_classa_prop = sum(classa_prop, na.rm = TRUE),
      max_job_classa_prop = max(classa_prop, na.rm = TRUE),
      min_job_classa_prop = min(classa_prop, na.rm = TRUE),
      all_jobs_sub100 = all(classa_prop < 100),
      any_job_y100 = any(y100 %in% TRUE),
      job_numbers = paste(sort(unique(job_number)), collapse = ";"),
      bbls = paste(sort(unique(na.omit(bbl))), collapse = ";"),
      addresses = paste(sort(unique(na.omit(address))), collapse = ";"),
      .groups = "drop"
    ) |>
    mutate(
      site_method = site_method,
      site_y100 = site_classa_prop >= 100
    ) |>
    select(site_method, everything())
}

site_clusters <- bind_rows(site_cluster_rows)

same_site_aggregation <- site_clusters |>
  group_by(site_method, filing_year) |>
  summarise(
    clusters = n(),
    candidate_job_rows = sum(cluster_rows),
    primary_job_rows = sum(primary_rows),
    multi_job_clusters = sum(cluster_rows > 1),
    site_y100_clusters = sum(site_y100),
    exact_99_clusters = sum(site_classa_prop == 99),
    all_sub100_site_y100_clusters = sum(site_y100 & all_jobs_sub100 & cluster_rows > 1),
    all_sub100_site_y100_job_rows = sum(if_else(site_y100 & all_jobs_sub100 & cluster_rows > 1, cluster_rows, 0L)),
    .groups = "drop"
  ) |>
  arrange(site_method, filing_year)

same_site_split_candidates <- site_clusters |>
  filter(site_y100, all_jobs_sub100, cluster_rows > 1) |>
  arrange(site_method, filing_year, filing_quarter, site_key)

write_csv(counts_by_year, "../output/hdb_mappluto_training_panel_counts_by_year.csv", na = "")
write_csv(candidate_primary_y100, "../output/hdb_mappluto_training_panel_candidate_primary_y100.csv", na = "")
write_csv(exclusion_reasons, "../output/hdb_mappluto_training_panel_exclusion_reasons.csv", na = "")
write_csv(exclusion_reason_by_y100, "../output/hdb_mappluto_training_panel_exclusion_reason_by_y100.csv", na = "")
write_csv(vintage_use, "../output/hdb_mappluto_training_panel_vintage_use.csv", na = "")
write_csv(release_design_by_year, "../output/hdb_mappluto_training_panel_release_design_by_year.csv", na = "")
write_csv(timing_distance_by_year, "../output/hdb_mappluto_training_panel_timing_distance_by_year.csv", na = "")
write_csv(hdb_only_unit_bins, "../output/hdb_mappluto_training_panel_hdb_only_unit_bins.csv", na = "")
write_csv(threshold_95_105, "../output/hdb_mappluto_training_panel_threshold_95_105.csv", na = "")
write_csv(filing_quarter_y100, "../output/hdb_mappluto_training_panel_filing_quarter_y100.csv", na = "")
write_csv(model_windows, "../output/hdb_mappluto_training_panel_model_windows.csv", na = "")
write_csv(feature_missingness, "../output/hdb_mappluto_training_panel_feature_missingness.csv", na = "")
write_csv(duplicate_bbl_jobs, "../output/hdb_mappluto_training_panel_duplicate_bbl_jobs.csv", na = "")
write_csv(comparison_2023, "../output/hdb_mappluto_training_panel_2023_comparison.csv", na = "")
write_csv(latest_vs_lag, "../output/hdb_mappluto_training_panel_latest_vs_lag1.csv", na = "")
write_csv(latest_vs_lag1_2023_summary, "../output/hdb_mappluto_training_panel_2023_latest_vs_lag1_summary.csv", na = "")
write_csv(latest_vs_lag1_2023_inclusion, "../output/hdb_mappluto_training_panel_2023_latest_vs_lag1_inclusion.csv", na = "")
write_csv(same_site_aggregation, "../output/hdb_mappluto_training_panel_same_site_aggregation.csv", na = "")
write_csv(same_site_split_candidates, "../output/hdb_mappluto_training_panel_same_site_split_candidates.csv", na = "")
cat("Wrote HDB-MapPLUTO training-panel audit outputs to ../output\n")

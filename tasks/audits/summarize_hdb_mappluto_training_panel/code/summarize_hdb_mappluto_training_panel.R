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

counts_by_year <- panel |>
  group_by(filing_year) |>
  summarise(
    candidate_rows = n(),
    primary_rows = sum(primary_sample, na.rm = TRUE),
    y100_rows = sum(y100 %in% TRUE, na.rm = TRUE),
    primary_y100_rows = sum(primary_sample & y100 %in% TRUE, na.rm = TRUE),
    invalid_bbl_rows = sum(exclusion_reason == "invalid_bbl", na.rm = TRUE),
    no_lagged_pluto_rows = sum(exclusion_reason == "no_lagged_pluto_available", na.rm = TRUE),
    no_mappluto_match_rows = sum(exclusion_reason == "no_mappluto_match", na.rm = TRUE),
    .groups = "drop"
  )

exclusion_reasons <- panel |>
  count(filing_year, exclusion_reason, name = "rows") |>
  arrange(filing_year, desc(rows), exclusion_reason)

vintage_use <- panel |>
  count(
    filing_year,
    pluto_version_latest_pre_filing,
    pluto_version_used,
    primary_sample,
    exclusion_reason,
    name = "rows"
  ) |>
  arrange(filing_year, pluto_version_used, primary_sample, exclusion_reason)

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
    primary_2018_2022_missing_share = mean(is.na(feature_values[panel$primary_sample & panel$filing_year <= 2022])),
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
  for (period_name in c("train_2018_2022", "holdout_2023")) {
    period_rows <- panel |>
      filter(primary_sample, if (period_name == "train_2018_2022") filing_year <= 2022 else filing_year == 2023)
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

comparison_counter <- comparison_counter + 1L
comparison_rows[[comparison_counter]] <- panel |>
  filter(primary_sample) |>
  mutate(period = if_else(filing_year <= 2022, "train_2018_2022", "holdout_2023")) |>
  group_by(period) |>
  summarise(
    feature = "y100",
    rows = n(),
    nonmissing_rows = sum(!is.na(y100)),
    mean_value = mean(y100, na.rm = TRUE),
    median_value = median(as.numeric(y100), na.rm = TRUE),
    .groups = "drop"
  ) |>
  select(period, feature, rows, nonmissing_rows, mean_value, median_value)

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

write_csv(counts_by_year, "../output/hdb_mappluto_training_panel_counts_by_year.csv", na = "")
write_csv(exclusion_reasons, "../output/hdb_mappluto_training_panel_exclusion_reasons.csv", na = "")
write_csv(vintage_use, "../output/hdb_mappluto_training_panel_vintage_use.csv", na = "")
write_csv(feature_missingness, "../output/hdb_mappluto_training_panel_feature_missingness.csv", na = "")
write_csv(duplicate_bbl_jobs, "../output/hdb_mappluto_training_panel_duplicate_bbl_jobs.csv", na = "")
write_csv(comparison_2023, "../output/hdb_mappluto_training_panel_2023_comparison.csv", na = "")
write_csv(latest_vs_lag, "../output/hdb_mappluto_training_panel_latest_vs_lag1.csv", na = "")
cat("Wrote HDB-MapPLUTO training-panel audit outputs to ../output\n")

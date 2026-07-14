# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_residual_patterns/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

heldout_predictions <- read_parquet("../input/no_notch_heldout_predictions.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(model == "lognormal_linear_simple")

time_windows <- read_csv("../input/no_notch_time_windows.csv", show_col_types = FALSE) |>
  mutate(
    train_start = as.Date(train_start),
    train_end = as.Date(train_end),
    test_start = as.Date(test_start),
    test_end = as.Date(test_end)
  )

dob_now <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  as.data.frame() |>
  as_tibble()

if (n_distinct(panel$job_number) != nrow(panel)) {
  stop("HDB-MapPLUTO panel job_number is not unique.")
}

if (n_distinct(dob_now$job_number) != nrow(dob_now)) {
  stop("DOB NOW initial-filing job_number is not unique.")
}

feature_bbl_counts <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= 6,
    !is.na(pluto_feature_bbl)
  ) |>
  count(pluto_feature_bbl, name = "all_period_feature_bbl_model_rows")

latest_training_predictions <- heldout_predictions |>
  left_join(
    time_windows |>
      select(window, train_start, train_end, test_start, test_end),
    by = "window",
    relationship = "many-to-one"
  ) |>
  arrange(job_number, desc(train_end), desc(train_start)) |>
  group_by(job_number) |>
  slice(1L) |>
  ungroup()

if (n_distinct(latest_training_predictions$job_number) != nrow(latest_training_predictions)) {
  stop("Latest-training prediction selection did not produce unique jobs.")
}

residual_projects <- latest_training_predictions |>
  left_join(
    panel,
    by = c("job_number", "date_filed"),
    relationship = "many-to-one"
  ) |>
  left_join(
    feature_bbl_counts,
    by = "pluto_feature_bbl",
    relationship = "many-to-one"
  ) |>
  left_join(
    dob_now |>
      select(
        job_number,
        dob_filing_date = filing_date,
        filing_review_type,
        building_type,
        proposed_stories,
        proposed_height,
        initial_cost,
        total_construction_floor_area,
        applicant_business_name,
        applicant_license,
        owner_business_name,
        owner_type,
        job_description
      ),
    by = "job_number",
    relationship = "many-to-one"
  ) |>
  mutate(
    actual_units = units,
    predicted_units = predicted_median_units,
    log_error = log(actual_units) - log(predicted_units),
    absolute_log_error = abs(log_error),
    squared_log_error = log_error^2,
    actual_to_predicted_ratio = actual_units / predicted_units,
    filing_year = as.integer(format(date_filed, "%Y")),
    all_period_feature_bbl_model_rows = coalesce(
      all_period_feature_bbl_model_rows,
      0L
    ),
    feature_bbl_reuse_bucket = case_when(
      all_period_feature_bbl_model_rows <= 1L ~ "1",
      all_period_feature_bbl_model_rows <= 5L ~ "2-5",
      all_period_feature_bbl_model_rows <= 20L ~ "6-20",
      TRUE ~ "21+"
    ),
    positive_residential_capacity = !is.na(allowed_res_area) & allowed_res_area > 0,
    max_zoning_far = pmax(
      coalesce(residfar, 0),
      coalesce(commfar, 0),
      coalesce(facilfar, 0)
    ),
    max_allowed_area = lotarea * max_zoning_far,
    actual_units_per_10000_residential_capacity = if_else(
      positive_residential_capacity,
      actual_units / allowed_res_area * 10000,
      NA_real_
    ),
    zone_group = case_when(
      str_detect(zonedist1, "/") ~ "mixed slash district",
      str_detect(zonedist1, "^R[1-5]") ~ "R1-R5",
      str_detect(zonedist1, "^R6") ~ "R6",
      str_detect(zonedist1, "^R7") ~ "R7",
      str_detect(zonedist1, "^R(8|9|10)") ~ "R8-R10",
      str_detect(zonedist1, "^C") ~ "commercial",
      str_detect(zonedist1, "^M") ~ "manufacturing",
      TRUE ~ "other"
    ),
    landuse_group = case_when(
      as.character(landuse) == "11" ~ "vacant",
      as.character(landuse) == "10" ~ "parking",
      as.character(landuse) %in% c("05", "5", "06", "6") ~ "commercial/industrial",
      !is.na(unitsres) & unitsres > 0 ~ "existing residential",
      TRUE ~ "other"
    ),
    bldgclass_group = str_sub(bldgclass, 1L, 1L),
    has_overlay = !is.na(overlay1) & str_squish(overlay1) != "",
    has_special_district = !is.na(spdist1) & str_squish(spdist1) != "",
    split_zone = coalesce(splitzone, "N") == "Y",
    historic_or_landmark =
      (!is.na(histdist) & str_squish(histdist) != "") |
      (!is.na(landmark) & str_squish(landmark) != ""),
    flood_flag =
      coalesce(firm07_flag, "0") == "1" |
      coalesce(pfirm15_flag, "0") == "1",
    dob_now_match = !is.na(dob_filing_date),
    construction_sf_per_unit = total_construction_floor_area / actual_units,
    construction_area_to_residential_capacity =
      total_construction_floor_area / allowed_res_area,
    construction_area_to_max_capacity =
      total_construction_floor_area / max_allowed_area
  )

if (
  any(residual_projects$actual_units < 6L) ||
    any(residual_projects$predicted_units < 6L) ||
    any(!is.finite(residual_projects$log_error))
) {
  stop("Residual project sample violates unit or finite-error checks.")
}

site_year_summary <- residual_projects |>
  group_by(pluto_feature_bbl, filing_year) |>
  summarise(
    building_rows = n(),
    first_filing_date = min(date_filed),
    last_filing_date = max(date_filed),
    address_examples = paste(head(unique(address), 3L), collapse = " | "),
    actual_site_units = sum(actual_units),
    predicted_site_units = median(predicted_units),
    building_row_rmse = sqrt(mean(squared_log_error)),
    all_period_feature_bbl_model_rows = max(all_period_feature_bbl_model_rows),
    .groups = "drop"
  ) |>
  mutate(
    site_log_error = log(actual_site_units) - log(predicted_site_units),
    absolute_site_log_error = abs(site_log_error),
    repeated_site_year = building_rows > 1L
  )

residual_projects <- residual_projects |>
  left_join(
    site_year_summary |>
      select(pluto_feature_bbl, filing_year, building_rows, repeated_site_year),
    by = c("pluto_feature_bbl", "filing_year"),
    relationship = "many-to-one"
  )

summarize_errors <- function(data, error_column, sample_name, unit_name) {
  errors <- data[[error_column]]
  tibble(
    sample = sample_name,
    unit = unit_name,
    rows = length(errors),
    mean_log_error = mean(errors),
    mean_absolute_log_error = mean(abs(errors)),
    root_mean_squared_log_error = sqrt(mean(errors^2)),
    p90_absolute_log_error = quantile(abs(errors), 0.90)
  )
}

source_decomposition <- bind_rows(
  summarize_errors(
    residual_projects,
    "log_error",
    "all held-out filings",
    "building filing"
  ),
  summarize_errors(
    residual_projects |>
      filter(all_period_feature_bbl_model_rows == 1L),
    "log_error",
    "diagnostic all-period singleton feature BBL",
    "building filing"
  ),
  summarize_errors(
    residual_projects |>
      filter(
        all_period_feature_bbl_model_rows == 1L,
        positive_residential_capacity
      ),
    "log_error",
    "singleton feature BBL with positive residential capacity",
    "building filing"
  ),
  summarize_errors(
    residual_projects |>
      filter(repeated_site_year),
    "log_error",
    "filings in repeated BBL-years",
    "building filing"
  ),
  summarize_errors(
    site_year_summary,
    "site_log_error",
    "all provisional BBL-years",
    "provisional BBL-year"
  ),
  summarize_errors(
    site_year_summary |>
      filter(repeated_site_year),
    "site_log_error",
    "repeated provisional BBL-years",
    "provisional BBL-year"
  )
)

reuse_summary <- residual_projects |>
  group_by(feature_bbl_reuse_bucket) |>
  summarise(
    rows = n(),
    feature_bbls = n_distinct(pluto_feature_bbl),
    mean_log_error = mean(log_error),
    mean_absolute_log_error = mean(absolute_log_error),
    root_mean_squared_log_error = sqrt(mean(squared_log_error)),
    squared_log_error = sum(squared_log_error),
    .groups = "drop"
  ) |>
  mutate(
    row_share = rows / sum(rows),
    squared_error_share = squared_log_error / sum(squared_log_error),
    feature_bbl_reuse_bucket = factor(
      feature_bbl_reuse_bucket,
      levels = c("1", "2-5", "6-20", "21+")
    )
  ) |>
  arrange(feature_bbl_reuse_bucket)

clean_singletons <- residual_projects |>
  filter(
    all_period_feature_bbl_model_rows == 1L,
    positive_residential_capacity
  )

summarize_groups <- function(data, variable_name) {
  data |>
    mutate(group = as.character(.data[[variable_name]])) |>
    group_by(group) |>
    summarise(
      rows = n(),
      mean_log_error = mean(log_error),
      mean_absolute_log_error = mean(absolute_log_error),
      root_mean_squared_log_error = sqrt(mean(squared_log_error)),
      share_underpredicted_by_factor_two = mean(log_error > log(2)),
      share_overpredicted_by_factor_two = mean(log_error < -log(2)),
      .groups = "drop"
    ) |>
    filter(rows >= 20L) |>
    mutate(variable = variable_name, .before = 1L)
}

group_summary <- bind_rows(lapply(
  c(
    "filing_year", "hdb_borough_name", "zone_group", "landuse_group",
    "bldgclass_group", "has_overlay", "has_special_district", "split_zone",
    "historic_or_landmark", "flood_flag", "zipcode"
  ),
  function(variable_name) summarize_groups(clean_singletons, variable_name)
)) |>
  arrange(variable, desc(root_mean_squared_log_error), group)

continuous_features <- clean_singletons |>
  transmute(
    log_error,
    absolute_log_error,
    log_lotarea = log(lotarea),
    residfar,
    builtfar,
    log_allowed_res_area = log(allowed_res_area),
    log_max_allowed_area = if_else(max_allowed_area > 0, log(max_allowed_area), NA_real_),
    residual_res_share = pmin(pmax(residual_res_area / allowed_res_area, 0), 1),
    log_assessland = if_else(assessland > 0, log(assessland), NA_real_),
    log_assesstot = if_else(assesstot > 0, log(assesstot), NA_real_),
    log_bldgarea = if_else(bldgarea > 0, log(bldgarea), NA_real_),
    log_resarea = if_else(resarea > 0, log(resarea), NA_real_),
    log_comarea = if_else(comarea > 0, log(comarea), NA_real_),
    log_existing_units = if_else(unitsres > 0, log(unitsres), NA_real_),
    numbldgs,
    numfloors,
    pluto_feature_age_days = pluto_days_relative_to_filing
  )

continuous_correlations <- bind_rows(lapply(
  setdiff(names(continuous_features), c("log_error", "absolute_log_error")),
  function(feature_name) {
    tibble(
      feature = feature_name,
      nonmissing_rows = sum(!is.na(continuous_features[[feature_name]])),
      signed_error_spearman = cor(
        continuous_features$log_error,
        continuous_features[[feature_name]],
        use = "complete.obs",
        method = "spearman"
      ),
      absolute_error_spearman = cor(
        continuous_features$absolute_log_error,
        continuous_features[[feature_name]],
        use = "complete.obs",
        method = "spearman"
      )
    )
  }
)) |>
  arrange(desc(abs(signed_error_spearman)), feature)

tail_cases <- bind_rows(
  residual_projects |>
    arrange(desc(log_error)) |>
    slice_head(n = 40L) |>
    mutate(direction = "underpredicted", tail_rank = row_number()),
  residual_projects |>
    arrange(log_error) |>
    slice_head(n = 40L) |>
    mutate(direction = "overpredicted", tail_rank = row_number())
) |>
  select(
    direction, tail_rank, job_number, date_filed, address, hdb_borough_name,
    actual_units, predicted_units, actual_to_predicted_ratio, log_error,
    pluto_feature_bbl, all_period_feature_bbl_model_rows, building_rows,
    lotarea, allowed_res_area, max_allowed_area,
    actual_units_per_10000_residential_capacity, residfar, commfar, facilfar,
    builtfar, unitsres, numbldgs, landuse, bldgclass, zonedist1,
    pluto_match_method, appbbl_resolution_status, pluto_days_relative_to_filing,
    dob_now_match, total_construction_floor_area, construction_sf_per_unit,
    construction_area_to_residential_capacity, construction_area_to_max_capacity,
    proposed_stories, applicant_business_name, owner_business_name,
    job_description
  )

dob_coverage <- residual_projects |>
  group_by(filing_year) |>
  summarise(
    heldout_rows = n(),
    dob_now_matches = sum(dob_now_match),
    dob_now_match_share = mean(dob_now_match),
    .groups = "drop"
  )

dob_area_rows <- residual_projects |>
  filter(
    dob_now_match,
    total_construction_floor_area > 0,
    max_allowed_area > 0,
    is.finite(construction_area_to_max_capacity)
  )

dob_diagnostics <- tibble(
  metric = c(
    "matched_positive_area_rows",
    "signed_error_correlation_log_construction_area",
    "signed_error_correlation_log_construction_area_to_max_capacity",
    "absolute_error_correlation_absolute_log_area_to_max_capacity",
    "median_construction_sf_per_unit",
    "p10_construction_sf_per_unit",
    "p90_construction_sf_per_unit",
    "median_construction_area_to_max_capacity",
    "p90_construction_area_to_max_capacity"
  ),
  value = c(
    nrow(dob_area_rows),
    cor(
      dob_area_rows$log_error,
      log(dob_area_rows$total_construction_floor_area),
      method = "spearman"
    ),
    cor(
      dob_area_rows$log_error,
      log(dob_area_rows$construction_area_to_max_capacity),
      method = "spearman"
    ),
    cor(
      dob_area_rows$absolute_log_error,
      abs(log(dob_area_rows$construction_area_to_max_capacity)),
      method = "spearman"
    ),
    median(dob_area_rows$construction_sf_per_unit),
    quantile(dob_area_rows$construction_sf_per_unit, 0.10),
    quantile(dob_area_rows$construction_sf_per_unit, 0.90),
    median(dob_area_rows$construction_area_to_max_capacity),
    quantile(dob_area_rows$construction_area_to_max_capacity, 0.90)
  )
)

applicant_summary <- residual_projects |>
  filter(
    dob_now_match,
    !is.na(applicant_business_name),
    applicant_business_name != ""
  ) |>
  add_count(applicant_business_name, name = "applicant_projects") |>
  filter(applicant_projects >= 5L) |>
  group_by(applicant_business_name) |>
  summarise(
    projects = n(),
    mean_log_error = mean(log_error),
    mean_absolute_log_error = mean(absolute_log_error),
    root_mean_squared_log_error = sqrt(mean(squared_log_error)),
    median_actual_units = median(actual_units),
    .groups = "drop"
  ) |>
  arrange(desc(projects), applicant_business_name)

reuse_plot_data <- reuse_summary |>
  select(feature_bbl_reuse_bucket, row_share, squared_error_share) |>
  pivot_longer(
    cols = c(row_share, squared_error_share),
    names_to = "series",
    values_to = "share"
  ) |>
  mutate(
    series = recode(
      series,
      row_share = "Held-out row share",
      squared_error_share = "Squared-error share"
    )
  )

reuse_plot <- ggplot(
  reuse_plot_data,
  aes(x = feature_bbl_reuse_bucket, y = share, fill = series)
) +
  geom_col(position = "dodge", width = 0.72) +
  geom_text(
    aes(label = label_percent(accuracy = 1)(share)),
    position = position_dodge(width = 0.72),
    vjust = -0.25,
    size = 3
  ) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.12))) +
  scale_fill_manual(
    values = c(
      "Held-out row share" = "#777777",
      "Squared-error share" = "#0072B2"
    )
  ) +
  labs(
    title = "A few shared feature lots generate disproportionate error",
    x = "All-period model filings linked to feature BBL",
    y = NULL,
    fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom"
  )

aggregation_plot_data <- source_decomposition |>
  filter(
    sample %in% c(
      "all held-out filings",
      "diagnostic all-period singleton feature BBL",
      "filings in repeated BBL-years",
      "repeated provisional BBL-years"
    )
  ) |>
  mutate(
    sample = recode(
      sample,
      `all held-out filings` = "All building filings",
      `diagnostic all-period singleton feature BBL` = "Singleton feature BBLs",
      `filings in repeated BBL-years` = "Repeated BBL-year: buildings",
      `repeated provisional BBL-years` = "Repeated BBL-year: summed site"
    ),
    sample = factor(
      sample,
      levels = c(
        "All building filings",
        "Singleton feature BBLs",
        "Repeated BBL-year: buildings",
        "Repeated BBL-year: summed site"
      )
    )
  )

aggregation_plot <- ggplot(
  aggregation_plot_data,
  aes(x = sample, y = root_mean_squared_log_error)
) +
  geom_col(fill = "#0072B2", width = 0.66) +
  geom_text(
    aes(label = number(root_mean_squared_log_error, accuracy = 0.01)),
    vjust = -0.35,
    size = 3.2
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Summing companion buildings removes much of the apparent miss",
    x = NULL,
    y = "Log-unit RMSE"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 25, hjust = 1),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

dob_plot <- ggplot(
  dob_area_rows |>
    filter(
      construction_area_to_max_capacity >= 0.05,
      construction_area_to_max_capacity <= 100
    ),
  aes(x = construction_area_to_max_capacity, y = log_error)
) +
  geom_hline(yintercept = 0, color = "#777777", linewidth = 0.5) +
  geom_point(alpha = 0.18, size = 1.1, color = "#555555") +
  geom_smooth(method = "lm", se = FALSE, color = "#0072B2", linewidth = 0.8) +
  scale_x_log10(labels = label_number()) +
  labs(
    title = "Large misses coincide with parcel-capacity mismatch",
    subtitle = "DOB construction area is diagnostic only, not a baseline predictor",
    x = "DOB construction area / linked-lot maximum FAR capacity",
    y = "Log(actual / predicted units)"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

landuse_plot <- group_summary |>
  filter(variable == "landuse_group") |>
  mutate(group = reorder(group, root_mean_squared_log_error)) |>
  ggplot(aes(x = group, y = root_mean_squared_log_error)) +
  geom_col(fill = "#0072B2", width = 0.66) +
  geom_text(
    aes(label = number(root_mean_squared_log_error, accuracy = 0.01)),
    vjust = -0.35,
    size = 3.2
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Clean singleton residuals are largest on undeveloped sites",
    x = NULL,
    y = "Log-unit RMSE"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 25, hjust = 1),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

diagnostic_dashboard <- (reuse_plot | aggregation_plot) /
  (dob_plot | landuse_plot) +
  plot_annotation(
    title = "Where does the individual unit-prediction error come from?",
    subtitle = "One latest-training out-of-time prediction per 2016-2023 filing"
  )

write_csv_if_changed(
  source_decomposition,
  "../output/no_notch_residual_source_decomposition.csv"
)
write_csv_if_changed(
  reuse_summary,
  "../output/no_notch_residual_reuse_summary.csv"
)
write_csv_if_changed(
  group_summary,
  "../output/no_notch_residual_group_summary.csv"
)
write_csv_if_changed(
  continuous_correlations,
  "../output/no_notch_residual_continuous_correlations.csv"
)
write_csv_if_changed(
  site_year_summary,
  "../output/no_notch_residual_site_year_summary.csv"
)
write_csv_if_changed(
  tail_cases,
  "../output/no_notch_residual_tail_cases.csv"
)
write_csv_if_changed(
  dob_coverage,
  "../output/no_notch_residual_dob_coverage.csv"
)
write_csv_if_changed(
  dob_diagnostics,
  "../output/no_notch_residual_dob_diagnostics.csv"
)
write_csv_if_changed(
  applicant_summary,
  "../output/no_notch_residual_applicant_summary.csv"
)
write_parquet_if_changed(
  residual_projects |>
    select(
      window, train_start, train_end, test_start, test_end,
      job_number, date_filed, address, hdb_borough_name, hdb_community_district,
      bbl, pluto_feature_bbl, all_period_feature_bbl_model_rows,
      building_rows, repeated_site_year, actual_units, predicted_units,
      probability_at_least_100, probability_exactly_99,
      log_error, absolute_log_error, actual_to_predicted_ratio,
      lotarea, allowed_res_area, max_allowed_area, residual_res_area,
      residfar, commfar, facilfar, builtfar, unitsres, numbldgs, numfloors,
      zonedist1, zone_group, landuse, landuse_group, bldgclass,
      has_overlay, has_special_district, split_zone, historic_or_landmark,
      pluto_match_method, appbbl_resolution_status,
      pluto_days_relative_to_filing, dob_now_match,
      total_construction_floor_area, construction_sf_per_unit,
      construction_area_to_residential_capacity,
      construction_area_to_max_capacity, proposed_stories, proposed_height,
      applicant_business_name, owner_business_name, owner_type, job_description
    ),
  "../output/no_notch_residual_project_predictions.parquet"
)

ggsave(
  "../output/no_notch_residual_diagnostics.pdf",
  diagnostic_dashboard,
  width = 12,
  height = 9,
  bg = "white"
)
ggsave(
  "../output/no_notch_residual_diagnostics.png",
  diagnostic_dashboard,
  width = 12,
  height = 9,
  dpi = 180,
  bg = "white"
)

cat("Wrote no-notch residual-pattern audit outputs.\n")

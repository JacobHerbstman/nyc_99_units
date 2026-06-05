# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_dof_sales_feasibility/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

minimum_classa_prop <- 50L
prefiling_lookback_days <- 1826L
prefiling_exclusion_days <- 30L
nominal_sale_price_threshold <- 1000
low_price_per_allowed_res_sqft_threshold <- 1
high_price_per_allowed_res_sqft_threshold <- 2000

hdb_panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble()

sales_min_date <- min(dof_sales$sale_date, na.rm = TRUE)
sales_max_date <- max(dof_sales$sale_date, na.rm = TRUE)

project_rows <- hdb_panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    !is.na(classa_prop),
    classa_prop >= minimum_classa_prop,
    !is.na(date_filed)
  ) |>
  mutate(
    positive_lotarea = !is.na(lotarea) & lotarea > 0,
    positive_allowed_res_area = !is.na(allowed_res_area) & allowed_res_area > 0,
    sale_window_start = date_filed - prefiling_lookback_days,
    sale_window_end = date_filed - prefiling_exclusion_days,
    full_sales_window_observable = sale_window_start >= sales_min_date & sale_window_end <= sales_max_date
  )

project_bbl_candidates <- bind_rows(
  project_rows |>
    transmute(
      hdb_panel_row_id,
      site_bbl = normalize_bbl_field(bbl),
      site_bbl_source = "hdb_bbl"
    ),
  project_rows |>
    transmute(
      hdb_panel_row_id,
      site_bbl = normalize_bbl_field(pluto_feature_bbl),
      site_bbl_source = "pluto_feature_bbl"
    )
) |>
  filter(!is.na(site_bbl)) |>
  distinct(hdb_panel_row_id, site_bbl, site_bbl_source)

project_bbl_duplicate_sources <- project_bbl_candidates |>
  count(hdb_panel_row_id, site_bbl, name = "rows") |>
  filter(rows > 1)

project_bbl_summary <- project_bbl_candidates |>
  group_by(hdb_panel_row_id) |>
  summarise(
    candidate_bbls = n_distinct(site_bbl),
    candidate_bbl_source_list = paste(sort(unique(site_bbl_source)), collapse = "|"),
    .groups = "drop"
  )

sales_positive <- dof_sales |>
  filter(valid_bbl, positive_sale_price, !is.na(sale_date), !is.na(sale_price)) |>
  select(
    sale_record_id, sale_bbl = bbl, sale_date, sale_year, sale_price,
    source_borough, source_year, neighborhood, building_class_category,
    tax_class_at_time_of_sale, building_class_at_time_of_sale,
    sale_address = address, sale_zip_code = zip_code,
    sale_residential_units = residential_units,
    sale_commercial_units = commercial_units,
    sale_total_units = total_units,
    sale_land_square_feet = land_square_feet,
    sale_gross_square_feet = gross_square_feet,
    sale_year_built = year_built
  )

if (anyDuplicated(sales_positive$sale_record_id) > 0) {
  stop("Positive-price DOF sales are not unique by sale_record_id.")
}

nearest_sale_rows <- vector("list", nrow(project_rows))

for (i in seq_len(nrow(project_rows))) {
  current_project <- project_rows[i, ]
  current_bbls <- project_bbl_candidates |>
    filter(hdb_panel_row_id == current_project$hdb_panel_row_id) |>
    select(site_bbl, site_bbl_source)

  if (nrow(current_bbls) == 0) {
    nearest_sale_rows[[i]] <- current_project |>
      transmute(
        hdb_panel_row_id, job_number, date_filed, filing_year, hdb_bbl = bbl,
        pluto_feature_bbl, pluto_match_method, classa_prop, y100,
        lotarea, allowed_res_area, positive_lotarea, positive_allowed_res_area,
        sale_window_start, sale_window_end, full_sales_window_observable,
        candidate_bbls = 0L,
        candidate_bbl_source_list = NA_character_,
        prefiling_sale_rows = 0L,
        prefiling_distinct_sale_bbls = 0L,
        prefiling_distinct_sale_dates = 0L,
        sale_link_status = "no_candidate_bbl"
      )
    next
  }

  current_sources <- current_bbls |>
    group_by(site_bbl) |>
    summarise(site_bbl_source = paste(sort(unique(site_bbl_source)), collapse = "|"), .groups = "drop")

  current_sales <- sales_positive |>
    filter(
      sale_bbl %in% current_sources$site_bbl,
      sale_date >= current_project$sale_window_start,
      sale_date <= current_project$sale_window_end
    ) |>
    left_join(
      current_sources,
      by = c("sale_bbl" = "site_bbl"),
      relationship = "many-to-one"
    ) |>
    arrange(desc(sale_date), desc(sale_price), sale_record_id)

  if (nrow(current_sales) == 0) {
    nearest_sale_rows[[i]] <- current_project |>
      left_join(project_bbl_summary, by = "hdb_panel_row_id", relationship = "one-to-one") |>
      transmute(
        hdb_panel_row_id, job_number, date_filed, filing_year, hdb_bbl = bbl,
        pluto_feature_bbl, pluto_match_method, classa_prop, y100,
        lotarea, allowed_res_area, positive_lotarea, positive_allowed_res_area,
        sale_window_start, sale_window_end, full_sales_window_observable,
        candidate_bbls,
        candidate_bbl_source_list,
        prefiling_sale_rows = 0L,
        prefiling_distinct_sale_bbls = 0L,
        prefiling_distinct_sale_dates = 0L,
        sale_link_status = "no_prefiling_positive_price_sale"
      )
    next
  }

  nearest_sale_rows[[i]] <- current_project |>
    left_join(project_bbl_summary, by = "hdb_panel_row_id", relationship = "one-to-one") |>
    mutate(
      prefiling_sale_rows = nrow(current_sales),
      prefiling_distinct_sale_bbls = n_distinct(current_sales$sale_bbl),
      prefiling_distinct_sale_dates = n_distinct(current_sales$sale_date)
    ) |>
    bind_cols(current_sales[1, ]) |>
    transmute(
      hdb_panel_row_id, job_number, date_filed, filing_year, hdb_bbl = bbl,
      pluto_feature_bbl, pluto_match_method, classa_prop, y100,
      lotarea, allowed_res_area, positive_lotarea, positive_allowed_res_area,
      sale_window_start, sale_window_end, full_sales_window_observable,
      candidate_bbls, candidate_bbl_source_list,
      prefiling_sale_rows, prefiling_distinct_sale_bbls, prefiling_distinct_sale_dates,
      sale_record_id, sale_bbl, site_bbl_source, sale_date,
      days_sale_to_filing = as.integer(date_filed - sale_date),
      sale_price, price_per_lot_sqft = sale_price / lotarea,
      price_per_allowed_res_sqft = sale_price / allowed_res_area,
      source_borough, source_year, neighborhood, building_class_category,
      tax_class_at_time_of_sale, building_class_at_time_of_sale,
      sale_address, sale_zip_code,
      sale_residential_units, sale_commercial_units, sale_total_units,
      sale_land_square_feet, sale_gross_square_feet, sale_year_built,
      sale_link_status = if_else(positive_allowed_res_area, "feasible_price_per_buildable_res_sqft", "sale_match_no_positive_allowed_res_area")
    )
}

nearest_sales <- bind_rows(nearest_sale_rows) |>
  mutate(
    has_prefiling_sale = !is.na(sale_record_id),
    outcome_feasible = sale_link_status == "feasible_price_per_buildable_res_sqft" &
      !is.na(price_per_allowed_res_sqft) &
      is.finite(price_per_allowed_res_sqft) &
      price_per_allowed_res_sqft > 0,
    nominal_sale_price = has_prefiling_sale & !is.na(sale_price) & sale_price < nominal_sale_price_threshold,
    low_price_per_allowed_res_sqft = outcome_feasible & price_per_allowed_res_sqft < low_price_per_allowed_res_sqft_threshold,
    high_price_per_allowed_res_sqft = outcome_feasible & price_per_allowed_res_sqft > high_price_per_allowed_res_sqft_threshold,
    outcome_feasible_non_nominal = outcome_feasible & !nominal_sale_price
  )

summary_rows <- bind_rows(
  tibble(metric = "minimum_classa_prop", value = minimum_classa_prop, note = "Project sample threshold."),
  tibble(metric = "prefiling_lookback_days", value = prefiling_lookback_days, note = "Approximate five-year lookback window."),
  tibble(metric = "prefiling_exclusion_days", value = prefiling_exclusion_days, note = "Sales in final 30 days before filing are excluded."),
  tibble(metric = "nominal_sale_price_threshold", value = nominal_sale_price_threshold, note = "Diagnostic threshold only. Below this is flagged as nominal consideration."),
  tibble(metric = "low_price_per_allowed_res_sqft_threshold", value = low_price_per_allowed_res_sqft_threshold, note = "Diagnostic lower-tail flag only."),
  tibble(metric = "high_price_per_allowed_res_sqft_threshold", value = high_price_per_allowed_res_sqft_threshold, note = "Diagnostic upper-tail flag only."),
  tibble(metric = "dof_sales_min_date", value = as.numeric(sales_min_date), note = "R Date numeric days since 1970-01-01."),
  tibble(metric = "dof_sales_max_date", value = as.numeric(sales_max_date), note = "R Date numeric days since 1970-01-01."),
  tibble(metric = "project_rows", value = nrow(nearest_sales), note = "Primary leakage-safe HDB-MapPLUTO rows with at least 50 proposed Class A units."),
  tibble(metric = "full_sales_window_observable_rows", value = sum(nearest_sales$full_sales_window_observable), note = "Rows with complete five-year pre-filing DOF coverage."),
  tibble(metric = "positive_allowed_res_area_rows", value = sum(nearest_sales$positive_allowed_res_area), note = "Rows with positive MapPLUTO allowed residential area denominator."),
  tibble(metric = "prefiling_positive_price_sale_rows", value = sum(nearest_sales$has_prefiling_sale), note = "Rows with at least one positive-price DOF sale in the candidate BBL window."),
  tibble(metric = "outcome_feasible_rows", value = sum(nearest_sales$outcome_feasible), note = "Rows with positive pre-filing sale and positive price per allowed residential square foot."),
  tibble(metric = "outcome_feasible_non_nominal_rows", value = sum(nearest_sales$outcome_feasible_non_nominal), note = "Outcome-feasible rows excluding sale prices below the nominal consideration threshold."),
  tibble(metric = "outcome_feasible_low_price_per_allowed_res_sqft_rows", value = sum(nearest_sales$low_price_per_allowed_res_sqft), note = "Outcome-feasible rows below diagnostic lower-tail threshold."),
  tibble(metric = "outcome_feasible_high_price_per_allowed_res_sqft_rows", value = sum(nearest_sales$high_price_per_allowed_res_sqft), note = "Outcome-feasible rows above diagnostic upper-tail threshold."),
  tibble(metric = "outcome_feasible_share", value = mean(nearest_sales$outcome_feasible), note = "Share of project rows with feasible primary price outcome."),
  tibble(metric = "outcome_feasible_non_nominal_share", value = mean(nearest_sales$outcome_feasible_non_nominal), note = "Share of project rows with feasible primary price outcome after nominal-price flag."),
  tibble(metric = "duplicate_project_bbl_source_rows", value = nrow(project_bbl_duplicate_sources), note = "Rows where HDB BBL and PLUTO feature BBL give the same site BBL with two source labels.")
)

by_year <- nearest_sales |>
  group_by(filing_year) |>
  summarise(
    projects = n(),
    full_sales_window_observable_rows = sum(full_sales_window_observable),
    positive_allowed_res_area_rows = sum(positive_allowed_res_area),
    prefiling_positive_price_sale_rows = sum(has_prefiling_sale),
    outcome_feasible_rows = sum(outcome_feasible),
    outcome_feasible_non_nominal_rows = sum(outcome_feasible_non_nominal),
    sale_match_share = mean(has_prefiling_sale),
    outcome_feasible_share = mean(outcome_feasible),
    outcome_feasible_non_nominal_share = mean(outcome_feasible_non_nominal),
    median_days_sale_to_filing = median(days_sale_to_filing, na.rm = TRUE),
    median_price_per_allowed_res_sqft = median(price_per_allowed_res_sqft[outcome_feasible], na.rm = TRUE),
    .groups = "drop"
  )

by_match_method <- nearest_sales |>
  group_by(pluto_match_method) |>
  summarise(
    projects = n(),
    full_sales_window_observable_rows = sum(full_sales_window_observable),
    positive_allowed_res_area_rows = sum(positive_allowed_res_area),
    prefiling_positive_price_sale_rows = sum(has_prefiling_sale),
    outcome_feasible_rows = sum(outcome_feasible),
    outcome_feasible_non_nominal_rows = sum(outcome_feasible_non_nominal),
    sale_match_share = mean(has_prefiling_sale),
    outcome_feasible_share = mean(outcome_feasible),
    outcome_feasible_non_nominal_share = mean(outcome_feasible_non_nominal),
    median_days_sale_to_filing = median(days_sale_to_filing, na.rm = TRUE),
    median_price_per_allowed_res_sqft = median(price_per_allowed_res_sqft[outcome_feasible], na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(projects))

price_distribution <- nearest_sales |>
  filter(outcome_feasible) |>
  summarise(
    rows = n(),
    sale_price_p05 = quantile(sale_price, 0.05, names = FALSE, na.rm = TRUE),
    sale_price_p25 = quantile(sale_price, 0.25, names = FALSE, na.rm = TRUE),
    sale_price_p50 = quantile(sale_price, 0.50, names = FALSE, na.rm = TRUE),
    sale_price_p75 = quantile(sale_price, 0.75, names = FALSE, na.rm = TRUE),
    sale_price_p95 = quantile(sale_price, 0.95, names = FALSE, na.rm = TRUE),
    price_per_lot_sqft_p05 = quantile(price_per_lot_sqft, 0.05, names = FALSE, na.rm = TRUE),
    price_per_lot_sqft_p25 = quantile(price_per_lot_sqft, 0.25, names = FALSE, na.rm = TRUE),
    price_per_lot_sqft_p50 = quantile(price_per_lot_sqft, 0.50, names = FALSE, na.rm = TRUE),
    price_per_lot_sqft_p75 = quantile(price_per_lot_sqft, 0.75, names = FALSE, na.rm = TRUE),
    price_per_lot_sqft_p95 = quantile(price_per_lot_sqft, 0.95, names = FALSE, na.rm = TRUE),
    price_per_allowed_res_sqft_p05 = quantile(price_per_allowed_res_sqft, 0.05, names = FALSE, na.rm = TRUE),
    price_per_allowed_res_sqft_p25 = quantile(price_per_allowed_res_sqft, 0.25, names = FALSE, na.rm = TRUE),
    price_per_allowed_res_sqft_p50 = quantile(price_per_allowed_res_sqft, 0.50, names = FALSE, na.rm = TRUE),
    price_per_allowed_res_sqft_p75 = quantile(price_per_allowed_res_sqft, 0.75, names = FALSE, na.rm = TRUE),
    price_per_allowed_res_sqft_p95 = quantile(price_per_allowed_res_sqft, 0.95, names = FALSE, na.rm = TRUE)
  )

write_csv_if_changed(summary_rows, "../output/hdb_dof_sales_feasibility_summary.csv")
write_csv_if_changed(by_year, "../output/hdb_dof_sales_feasibility_by_year.csv")
write_csv_if_changed(by_match_method, "../output/hdb_dof_sales_feasibility_by_match_method.csv")
write_csv_if_changed(nearest_sales, "../output/hdb_dof_sales_nearest_prefiling_sales.csv")
write_csv_if_changed(price_distribution, "../output/hdb_dof_sales_price_distribution.csv")
cat("Wrote HDB-DOF sales feasibility audit outputs to ../output\n")

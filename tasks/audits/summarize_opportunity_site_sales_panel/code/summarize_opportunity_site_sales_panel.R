# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_opportunity_site_sales_panel/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

deadline_421a <- as.Date("2022-06-15")
transition_start <- as.Date("2022-06-16")
adoption_485x <- as.Date("2024-04-20")

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_sales <- read_parquet("../input/opportunity_sales_exact_bbl.parquet") |>
  as.data.frame() |>
  as_tibble()

lot_quarter_panel <- read_parquet("../input/opportunity_lot_quarter_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble()

lot_counts_citywide <- opportunity_lots |>
  summarise(
    group_type = "citywide",
    group_value = "all",
    lots = n(),
    valid_bbl_lots = sum(valid_bbl),
    positive_lotarea_lots = sum(positive_lotarea),
    positive_allowed_policy_res_sqft_lots = sum(positive_allowed_policy_res_sqft),
    primary_opp50_850_lots = sum(primary_opp50_850),
    soft_site_opp50_850_lots = sum(soft_site_opp50_850),
    capacity100_850_lots = sum(capacity100_850 & primary_opp50_850),
    condo_or_billing_lot_rows = sum(condo_or_billing_lot),
    public_transport_utility_open_space_landuse_rows = sum(public_transport_utility_open_space_landuse),
    median_allowed_policy_res_sqft_primary = median(allowed_policy_res_sqft[primary_opp50_850], na.rm = TRUE)
  )

lot_counts_borough <- opportunity_lots |>
  group_by(borough) |>
  summarise(
    group_type = "borough",
    group_value = as.character(borough[1]),
    lots = n(),
    valid_bbl_lots = sum(valid_bbl),
    positive_lotarea_lots = sum(positive_lotarea),
    positive_allowed_policy_res_sqft_lots = sum(positive_allowed_policy_res_sqft),
    primary_opp50_850_lots = sum(primary_opp50_850),
    soft_site_opp50_850_lots = sum(soft_site_opp50_850),
    capacity100_850_lots = sum(capacity100_850 & primary_opp50_850),
    condo_or_billing_lot_rows = sum(condo_or_billing_lot),
    public_transport_utility_open_space_landuse_rows = sum(public_transport_utility_open_space_landuse),
    median_allowed_policy_res_sqft_primary = median(allowed_policy_res_sqft[primary_opp50_850], na.rm = TRUE),
    .groups = "drop"
  )

write_csv_if_changed(bind_rows(lot_counts_citywide, lot_counts_borough), "../output/opportunity_lot_counts.csv")

capacity_thresholds <- bind_rows(lapply(c(650, 750, 850, 1000), function(gross_sqft_per_unit) {
  opportunity_lots |>
    mutate(
      capacity50_flag = !primary_hard_exclusion & !is.na(allowed_policy_res_sqft) &
        allowed_policy_res_sqft >= 50 * gross_sqft_per_unit,
      capacity100_flag = !primary_hard_exclusion & !is.na(allowed_policy_res_sqft) &
        allowed_policy_res_sqft >= 100 * gross_sqft_per_unit
    ) |>
    group_by(borough) |>
    summarise(
      gross_sqft_per_unit = gross_sqft_per_unit,
      lots = n(),
      capacity50_lots = sum(capacity50_flag),
      capacity100_lots = sum(capacity100_flag),
      soft_capacity50_lots = sum(capacity50_flag & soft_site_opp50_850),
      total_allowed_policy_res_sqft_capacity50 = sum(allowed_policy_res_sqft[capacity50_flag], na.rm = TRUE),
      median_allowed_policy_res_sqft_capacity50 = median(allowed_policy_res_sqft[capacity50_flag], na.rm = TRUE),
      .groups = "drop"
    )
}))

write_csv_if_changed(capacity_thresholds, "../output/opportunity_capacity_thresholds.csv")

sales_linkage_summary <- lot_quarter_panel |>
  group_by(quarter_policy_period, borough, capacity_exposure_quartile_citywide) |>
  summarise(
    lot_quarters = n(),
    lots = n_distinct(bbl),
    sold_lot_quarters = sum(sold_exact_q),
    positive_sale_lot_quarters = sum(positive_sale_exact_q),
    positive_non_nominal_sale_lot_quarters = sum(positive_non_nominal_sale_exact_q),
    sale_count_exact = sum(sale_count_exact_q),
    positive_sale_count_exact = sum(positive_sale_count_exact_q),
    positive_non_nominal_sale_count_exact = sum(positive_non_nominal_sale_count_exact_q),
    sale_price_nominal_sum = sum(sale_price_nominal_sum_q, na.rm = TRUE),
    sold_lot_quarter_share = mean(sold_exact_q),
    .groups = "drop"
  )

write_csv_if_changed(sales_linkage_summary, "../output/opportunity_sales_linkage_summary.csv")

price_distribution <- opportunity_sales |>
  filter(primary_opp50_850, positive_sale_price, !nominal_sale_price) |>
  group_by(policy_period, borough, capacity_exposure_quartile_citywide) |>
  summarise(
    sales = n(),
    distinct_lots = n_distinct(sale_bbl),
    median_sale_price_nominal = median(sale_price_nominal, na.rm = TRUE),
    p10_price_per_allowed_policy_res_sqft_nominal = quantile(price_per_allowed_policy_res_sqft_nominal, 0.10, na.rm = TRUE, names = FALSE),
    median_price_per_allowed_policy_res_sqft_nominal = median(price_per_allowed_policy_res_sqft_nominal, na.rm = TRUE),
    p90_price_per_allowed_policy_res_sqft_nominal = quantile(price_per_allowed_policy_res_sqft_nominal, 0.90, na.rm = TRUE, names = FALSE),
    low_price_per_allowed_policy_res_sqft_rows = sum(low_price_per_allowed_policy_res_sqft),
    high_price_per_allowed_policy_res_sqft_rows = sum(high_price_per_allowed_policy_res_sqft),
    .groups = "drop"
  )

write_csv_if_changed(price_distribution, "../output/opportunity_sales_price_distribution.csv")

primary_blocks <- opportunity_lots |>
  filter(primary_opp50_850) |>
  group_by(borough, block) |>
  summarise(
    primary_lots_on_block = n(),
    block_capacity_exposure_quartile_citywide = max(capacity_exposure_quartile_citywide, na.rm = TRUE),
    block_allowed_policy_res_sqft = sum(allowed_policy_res_sqft, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    block_capacity_exposure_quartile_citywide = if_else(
      is.infinite(block_capacity_exposure_quartile_citywide),
      NA_integer_,
      as.integer(block_capacity_exposure_quartile_citywide)
    )
  )

primary_bbls <- opportunity_lots |>
  filter(primary_opp50_850) |>
  transmute(bbl)

same_block_unmatched_sales <- dof_sales |>
  filter(valid_bbl, positive_sale_price, !is.na(sale_date), !is.na(bbl)) |>
  mutate(
    sale_bbl = normalize_bbl_field(bbl),
    sale_borough = standardize_borough_code(borough_code),
    sale_block = suppressWarnings(as.integer(block_number)),
    policy_period = case_when(
      sale_date <= deadline_421a ~ "pre_421a_expiration",
      sale_date >= transition_start & sale_date < adoption_485x ~ "transition_421a_expired_pre_485x",
      sale_date >= adoption_485x ~ "post_485x_adoption",
      TRUE ~ NA_character_
    ),
    sale_lot_number = suppressWarnings(as.integer(lot_number)),
    condo_or_replatted_sale_lot = !is.na(sale_lot_number) & sale_lot_number >= 7500L
  ) |>
  anti_join(primary_bbls, by = c("sale_bbl" = "bbl")) |>
  inner_join(
    primary_blocks,
    by = c("sale_borough" = "borough", "sale_block" = "block"),
    relationship = "many-to-one"
  )

same_block_summary <- same_block_unmatched_sales |>
  group_by(policy_period, sale_borough, block_capacity_exposure_quartile_citywide) |>
  summarise(
    same_block_unmatched_sales = n(),
    same_block_unmatched_positive_value = sum(sale_price, na.rm = TRUE),
    same_block_unmatched_condo_or_replatted_sales = sum(condo_or_replatted_sale_lot),
    .groups = "drop"
  )

exact_sales_summary <- opportunity_sales |>
  filter(primary_opp50_850, positive_sale_price) |>
  group_by(policy_period, sale_borough_code, capacity_exposure_quartile_citywide) |>
  summarise(
    exact_sales = n(),
    exact_positive_value = sum(sale_price_nominal, na.rm = TRUE),
    exact_distinct_lots = n_distinct(sale_bbl),
    .groups = "drop"
  )

exact_match_bias <- same_block_summary |>
  full_join(
    exact_sales_summary,
    by = c(
      "policy_period" = "policy_period",
      "sale_borough" = "sale_borough_code",
      "block_capacity_exposure_quartile_citywide" = "capacity_exposure_quartile_citywide"
    )
  ) |>
  mutate(
    same_block_unmatched_sales = coalesce(same_block_unmatched_sales, 0L),
    same_block_unmatched_positive_value = coalesce(same_block_unmatched_positive_value, 0),
    same_block_unmatched_condo_or_replatted_sales = coalesce(same_block_unmatched_condo_or_replatted_sales, 0L),
    exact_sales = coalesce(exact_sales, 0L),
    exact_positive_value = coalesce(exact_positive_value, 0),
    exact_distinct_lots = coalesce(exact_distinct_lots, 0L),
    candidate_missed_to_exact_sales = if_else(exact_sales > 0, same_block_unmatched_sales / exact_sales, NA_real_),
    candidate_missed_value_to_exact_value = if_else(exact_positive_value > 0, same_block_unmatched_positive_value / exact_positive_value, NA_real_)
  ) |>
  arrange(policy_period, sale_borough, block_capacity_exposure_quartile_citywide)

write_csv_if_changed(exact_match_bias, "../output/opportunity_exact_match_bias_by_capacity_quartile.csv")
cat("Wrote opportunity-site sales diagnostics to ../output\n")

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

acris_site_incidence <- read_parquet("../input/acris_private_market_site_sale_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    opportunity_bbl = normalize_bbl_field(opportunity_bbl),
    event_quarter_start = as.Date(event_quarter_start)
  ) |>
  filter(primary_opp50_850)

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble()

primary_lots <- opportunity_lots |>
  filter(primary_opp50_850)

panel_key_duplicates <- lot_quarter_panel |>
  count(bbl, quarter_start, name = "rows") |>
  filter(rows > 1L)

expected_panel_rows <- n_distinct(primary_lots$bbl) * n_distinct(lot_quarter_panel$quarter_start)

panel_source_reconciliation <- tibble(
  metric = c(
    "primary_private_incidence_count",
    "strict_private_incidence_count",
    "broad_priced_transfer_incidence_count",
    "primary_complete_price_incidence_count",
    "strict_complete_price_incidence_count"
  ),
  source_count = c(
    sum(acris_site_incidence$event_primary_private_sale),
    sum(acris_site_incidence$event_strict_private_sale),
    sum(acris_site_incidence$event_broad_priced_transfer),
    sum(acris_site_incidence$primary_price_alloc_complete),
    sum(acris_site_incidence$strict_price_alloc_complete)
  ),
  panel_count = c(
    sum(lot_quarter_panel$acris_primary_private_sale_event_count_q),
    sum(lot_quarter_panel$acris_strict_private_sale_event_count_q),
    sum(lot_quarter_panel$acris_broad_priced_transfer_event_count_q),
    sum(lot_quarter_panel$acris_primary_price_complete_event_count_q),
    sum(lot_quarter_panel$acris_strict_price_complete_event_count_q)
  )
)

panel_hard_checks <- tibble(
  check_name = c(
    "unique_bbl_quarter",
    "row_count_equals_primary_lots_times_quarters",
    "all_rows_are_primary_opportunity_lots",
    "source_incidence_counts_match_panel",
    "strict_sale_is_subset_of_primary_sale",
    "primary_complete_price_implies_primary_sale",
    "strict_complete_price_implies_strict_sale",
    "broad_price_usable_implies_broad_sale",
    "primary_price_per_allowed_sqft_positive_when_present",
    "strict_price_per_allowed_sqft_positive_when_present",
    "low_price_never_in_primary"
  ),
  failed_rows = c(
    nrow(panel_key_duplicates),
    as.integer(nrow(lot_quarter_panel) != expected_panel_rows),
    lot_quarter_panel |> filter(!primary_opp50_850) |> nrow(),
    panel_source_reconciliation |> filter(source_count != panel_count) |> nrow(),
    lot_quarter_panel |> filter(strict_private_sale_acris_q & !primary_private_sale_acris_q) |> nrow(),
    lot_quarter_panel |> filter(primary_price_complete_sale_acris_q & !primary_private_sale_acris_q) |> nrow(),
    lot_quarter_panel |> filter(strict_price_complete_sale_acris_q & !strict_private_sale_acris_q) |> nrow(),
    lot_quarter_panel |> filter(broad_price_usable_sale_acris_q & !broad_priced_transfer_acris_q) |> nrow(),
    lot_quarter_panel |> filter(!is.na(acris_primary_price_per_allowed_policy_res_sqft_q) & acris_primary_price_per_allowed_policy_res_sqft_q <= 0) |> nrow(),
    lot_quarter_panel |> filter(!is.na(acris_strict_price_per_allowed_policy_res_sqft_q) & acris_strict_price_per_allowed_policy_res_sqft_q <= 0) |> nrow(),
    lot_quarter_panel |> filter(primary_private_sale_acris_q & acris_any_low_price_q) |> nrow()
  )
) |>
  mutate(
    passed = failed_rows == 0L,
    audit_note = case_when(
      check_name == "source_incidence_counts_match_panel" ~ paste(
        paste(panel_source_reconciliation$metric, panel_source_reconciliation$source_count, panel_source_reconciliation$panel_count, sep = "="),
        collapse = "; "
      ),
      TRUE ~ NA_character_
    )
  )

write_csv_if_changed(panel_hard_checks, "../output/opportunity_panel_hard_checks.csv")

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

acris_site_sale_linkage_summary <- lot_quarter_panel |>
  group_by(quarter_policy_period, borough, capacity_exposure_quartile_citywide) |>
  summarise(
    lot_quarters = n(),
    lots = n_distinct(bbl),
    acris_site_lot_quarters = sum(sold_acris_site_q),
    acris_primary_private_sale_lot_quarters = sum(primary_private_sale_acris_q),
    acris_strict_private_sale_lot_quarters = sum(strict_private_sale_acris_q),
    acris_broad_priced_transfer_lot_quarters = sum(broad_priced_transfer_acris_q),
    acris_primary_price_usable_lot_quarters = sum(primary_price_usable_sale_acris_q),
    acris_primary_price_complete_lot_quarters = sum(primary_price_complete_sale_acris_q),
    acris_strict_price_complete_lot_quarters = sum(strict_price_complete_sale_acris_q),
    acris_broad_price_usable_lot_quarters = sum(broad_price_usable_sale_acris_q),
    acris_site_sale_event_count = sum(acris_site_sale_event_count_q),
    acris_primary_private_sale_event_count = sum(acris_primary_private_sale_event_count_q),
    acris_strict_private_sale_event_count = sum(acris_strict_private_sale_event_count_q),
    acris_broad_priced_transfer_event_count = sum(acris_broad_priced_transfer_event_count_q),
    acris_primary_price_complete_event_count = sum(acris_primary_price_complete_event_count_q),
    acris_strict_price_complete_event_count = sum(acris_strict_price_complete_event_count_q),
    acris_primary_alloc_price_allowed_res_area_sum = sum(acris_primary_alloc_price_allowed_res_area_sum_q, na.rm = TRUE),
    acris_strict_alloc_price_allowed_res_area_sum = sum(acris_strict_alloc_price_allowed_res_area_sum_q, na.rm = TRUE),
    acris_incomplete_allocation_lot_quarters = sum(acris_any_incomplete_allocation_denominator_q),
    acris_low_opportunity_share_lot_quarters = sum(acris_any_low_opportunity_share_q),
    acris_low_price_lot_quarters = sum(acris_any_low_price_q),
    acris_weak_related_party_lot_quarters = sum(acris_any_weak_related_party_q),
    acris_trust_estate_party_lot_quarters = sum(acris_any_trust_estate_party_q),
    acris_mixed_rights_lot_quarters = sum(acris_any_mixed_rights_q),
    acris_primary_price_complete_lot_quarter_share = mean(primary_price_complete_sale_acris_q),
    .groups = "drop"
  )

write_csv_if_changed(acris_site_sale_linkage_summary, "../output/opportunity_acris_site_sale_linkage_summary.csv")

acris_price_distribution <- lot_quarter_panel |>
  filter(primary_price_complete_sale_acris_q, allowed_policy_res_sqft > 0) |>
  mutate(
    acris_primary_price_per_allowed_policy_res_sqft = acris_primary_alloc_price_allowed_res_area_sum_q / allowed_policy_res_sqft
  ) |>
  group_by(quarter_policy_period, borough, capacity_exposure_quartile_citywide) |>
  summarise(
    lot_quarters = n(),
    lots = n_distinct(bbl),
    median_acris_alloc_price_allowed_res_area = median(acris_primary_alloc_price_allowed_res_area_sum_q, na.rm = TRUE),
    p10_acris_price_per_allowed_policy_res_sqft = quantile(acris_primary_price_per_allowed_policy_res_sqft, 0.10, na.rm = TRUE, names = FALSE),
    median_acris_price_per_allowed_policy_res_sqft = median(acris_primary_price_per_allowed_policy_res_sqft, na.rm = TRUE),
    p90_acris_price_per_allowed_policy_res_sqft = quantile(acris_primary_price_per_allowed_policy_res_sqft, 0.90, na.rm = TRUE, names = FALSE),
    incomplete_allocation_lot_quarters = sum(acris_any_incomplete_allocation_denominator_q),
    low_opportunity_share_lot_quarters = sum(acris_any_low_opportunity_share_q),
    low_price_lot_quarters = sum(acris_any_low_price_q),
    weak_related_party_lot_quarters = sum(acris_any_weak_related_party_q),
    trust_estate_party_lot_quarters = sum(acris_any_trust_estate_party_q),
    .groups = "drop"
  )

write_csv_if_changed(acris_price_distribution, "../output/opportunity_acris_site_sale_price_distribution.csv")

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

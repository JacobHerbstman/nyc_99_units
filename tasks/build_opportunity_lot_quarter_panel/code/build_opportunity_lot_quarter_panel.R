# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_opportunity_lot_quarter_panel/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

collapse_unique <- function(x) {
  values <- sort(unique(as.character(x[!is.na(x) & x != ""])))
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(values, collapse = ";")
}

first_flagged_value <- function(x, flag) {
  values <- x[flag & !is.na(x)]
  if (length(values) == 0L) {
    return(NA_real_)
  }

  values[1L]
}

deadline_421a <- as.Date("2022-06-15")
transition_start <- as.Date("2022-06-16")
adoption_485x <- as.Date("2024-04-20")
rules_adopted_485x <- as.Date("2024-12-16")
rules_effective_485x <- as.Date("2025-01-15")

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850) |>
  select(
    bbl, borough, block, lot, address, cd, zipcode, council,
    frozen_source_id, frozen_vintage, frozen_safe_available_date,
    primary_opportunity_rule,
    zonedist1, zone_base, zone_detail, landuse_code, bldgclass, bldgclass_family,
    lotarea, bldgarea, resarea, unitsres, unitstotal, yearbuilt,
    builtfar, residfar, commfar, facilfar, assessland, assesstot,
    allowed_policy_res_sqft, residual_policy_res_sqft,
    residual_policy_bldgarea_sqft, builtfar_ratio,
    capacity_units_850, capacity50_850, capacity100_850,
    capacity_exposure_pctile_citywide, capacity_exposure_quartile_citywide,
    capacity_exposure_pctile_borough, capacity_exposure_quartile_borough,
    vacant_landuse, parking_landuse, vacant_bldgclass, underbuilt_half_allowed_far,
    public_transport_utility_open_space_landuse, condo_or_billing_lot,
    primary_opp50_850, soft_site_opp50_850
  )

if (anyDuplicated(opportunity_lots$bbl) > 0) {
  stop("Primary opportunity lots are not unique by BBL.")
}

opportunity_sales <- read_parquet("../input/opportunity_sales_exact_bbl.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850) |>
  mutate(
    sale_quarter_start = as.Date(sale_quarter_start),
    positive_non_nominal_sale = positive_sale_price & !nominal_sale_price
  )

acris_site_sales <- read_parquet("../input/acris_private_market_site_sale_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    opportunity_bbl = normalize_bbl_field(opportunity_bbl),
    event_date_primary = as.Date(event_date_primary),
    event_quarter_start = as.Date(event_quarter_start)
  ) |>
  filter(primary_opp50_850)

if (anyDuplicated(paste(acris_site_sales$event_id, acris_site_sales$opportunity_bbl, sep = "::")) > 0L) {
  stop("ACRIS private-market site-sale incidence is not unique by event_id/opportunity_bbl.")
}

quarter_rows <- tibble(
  quarter_start = seq(as.Date("2010-01-01"), as.Date("2025-10-01"), by = "3 months")
) |>
  mutate(
    quarter_end = quarter_start %m+% months(3L) - days(1L),
    quarter = paste0(year(quarter_start), "Q", quarter(quarter_start)),
    quarter_contains_421a_deadline = quarter_start <= deadline_421a & quarter_end >= deadline_421a,
    quarter_contains_485x_adoption = quarter_start <= adoption_485x & quarter_end >= adoption_485x,
    quarter_contains_485x_rules_adopted = quarter_start <= rules_adopted_485x & quarter_end >= rules_adopted_485x,
    quarter_contains_485x_rules_effective = quarter_start <= rules_effective_485x & quarter_end >= rules_effective_485x,
    clean_pre_421a_expiration_quarter = quarter_end <= deadline_421a,
    clean_transition_quarter = quarter_start >= transition_start & quarter_end < adoption_485x,
    clean_post_485x_adoption_quarter = quarter_start >= as.Date("2024-07-01"),
    clean_post_485x_rules_effective_quarter = quarter_start >= as.Date("2025-04-01"),
    quarter_policy_period = case_when(
      clean_pre_421a_expiration_quarter ~ "pre_421a_expiration",
      clean_transition_quarter ~ "transition_421a_expired_pre_485x",
      clean_post_485x_adoption_quarter ~ "post_485x_adoption",
      TRUE ~ "mixed_policy_quarter"
    )
  )

sales_by_quarter <- opportunity_sales |>
  group_by(sale_bbl, sale_quarter_start) |>
  summarise(
    sale_count_exact_q = n(),
    positive_sale_count_exact_q = sum(positive_sale_price),
    positive_non_nominal_sale_count_exact_q = sum(positive_non_nominal_sale),
    nominal_sale_count_exact_q = sum(nominal_sale_price),
    sale_price_nominal_sum_q = sum(sale_price_nominal[positive_sale_price], na.rm = TRUE),
    sale_price_nominal_max_q = if (any(positive_sale_price)) max(sale_price_nominal[positive_sale_price], na.rm = TRUE) else NA_real_,
    primary_price_outcome_feasible_sale_count_q = sum(primary_price_outcome_feasible_nominal),
    .groups = "drop"
  ) |>
  mutate(sale_price_nominal_max_q = if_else(is.infinite(sale_price_nominal_max_q), NA_real_, sale_price_nominal_max_q))

acris_site_sales_by_quarter <- acris_site_sales |>
  arrange(opportunity_bbl, event_quarter_start, event_date_primary, event_id) |>
  group_by(opportunity_bbl, event_quarter_start) |>
  summarise(
    acris_site_sale_event_count_q = n_distinct(event_id),
    acris_primary_private_sale_event_count_q = n_distinct(event_id[event_primary_private_sale]),
    acris_primary_price_usable_event_count_q = n_distinct(event_id[primary_price_alloc_usable]),
    acris_primary_price_complete_event_count_q = n_distinct(event_id[primary_price_alloc_complete]),
    acris_strict_price_complete_event_count_q = n_distinct(event_id[strict_price_alloc_complete]),
    acris_broad_price_usable_event_count_q = n_distinct(event_id[broad_price_alloc_usable]),
    acris_primary_alloc_price_allowed_res_area_sum_q = sum(event_price_alloc_allowed_res_area[primary_price_alloc_complete], na.rm = TRUE),
    acris_primary_alloc_price_lotarea_sum_q = sum(event_price_alloc_lotarea[primary_price_alloc_complete], na.rm = TRUE),
    acris_primary_alloc_price_equal_sum_q = sum(event_price_alloc_equal[primary_price_alloc_complete], na.rm = TRUE),
    acris_primary_alloc_price_allowed_res_area_max_q = if (any(primary_price_alloc_complete)) max(event_price_alloc_allowed_res_area[primary_price_alloc_complete], na.rm = TRUE) else NA_real_,
    acris_primary_alloc_price_allowed_res_area_first_q = first_flagged_value(event_price_alloc_allowed_res_area, primary_price_alloc_complete),
    acris_primary_event_ids_q = collapse_unique(event_id[event_primary_private_sale]),
    acris_primary_price_complete_event_ids_q = collapse_unique(event_id[primary_price_alloc_complete]),
    acris_price_resolution_statuses_q = collapse_unique(price_resolution_status[primary_price_alloc_usable]),
    acris_incidence_warning_codes_q = collapse_unique(incidence_warning_codes[event_primary_private_sale]),
    acris_any_incomplete_allocation_denominator_q = any(event_primary_private_sale & !primary_price_alloc_complete),
    acris_any_low_opportunity_share_q = any(event_primary_private_sale & event_low_opportunity_share_flag),
    acris_any_low_price_q = any(event_primary_private_sale & event_low_price_flag),
    acris_any_weak_related_party_q = any(event_primary_private_sale & related_party_weak_flag),
    acris_any_trust_estate_party_q = any(event_primary_private_sale & trust_estate_party_flag),
    acris_any_mixed_rights_q = any(event_primary_private_sale & mixed_rights_flag),
    .groups = "drop"
  )

if (anyDuplicated(paste(acris_site_sales_by_quarter$opportunity_bbl, acris_site_sales_by_quarter$event_quarter_start, sep = "::")) > 0L) {
  stop("ACRIS site sales by BBL-quarter are not unique.")
}

lot_quarter_panel <- merge(opportunity_lots, quarter_rows, by = NULL) |>
  as_tibble() |>
  left_join(
    sales_by_quarter,
    by = c("bbl" = "sale_bbl", "quarter_start" = "sale_quarter_start"),
    relationship = "one-to-one"
  ) |>
  left_join(
    acris_site_sales_by_quarter,
    by = c("bbl" = "opportunity_bbl", "quarter_start" = "event_quarter_start"),
    relationship = "one-to-one"
  ) |>
  mutate(
    sale_count_exact_q = coalesce(sale_count_exact_q, 0L),
    positive_sale_count_exact_q = coalesce(positive_sale_count_exact_q, 0L),
    positive_non_nominal_sale_count_exact_q = coalesce(positive_non_nominal_sale_count_exact_q, 0L),
    nominal_sale_count_exact_q = coalesce(nominal_sale_count_exact_q, 0L),
    sale_price_nominal_sum_q = coalesce(sale_price_nominal_sum_q, 0),
    primary_price_outcome_feasible_sale_count_q = coalesce(primary_price_outcome_feasible_sale_count_q, 0L),
    sold_exact_q = sale_count_exact_q > 0,
    positive_sale_exact_q = positive_sale_count_exact_q > 0,
    positive_non_nominal_sale_exact_q = positive_non_nominal_sale_count_exact_q > 0,
    primary_price_outcome_feasible_sale_q = primary_price_outcome_feasible_sale_count_q > 0,
    acris_site_sale_event_count_q = coalesce(acris_site_sale_event_count_q, 0L),
    acris_primary_private_sale_event_count_q = coalesce(acris_primary_private_sale_event_count_q, 0L),
    acris_primary_price_usable_event_count_q = coalesce(acris_primary_price_usable_event_count_q, 0L),
    acris_primary_price_complete_event_count_q = coalesce(acris_primary_price_complete_event_count_q, 0L),
    acris_strict_price_complete_event_count_q = coalesce(acris_strict_price_complete_event_count_q, 0L),
    acris_broad_price_usable_event_count_q = coalesce(acris_broad_price_usable_event_count_q, 0L),
    acris_primary_alloc_price_allowed_res_area_sum_q = coalesce(acris_primary_alloc_price_allowed_res_area_sum_q, 0),
    acris_primary_alloc_price_lotarea_sum_q = coalesce(acris_primary_alloc_price_lotarea_sum_q, 0),
    acris_primary_alloc_price_equal_sum_q = coalesce(acris_primary_alloc_price_equal_sum_q, 0),
    sold_acris_site_q = acris_site_sale_event_count_q > 0,
    primary_private_sale_acris_q = acris_primary_private_sale_event_count_q > 0,
    primary_price_usable_sale_acris_q = acris_primary_price_usable_event_count_q > 0,
    primary_price_complete_sale_acris_q = acris_primary_price_complete_event_count_q > 0,
    strict_price_complete_sale_acris_q = acris_strict_price_complete_event_count_q > 0,
    broad_price_usable_sale_acris_q = acris_broad_price_usable_event_count_q > 0,
    acris_any_incomplete_allocation_denominator_q = coalesce(acris_any_incomplete_allocation_denominator_q, FALSE),
    acris_any_low_opportunity_share_q = coalesce(acris_any_low_opportunity_share_q, FALSE),
    acris_any_low_price_q = coalesce(acris_any_low_price_q, FALSE),
    acris_any_weak_related_party_q = coalesce(acris_any_weak_related_party_q, FALSE),
    acris_any_trust_estate_party_q = coalesce(acris_any_trust_estate_party_q, FALSE),
    acris_any_mixed_rights_q = coalesce(acris_any_mixed_rights_q, FALSE)
  ) |>
  arrange(bbl, quarter_start)

expected_rows <- nrow(opportunity_lots) * nrow(quarter_rows)

if (nrow(lot_quarter_panel) != expected_rows) {
  stop("Lot-quarter panel row count is not equal to primary opportunity lots times quarters.")
}

write_parquet_if_changed(lot_quarter_panel, "../output/opportunity_lot_quarter_panel.parquet")
cat("Wrote opportunity lot-quarter panel to ../output\n")

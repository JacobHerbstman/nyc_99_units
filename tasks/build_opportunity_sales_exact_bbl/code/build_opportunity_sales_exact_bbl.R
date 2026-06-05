# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_opportunity_sales_exact_bbl/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

deadline_421a <- as.Date("2022-06-15")
start_transition <- as.Date("2022-06-16")
adoption_485x <- as.Date("2024-04-20")
rules_adopted_485x <- as.Date("2024-12-16")
rules_effective_485x <- as.Date("2025-01-15")
nominal_sale_price_threshold <- 1000
low_price_per_allowed_res_sqft_threshold <- 1
high_price_per_allowed_res_sqft_threshold <- 2000

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

if (anyDuplicated(opportunity_lots$bbl[!is.na(opportunity_lots$bbl)]) > 0) {
  stop("Frozen opportunity lots are not unique by BBL.")
}

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble()

if (anyDuplicated(dof_sales$sale_record_id) > 0) {
  stop("DOF annualized sales rows are not unique by sale_record_id.")
}

sales_clean <- dof_sales |>
  filter(valid_bbl, !is.na(bbl), !is.na(sale_date), sale_date >= as.Date("2010-01-01"), sale_date <= as.Date("2025-12-31")) |>
  mutate(
    sale_bbl = normalize_bbl_field(bbl),
    sale_quarter_start = floor_date(sale_date, unit = "quarter"),
    sale_quarter = paste0(year(sale_quarter_start), "Q", quarter(sale_quarter_start)),
    policy_period = case_when(
      sale_date <= deadline_421a ~ "pre_421a_expiration",
      sale_date >= start_transition & sale_date < adoption_485x ~ "transition_421a_expired_pre_485x",
      sale_date >= adoption_485x ~ "post_485x_adoption",
      TRUE ~ NA_character_
    ),
    post_421a_expiration = sale_date > deadline_421a,
    post_485x_adoption = sale_date >= adoption_485x,
    post_485x_rules_adopted = sale_date >= rules_adopted_485x,
    post_485x_rules_effective = sale_date >= rules_effective_485x,
    nominal_sale_price = !is.na(sale_price) & sale_price > 0 & sale_price < nominal_sale_price_threshold
  ) |>
  transmute(
    sale_record_id, sale_bbl, sale_borough_code = borough_code,
    sale_block_number = block_number, sale_lot_number = lot_number,
    sale_date, sale_year, sale_quarter_start, sale_quarter, policy_period,
    post_421a_expiration, post_485x_adoption, post_485x_rules_adopted,
    post_485x_rules_effective,
    sale_price_nominal = sale_price,
    positive_sale_price, nominal_sale_price,
    neighborhood, building_class_category, tax_class_at_present,
    building_class_at_present, sale_address = address, sale_zip_code = zip_code,
    sale_residential_units = residential_units,
    sale_commercial_units = commercial_units,
    sale_total_units = total_units,
    sale_land_square_feet = land_square_feet,
    sale_gross_square_feet = gross_square_feet,
    sale_year_built = year_built,
    tax_class_at_time_of_sale,
    building_class_at_time_of_sale,
    source_year, source_borough, source_raw_path, source_row_number
  )

opportunity_lots_for_join <- opportunity_lots |>
  filter(valid_bbl, !is.na(bbl)) |>
  select(
    frozen_bbl = bbl,
    frozen_source_id, frozen_vintage, frozen_release_order, frozen_safe_available_date,
    freeze_rule, primary_opportunity_rule,
    borough, block, lot, address, cd, zipcode, council,
    zonedist1, zonedist2, zonedist3, zonedist4, zone_base, zone_detail,
    overlay1, overlay2, spdist1, spdist2, spdist3, ltdheight, splitzone,
    landuse, landuse_code, bldgclass, bldgclass_family,
    lotarea, bldgarea, resarea, comarea, unitsres, unitstotal, numbldgs,
    numfloors, yearbuilt, builtfar, residfar, commfar, facilfar,
    assessland, assesstot, histdist, landmark,
    allowed_policy_res_sqft, allowed_policy_res_sqft_source,
    residual_policy_res_sqft, residual_policy_bldgarea_sqft,
    allowed_policy_far, builtfar_ratio,
    starts_with("capacity_units_"), starts_with("capacity50_"), starts_with("capacity100_"),
    capacity_exposure_pctile_citywide, capacity_exposure_quartile_citywide,
    capacity_exposure_pctile_borough, capacity_exposure_quartile_borough,
    positive_lotarea, positive_residfar, positive_allowed_policy_res_sqft,
    vacant_landuse, parking_landuse, public_transport_utility_open_space_landuse,
    vacant_bldgclass, condo_or_billing_lot, underbuilt_half_allowed_far,
    primary_hard_exclusion, primary_opp50_850, soft_site_opp50_850
  )

if (anyDuplicated(opportunity_lots_for_join$frozen_bbl) > 0) {
  stop("Opportunity-lot join table is not unique by frozen_bbl.")
}

opportunity_sales <- sales_clean |>
  inner_join(
    opportunity_lots_for_join,
    by = c("sale_bbl" = "frozen_bbl"),
    relationship = "many-to-one"
  ) |>
  mutate(
    exact_bbl_link = TRUE,
    price_deflator_status = "not_applied_nominal_only",
    price_per_allowed_policy_res_sqft_nominal = if_else(
      positive_sale_price & !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0,
      sale_price_nominal / allowed_policy_res_sqft,
      NA_real_
    ),
    price_per_lot_sqft_nominal = if_else(
      positive_sale_price & !is.na(lotarea) & lotarea > 0,
      sale_price_nominal / lotarea,
      NA_real_
    ),
    price_per_residual_policy_res_sqft_nominal = if_else(
      positive_sale_price & !is.na(residual_policy_res_sqft) & residual_policy_res_sqft > 0,
      sale_price_nominal / residual_policy_res_sqft,
      NA_real_
    ),
    log_sale_price_nominal = if_else(positive_sale_price, log(sale_price_nominal), NA_real_),
    log_price_per_allowed_policy_res_sqft_nominal = if_else(
      !is.na(price_per_allowed_policy_res_sqft_nominal) & price_per_allowed_policy_res_sqft_nominal > 0,
      log(price_per_allowed_policy_res_sqft_nominal),
      NA_real_
    ),
    log_price_per_lot_sqft_nominal = if_else(
      !is.na(price_per_lot_sqft_nominal) & price_per_lot_sqft_nominal > 0,
      log(price_per_lot_sqft_nominal),
      NA_real_
    ),
    log_price_per_residual_policy_res_sqft_nominal = if_else(
      !is.na(price_per_residual_policy_res_sqft_nominal) & price_per_residual_policy_res_sqft_nominal > 0,
      log(price_per_residual_policy_res_sqft_nominal),
      NA_real_
    ),
    low_price_per_allowed_policy_res_sqft = !is.na(price_per_allowed_policy_res_sqft_nominal) &
      price_per_allowed_policy_res_sqft_nominal < low_price_per_allowed_res_sqft_threshold,
    high_price_per_allowed_policy_res_sqft = !is.na(price_per_allowed_policy_res_sqft_nominal) &
      price_per_allowed_policy_res_sqft_nominal > high_price_per_allowed_res_sqft_threshold,
    primary_price_outcome_feasible_nominal = primary_opp50_850 &
      positive_sale_price &
      !nominal_sale_price &
      !is.na(price_per_allowed_policy_res_sqft_nominal) &
      is.finite(price_per_allowed_policy_res_sqft_nominal) &
      price_per_allowed_policy_res_sqft_nominal > 0
  ) |>
  arrange(sale_date, sale_record_id, sale_bbl)

if (anyDuplicated(opportunity_sales$sale_record_id) > 0) {
  stop("Exact-BBL opportunity sales are not unique by sale_record_id.")
}

write_parquet_if_changed(opportunity_sales, "../output/opportunity_sales_exact_bbl.parquet")
cat("Wrote exact-BBL opportunity sales to ../output\n")

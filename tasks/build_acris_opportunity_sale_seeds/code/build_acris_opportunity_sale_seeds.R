# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_opportunity_sale_seeds/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
})

source("../../_lib/source_pipeline_utils.R")

start_date <- as.Date("2010-01-01")
end_date <- as.Date("2025-12-31")

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_blocks <- read_csv("../input/acris_opportunity_blocks.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    borough = standardize_borough_code(borough),
    block = suppressWarnings(as.integer(block))
  )

dof_sales <- read_parquet("../input/dof_annualized_sales.parquet") |>
  as.data.frame() |>
  as_tibble()

primary_bbls <- opportunity_lots |>
  filter(primary_opp50_850, valid_bbl) |>
  transmute(
    sale_bbl = bbl,
    is_primary_opportunity_bbl = TRUE
  )

seed_sales <- dof_sales |>
  filter(valid_bbl, positive_sale_price, !is.na(sale_date), sale_date >= start_date, sale_date <= end_date) |>
  mutate(
    sale_bbl = normalize_bbl_field(bbl),
    sale_borough = standardize_borough_code(borough_code),
    sale_block = suppressWarnings(as.integer(block_number)),
    sale_lot = suppressWarnings(as.integer(lot_number)),
    sale_quarter_start = floor_date(sale_date, "quarter"),
    sale_quarter = paste0(year(sale_quarter_start), "Q", quarter(sale_quarter_start))
  ) |>
  inner_join(
    opportunity_blocks,
    by = c("sale_borough" = "borough", "sale_block" = "block"),
    relationship = "many-to-one"
  ) |>
  left_join(
    primary_bbls,
    by = "sale_bbl",
    relationship = "many-to-one"
  ) |>
  mutate(
    is_primary_opportunity_bbl = coalesce(is_primary_opportunity_bbl, FALSE),
    seed_match_type = if_else(is_primary_opportunity_bbl, "exact_primary_opportunity_bbl", "same_block_unmatched_bbl"),
    sale_price_key = as.character(round(sale_price)),
    document_date_key = format(sale_date, "%Y-%m-%d"),
    acris_master_exact_key = paste(sale_borough, document_date_key, sale_price_key, sep = "::"),
    condo_or_replatted_sale_lot = !is.na(sale_lot) & sale_lot >= 7500L
  ) |>
  select(
    sale_record_id, seed_match_type, is_primary_opportunity_bbl,
    sale_bbl, sale_borough, sale_block, sale_lot,
    sale_date, sale_year, sale_quarter_start, sale_quarter,
    sale_price, sale_price_key, document_date_key, acris_master_exact_key,
    condo_or_replatted_sale_lot,
    neighborhood, building_class_category, tax_class_at_present,
    building_class_at_present, tax_class_at_time_of_sale,
    building_class_at_time_of_sale, sale_address = address, sale_zip_code = zip_code,
    sale_residential_units = residential_units, sale_commercial_units = commercial_units,
    sale_total_units = total_units, sale_land_square_feet = land_square_feet,
    sale_gross_square_feet = gross_square_feet, sale_year_built = year_built,
    primary_opportunity_lots, soft_site_opportunity_lots, capacity100_850_lots,
    total_allowed_policy_res_sqft, max_allowed_policy_res_sqft,
    max_capacity_exposure_quartile_citywide, max_capacity_exposure_quartile_borough,
    source_year, source_borough, source_raw_path, source_row_number
  ) |>
  arrange(sale_date, sale_record_id)

if (anyDuplicated(seed_sales$sale_record_id) > 0) {
  stop("ACRIS opportunity sale seeds are not unique by sale_record_id.")
}

write_parquet_if_changed(seed_sales, "../output/acris_opportunity_sale_seeds.parquet")
cat("Wrote ACRIS opportunity sale seeds to ../output\n")

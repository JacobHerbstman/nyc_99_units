# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_opportunity_block_universe/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})

source("../../_lib/source_pipeline_utils.R")

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_blocks <- opportunity_lots |>
  filter(primary_opp50_850, valid_bbl, !is.na(borough), !is.na(block)) |>
  group_by(borough, block) |>
  summarise(
    primary_opportunity_lots = n(),
    soft_site_opportunity_lots = sum(soft_site_opp50_850),
    capacity100_850_lots = sum(capacity100_850),
    total_allowed_policy_res_sqft = sum(allowed_policy_res_sqft, na.rm = TRUE),
    max_allowed_policy_res_sqft = max(allowed_policy_res_sqft, na.rm = TRUE),
    max_capacity_exposure_quartile_citywide = max(capacity_exposure_quartile_citywide, na.rm = TRUE),
    max_capacity_exposure_quartile_borough = max(capacity_exposure_quartile_borough, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    max_allowed_policy_res_sqft = if_else(is.infinite(max_allowed_policy_res_sqft), NA_real_, max_allowed_policy_res_sqft),
    max_capacity_exposure_quartile_citywide = if_else(
      is.infinite(max_capacity_exposure_quartile_citywide),
      NA_integer_,
      as.integer(max_capacity_exposure_quartile_citywide)
    ),
    max_capacity_exposure_quartile_borough = if_else(
      is.infinite(max_capacity_exposure_quartile_borough),
      NA_integer_,
      as.integer(max_capacity_exposure_quartile_borough)
    )
  ) |>
  arrange(borough, block)

if (anyDuplicated(paste(opportunity_blocks$borough, opportunity_blocks$block, sep = "::")) > 0) {
  stop("Opportunity block universe is not unique by borough/block.")
}

write_csv_if_changed(opportunity_blocks, "../output/acris_opportunity_blocks.csv")
cat("Wrote ACRIS opportunity block universe to ../output\n")

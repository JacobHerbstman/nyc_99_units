# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_opportunity_panel_first_pass/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(fixest)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

panel <- read_parquet("../input/opportunity_lot_quarter_panel.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    high_q4 = as.integer(capacity_exposure_quartile_citywide == 4L),
    high_q34 = as.integer(capacity_exposure_quartile_citywide >= 3L),
    transition = as.integer(quarter_policy_period == "transition_421a_expired_pre_485x"),
    mixed_policy = as.integer(quarter_policy_period == "mixed_policy_quarter"),
    post_485x = as.integer(quarter_policy_period == "post_485x_adoption"),
    primary_price_psf = acris_primary_price_per_allowed_policy_res_sqft_q
  )

panel_key_duplicates <- panel |>
  count(bbl, quarter_start, name = "rows") |>
  filter(rows > 1L)

expected_rows <- n_distinct(panel$bbl) * n_distinct(panel$quarter_start)

hard_checks <- tibble(
  check_name = c(
    "unique_bbl_quarter",
    "row_count_equals_lots_times_quarters",
    "all_rows_primary_opportunity_lots",
    "primary_price_positive_when_present",
    "strict_price_positive_when_present"
  ),
  failed_rows = c(
    nrow(panel_key_duplicates),
    as.integer(nrow(panel) != expected_rows),
    panel |> filter(!primary_opp50_850) |> nrow(),
    panel |> filter(!is.na(acris_primary_price_per_allowed_policy_res_sqft_q) & acris_primary_price_per_allowed_policy_res_sqft_q <= 0) |> nrow(),
    panel |> filter(!is.na(acris_strict_price_per_allowed_policy_res_sqft_q) & acris_strict_price_per_allowed_policy_res_sqft_q <= 0) |> nrow()
  )
) |>
  mutate(passed = failed_rows == 0L)

if (any(!hard_checks$passed)) {
  write_csv_if_changed(hard_checks, "../output/opportunity_panel_first_pass_hard_checks.csv")
  stop("Opportunity panel first-pass audit failed at least one hard check.")
}

period_quartile <- panel |>
  group_by(quarter_policy_period, capacity_exposure_quartile_citywide) |>
  summarise(
    lot_quarters = n(),
    lots = n_distinct(bbl),
    primary_sale_lot_quarters = sum(primary_private_sale_acris_q),
    strict_sale_lot_quarters = sum(strict_private_sale_acris_q),
    broad_priced_transfer_lot_quarters = sum(broad_priced_transfer_acris_q),
    primary_price_complete_lot_quarters = sum(primary_price_complete_sale_acris_q),
    primary_sale_rate_per_1000_lot_quarters = 1000 * mean(primary_private_sale_acris_q),
    strict_sale_rate_per_1000_lot_quarters = 1000 * mean(strict_private_sale_acris_q),
    median_primary_price_per_allowed_sqft = median(primary_price_psf, na.rm = TRUE),
    mean_primary_price_per_allowed_sqft = mean(primary_price_psf, na.rm = TRUE),
    p10_primary_price_per_allowed_sqft = quantile(primary_price_psf, 0.10, na.rm = TRUE, names = FALSE),
    p90_primary_price_per_allowed_sqft = quantile(primary_price_psf, 0.90, na.rm = TRUE, names = FALSE),
    incomplete_allocation_lot_quarters = sum(acris_any_incomplete_allocation_denominator_q),
    low_opportunity_share_lot_quarters = sum(acris_any_low_opportunity_share_q),
    weak_related_party_lot_quarters = sum(acris_any_weak_related_party_q),
    .groups = "drop"
  ) |>
  arrange(quarter_policy_period, capacity_exposure_quartile_citywide)

price_sample <- panel |>
  filter(primary_price_complete_sale_acris_q, primary_price_psf > 0)

sample_rows <- tibble(
  sample_name = c(
    "lot_quarter_panel",
    "primary_private_sale_lot_quarters",
    "primary_price_complete_positive_price"
  ),
  observations = c(
    nrow(panel),
    sum(panel$primary_private_sale_acris_q),
    nrow(price_sample)
  ),
  lots = c(
    n_distinct(panel$bbl),
    n_distinct(panel$bbl[panel$primary_private_sale_acris_q]),
    n_distinct(price_sample$bbl)
  ),
  quarters = c(
    n_distinct(panel$quarter_start),
    n_distinct(panel$quarter_start[panel$primary_private_sale_acris_q]),
    n_distinct(price_sample$quarter_start)
  )
)

sale_q4 <- feols(
  primary_private_sale_acris_q ~ high_q4:transition + high_q4:mixed_policy + high_q4:post_485x | bbl + quarter_start,
  cluster = ~bbl,
  data = panel
)

sale_q34 <- feols(
  primary_private_sale_acris_q ~ high_q34:transition + high_q34:mixed_policy + high_q34:post_485x | bbl + quarter_start,
  cluster = ~bbl,
  data = panel
)

price_q4 <- feols(
  log(primary_price_psf) ~ high_q4:transition + high_q4:mixed_policy + high_q4:post_485x | borough + quarter_start,
  cluster = ~bbl,
  data = price_sample
)

price_q34 <- feols(
  log(primary_price_psf) ~ high_q34:transition + high_q34:mixed_policy + high_q34:post_485x | borough + quarter_start,
  cluster = ~bbl,
  data = price_sample
)

model_list <- list(
  sale_q4 = sale_q4,
  sale_q34 = sale_q34,
  log_price_q4 = price_q4,
  log_price_q34 = price_q34
)

regression_rows <- bind_rows(lapply(names(model_list), function(model_name) {
  model_object <- model_list[[model_name]]
  model_observations <- model_object$nobs
  model_r2 <- as.numeric(r2(model_object, type = "r2"))
  model_within_r2 <- as.numeric(r2(model_object, type = "wr2"))

  as.data.frame(coeftable(model_object)) |>
    rownames_to_column("term") |>
    as_tibble() |>
    transmute(
      model = model_name,
      outcome = case_when(
        model_name %in% c("sale_q4", "sale_q34") ~ "primary_private_sale_acris_q",
        TRUE ~ "log_primary_price_per_allowed_sqft"
      ),
      exposure_definition = case_when(
        model_name %in% c("sale_q4", "log_price_q4") ~ "quartile_4_vs_1_to_3",
        TRUE ~ "quartiles_3_to_4_vs_1_to_2"
      ),
      term,
      estimate = Estimate,
      std_error = `Std. Error`,
      t_value = `t value`,
      p_value = `Pr(>|t|)`,
      observations = model_observations,
      r2 = model_r2,
      within_r2 = model_within_r2
    )
}))

write_csv_if_changed(period_quartile, "../output/opportunity_panel_first_pass_period_quartile.csv")
write_csv_if_changed(regression_rows, "../output/opportunity_panel_first_pass_regressions.csv")
write_csv_if_changed(sample_rows, "../output/opportunity_panel_first_pass_samples.csv")
write_csv_if_changed(hard_checks, "../output/opportunity_panel_first_pass_hard_checks.csv")

cat("Wrote opportunity panel first-pass diagnostics to ../output\n")

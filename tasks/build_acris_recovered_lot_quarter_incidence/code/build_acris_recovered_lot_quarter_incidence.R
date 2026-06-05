# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_recovered_lot_quarter_incidence/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(tibble)
  library(tidyr)
})

source("../../_lib/source_pipeline_utils.R")

deadline_421a <- as.Date("2022-06-15")
transition_start <- as.Date("2022-06-16")
adoption_485x <- as.Date("2024-04-20")
rules_adopted_485x <- as.Date("2024-12-16")
rules_effective_485x <- as.Date("2025-01-15")

recovered_sale_events <- read_parquet("../input/acris_recovered_sale_events.parquet") |>
  as.data.frame() |>
  as_tibble()

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

event_bbl_rows <- recovered_sale_events |>
  select(
    document_id, event_id, crfn, document_date, document_amt,
    recorded_borough, doc_type, recorded_datetime, percent_trans, good_through_date,
    event_date, event_price, dof_sale_records_linked, dof_sale_bbls_linked,
    dof_sale_record_ids, dof_sale_bbls, seed_match_types,
    exact_primary_seed_rows, same_block_seed_rows, legal_bbl_count, legal_bbls,
    primary_opportunity_bbl_count, primary_opportunity_bbls,
    price_source, recovery_method
  ) |>
  separate_longer_delim(primary_opportunity_bbls, delim = ";") |>
  rename(bbl = primary_opportunity_bbls) |>
  mutate(bbl = normalize_bbl_field(bbl)) |>
  filter(!is.na(bbl))

event_bbl_counts <- event_bbl_rows |>
  group_by(event_id) |>
  summarise(recovered_incidence_bbl_count = n_distinct(bbl), .groups = "drop")

event_bbl_rows <- event_bbl_rows |>
  left_join(event_bbl_counts, by = "event_id", relationship = "many-to-one")

if (any(event_bbl_rows$recovered_incidence_bbl_count != event_bbl_rows$primary_opportunity_bbl_count)) {
  stop("Expanded recovered-event BBL count does not match event primary_opportunity_bbl_count.")
}

event_allowed_area <- event_bbl_rows |>
  left_join(
    opportunity_lots |>
      select(bbl, allowed_policy_res_sqft),
    by = "bbl",
    relationship = "many-to-one"
  ) |>
  group_by(event_id) |>
  summarise(event_allowed_policy_res_sqft = sum(allowed_policy_res_sqft, na.rm = TRUE), .groups = "drop")

incidence <- event_bbl_rows |>
  left_join(opportunity_lots, by = "bbl", relationship = "many-to-one") |>
  left_join(event_allowed_area, by = "event_id", relationship = "many-to-one") |>
  mutate(
    event_quarter_start = floor_date(event_date, "quarter"),
    event_quarter_end = event_quarter_start %m+% months(3L) - days(1L),
    event_quarter = paste0(year(event_quarter_start), "Q", quarter(event_quarter_start)),
    quarter_contains_421a_deadline = event_quarter_start <= deadline_421a & event_quarter_end >= deadline_421a,
    quarter_contains_485x_adoption = event_quarter_start <= adoption_485x & event_quarter_end >= adoption_485x,
    quarter_contains_485x_rules_adopted = event_quarter_start <= rules_adopted_485x & event_quarter_end >= rules_adopted_485x,
    quarter_contains_485x_rules_effective = event_quarter_start <= rules_effective_485x & event_quarter_end >= rules_effective_485x,
    clean_pre_421a_expiration_quarter = event_quarter_end <= deadline_421a,
    clean_transition_quarter = event_quarter_start >= transition_start & event_quarter_end < adoption_485x,
    clean_post_485x_adoption_quarter = event_quarter_start >= as.Date("2024-07-01"),
    clean_post_485x_rules_effective_quarter = event_quarter_start >= as.Date("2025-04-01"),
    quarter_policy_period = case_when(
      clean_pre_421a_expiration_quarter ~ "pre_421a_expiration",
      clean_transition_quarter ~ "transition_421a_expired_pre_485x",
      clean_post_485x_adoption_quarter ~ "post_485x_adoption",
      TRUE ~ "mixed_policy_quarter"
    ),
    event_price_alloc_equal_bbl = event_price / recovered_incidence_bbl_count,
    event_price_alloc_allowed_res_area = if_else(
      event_allowed_policy_res_sqft > 0,
      event_price * allowed_policy_res_sqft / event_allowed_policy_res_sqft,
      NA_real_
    ),
    event_price_per_event_allowed_res_sqft = if_else(
      event_allowed_policy_res_sqft > 0,
      event_price / event_allowed_policy_res_sqft,
      NA_real_
    ),
    event_price_is_document_level = TRUE
  ) |>
  arrange(event_date, event_id, bbl)

if (nrow(incidence) != sum(recovered_sale_events$primary_opportunity_bbl_count)) {
  stop("Incidence row count does not equal sum of recovered event primary opportunity BBL counts.")
}

if (anyDuplicated(paste(incidence$event_id, incidence$bbl, sep = "::")) > 0) {
  stop("Recovered event incidence is not unique by event_id/BBL.")
}

if (sum(is.na(incidence$borough)) > 0) {
  stop("At least one recovered event BBL did not match frozen opportunity lots.")
}

write_parquet_if_changed(incidence, "../output/acris_recovered_sale_lot_quarter_incidence.parquet")
cat("Built ACRIS recovered sale lot-quarter incidence to ../output\n")

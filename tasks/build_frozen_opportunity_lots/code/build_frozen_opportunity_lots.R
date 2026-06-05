# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_frozen_opportunity_lots/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

policy_freeze_date <- as.Date("2022-06-15")
primary_gross_sqft_per_unit <- 850
opportunity_unit_threshold <- 50L
notch_unit_threshold <- 100L

release_calendar <- read_csv("../input/mappluto_release_calendar.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    release_order = suppressWarnings(as.integer(release_order)),
    safe_available_date = as.Date(safe_available_date),
    usable_for_training = str_to_upper(as.character(usable_for_training)) == "TRUE"
  ) |>
  filter(usable_for_training, safe_available_date < policy_freeze_date) |>
  arrange(release_order)

if (nrow(release_calendar) == 0) {
  stop("No usable MapPLUTO release is safely available before ", policy_freeze_date, ".")
}

selected_release <- release_calendar[nrow(release_calendar), ]

mappluto_lot_files <- read_csv("../input/mappluto_lot_files.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    source_id = as.character(source_id),
    vintage = as.character(vintage),
    parquet_path = as.character(parquet_path)
  ) |>
  filter(source_id == selected_release$source_id, vintage == selected_release$vintage)

if (nrow(mappluto_lot_files) != 1L) {
  stop("Expected one staged MapPLUTO lot file for the selected frozen release.")
}

mappluto_lots <- read_parquet(mappluto_lot_files$parquet_path[1]) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    bbl = normalize_bbl_field(bbl),
    borough = standardize_borough_code(borough),
    block = suppressWarnings(as.integer(block)),
    lot = suppressWarnings(as.integer(lot)),
    landuse_code = str_pad(str_squish(as.character(landuse)), 2L, pad = "0"),
    landuse_code = if_else(is.na(landuse_code) | landuse_code %in% c("", "NA"), NA_character_, landuse_code),
    bldgclass = str_to_upper(str_squish(as.character(bldgclass))),
    bldgclass = if_else(is.na(bldgclass) | bldgclass == "", NA_character_, bldgclass),
    bldgclass_family = str_sub(bldgclass, 1L, 1L),
    zonedist1_clean = str_to_upper(str_squish(as.character(zonedist1))),
    zone_base = str_extract(zonedist1_clean, "^[RCM][0-9]+"),
    zone_base = if_else(is.na(zone_base) | zone_base == "", "missing", zone_base),
    zone_detail = case_when(
      str_detect(zonedist1_clean, "/") ~ "MX_slash",
      zone_base %in% c("R1", "R2", "R3", "R4", "R5") ~ "R1_R5",
      zone_base == "R6" ~ "R6",
      zone_base == "R7" ~ "R7",
      zone_base %in% c("R8", "R9", "R10") ~ "R8_R10",
      str_detect(zonedist1_clean, "^C") ~ "C",
      str_detect(zonedist1_clean, "^M") ~ "M_non_slash",
      TRUE ~ "Other"
    ),
    valid_bbl = str_detect(bbl, "^[1-5][0-9]{9}$"),
    positive_lotarea = !is.na(lotarea) & lotarea > 0,
    nonnegative_residfar = !is.na(residfar) & residfar >= 0,
    positive_residfar = !is.na(residfar) & residfar > 0,
    allowed_standard_res_sqft = if_else(positive_lotarea & nonnegative_residfar, lotarea * residfar, NA_real_),
    allowed_policy_res_sqft = allowed_standard_res_sqft,
    allowed_policy_res_sqft_source = "lotarea_times_residfar",
    positive_allowed_policy_res_sqft = !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0,
    residual_policy_res_sqft = if_else(
      !is.na(allowed_policy_res_sqft) & !is.na(resarea) & resarea >= 0,
      pmax(allowed_policy_res_sqft - resarea, 0),
      NA_real_
    ),
    residual_policy_bldgarea_sqft = if_else(
      !is.na(allowed_policy_res_sqft) & !is.na(bldgarea) & bldgarea >= 0,
      pmax(allowed_policy_res_sqft - bldgarea, 0),
      NA_real_
    ),
    allowed_policy_far = residfar,
    builtfar_ratio = if_else(!is.na(builtfar) & !is.na(allowed_policy_far) & allowed_policy_far > 0, builtfar / allowed_policy_far, NA_real_),
    capacity_units_650 = allowed_policy_res_sqft / 650,
    capacity_units_750 = allowed_policy_res_sqft / 750,
    capacity_units_850 = allowed_policy_res_sqft / 850,
    capacity_units_1000 = allowed_policy_res_sqft / 1000,
    capacity50_650 = !is.na(capacity_units_650) & capacity_units_650 >= opportunity_unit_threshold,
    capacity50_750 = !is.na(capacity_units_750) & capacity_units_750 >= opportunity_unit_threshold,
    capacity50_850 = !is.na(capacity_units_850) & capacity_units_850 >= opportunity_unit_threshold,
    capacity50_1000 = !is.na(capacity_units_1000) & capacity_units_1000 >= opportunity_unit_threshold,
    capacity100_650 = !is.na(capacity_units_650) & capacity_units_650 >= notch_unit_threshold,
    capacity100_750 = !is.na(capacity_units_750) & capacity_units_750 >= notch_unit_threshold,
    capacity100_850 = !is.na(capacity_units_850) & capacity_units_850 >= notch_unit_threshold,
    capacity100_1000 = !is.na(capacity_units_1000) & capacity_units_1000 >= notch_unit_threshold,
    vacant_landuse = landuse_code %in% c("11"),
    parking_landuse = landuse_code %in% c("10"),
    public_transport_utility_open_space_landuse = landuse_code %in% c("07", "08", "09"),
    vacant_bldgclass = bldgclass_family %in% c("V"),
    condo_or_billing_lot = (!is.na(lot) & lot >= 7500L) | bldgclass_family %in% c("R"),
    underbuilt_half_allowed_far = !is.na(builtfar_ratio) & builtfar_ratio <= 0.5,
    primary_hard_exclusion = !valid_bbl |
      !positive_lotarea |
      !positive_allowed_policy_res_sqft |
      condo_or_billing_lot |
      public_transport_utility_open_space_landuse,
    primary_opp50_850 = !primary_hard_exclusion & capacity50_850,
    soft_site_opp50_850 = primary_opp50_850 & (
      vacant_landuse |
        parking_landuse |
        vacant_bldgclass |
        underbuilt_half_allowed_far |
        (!is.na(residual_policy_bldgarea_sqft) & residual_policy_bldgarea_sqft >= opportunity_unit_threshold * primary_gross_sqft_per_unit)
    ),
    frozen_source_id = selected_release$source_id,
    frozen_vintage = selected_release$vintage,
    frozen_release_order = selected_release$release_order,
    frozen_safe_available_date = selected_release$safe_available_date,
    freeze_rule = "latest_usable_release_before_2022_06_15",
    primary_opportunity_rule = "allowed_policy_res_sqft_ge_50_times_850_exact_tax_lot"
  )

duplicate_bbls <- mappluto_lots |>
  filter(!is.na(bbl)) |>
  count(bbl, name = "rows") |>
  filter(rows > 1)

if (nrow(duplicate_bbls) > 0) {
  stop("Frozen MapPLUTO lot file is not unique by BBL.")
}

capacity_ranks <- mappluto_lots |>
  filter(primary_opp50_850, !is.na(allowed_policy_res_sqft)) |>
  arrange(allowed_policy_res_sqft, bbl) |>
  transmute(
    bbl,
    capacity_exposure_pctile_citywide = percent_rank(allowed_policy_res_sqft),
    capacity_exposure_quartile_citywide = ntile(allowed_policy_res_sqft, 4L)
  )

borough_capacity_ranks <- mappluto_lots |>
  filter(primary_opp50_850, !is.na(allowed_policy_res_sqft)) |>
  group_by(borough) |>
  arrange(allowed_policy_res_sqft, bbl, .by_group = TRUE) |>
  mutate(
    capacity_exposure_pctile_borough = percent_rank(allowed_policy_res_sqft),
    capacity_exposure_quartile_borough = ntile(allowed_policy_res_sqft, 4L)
  ) |>
  ungroup() |>
  select(bbl, capacity_exposure_pctile_borough, capacity_exposure_quartile_borough)

mappluto_lots <- mappluto_lots |>
  left_join(capacity_ranks, by = "bbl", relationship = "one-to-one") |>
  left_join(borough_capacity_ranks, by = "bbl", relationship = "one-to-one") |>
  select(
    frozen_source_id, frozen_vintage, frozen_release_order, frozen_safe_available_date,
    freeze_rule, primary_opportunity_rule,
    bbl, valid_bbl, borough, block, lot, address, cd, zipcode, council,
    zonedist1, zonedist2, zonedist3, zonedist4, zone_base, zone_detail,
    overlay1, overlay2, spdist1, spdist2, spdist3, ltdheight, splitzone,
    landuse, landuse_code, bldgclass, bldgclass_family,
    lotarea, bldgarea, resarea, comarea, unitsres, unitstotal, numbldgs,
    numfloors, yearbuilt, builtfar, residfar, commfar, facilfar,
    assessland, assesstot, histdist, landmark,
    allowed_standard_res_sqft, allowed_policy_res_sqft, allowed_policy_res_sqft_source,
    residual_policy_res_sqft, residual_policy_bldgarea_sqft, allowed_policy_far,
    builtfar_ratio, starts_with("capacity_units_"), starts_with("capacity50_"),
    starts_with("capacity100_"), capacity_exposure_pctile_citywide,
    capacity_exposure_quartile_citywide, capacity_exposure_pctile_borough,
    capacity_exposure_quartile_borough,
    positive_lotarea, positive_residfar, positive_allowed_policy_res_sqft,
    vacant_landuse, parking_landuse, public_transport_utility_open_space_landuse,
    vacant_bldgclass, condo_or_billing_lot, underbuilt_half_allowed_far,
    primary_hard_exclusion, primary_opp50_850, soft_site_opp50_850,
    everything()
  )

write_parquet_if_changed(mappluto_lots, "../output/mappluto_opportunity_lots_frozen.parquet")
cat("Wrote frozen opportunity lots to ../output\n")

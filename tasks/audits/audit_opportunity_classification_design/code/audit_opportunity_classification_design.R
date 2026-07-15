# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_opportunity_classification_design/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

policy_deadline <- as.Date("2022-06-15")
main_start_date <- as.Date("2016-01-01")
gross_sqft_per_unit_values <- c(650, 750, 850, 1000)
classification_thresholds <- c(50, 100)
score_group_counts <- c(3, 4)
main_score_window <- "pre_2021_to_2021_2022h1"
main_score_split <- "test_2021_2022h1"
main_score_model <- "ridge_logit_enriched"

safe_ratio <- function(numerator, denominator) {
  ifelse(is.na(denominator) | denominator == 0, NA_real_, numerator / denominator)
}

write_markdown_if_changed <- function(lines, out_path) {
  temp_path <- tempfile(fileext = ".md")
  writeLines(lines, temp_path, useBytes = TRUE)
  copy_if_changed(temp_path, out_path)
}

capacity_bin_label <- function(capacity_units) {
  case_when(
    is.na(capacity_units) ~ "missing_capacity",
    capacity_units < 50 ~ "under_50",
    capacity_units < 70 ~ "50_69",
    capacity_units < 100 ~ "70_99",
    capacity_units < 150 ~ "100_149",
    TRUE ~ "150_plus"
  )
}

actual_unit_bin_label <- function(classa_prop) {
  case_when(
    is.na(classa_prop) ~ "missing_units",
    classa_prop < 50 ~ "under_50",
    classa_prop < 70 ~ "50_69",
    classa_prop < 100 ~ "70_99",
    classa_prop < 150 ~ "100_149",
    TRUE ~ "150_plus"
  )
}

hdb_panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

frozen_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

score_rows <- read_csv("../input/candidate_prediction_scores.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    date_filed = as.Date(date_filed),
    candidate_min_classa_prop = as.integer(candidate_min_classa_prop),
    classa_prop = as.numeric(classa_prop),
    y100_num = as.integer(y100_num),
    score_value = as.numeric(score_value)
  )

hdb_rows <- hdb_panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    !is.na(classa_prop),
    !is.na(allowed_res_area),
    allowed_res_area > 0,
    !is.na(date_filed),
    date_filed <= policy_deadline
  ) |>
  mutate(
    sample_window = if_else(date_filed >= main_start_date, "main_2016_to_2022_06_15", "legacy_2010_to_2015"),
    sample_window_all = "all_2010_to_2022_06_15",
    y50 = classa_prop >= 50,
    y100 = classa_prop >= 100,
    actual_unit_bin = actual_unit_bin_label(classa_prop),
    capacity_units_650 = allowed_res_area / 650,
    capacity_units_750 = allowed_res_area / 750,
    capacity_units_850 = allowed_res_area / 850,
    capacity_units_1000 = allowed_res_area / 1000
  )

if (nrow(hdb_rows) == 0) {
  stop("No HDB rows available for opportunity classification audit.")
}

score_detail_keys <- hdb_panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    !is.na(classa_prop),
    !is.na(date_filed)
  ) |>
  mutate(
    y50 = classa_prop >= 50,
    y100 = classa_prop >= 100,
    actual_unit_bin = actual_unit_bin_label(classa_prop),
    capacity_units_650 = allowed_res_area / 650,
    capacity_units_750 = allowed_res_area / 750,
    capacity_units_850 = allowed_res_area / 850,
    capacity_units_1000 = allowed_res_area / 1000
  ) |>
  select(
    job_number, date_filed, classa_prop,
    bbl, pluto_feature_bbl, hdb_borough_name, address,
    zonedist1, landuse, bldgclass,
    lotarea, residfar, builtfar, allowed_res_area,
    capacity_units_650, capacity_units_750, capacity_units_850, capacity_units_1000,
    actual_unit_bin, y50, y100
  ) |>
  distinct()

hdb_detail_duplicates <- score_detail_keys |>
  count(job_number, date_filed, classa_prop, name = "rows") |>
  filter(rows > 1L)

if (nrow(hdb_detail_duplicates) > 0) {
  stop("HDB detail rows are not unique by job number/date/classa_prop.")
}

capacity_rule_summary <- tibble(
  rule_component = c(
    "allowed_residential_square_feet",
    "gross_sqft_per_unit_main",
    "capacity_units_main",
    "capacity_50_cutoff_sqft",
    "capacity_100_cutoff_sqft",
    "main_scope",
    "interpretation",
    "not_interpretation"
  ),
  value = c(
    "lotarea times residfar",
    "850",
    "allowed_residential_square_feet divided by 850",
    as.character(50 * 850),
    as.character(100 * 850),
    "audit-only rule under review before production exposure construction",
    "mechanical frozen lot capacity screen",
    "not predicted units and not probability of redevelopment"
  ),
  decision_type = c(
    "mechanical",
    "substantive",
    "substantive",
    "substantive",
    "substantive",
    "scope",
    "interpretation",
    "interpretation"
  )
)

write_csv_if_changed(capacity_rule_summary, "../output/capacity_rule_summary.csv")

frozen_counts <- bind_rows(lapply(c("all_boroughs", "non_staten_island"), function(analysis_universe) {
  universe_lots <- frozen_lots
  if (analysis_universe == "non_staten_island") {
    universe_lots <- universe_lots |> filter(borough != "5")
  }

  bind_rows(lapply(gross_sqft_per_unit_values, function(gross_sqft_per_unit) {
    universe_lots |>
      mutate(
        capacity50_flag = !primary_hard_exclusion & !is.na(allowed_policy_res_sqft) &
          allowed_policy_res_sqft >= 50 * gross_sqft_per_unit,
        capacity100_flag = !primary_hard_exclusion & !is.na(allowed_policy_res_sqft) &
          allowed_policy_res_sqft >= 100 * gross_sqft_per_unit
      ) |>
      group_by(borough) |>
      summarise(
        analysis_universe = analysis_universe,
        gross_sqft_per_unit = gross_sqft_per_unit,
        lots = n(),
        primary_hard_exclusion_lots = sum(primary_hard_exclusion),
        capacity50_lots = sum(capacity50_flag),
        capacity100_lots = sum(capacity100_flag),
        soft_site_opp50_850_lots = sum(soft_site_opp50_850),
        median_allowed_policy_res_sqft_capacity50 = median(allowed_policy_res_sqft[capacity50_flag], na.rm = TRUE),
        .groups = "drop"
      )
  }))
}))

write_csv_if_changed(frozen_counts, "../output/frozen_opportunity_capacity_counts.csv")

hdb_windows <- bind_rows(
  hdb_rows |> mutate(audit_window = sample_window),
  hdb_rows |> mutate(audit_window = sample_window_all)
)

capacity_confusion <- bind_rows(lapply(gross_sqft_per_unit_values, function(gross_sqft_per_unit) {
  bind_rows(lapply(classification_thresholds, function(unit_threshold) {
    capacity_column <- paste0("capacity_units_", gross_sqft_per_unit)
    hdb_windows |>
      mutate(
        actual_positive = classa_prop >= unit_threshold,
        predicted_positive = .data[[capacity_column]] >= unit_threshold
      ) |>
      group_by(audit_window) |>
      summarise(
        gross_sqft_per_unit = gross_sqft_per_unit,
        unit_threshold = unit_threshold,
        rows = n(),
        actual_positive_rows = sum(actual_positive),
        predicted_positive_rows = sum(predicted_positive, na.rm = TRUE),
        true_positive_rows = sum(actual_positive & predicted_positive, na.rm = TRUE),
        false_positive_rows = sum(!actual_positive & predicted_positive, na.rm = TRUE),
        false_negative_rows = sum(actual_positive & !predicted_positive, na.rm = TRUE),
        true_negative_rows = sum(!actual_positive & !predicted_positive, na.rm = TRUE),
        recall = safe_ratio(true_positive_rows, actual_positive_rows),
        precision = safe_ratio(true_positive_rows, predicted_positive_rows),
        specificity = safe_ratio(true_negative_rows, rows - actual_positive_rows),
        false_negative_share_of_actual_positive = safe_ratio(false_negative_rows, actual_positive_rows),
        false_positive_share_of_actual_negative = safe_ratio(false_positive_rows, rows - actual_positive_rows),
        .groups = "drop"
      )
  }))
}))

write_csv_if_changed(capacity_confusion, "../output/hdb_capacity_threshold_confusion.csv")

capacity_bin_outcomes <- bind_rows(lapply(gross_sqft_per_unit_values, function(gross_sqft_per_unit) {
  capacity_column <- paste0("capacity_units_", gross_sqft_per_unit)
  hdb_windows |>
    mutate(capacity_unit_bin = capacity_bin_label(.data[[capacity_column]])) |>
    group_by(audit_window, capacity_unit_bin, actual_unit_bin) |>
    summarise(
      gross_sqft_per_unit = gross_sqft_per_unit,
      rows = n(),
      y50_rows = sum(y50),
      y100_rows = sum(y100),
      mean_classa_prop = mean(classa_prop),
      median_classa_prop = median(classa_prop),
      .groups = "drop"
    )
}))

write_csv_if_changed(capacity_bin_outcomes, "../output/hdb_capacity_bin_outcomes.csv")

capacity_tier_performance <- bind_rows(lapply(gross_sqft_per_unit_values, function(gross_sqft_per_unit) {
  capacity_column <- paste0("capacity_units_", gross_sqft_per_unit)
  bind_rows(lapply(score_group_counts, function(group_count) {
    hdb_windows |>
      filter(classa_prop >= 50) |>
      group_by(audit_window) |>
      mutate(
        score_tier = ntile(.data[[capacity_column]], group_count),
        total_y100_rows = sum(y100)
      ) |>
      group_by(audit_window, score_tier) |>
      summarise(
        score_source = paste0("capacity_units_", gross_sqft_per_unit),
        group_count = group_count,
        rows = n(),
        y100_rows = sum(y100),
        y100_share = mean(y100),
        capture_share = safe_ratio(y100_rows, first(total_y100_rows)),
        mean_classa_prop = mean(classa_prop),
        median_classa_prop = median(classa_prop),
        mean_capacity_units = mean(.data[[capacity_column]], na.rm = TRUE),
        .groups = "drop"
      )
  }))
}))

write_csv_if_changed(capacity_tier_performance, "../output/hdb_capacity_tier_performance.csv")

score_detail_rows <- score_rows |>
  filter(candidate_min_classa_prop == 50) |>
  left_join(
    score_detail_keys,
    by = c("job_number", "date_filed", "classa_prop"),
    relationship = "many-to-one"
  )

if (any(is.na(score_detail_rows$bbl))) {
  stop("Some candidate prediction score rows did not join back to HDB details.")
}

score_tier_performance <- bind_rows(lapply(score_group_counts, function(group_count) {
  score_detail_rows |>
    group_by(window, model, feature_layer, split, split_role, score_kind) |>
    mutate(
      score_tier = ntile(score_value, group_count),
      total_y100_rows = sum(y100_num)
    ) |>
    group_by(window, model, feature_layer, split, split_role, score_kind, score_tier) |>
    summarise(
      group_count = group_count,
      rows = n(),
      y100_rows = sum(y100_num),
      y100_share = mean(y100_num),
      capture_share = safe_ratio(y100_rows, first(total_y100_rows)),
      mean_score = mean(score_value),
      min_score = min(score_value),
      max_score = max(score_value),
      mean_classa_prop = mean(classa_prop),
      median_classa_prop = median(classa_prop),
      share_exactly_99 = mean(classa_prop == 99),
      mean_capacity_units_850 = mean(capacity_units_850, na.rm = TRUE),
      .groups = "drop"
    )
}))

write_csv_if_changed(score_tier_performance, "../output/hdb_score_tier_performance.csv")

score_tier_contrast <- score_tier_performance |>
  filter(split_role == "test") |>
  group_by(window, model, feature_layer, split, score_kind, group_count) |>
  summarise(
    bottom_tier_y100_share = y100_share[score_tier == 1][1],
    top_tier_y100_share = y100_share[score_tier == group_count][1],
    bottom_tier_rows = rows[score_tier == 1][1],
    top_tier_rows = rows[score_tier == group_count][1],
    bottom_tier_y100_rows = y100_rows[score_tier == 1][1],
    top_tier_y100_rows = y100_rows[score_tier == group_count][1],
    top_tier_capture_share = capture_share[score_tier == group_count][1],
    top_minus_bottom_y100_share = top_tier_y100_share - bottom_tier_y100_share,
    top_over_bottom_y100_share = safe_ratio(top_tier_y100_share, bottom_tier_y100_share),
    rows = sum(rows),
    .groups = "drop"
  ) |>
  arrange(group_count, window, model)

write_csv_if_changed(score_tier_contrast, "../output/hdb_score_tier_contrast.csv")

main_score_details <- score_detail_rows |>
  filter(
    window == main_score_window,
    split == main_score_split,
    model == main_score_model,
    split_role == "test"
  ) |>
  mutate(
    score_quartile = ntile(score_value, 4L),
    score_tercile = ntile(score_value, 3L),
    example_category = case_when(
      score_quartile == 4L & y100_num == 1L ~ "top_quartile_y100",
      score_quartile == 4L & y100_num == 0L ~ "top_quartile_below_100",
      score_quartile == 1L & y100_num == 1L ~ "bottom_quartile_y100",
      score_quartile == 1L & y100_num == 0L ~ "bottom_quartile_below_100",
      score_tercile == 3L & classa_prop >= 90 & classa_prop < 100 ~ "top_tercile_90_99",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(example_category)) |>
  group_by(example_category) |>
  arrange(desc(score_value), desc(classa_prop), job_number, .by_group = TRUE) |>
  slice_head(n = 10L) |>
  ungroup() |>
  select(
    example_category, job_number, date_filed, classa_prop, y100_num,
    score_value, score_quartile, score_tercile,
    bbl, pluto_feature_bbl, hdb_borough_name, address, zonedist1,
    landuse, bldgclass, lotarea, residfar, builtfar, allowed_res_area,
    capacity_units_750, capacity_units_850, capacity_units_1000
  )

write_csv_if_changed(main_score_details, "../output/hdb_score_tier_examples.csv")

capacity_examples <- hdb_rows |>
  filter(sample_window == "main_2016_to_2022_06_15") |>
  mutate(
    capacity100_850 = capacity_units_850 >= 100,
    capacity50_850 = capacity_units_850 >= 50,
    example_category = case_when(
      y100 & capacity100_850 ~ "threshold100_true_positive",
      !y100 & capacity100_850 ~ "threshold100_false_positive",
      y100 & !capacity100_850 ~ "threshold100_false_negative",
      y50 & capacity50_850 ~ "threshold50_true_positive",
      !y50 & capacity50_850 ~ "threshold50_false_positive",
      y50 & !capacity50_850 ~ "threshold50_false_negative",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(example_category)) |>
  group_by(example_category) |>
  arrange(desc(classa_prop), desc(capacity_units_850), job_number, .by_group = TRUE) |>
  slice_head(n = 10L) |>
  ungroup() |>
  select(
    example_category, job_number, date_filed, classa_prop, y50, y100,
    bbl, pluto_feature_bbl, hdb_borough_name, address, zonedist1,
    landuse, bldgclass, lotarea, residfar, builtfar, allowed_res_area,
    capacity_units_650, capacity_units_750, capacity_units_850, capacity_units_1000
  )

write_csv_if_changed(capacity_examples, "../output/hdb_capacity_classification_examples.csv")

write_markdown_if_changed(
  c(
    "# Research Understanding Checklist",
    "",
    "## Session Goal",
    "- [x] Research question or task: audit whether mechanical capacity and existing prediction-score tiers can classify large HDB projects before production exposure construction.",
    "- [x] Why this matters: the land-sales design should not depend on an unvalidated opportunity definition or a model score that is misread as unconditional redevelopment probability.",
    "- [x] What changed in this session: added audit-only diagnostics; production opportunity lots and sales panels were not changed.",
    "",
    "## Stage 1: Problem And Motivation",
    "- [x] What problem existed? We need to know whether 50+/100+ opportunity classifications are meaningful before using them downstream.",
    "- [x] Why would a naive approach fail? A capacity screen is only physical/zoning feasibility, and a y100 score is conditional on observed large HDB filings.",
    "- [ ] Mastery status: needs researcher review of audit tables.",
    "",
    "## Stage 2: Data Provenance And Raw Inputs",
    "- [x] HDB supplies observed proposed Class A units for New Building filings.",
    "- [x] Lagged MapPLUTO supplies lot/zoning characteristics for HDB filings.",
    "- [x] Frozen MapPLUTO supplies the pre-policy lot universe.",
    "- [x] Candidate prediction scores come from an audit-only model task.",
    "",
    "## Stage 3: Classification Logic",
    "- [x] The 850 sqft/unit rule converts allowed residential square feet to implied capacity units.",
    "- [x] The rule is substantive and tested against 650, 750, and 1000 sqft/unit alternatives.",
    "- [x] Score terciles/quartiles are ranking diagnostics among observed 50+ HDB candidate projects.",
    "- [ ] Researcher should decide whether top/bottom terciles or quartiles are easier to defend.",
    "",
    "## Stage 4: Interpretation",
    "- [x] Capacity is not predicted units.",
    "- [x] Prediction score is not unconditional redevelopment probability.",
    "- [x] Top score bins can be used only if calibration and false-positive/false-negative examples look credible.",
    "",
    "## Open Questions",
    "- [ ] Is 850 sqft/unit acceptable as the main bridge after reviewing sensitivity?",
    "- [ ] Are quartiles or terciles better for the eventual exposure grouping?",
    "- [ ] Does the ridge logit score add enough beyond mechanical capacity to justify using it downstream?",
    "- [ ] Should borough-standardized score ranks be added before production scoring?"
  ),
  "../output/research_understanding_checklist.md"
)

cat("Wrote opportunity classification design audit outputs to ../output\n")

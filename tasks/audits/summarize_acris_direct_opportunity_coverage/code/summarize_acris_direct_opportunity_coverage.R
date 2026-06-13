# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_acris_direct_opportunity_coverage/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850, valid_bbl, borough != "5")

direct_legals <- read_parquet("../input/acris_direct_opportunity_legals.parquet") |>
  as.data.frame() |>
  as_tibble()

direct_deed_bbls <- read_parquet("../input/acris_direct_opportunity_deed_bbls.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    document_year = year(document_date),
    document_quarter = floor_date(document_date, "quarter"),
    positive_document_amt = !is.na(document_amt) & document_amt > 0,
    in_sales_window = !is.na(document_date) & document_date >= as.Date("2010-01-01") & document_date <= as.Date("2025-12-31")
  )

exact_sales <- read_parquet("../input/opportunity_sales_exact_bbl.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(primary_opp50_850, sale_borough_code != "5")

direct_document_bbls <- direct_legals |>
  filter(valid_legal_bbl, direct_opportunity_bbl_match) |>
  distinct(document_id, legal_borough, legal_bbl)

direct_deed_documents <- direct_deed_bbls |>
  distinct(document_id, legal_borough, legal_bbl, doc_type, document_date, document_year,
           document_quarter, document_amt, percent_trans, positive_document_amt,
           in_sales_window, deed_percent_trans_100)

coverage_by_borough <- lots |>
  count(borough, name = "primary_bbls") |>
  left_join(
    direct_document_bbls |>
      group_by(legal_borough) |>
      summarise(
        primary_bbls_with_any_direct_legal = n_distinct(legal_bbl),
        direct_document_bbl_pairs = n(),
        direct_documents = n_distinct(document_id),
        .groups = "drop"
      ),
    by = c("borough" = "legal_borough")
  ) |>
  left_join(
    direct_deed_documents |>
      group_by(legal_borough) |>
      summarise(
        direct_deed_documents = n_distinct(document_id),
        direct_deed_positive_amt_2010_2025 = n_distinct(document_id[positive_document_amt %in% TRUE & in_sales_window %in% TRUE]),
        direct_deed_percent_trans_100_documents = n_distinct(document_id[deed_percent_trans_100 %in% TRUE]),
        direct_deed_bbl_pairs = n(),
        .groups = "drop"
      ),
    by = c("borough" = "legal_borough")
  ) |>
  left_join(
    exact_sales |>
      group_by(sale_borough_code) |>
      summarise(
        exact_dof_primary_rows = n(),
        exact_dof_primary_bbls = n_distinct(sale_bbl),
        exact_dof_primary_bbl_quarters = n_distinct(paste(sale_bbl, sale_quarter, sep = "::")),
        .groups = "drop"
      ),
    by = c("borough" = "sale_borough_code")
  ) |>
  mutate(
    across(where(is.numeric), ~replace_na(.x, 0)),
    direct_legal_bbl_share = round(primary_bbls_with_any_direct_legal / primary_bbls, 4),
    direct_deed_positive_doc_per_primary_bbl = round(direct_deed_positive_amt_2010_2025 / primary_bbls, 4),
    exact_dof_bbl_quarter_per_primary_bbl = round(exact_dof_primary_bbl_quarters / primary_bbls, 4)
  ) |>
  arrange(borough)

document_types <- direct_deed_documents |>
  mutate(
    doc_type = coalesce(doc_type, "missing_doc_type"),
    document_year_group = case_when(
      is.na(document_year) ~ "missing_date",
      document_year < 2010 ~ "pre_2010",
      document_year <= 2025 ~ "2010_2025",
      TRUE ~ "post_2025"
    )
  ) |>
  count(legal_borough, doc_type, document_year_group, positive_document_amt, deed_percent_trans_100, name = "direct_deed_documents") |>
  arrange(legal_borough, desc(direct_deed_documents), doc_type, document_year_group)

legal_flags <- direct_legals |>
  mutate(
    has_unit = !is.na(unit) & unit != "" & unit != "(-)",
    partial_lot_flag = !is.na(partial_lot) & partial_lot != "" & partial_lot != "E",
    easement_flag = !is.na(easement) & easement != "" & easement != "N",
    air_rights_flag = !is.na(air_rights) & air_rights != "" & air_rights != "N",
    subterranean_rights_flag = !is.na(subterranean_rights) & subterranean_rights != "" & subterranean_rights != "N",
    property_type = coalesce(property_type, "missing")
  ) |>
  group_by(legal_borough, property_type) |>
  summarise(
    legal_rows = n(),
    documents = n_distinct(document_id),
    bbls = n_distinct(legal_bbl),
    rows_with_unit = sum(has_unit),
    rows_partial_lot = sum(partial_lot_flag),
    rows_easement = sum(easement_flag),
    rows_air_rights = sum(air_rights_flag),
    rows_subterranean_rights = sum(subterranean_rights_flag),
    .groups = "drop"
  ) |>
  arrange(legal_borough, desc(legal_rows), property_type)

acris_bbl_quarters <- direct_deed_documents |>
  filter(positive_document_amt, in_sales_window, !is.na(document_quarter)) |>
  distinct(legal_borough, legal_bbl, document_quarter, document_year)

dof_bbl_quarters <- exact_sales |>
  filter(positive_sale_price) |>
  distinct(sale_borough_code, sale_bbl, sale_quarter_start, sale_year)

dof_overlap_by_year <- acris_bbl_quarters |>
  left_join(
    dof_bbl_quarters |>
      mutate(dof_exact_same_bbl_quarter = TRUE),
    by = c(
      "legal_borough" = "sale_borough_code",
      "legal_bbl" = "sale_bbl",
      "document_quarter" = "sale_quarter_start"
    ),
    relationship = "many-to-one"
  ) |>
  mutate(dof_exact_same_bbl_quarter = coalesce(dof_exact_same_bbl_quarter, FALSE)) |>
  group_by(legal_borough, document_year) |>
  summarise(
    direct_acris_deed_positive_bbl_quarters = n_distinct(paste(legal_bbl, document_quarter, sep = "::")),
    direct_acris_deed_positive_bbl_quarters_with_exact_dof = n_distinct(paste(legal_bbl[dof_exact_same_bbl_quarter], document_quarter[dof_exact_same_bbl_quarter], sep = "::")),
    .groups = "drop"
  ) |>
  full_join(
    dof_bbl_quarters |>
      group_by(sale_borough_code, sale_year) |>
      summarise(exact_dof_positive_bbl_quarters = n_distinct(paste(sale_bbl, sale_quarter_start, sep = "::")), .groups = "drop"),
    by = c("legal_borough" = "sale_borough_code", "document_year" = "sale_year")
  ) |>
  mutate(
    across(where(is.numeric), ~replace_na(.x, 0)),
    acris_share_with_exact_dof = if_else(
      direct_acris_deed_positive_bbl_quarters > 0,
      round(direct_acris_deed_positive_bbl_quarters_with_exact_dof / direct_acris_deed_positive_bbl_quarters, 4),
      NA_real_
    )
  ) |>
  arrange(legal_borough, document_year)

non_deed_document_counts <- direct_document_bbls |>
  anti_join(direct_deed_documents |> distinct(document_id), by = "document_id") |>
  group_by(legal_borough) |>
  summarise(
    direct_non_deed_or_out_of_window_documents = n_distinct(document_id),
    direct_non_deed_or_out_of_window_bbls = n_distinct(legal_bbl),
    .groups = "drop"
  ) |>
  arrange(legal_borough)

exact_dof_building_class_mix <- exact_sales |>
  filter(positive_sale_price) |>
  mutate(
    building_class_category = coalesce(building_class_category, "missing_building_class_category"),
    diagnostic_unit_churn_class = str_detect(
      building_class_category,
      regex("CONDO|COOP|ONE FAMILY|TWO FAMILY|THREE FAMILY|HOMES|DWELLINGS", ignore_case = TRUE)
    ),
    diagnostic_small_record_units = !is.na(sale_total_units) & sale_total_units <= 3
  ) |>
  group_by(sale_borough_code, building_class_category) |>
  summarise(
    exact_dof_positive_rows = n(),
    exact_dof_bbls = n_distinct(sale_bbl),
    exact_dof_bbl_quarters = n_distinct(paste(sale_bbl, sale_quarter, sep = "::")),
    diagnostic_unit_churn_class = first(diagnostic_unit_churn_class),
    diagnostic_small_record_units_share = round(mean(diagnostic_small_record_units, na.rm = TRUE), 4),
    .groups = "drop"
  ) |>
  arrange(sale_borough_code, desc(exact_dof_positive_rows), building_class_category)

positive_deed_property_types <- direct_deed_bbls |>
  filter(deed_positive_document_amt, deed_sales_window_2010_2025) |>
  mutate(direct_legal_property_types = coalesce(direct_legal_property_types, "missing_property_type")) |>
  group_by(legal_borough, direct_legal_property_types) |>
  summarise(
    positive_deed_bbl_pairs = n(),
    positive_deed_documents = n_distinct(document_id),
    positive_deed_bbls = n_distinct(legal_bbl),
    positive_deed_with_unit_legal_row = sum(has_unit_legal_row),
    positive_deed_with_partial_lot_flag = sum(has_partial_lot_flag),
    .groups = "drop"
  ) |>
  arrange(legal_borough, desc(positive_deed_bbl_pairs), direct_legal_property_types)

write_csv_if_changed(coverage_by_borough, "../output/acris_direct_opportunity_coverage_by_borough.csv")
write_csv_if_changed(document_types, "../output/acris_direct_opportunity_document_types.csv")
write_csv_if_changed(legal_flags, "../output/acris_direct_opportunity_legal_flags.csv")
write_csv_if_changed(dof_overlap_by_year, "../output/acris_direct_opportunity_dof_overlap_by_year.csv")
write_csv_if_changed(non_deed_document_counts, "../output/acris_direct_opportunity_non_deed_document_counts.csv")
write_csv_if_changed(exact_dof_building_class_mix, "../output/acris_direct_opportunity_exact_dof_building_class_mix.csv")
write_csv_if_changed(positive_deed_property_types, "../output/acris_direct_opportunity_positive_deed_property_types.csv")
cat("Wrote direct ACRIS opportunity coverage audit outputs to ../output\n")

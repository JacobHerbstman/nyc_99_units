# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_acris_recovery_layer/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv("../input/acris_deed_master_files.csv", show_col_types = FALSE, na = c("", "NA"))

deed_master <- read_parquet("../input/acris_deed_master.parquet") |>
  as.data.frame() |>
  as_tibble()

sale_seeds <- read_parquet("../input/acris_opportunity_sale_seeds.parquet") |>
  as.data.frame() |>
  as_tibble()

candidate_links <- read_parquet("../input/acris_dof_deed_candidate_links.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_legals <- read_parquet("../input/acris_opportunity_legals.parquet") |>
  as.data.frame() |>
  as_tibble()

recovered_sale_events <- read_parquet("../input/acris_recovered_sale_events.parquet") |>
  as.data.frame() |>
  as_tibble()

recovered_incidence <- read_parquet("../input/acris_recovered_sale_lot_quarter_incidence.parquet") |>
  as.data.frame() |>
  as_tibble()

write_csv_if_changed(
  file_manifest |>
    group_by(source_id, file_role, status) |>
    summarise(
      files = n(),
      rows = sum(row_count, na.rm = TRUE),
      first_part = suppressWarnings(min(part_number, na.rm = TRUE)),
      last_part = suppressWarnings(max(part_number, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    mutate(
      first_part = if_else(is.infinite(first_part), NA_real_, first_part),
      last_part = if_else(is.infinite(last_part), NA_real_, last_part)
    ),
  "../output/acris_deed_master_fetch_summary.csv"
)

write_csv_if_changed(
  deed_master |>
    summarise(
      documents = n(),
      duplicate_version_documents = sum(master_document_versions > 1L),
      conflicting_amount_documents = sum(master_document_conflicting_amount),
      min_document_date = min(document_date, na.rm = TRUE),
      max_document_date = max(document_date, na.rm = TRUE),
      min_good_through_date = min(good_through_date, na.rm = TRUE),
      max_good_through_date = max(good_through_date, na.rm = TRUE)
    ),
  "../output/acris_deed_master_version_summary.csv"
)

write_csv_if_changed(
  deed_master |>
    count(master_document_versions, master_document_conflicting_amount, name = "documents") |>
    arrange(master_document_versions, master_document_conflicting_amount),
  "../output/acris_deed_master_version_counts.csv"
)

candidate_seed_counts <- candidate_links |>
  group_by(sale_record_id) |>
  summarise(
    candidate_rows = n(),
    candidate_documents = n_distinct(document_id[!is.na(document_id)]),
    max_exact_key_product = max(exact_key_product, na.rm = TRUE),
    candidate_key_status = paste(sort(unique(candidate_key_status)), collapse = "|"),
    .groups = "drop"
  )

seed_coverage <- sale_seeds |>
  left_join(candidate_seed_counts, by = "sale_record_id", relationship = "one-to-one") |>
  mutate(
    has_acris_deed_candidate = !is.na(candidate_rows),
    candidate_rows = replace_na(candidate_rows, 0L),
    candidate_documents = replace_na(candidate_documents, 0L),
    max_exact_key_product = replace_na(max_exact_key_product, 0L),
    candidate_key_status = replace_na(candidate_key_status, "no_exact_deed_candidate")
  )

write_csv_if_changed(
  seed_coverage |>
    group_by(seed_match_type, candidate_key_status) |>
    summarise(
      seed_sales = n(),
      candidate_rows = sum(candidate_rows),
      candidate_documents = sum(candidate_documents),
      .groups = "drop"
    ) |>
    arrange(seed_match_type, candidate_key_status),
  "../output/acris_recovery_candidate_summary.csv"
)

write_csv_if_changed(
  seed_coverage |>
    group_by(sale_year, seed_match_type) |>
    summarise(
      seed_sales = n(),
      seeds_with_acris_deed_candidate = sum(has_acris_deed_candidate),
      candidate_seed_share = seeds_with_acris_deed_candidate / seed_sales,
      exact_key_candidate_rows = sum(candidate_rows),
      exact_key_candidate_documents = sum(candidate_documents),
      .groups = "drop"
    ) |>
    arrange(sale_year, seed_match_type),
  "../output/acris_recovery_candidate_coverage_by_year.csv"
)

write_csv_if_changed(
  candidate_links |>
    filter(!is.na(document_id)) |>
    distinct(acris_master_exact_key, seed_rows_on_exact_key, deed_rows_on_exact_key, exact_key_product, candidate_key_status) |>
    arrange(desc(exact_key_product), acris_master_exact_key) |>
    slice_head(n = 100),
  "../output/acris_recovery_top_exact_key_collisions.csv"
)

write_csv_if_changed(
  candidate_links |>
    filter(!is.na(document_id)) |>
    group_by(document_id) |>
    summarise(
      candidate_seed_sales = n_distinct(sale_record_id),
      candidate_sale_bbls = n_distinct(sale_bbl),
      seed_match_types = paste(sort(unique(seed_match_type)), collapse = "|"),
      document_date = first(document_date),
      document_amt = first(document_amt),
      .groups = "drop"
    ) |>
    count(candidate_seed_sales, seed_match_types, name = "documents") |>
    arrange(desc(candidate_seed_sales), seed_match_types),
  "../output/acris_recovery_document_candidate_multiplicity.csv"
)

write_csv_if_changed(
  opportunity_legals |>
    summarise(
      legal_rows = n(),
      documents = n_distinct(document_id),
      valid_legal_rows = sum(valid_legal_bbl),
      valid_legal_documents = n_distinct(document_id[valid_legal_bbl]),
      legal_bbls = n_distinct(legal_bbl[valid_legal_bbl]),
      min_good_through_date = min(good_through_date, na.rm = TRUE),
      max_good_through_date = max(good_through_date, na.rm = TRUE)
    ),
  "../output/acris_opportunity_legals_summary.csv"
)

write_csv_if_changed(
  recovered_sale_events |>
    summarise(
      events = n(),
      documents = n_distinct(document_id),
      min_event_date = min(event_date, na.rm = TRUE),
      max_event_date = max(event_date, na.rm = TRUE),
      exact_primary_only_events = sum(seed_match_types == "exact_primary_opportunity_bbl"),
      same_block_only_events = sum(seed_match_types == "same_block_unmatched_bbl"),
      mixed_seed_type_events = sum(grepl("|", seed_match_types, fixed = TRUE)),
      multi_dof_row_events = sum(dof_sale_records_linked > 1L),
      multi_primary_bbl_events = sum(primary_opportunity_bbl_count > 1L),
      total_event_price = sum(event_price, na.rm = TRUE),
      median_event_price = median(event_price, na.rm = TRUE)
    ),
  "../output/acris_recovered_sale_event_summary.csv"
)

write_csv_if_changed(
  recovered_sale_events |>
    mutate(event_year = as.integer(format(event_date, "%Y"))) |>
    group_by(event_year) |>
    summarise(
      events = n(),
      total_event_price = sum(event_price, na.rm = TRUE),
      median_event_price = median(event_price, na.rm = TRUE),
      multi_dof_row_events = sum(dof_sale_records_linked > 1L),
      .groups = "drop"
    ) |>
    arrange(event_year),
  "../output/acris_recovered_sale_events_by_year.csv"
)

write_csv_if_changed(
  recovered_sale_events |>
    count(seed_match_types, name = "events") |>
    arrange(seed_match_types),
  "../output/acris_recovered_sale_events_by_seed_type.csv"
)

incidence_event_reconciliation <- recovered_incidence |>
  group_by(event_id) |>
  summarise(
    event_price = first(event_price),
    equal_alloc_sum = sum(event_price_alloc_equal_bbl),
    area_alloc_sum = sum(event_price_alloc_allowed_res_area, na.rm = TRUE),
    .groups = "drop"
  )

write_csv_if_changed(
  recovered_incidence |>
    summarise(
      incidence_rows = n(),
      events = n_distinct(event_id),
      bbls = n_distinct(bbl),
      bbl_quarters = n_distinct(paste(bbl, event_quarter_start, sep = "::")),
      min_event_date = min(event_date, na.rm = TRUE),
      max_event_date = max(event_date, na.rm = TRUE),
      document_price_duplicated_sum = sum(event_price, na.rm = TRUE),
      equal_allocated_price_sum = sum(event_price_alloc_equal_bbl, na.rm = TRUE),
      area_allocated_price_sum = sum(event_price_alloc_allowed_res_area, na.rm = TRUE),
      missing_area_allocation_rows = sum(is.na(event_price_alloc_allowed_res_area)),
      max_equal_allocation_abs_diff = max(abs(incidence_event_reconciliation$event_price - incidence_event_reconciliation$equal_alloc_sum)),
      max_area_allocation_abs_diff = max(abs(incidence_event_reconciliation$event_price - incidence_event_reconciliation$area_alloc_sum))
    ),
  "../output/acris_recovered_sale_incidence_summary.csv"
)

write_csv_if_changed(
  recovered_incidence |>
    group_by(event_quarter_start, event_quarter, quarter_policy_period) |>
    summarise(
      incidence_rows = n(),
      events = n_distinct(event_id),
      bbls = n_distinct(bbl),
      equal_allocated_price_sum = sum(event_price_alloc_equal_bbl, na.rm = TRUE),
      area_allocated_price_sum = sum(event_price_alloc_allowed_res_area, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(event_quarter_start),
  "../output/acris_recovered_sale_incidence_by_quarter.csv"
)

cat("Wrote ACRIS recovery-layer audit diagnostics to ../output\n")

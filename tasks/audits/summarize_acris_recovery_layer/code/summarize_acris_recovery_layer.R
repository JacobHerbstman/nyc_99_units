# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_acris_recovery_layer/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

collapse_values <- function(x, max_values = 50L) {
  values <- sort(unique(as.character(x[!is.na(x) & x != ""])))

  if (length(values) == 0) {
    return("")
  }

  if (length(values) > max_values) {
    return(paste(c(values[seq_len(max_values)], paste0("more_", length(values) - max_values)), collapse = ";"))
  }

  paste(values, collapse = ";")
}

split_semicolon_values <- function(x) {
  if (is.na(x) || x == "") {
    return(character())
  }

  out <- unlist(strsplit(as.character(x), ";", fixed = TRUE), use.names = FALSE)
  out[out != ""]
}

semicolon_contains <- function(x, value) {
  value %in% split_semicolon_values(x)
}

semicolon_bbl_blocks <- function(x) {
  values <- split_semicolon_values(x)
  values <- values[nchar(values) == 10]
  collapse_values(substr(values, 2, 6))
}

semicolon_bbl_lots <- function(x) {
  values <- split_semicolon_values(x)
  values <- values[nchar(values) == 10]
  collapse_values(substr(values, 7, 10))
}

paste_true_flags <- function(flag_names, flag_values) {
  out <- flag_names[which(flag_values)]
  if (length(out) == 0) {
    return("")
  }

  paste(out, collapse = "|")
}

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

opportunity_sales_exact <- read_parquet("../input/opportunity_sales_exact_bbl.parquet") |>
  as.data.frame() |>
  as_tibble()

opportunity_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
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

primary_opportunity_bbls <- opportunity_lots |>
  filter(primary_opp50_850, valid_bbl) |>
  distinct(bbl)

document_legal_bbls <- opportunity_legals |>
  filter(valid_legal_bbl) |>
  distinct(document_id, legal_bbl)

document_primary_bbls <- document_legal_bbls |>
  inner_join(primary_opportunity_bbls, by = c("legal_bbl" = "bbl"), relationship = "many-to-one")

document_primary_summary <- document_primary_bbls |>
  group_by(document_id) |>
  summarise(primary_frozen_bbls_in_legals = n_distinct(legal_bbl), .groups = "drop")

candidate_classified <- candidate_links |>
  filter(!is.na(document_id), document_id != "") |>
  left_join(
    document_legal_bbls |>
      mutate(legal_contains_sale_bbl = TRUE),
    by = c("document_id", "sale_bbl" = "legal_bbl"),
    relationship = "many-to-one"
  ) |>
  left_join(document_primary_summary, by = "document_id", relationship = "many-to-one") |>
  mutate(
    legal_contains_sale_bbl = coalesce(legal_contains_sale_bbl, FALSE),
    primary_frozen_bbls_in_legals = coalesce(primary_frozen_bbls_in_legals, 0L),
    legal_confirmed_candidate = legal_contains_sale_bbl & primary_frozen_bbls_in_legals > 0L,
    production_event_document = document_id %in% recovered_sale_events$document_id
  )

write_csv_if_changed(
  tibble(
    stage = c(
      "sale_seeds",
      "exact_dof_acris_key_candidate_pairs",
      "candidate_documents_fetched_legals",
      "candidate_pairs_sale_bbl_in_legals",
      "candidate_documents_with_sale_bbl_in_legals",
      "candidate_documents_with_primary_frozen_bbl_in_legals",
      "legally_confirmed_candidate_pairs",
      "legally_confirmed_candidate_documents",
      "production_events",
      "event_bbl_incidences",
      "distinct_frozen_bbls_in_incidences"
    ),
    records = c(
      nrow(sale_seeds),
      nrow(candidate_classified),
      nrow(opportunity_legals),
      sum(candidate_classified$legal_contains_sale_bbl),
      nrow(candidate_classified |> filter(legal_contains_sale_bbl) |> distinct(document_id)),
      nrow(candidate_classified |> filter(primary_frozen_bbls_in_legals > 0L) |> distinct(document_id)),
      sum(candidate_classified$legal_confirmed_candidate),
      nrow(candidate_classified |> filter(legal_confirmed_candidate) |> distinct(document_id)),
      nrow(recovered_sale_events),
      nrow(recovered_incidence),
      n_distinct(recovered_incidence$bbl)
    ),
    sale_records = c(
      n_distinct(sale_seeds$sale_record_id),
      n_distinct(candidate_classified$sale_record_id),
      NA_integer_,
      n_distinct(candidate_classified$sale_record_id[candidate_classified$legal_contains_sale_bbl]),
      NA_integer_,
      NA_integer_,
      n_distinct(candidate_classified$sale_record_id[candidate_classified$legal_confirmed_candidate]),
      NA_integer_,
      n_distinct(unlist(strsplit(paste(recovered_sale_events$dof_sale_record_ids, collapse = ";"), ";", fixed = TRUE))),
      NA_integer_,
      NA_integer_
    ),
    documents = c(
      NA_integer_,
      n_distinct(candidate_classified$document_id),
      n_distinct(opportunity_legals$document_id),
      n_distinct(candidate_classified$document_id[candidate_classified$legal_contains_sale_bbl]),
      n_distinct(candidate_classified$document_id[candidate_classified$legal_contains_sale_bbl]),
      n_distinct(candidate_classified$document_id[candidate_classified$primary_frozen_bbls_in_legals > 0L]),
      n_distinct(candidate_classified$document_id[candidate_classified$legal_confirmed_candidate]),
      n_distinct(candidate_classified$document_id[candidate_classified$legal_confirmed_candidate]),
      n_distinct(recovered_sale_events$document_id),
      n_distinct(recovered_incidence$document_id),
      NA_integer_
    ),
    bbls = c(
      n_distinct(sale_seeds$sale_bbl),
      n_distinct(candidate_classified$sale_bbl),
      n_distinct(opportunity_legals$legal_bbl),
      n_distinct(candidate_classified$sale_bbl[candidate_classified$legal_contains_sale_bbl]),
      NA_integer_,
      NA_integer_,
      n_distinct(candidate_classified$sale_bbl[candidate_classified$legal_confirmed_candidate]),
      NA_integer_,
      NA_integer_,
      n_distinct(recovered_incidence$bbl),
      n_distinct(recovered_incidence$bbl)
    )
  ),
  "../output/acris_recovery_attrition_funnel.csv"
)

recovered_incidence_audit <- recovered_incidence |>
  mutate(
    event_year = as.integer(format(event_date, "%Y")),
    post_2024_calendar_year = event_date >= as.Date("2024-01-01"),
    post_485x_adoption = event_date >= as.Date("2024-04-20"),
    event_price_per_total_allowed_res_sqft = if_else(
      event_allowed_policy_res_sqft > 0,
      event_price / event_allowed_policy_res_sqft,
      NA_real_
    ),
    area_alloc_price_per_allowed_res_sqft = if_else(
      allowed_policy_res_sqft > 0,
      event_price_alloc_allowed_res_area / allowed_policy_res_sqft,
      NA_real_
    ),
    equal_alloc_price_per_allowed_res_sqft = if_else(
      allowed_policy_res_sqft > 0,
      event_price_alloc_equal_bbl / allowed_policy_res_sqft,
      NA_real_
    ),
    event_price_per_total_lot_area = if_else(
      lotarea > 0,
      event_price / lotarea,
      NA_real_
    ),
    area_alloc_price_per_lot_area = if_else(
      lotarea > 0,
      event_price_alloc_allowed_res_area / lotarea,
      NA_real_
    ),
    equal_alloc_price_per_lot_area = if_else(
      lotarea > 0,
      event_price_alloc_equal_bbl / lotarea,
      NA_real_
    )
  )

event_metrics <- recovered_incidence_audit |>
  group_by(event_id) |>
  summarise(
    document_id = first(document_id),
    crfn = first(crfn),
    event_date = first(event_date),
    event_year = first(event_year),
    event_quarter = first(event_quarter),
    event_price = first(event_price),
    document_amt = first(document_amt),
    percent_trans = first(percent_trans),
    recorded_borough = first(recorded_borough),
    seed_match_types = first(seed_match_types),
    dof_sale_records_linked = first(dof_sale_records_linked),
    dof_sale_bbls_linked = first(dof_sale_bbls_linked),
    legal_bbl_count = first(legal_bbl_count),
    primary_opportunity_bbl_count = first(primary_opportunity_bbl_count),
    incidence_bbl_count = n_distinct(bbl),
    boroughs = collapse_values(borough),
    bbls = collapse_values(bbl),
    dof_sale_bbls = first(dof_sale_bbls),
    primary_opportunity_bbls = collapse_values(bbl),
    total_allowed_policy_res_sqft = sum(allowed_policy_res_sqft, na.rm = TRUE),
    total_lotarea = sum(lotarea, na.rm = TRUE),
    max_capacity_exposure_quartile_citywide = max(capacity_exposure_quartile_citywide, na.rm = TRUE),
    max_capacity_exposure_quartile_borough = max(capacity_exposure_quartile_borough, na.rm = TRUE),
    event_price_per_total_allowed_res_sqft = first(event_price_per_total_allowed_res_sqft),
    event_price_per_total_lot_area = if_else(sum(lotarea, na.rm = TRUE) > 0, first(event_price) / sum(lotarea, na.rm = TRUE), NA_real_),
    max_area_alloc_price = max(event_price_alloc_allowed_res_area, na.rm = TRUE),
    max_equal_alloc_price = max(event_price_alloc_equal_bbl, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    event_price_rank = dense_rank(desc(event_price)),
    event_price_per_allowed_rank = dense_rank(desc(event_price_per_total_allowed_res_sqft)),
    event_price_per_lotarea_rank = dense_rank(desc(event_price_per_total_lot_area))
  )

write_csv_if_changed(
  event_metrics |>
    filter(
      event_price_rank <= 100L |
        event_price_per_allowed_rank <= 100L |
        event_price_per_lotarea_rank <= 100L
    ) |>
    rowwise() |>
    mutate(
      manual_review_reason = paste_true_flags(
        c("top_100_event_price", "top_100_event_price_per_allowed_res_sqft", "top_100_event_price_per_lot_sqft"),
        c(event_price_rank <= 100L, event_price_per_allowed_rank <= 100L, event_price_per_lotarea_rank <= 100L)
      )
    ) |>
    ungroup() |>
    arrange(event_price_rank, event_price_per_allowed_rank, event_price_per_lotarea_rank),
  "../output/acris_recovered_sale_largest_events.csv"
)

write_csv_if_changed(
  recovered_incidence_audit |>
    filter(post_2024_calendar_year) |>
    mutate(
      manual_review_reason = case_when(
        post_485x_adoption ~ "calendar_2024_or_2025_post_485x_adoption",
        TRUE ~ "calendar_2024_pre_485x_adoption"
      )
    ) |>
    select(
      event_id, document_id, crfn, event_date, event_quarter, quarter_policy_period,
      post_485x_adoption, bbl, borough, block, lot, address, seed_match_types,
      event_price, event_price_alloc_equal_bbl, event_price_alloc_allowed_res_area,
      allowed_policy_res_sqft, lotarea, event_price_per_total_allowed_res_sqft,
      area_alloc_price_per_allowed_res_sqft, area_alloc_price_per_lot_area,
      dof_sale_records_linked, dof_sale_bbls_linked, dof_sale_bbls,
      legal_bbl_count, primary_opportunity_bbl_count, manual_review_reason
    ) |>
    arrange(event_date, event_id, bbl),
  "../output/acris_recovered_sale_post2024_manual_review.csv"
)

exact_sales_audit <- opportunity_sales_exact |>
  filter(primary_opp50_850, primary_price_outcome_feasible_nominal) |>
  transmute(
    audit_source = "exact_dof_bbl",
    event_year = sale_year,
    event_quarter_start = sale_quarter_start,
    borough,
    capacity_exposure_quartile_citywide,
    capacity_exposure_quartile_borough,
    records = 1L,
    distinct_events = 1L,
    distinct_bbls = 1L,
    price = sale_price_nominal,
    allocated_price = sale_price_nominal,
    price_per_allowed_res_sqft = price_per_allowed_policy_res_sqft_nominal,
    price_per_lot_sqft = price_per_lot_sqft_nominal
  )

recovered_sales_audit <- recovered_incidence_audit |>
  transmute(
    audit_source = "acris_recovered_legal_confirmed",
    event_year,
    event_quarter_start,
    borough,
    capacity_exposure_quartile_citywide,
    capacity_exposure_quartile_borough,
    records = 1L,
    distinct_events = 1L,
    distinct_bbls = 1L,
    price = event_price,
    allocated_price = event_price_alloc_allowed_res_area,
    price_per_allowed_res_sqft = area_alloc_price_per_allowed_res_sqft,
    price_per_lot_sqft = area_alloc_price_per_lot_area
  )

write_csv_if_changed(
  bind_rows(exact_sales_audit, recovered_sales_audit) |>
    group_by(audit_source, event_year) |>
    summarise(
      records = n(),
      total_allocated_price = sum(allocated_price, na.rm = TRUE),
      median_allocated_price = median(allocated_price, na.rm = TRUE),
      median_price_per_allowed_res_sqft = median(price_per_allowed_res_sqft, na.rm = TRUE),
      median_price_per_lot_sqft = median(price_per_lot_sqft, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(event_year, audit_source),
  "../output/acris_recovered_sale_exact_vs_recovered_by_year.csv"
)

write_csv_if_changed(
  bind_rows(exact_sales_audit, recovered_sales_audit) |>
    group_by(audit_source, event_year, borough, capacity_exposure_quartile_citywide) |>
    summarise(
      records = n(),
      total_allocated_price = sum(allocated_price, na.rm = TRUE),
      median_allocated_price = median(allocated_price, na.rm = TRUE),
      median_price_per_allowed_res_sqft = median(price_per_allowed_res_sqft, na.rm = TRUE),
      median_price_per_lot_sqft = median(price_per_lot_sqft, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(event_year, borough, capacity_exposure_quartile_citywide, audit_source),
  "../output/acris_recovered_sale_exact_vs_recovered_by_borough_exposure.csv"
)

price_outlier_review <- recovered_incidence_audit |>
  group_by(borough, event_year) |>
  mutate(
    borough_year_rows = n(),
    q01_area_allowed = if_else(borough_year_rows >= 20L, quantile(area_alloc_price_per_allowed_res_sqft, 0.01, na.rm = TRUE), NA_real_),
    q99_area_allowed = if_else(borough_year_rows >= 20L, quantile(area_alloc_price_per_allowed_res_sqft, 0.99, na.rm = TRUE), NA_real_),
    q01_area_lot = if_else(borough_year_rows >= 20L, quantile(area_alloc_price_per_lot_area, 0.01, na.rm = TRUE), NA_real_),
    q99_area_lot = if_else(borough_year_rows >= 20L, quantile(area_alloc_price_per_lot_area, 0.99, na.rm = TRUE), NA_real_)
  ) |>
  ungroup() |>
  mutate(
    flag_top_1pct_borough_year_allowed = !is.na(q99_area_allowed) & area_alloc_price_per_allowed_res_sqft >= q99_area_allowed,
    flag_bottom_1pct_borough_year_allowed = !is.na(q01_area_allowed) & area_alloc_price_per_allowed_res_sqft <= q01_area_allowed,
    flag_top_1pct_borough_year_lot = !is.na(q99_area_lot) & area_alloc_price_per_lot_area >= q99_area_lot,
    flag_bottom_1pct_borough_year_lot = !is.na(q01_area_lot) & area_alloc_price_per_lot_area <= q01_area_lot,
    flag_allowed_price_above_2000 = !is.na(area_alloc_price_per_allowed_res_sqft) & area_alloc_price_per_allowed_res_sqft > 2000,
    flag_lot_price_above_5000 = !is.na(area_alloc_price_per_lot_area) & area_alloc_price_per_lot_area > 5000,
    flag_allowed_price_below_20 = !is.na(area_alloc_price_per_allowed_res_sqft) & area_alloc_price_per_allowed_res_sqft > 0 & area_alloc_price_per_allowed_res_sqft < 20,
    flag_event_price_below_10000 = !is.na(event_price) & event_price > 0 & event_price < 10000,
    flag_event_price_zero = !is.na(event_price) & event_price == 0
  ) |>
  rowwise() |>
  mutate(
    manual_review_reason = paste_true_flags(
      c(
        "top_1pct_borough_year_allowed",
        "bottom_1pct_borough_year_allowed",
        "top_1pct_borough_year_lot",
        "bottom_1pct_borough_year_lot",
        "allowed_price_above_2000",
        "lot_price_above_5000",
        "allowed_price_below_20",
        "event_price_below_10000",
        "event_price_zero"
      ),
      c(
        flag_top_1pct_borough_year_allowed,
        flag_bottom_1pct_borough_year_allowed,
        flag_top_1pct_borough_year_lot,
        flag_bottom_1pct_borough_year_lot,
        flag_allowed_price_above_2000,
        flag_lot_price_above_5000,
        flag_allowed_price_below_20,
        flag_event_price_below_10000,
        flag_event_price_zero
      )
    )
  ) |>
  ungroup() |>
  filter(manual_review_reason != "")

write_csv_if_changed(
  price_outlier_review |>
    select(
      event_id, document_id, crfn, event_date, event_year, event_quarter,
      bbl, borough, block, lot, address, seed_match_types,
      event_price, event_price_alloc_equal_bbl, event_price_alloc_allowed_res_area,
      allowed_policy_res_sqft, lotarea, event_price_per_total_allowed_res_sqft,
      area_alloc_price_per_allowed_res_sqft, equal_alloc_price_per_allowed_res_sqft,
      event_price_per_total_lot_area, area_alloc_price_per_lot_area,
      equal_alloc_price_per_lot_area, borough_year_rows, q01_area_allowed,
      q99_area_allowed, q01_area_lot, q99_area_lot, manual_review_reason
    ) |>
    arrange(event_date, event_id, bbl),
  "../output/acris_recovered_sale_price_outlier_review.csv"
)

write_csv_if_changed(
  recovered_incidence_audit |>
    filter(seed_match_types != "exact_primary_opportunity_bbl") |>
    rowwise() |>
    mutate(
      sale_blocks = semicolon_bbl_blocks(dof_sale_bbls),
      sale_lots = semicolon_bbl_lots(dof_sale_bbls),
      frozen_block = substr(bbl, 2, 6),
      frozen_lot = substr(bbl, 7, 10),
      incidence_bbl_is_dof_sale_bbl = semicolon_contains(dof_sale_bbls, bbl),
      incidence_bbl_block_matches_dof_sale_block = frozen_block %in% split_semicolon_values(sale_blocks),
      manual_review_reason = case_when(
        seed_match_types == "same_block_unmatched_bbl" ~ "same_block_only_legal_confirmed",
        TRUE ~ "mixed_exact_primary_and_same_block_legal_confirmed"
      )
    ) |>
    ungroup() |>
    select(
      event_id, document_id, crfn, event_date, event_quarter, bbl, borough,
      block, lot, frozen_block, frozen_lot, dof_sale_bbls, sale_blocks,
      sale_lots, incidence_bbl_is_dof_sale_bbl, incidence_bbl_block_matches_dof_sale_block,
      seed_match_types, event_price, event_price_alloc_allowed_res_area,
      allowed_policy_res_sqft, area_alloc_price_per_allowed_res_sqft,
      legal_bbl_count, primary_opportunity_bbl_count, manual_review_reason
    ) |>
    arrange(event_date, event_id, bbl),
  "../output/acris_recovered_sale_same_block_mixed_review.csv"
)

same_bbl_quarter_flags <- recovered_incidence_audit |>
  group_by(bbl, event_quarter_start) |>
  filter(n_distinct(event_id) > 1L) |>
  summarise(
    flag_type = "same_bbl_multiple_recovered_events_same_quarter",
    event_ids = collapse_values(event_id),
    document_ids = collapse_values(document_id),
    event_dates = collapse_values(as.character(event_date)),
    event_prices = collapse_values(as.character(event_price)),
    flag_count = n_distinct(event_id),
    .groups = "drop"
  )

within_30_day_flags <- recovered_incidence_audit |>
  distinct(bbl, event_id, document_id, event_date, event_price) |>
  arrange(bbl, event_date, event_id) |>
  group_by(bbl) |>
  mutate(
    prior_event_id = lag(event_id),
    prior_document_id = lag(document_id),
    prior_event_date = lag(event_date),
    prior_event_price = lag(event_price),
    days_since_prior = as.integer(event_date - prior_event_date)
  ) |>
  ungroup() |>
  filter(!is.na(days_since_prior), days_since_prior <= 30L) |>
  transmute(
    flag_type = "same_bbl_multiple_recovered_events_within_30_days",
    bbl,
    event_quarter_start = floor_date(event_date, "quarter"),
    event_ids = paste(prior_event_id, event_id, sep = ";"),
    document_ids = paste(prior_document_id, document_id, sep = ";"),
    event_dates = paste(prior_event_date, event_date, sep = ";"),
    event_prices = paste(prior_event_price, event_price, sep = ";"),
    flag_count = 2L
  )

same_bbl_price_flags <- recovered_incidence_audit |>
  group_by(bbl, event_price) |>
  filter(n_distinct(event_id) > 1L) |>
  summarise(
    flag_type = "same_bbl_repeated_identical_event_price",
    event_quarter_start = min(event_quarter_start, na.rm = TRUE),
    event_ids = collapse_values(event_id),
    document_ids = collapse_values(document_id),
    event_dates = collapse_values(as.character(event_date)),
    event_prices = as.character(first(event_price)),
    flag_count = n_distinct(event_id),
    .groups = "drop"
  ) |>
  select(flag_type, bbl, event_quarter_start, event_ids, document_ids, event_dates, event_prices, flag_count)

crfn_duplicate_flags <- recovered_sale_events |>
  filter(!is.na(crfn), crfn != "") |>
  group_by(crfn) |>
  filter(n_distinct(document_id) > 1L) |>
  summarise(
    flag_type = "same_crfn_multiple_document_ids",
    bbl = "",
    event_quarter_start = as.Date(NA),
    event_ids = collapse_values(event_id),
    document_ids = collapse_values(document_id),
    event_dates = collapse_values(as.character(event_date)),
    event_prices = collapse_values(as.character(event_price)),
    flag_count = n_distinct(document_id),
    .groups = "drop"
  )

exact_bbl_quarters <- opportunity_sales_exact |>
  filter(primary_opp50_850, primary_price_outcome_feasible_nominal) |>
  distinct(bbl = sale_bbl, event_quarter_start = sale_quarter_start)

if (anyDuplicated(paste(exact_bbl_quarters$bbl, exact_bbl_quarters$event_quarter_start, sep = "::")) > 0) {
  stop("Exact sales BBL-quarter audit key is not unique.")
}

exact_recovered_same_quarter_flags <- exact_bbl_quarters |>
  inner_join(
    recovered_incidence_audit |>
      distinct(bbl, event_quarter_start, event_id, document_id, event_date, event_price),
    by = c("bbl", "event_quarter_start"),
    relationship = "one-to-many"
  ) |>
  group_by(bbl, event_quarter_start) |>
  summarise(
    flag_type = "same_bbl_exact_dof_and_recovered_acris_same_quarter",
    event_ids = collapse_values(event_id),
    document_ids = collapse_values(document_id),
    event_dates = collapse_values(as.character(event_date)),
    event_prices = collapse_values(as.character(event_price)),
    flag_count = n_distinct(event_id),
    .groups = "drop"
  )

write_csv_if_changed(
  bind_rows(
    same_bbl_quarter_flags,
    within_30_day_flags,
    same_bbl_price_flags,
    crfn_duplicate_flags,
    exact_recovered_same_quarter_flags
  ) |>
    arrange(flag_type, bbl, event_quarter_start),
  "../output/acris_recovered_sale_repeated_timing_flags.csv"
)

multi_lot_sensitivity <- recovered_incidence_audit |>
  mutate(
    area_alloc_share = if_else(event_price > 0, event_price_alloc_allowed_res_area / event_price, NA_real_),
    equal_alloc_share = if_else(event_price > 0, event_price_alloc_equal_bbl / event_price, NA_real_),
    area_to_equal_alloc_ratio = if_else(event_price_alloc_equal_bbl > 0, event_price_alloc_allowed_res_area / event_price_alloc_equal_bbl, NA_real_)
  ) |>
  group_by(event_id) |>
  summarise(
    document_id = first(document_id),
    crfn = first(crfn),
    event_date = first(event_date),
    event_price = first(event_price),
    seed_match_types = first(seed_match_types),
    legal_bbl_count = first(legal_bbl_count),
    primary_opportunity_bbl_count = first(primary_opportunity_bbl_count),
    incidence_bbl_count = n_distinct(bbl),
    total_allowed_res_area = sum(allowed_policy_res_sqft, na.rm = TRUE),
    min_area_alloc_share = min(area_alloc_share, na.rm = TRUE),
    max_area_alloc_share = max(area_alloc_share, na.rm = TRUE),
    hhi_area_alloc_shares = sum(area_alloc_share^2, na.rm = TRUE),
    max_equal_alloc_price = max(event_price_alloc_equal_bbl, na.rm = TRUE),
    max_area_alloc_price = max(event_price_alloc_allowed_res_area, na.rm = TRUE),
    max_area_to_equal_alloc_ratio = max(area_to_equal_alloc_ratio, na.rm = TRUE),
    bbls_with_zero_allowed_area = sum(allowed_policy_res_sqft <= 0 | is.na(allowed_policy_res_sqft)),
    bbls = collapse_values(bbl),
    dof_sale_bbls = first(dof_sale_bbls),
    .groups = "drop"
  ) |>
  mutate(
    flag_three_or_more_primary_bbls = primary_opportunity_bbl_count >= 3L,
    flag_five_or_more_legal_bbls = legal_bbl_count >= 5L,
    flag_area_alloc_over_75pct = max_area_alloc_share > 0.75,
    flag_area_equal_ratio_over_3 = max_area_to_equal_alloc_ratio > 3,
    flag_zero_allowed_area = bbls_with_zero_allowed_area > 0L,
    flag_multilot_event_above_25m = primary_opportunity_bbl_count > 1L & event_price > 25000000
  ) |>
  rowwise() |>
  mutate(
    manual_review_reason = paste_true_flags(
      c(
        "three_or_more_primary_bbls",
        "five_or_more_legal_bbls",
        "area_alloc_over_75pct",
        "area_equal_ratio_over_3",
        "zero_allowed_area",
        "multilot_event_above_25m"
      ),
      c(
        flag_three_or_more_primary_bbls,
        flag_five_or_more_legal_bbls,
        flag_area_alloc_over_75pct,
        flag_area_equal_ratio_over_3,
        flag_zero_allowed_area,
        flag_multilot_event_above_25m
      )
    )
  ) |>
  ungroup() |>
  mutate(
    manual_review_reason = if_else(
      manual_review_reason == "" & (primary_opportunity_bbl_count > 1L | legal_bbl_count > 1L),
      "multi_lot_event_no_threshold_flag",
      manual_review_reason
    )
  ) |>
  filter(primary_opportunity_bbl_count > 1L | legal_bbl_count > 1L | manual_review_reason != "") |>
  arrange(desc(event_price), event_id)

write_csv_if_changed(
  multi_lot_sensitivity,
  "../output/acris_recovered_sale_multilot_allocation_sensitivity.csv"
)

source_key_collision_review <- candidate_links |>
  filter(!is.na(document_id), document_id != "") |>
  group_by(acris_master_exact_key) |>
  summarise(
    n_dof_sales = n_distinct(sale_record_id),
    n_acris_documents = n_distinct(document_id),
    n_candidate_pairs = n(),
    n_confirmed_documents = n_distinct(document_id[document_id %in% recovered_sale_events$document_id]),
    n_production_events = n_distinct(document_id[document_id %in% recovered_sale_events$document_id]),
    dof_bbls = collapse_values(sale_bbl),
    sale_record_ids = collapse_values(sale_record_id),
    document_ids = collapse_values(document_id),
    crfns = collapse_values(crfn),
    seed_match_types = collapse_values(seed_match_type),
    .groups = "drop"
  ) |>
  separate(acris_master_exact_key, into = c("borough_key", "sale_date_key", "amount_key"), sep = "::", remove = FALSE) |>
  mutate(
    flag_multiple_dof_and_acris = n_dof_sales > 1L & n_acris_documents > 1L,
    flag_candidate_pairs_ge_5 = n_candidate_pairs >= 5L,
    flag_production_from_multi_seed_key = n_production_events > 0L & n_dof_sales > 1L
  ) |>
  rowwise() |>
  mutate(
    manual_review_reason = paste_true_flags(
      c(
        "multiple_dof_and_acris",
        "candidate_pairs_ge_5",
        "production_from_multi_seed_key"
      ),
      c(
        flag_multiple_dof_and_acris,
        flag_candidate_pairs_ge_5,
        flag_production_from_multi_seed_key
      )
    )
  ) |>
  ungroup() |>
  filter(manual_review_reason != "") |>
  arrange(desc(n_candidate_pairs), acris_master_exact_key)

write_csv_if_changed(
  source_key_collision_review,
  "../output/acris_recovery_source_key_collision_review.csv"
)

if (nrow(recovered_sale_events) > n_distinct(candidate_classified$document_id[candidate_classified$legal_confirmed_candidate])) {
  stop("Production events exceed legally confirmed candidate documents.")
}

if (anyDuplicated(paste(recovered_incidence$event_id, recovered_incidence$bbl, sep = "::")) > 0) {
  stop("Recovered incidence violates event_id/BBL grain.")
}

cat("Wrote ACRIS recovery-layer audit diagnostics to ../output\n")

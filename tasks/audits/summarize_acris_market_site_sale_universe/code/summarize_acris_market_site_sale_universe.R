# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_acris_market_site_sale_universe/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

split_codes <- function(x) {
  values <- unlist(str_split(coalesce(x, ""), ";", simplify = FALSE))
  values[!is.na(values) & values != ""]
}

events <- read_parquet("../input/market_site_sale_events.parquet") |>
  as.data.frame() |>
  as_tibble()

incidence <- read_parquet("../input/market_site_sale_event_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble()

documents <- read_parquet("../input/acris_deed_document_classified.parquet") |>
  as.data.frame() |>
  as_tibble()

clusters <- read_parquet("../input/acris_document_cluster_candidates.parquet") |>
  as.data.frame() |>
  as_tibble()

hard_checks <- tibble(
  check_name = c(
    "unique_event_id",
    "unique_event_opportunity_bbl",
    "unique_document_id",
    "source_document_single_event",
    "primary_positive_price",
    "primary_percent_trans_100",
    "primary_no_unit_churn",
    "primary_no_rights_only",
    "primary_no_public_hdfc_party",
    "primary_no_strong_related_party",
    "primary_no_ambiguous_cluster",
    "primary_incidence_has_allocated_price"
  ),
  passed = c(
    anyDuplicated(events$event_id) == 0L,
    anyDuplicated(paste(incidence$event_id, incidence$opportunity_bbl, sep = "::")) == 0L,
    anyDuplicated(documents$document_id) == 0L,
    documents |> count(document_id) |> summarise(ok = all(n == 1L)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!is.na(event_price_final) & event_price_final > 0)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(percent_trans_min == 100 & percent_trans_max == 100)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!unit_churn_flag)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!rights_only_flag)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!housing_public_or_regulated_party_flag)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!related_party_strong_flag)) |> pull(ok),
    events |> filter(event_market_status == "PRIMARY_MARKET_SITE_SALE") |> summarise(ok = all(!ambiguous_cluster_flag)) |> pull(ok),
    incidence |> filter(incidence_price_status == "PRIMARY_ALLOC_USABLE") |> summarise(ok = all(!is.na(alloc_price_allowed_res_area) & alloc_price_allowed_res_area > 0)) |> pull(ok)
  )
) |>
  mutate(passed = coalesce(passed, TRUE))

event_status_counts <- events |>
  count(event_market_status, name = "events") |>
  arrange(desc(events), event_market_status)

all_exclusion_codes <- split_codes(documents$document_exclusion_codes)

exclusion_code_counts <- tibble(document_exclusion_code = all_exclusion_codes) |>
  count(document_exclusion_code, name = "documents") |>
  arrange(desc(documents), document_exclusion_code)

attrition_by_year_borough <- documents |>
  mutate(
    document_year = suppressWarnings(as.integer(format(document_date, "%Y"))),
    recorded_borough = coalesce(recorded_borough, "missing")
  ) |>
  group_by(document_year, recorded_borough) |>
  summarise(
    direct_deed_documents = n_distinct(document_id),
    positive_amount_documents = n_distinct(document_id[amount_class %in% c("LOW", "MARKET_CANDIDATE")]),
    percent_100_documents = n_distinct(document_id[percent_trans == 100]),
    primary_candidate_documents = n_distinct(document_id[document_market_status == "DOC_PRIMARY_CANDIDATE"]),
    sens_private_documents = n_distinct(document_id[document_market_status == "DOC_SENS_PRIVATE_RELAXED"]),
    unit_churn_documents = n_distinct(document_id[document_market_status == "DOC_EXCLUDE_UNIT_CHURN"]),
    public_or_institutional_documents = n_distinct(document_id[document_market_status == "DOC_EXCLUDE_PUBLIC_OR_INSTITUTIONAL"]),
    related_party_documents = n_distinct(document_id[document_market_status == "DOC_EXCLUDE_RELATED_PARTY"]),
    .groups = "drop"
  ) |>
  arrange(document_year, recorded_borough)

allocation_reconciliation <- incidence |>
  group_by(event_id) |>
  summarise(
    event_price_final = first(event_price_final),
    incidence_rows = n(),
    opportunity_alloc_allowed_res_area_sum = sum(alloc_price_allowed_res_area, na.rm = TRUE),
    opportunity_alloc_lotarea_sum = sum(alloc_price_lotarea, na.rm = TRUE),
    opportunity_alloc_equal_sum = sum(alloc_price_equal, na.rm = TRUE),
    event_opp_share_allowed_res_area = first(event_opp_share_allowed_res_area),
    event_opp_share_lotarea = first(event_opp_share_lotarea),
    any_primary_alloc_usable = any(incidence_price_status == "PRIMARY_ALLOC_USABLE"),
    .groups = "drop"
  ) |>
  mutate(
    implied_allowed_res_area_opp_share = opportunity_alloc_allowed_res_area_sum / event_price_final,
    implied_lotarea_opp_share = opportunity_alloc_lotarea_sum / event_price_final
  ) |>
  arrange(event_id)

price_outliers <- incidence |>
  filter(!is.na(alloc_price_allowed_res_area), alloc_price_allowed_res_area > 0) |>
  mutate(event_year = suppressWarnings(as.integer(substr(event_quarter, 1L, 4L)))) |>
  group_by(legal_borough, event_year) |>
  arrange(price_per_allowed_res_sqft, event_id, opportunity_bbl, .by_group = TRUE) |>
  mutate(
    price_per_allowed_res_sqft_pctile = percent_rank(price_per_allowed_res_sqft),
    price_outlier_flag = price_per_allowed_res_sqft_pctile >= 0.99 |
      price_per_allowed_res_sqft_pctile <= 0.01 |
      price_per_allowed_res_sqft > 2000 |
      price_per_allowed_res_sqft < 5 |
      alloc_price_allowed_res_area > 25000000
  ) |>
  ungroup() |>
  filter(price_outlier_flag) |>
  select(
    event_id, opportunity_bbl, legal_borough, event_year, event_market_status,
    event_price_final, alloc_price_allowed_res_area, alloc_price_lotarea,
    price_per_allowed_res_sqft, price_per_lot_sqft,
    price_per_allowed_res_sqft_pctile, incidence_price_status,
    primary_exclusion_codes, warning_codes, allocation_warning_codes
  ) |>
  arrange(desc(price_per_allowed_res_sqft), event_id, opportunity_bbl)

cluster_risk <- clusters |>
  filter(
    exact_duplicate_group_docs > 1L |
      ambiguous_same_buyer_date_amount_flag |
      same_bbl_date_buyer_repeated_flag |
      duplicate_price_excluded_flag
  ) |>
  arrange(event_id, document_id)

write_csv_if_changed(hard_checks, "../output/market_site_sale_hard_checks.csv")
write_csv_if_changed(event_status_counts, "../output/market_site_sale_event_status_counts.csv")
write_csv_if_changed(exclusion_code_counts, "../output/market_site_sale_exclusion_code_counts.csv")
write_csv_if_changed(attrition_by_year_borough, "../output/market_site_sale_attrition_by_year_borough.csv")
write_csv_if_changed(allocation_reconciliation, "../output/market_site_sale_allocation_reconciliation.csv")
write_csv_if_changed(price_outliers, "../output/market_site_sale_price_outliers.csv")
write_csv_if_changed(cluster_risk, "../output/market_site_sale_cluster_risk.csv")
cat("Wrote ACRIS market site sale universe audit outputs to ../output\n")

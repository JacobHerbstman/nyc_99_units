# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acris_private_market_sales_layer/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

paste_codes <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(unique(values), collapse = ";")
}

split_codes <- function(x) {
  values <- unlist(str_split(coalesce(as.character(x), ""), ";", simplify = FALSE))
  values[!is.na(values) & values != ""]
}

audit_columns <- function(df, dataset_name) {
  bind_rows(lapply(names(df), function(column_name) {
    x <- df[[column_name]]
    x_character <- as.character(x)
    nonmissing <- !is.na(x)
    nonblank <- nonmissing & str_squish(x_character) != ""
    sample_values <- unique(x_character[nonblank])
    sample_values <- sample_values[!is.na(sample_values)]

    tibble(
      dataset = dataset_name,
      column_name = column_name,
      storage_class = paste(class(x), collapse = ";"),
      rows = length(x),
      missing_count = sum(is.na(x)),
      missing_share = mean(is.na(x)),
      blank_count = if (is.character(x)) sum(nonmissing & str_squish(x_character) == "") else NA_integer_,
      distinct_nonmissing = n_distinct(x[nonmissing]),
      true_count = if (is.logical(x)) sum(x, na.rm = TRUE) else NA_integer_,
      false_count = if (is.logical(x)) sum(!x, na.rm = TRUE) else NA_integer_,
      zero_count = if (is.numeric(x)) sum(x == 0, na.rm = TRUE) else NA_integer_,
      positive_count = if (is.numeric(x)) sum(x > 0, na.rm = TRUE) else NA_integer_,
      min_value = if (inherits(x, "Date") || is.numeric(x)) as.character(suppressWarnings(min(x, na.rm = TRUE))) else NA_character_,
      max_value = if (inherits(x, "Date") || is.numeric(x)) as.character(suppressWarnings(max(x, na.rm = TRUE))) else NA_character_,
      sample_values = paste(head(sample_values, 5L), collapse = " | ")
    )
  })) |>
    mutate(
      min_value = if_else(str_detect(min_value, "Inf"), NA_character_, min_value),
      max_value = if_else(str_detect(max_value, "Inf"), NA_character_, max_value)
    )
}

count_category <- function(df, column_name, category_family, id_column, price_column) {
  df |>
    mutate(category_value = coalesce(as.character(.data[[column_name]]), "missing")) |>
    group_by(category_value) |>
    summarise(
      rows = n(),
      distinct_events = n_distinct(.data[[id_column]]),
      primary_private_rows = sum(coalesce(event_primary_private_sale, FALSE)),
      strict_private_rows = sum(coalesce(event_strict_private_sale, FALSE)),
      broad_priced_transfer_rows = sum(coalesce(event_broad_priced_transfer, FALSE)),
      price_sum = sum(.data[[price_column]], na.rm = TRUE),
      median_price = median(.data[[price_column]], na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      category_family = category_family,
      category_value = if_else(category_value == "", "blank", category_value),
      median_price = if_else(is.infinite(median_price), NA_real_, median_price)
    ) |>
    select(category_family, category_value, everything())
}

count_flags <- function(df, dataset_name, id_column, flag_columns) {
  bind_rows(lapply(flag_columns, function(flag_column) {
    flag <- coalesce(df[[flag_column]], FALSE)
    tibble(
      dataset = dataset_name,
      flag_column = flag_column,
      rows = nrow(df),
      true_rows = sum(flag),
      true_share = mean(flag),
      true_distinct_events = n_distinct(df[[id_column]][flag]),
      primary_private_true_rows = sum(flag & coalesce(df$event_primary_private_sale, FALSE)),
      strict_private_true_rows = sum(flag & coalesce(df$event_strict_private_sale, FALSE)),
      broad_priced_transfer_true_rows = sum(flag & coalesce(df$event_broad_priced_transfer, FALSE))
    )
  }))
}

events <- read_parquet("../input/acris_private_market_site_sale_events.parquet") |>
  as.data.frame() |>
  as_tibble()

incidence <- read_parquet("../input/acris_private_market_site_sale_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble()

event_id_duplicates <- events |>
  count(event_id, name = "rows") |>
  filter(rows > 1L)

incidence_key_duplicates <- incidence |>
  count(event_id, opportunity_bbl, name = "rows") |>
  filter(rows > 1L)

event_weight_checks <- incidence |>
  group_by(event_id) |>
  summarise(
    direct_allowed_weight_sum = sum(alloc_weight_allowed_res_area_all_legal, na.rm = TRUE),
    direct_lotarea_weight_sum = sum(alloc_weight_lotarea_all_legal, na.rm = TRUE),
    direct_equal_weight_sum = sum(alloc_weight_equal_all_legal, na.rm = TRUE),
    primary_alloc_complete_rows = sum(primary_price_alloc_complete),
    .groups = "drop"
  )

hard_checks <- tibble(
  check_name = c(
    "unique_event_id",
    "unique_event_opportunity_bbl",
    "incidence_event_ids_exist_in_events",
    "events_are_resolved_priced",
    "primary_private_events_have_positive_price",
    "primary_private_events_have_no_exclusion_reason",
    "primary_private_events_no_unit_churn",
    "primary_private_events_no_rights_only",
    "primary_private_events_no_public_hdfc_housing",
    "primary_private_events_no_nonprofit_religious",
    "primary_private_events_no_strong_related_party",
    "primary_private_events_no_low_price",
    "strict_private_is_subset_of_primary",
    "strict_private_events_no_soft_warning_flags",
    "broad_priced_transfer_events_no_hard_transfer_exclusions",
    "broad_priced_transfer_events_no_low_price",
    "primary_private_events_have_incidence_rows",
    "incidence_rows_are_primary_opportunity_lots",
    "primary_price_usable_incidence_has_positive_allocated_price",
    "primary_price_complete_incidence_has_complete_denominator",
    "allowed_res_area_direct_weights_not_above_one",
    "lotarea_direct_weights_not_above_one",
    "equal_direct_weights_not_above_one",
    "primary_price_complete_price_per_allowed_sqft_positive"
  ),
  failed_rows = c(
    nrow(event_id_duplicates),
    nrow(incidence_key_duplicates),
    length(setdiff(incidence$event_id, events$event_id)),
    sum(!coalesce(events$resolved_priced_event, FALSE)),
    events |> filter(event_primary_private_sale, is.na(event_price_final) | event_price_final <= 0) |> nrow(),
    events |> filter(event_primary_private_sale, !is.na(event_primary_exclusion_reason)) |> nrow(),
    events |> filter(event_primary_private_sale, unit_churn_flag) |> nrow(),
    events |> filter(event_primary_private_sale, rights_only_flag) |> nrow(),
    events |> filter(event_primary_private_sale, public_party_flag | hdfc_party_flag | housing_public_or_regulated_party_flag) |> nrow(),
    events |> filter(event_primary_private_sale, nonprofit_religious_party_flag) |> nrow(),
    events |> filter(event_primary_private_sale, related_party_strong_flag) |> nrow(),
    events |> filter(event_primary_private_sale, event_low_price_flag) |> nrow(),
    events |> filter(event_strict_private_sale, !event_primary_private_sale) |> nrow(),
    events |> filter(
      event_strict_private_sale,
      related_party_weak_flag | trust_estate_party_flag | mixed_rights_flag |
        event_low_price_flag | event_low_opportunity_share_flag
    ) |> nrow(),
    events |> filter(
      event_broad_priced_transfer,
      unit_churn_flag | rights_only_flag |
        public_party_flag | hdfc_party_flag | housing_public_or_regulated_party_flag
    ) |> nrow(),
    events |> filter(event_broad_priced_transfer, event_low_price_flag) |> nrow(),
    length(setdiff(events$event_id[events$event_primary_private_sale], incidence$event_id)),
    incidence |> filter(!primary_opp50_850) |> nrow(),
    incidence |> filter(primary_price_alloc_usable, is.na(event_price_alloc_allowed_res_area) | event_price_alloc_allowed_res_area <= 0) |> nrow(),
    incidence |> filter(primary_price_alloc_complete, !allocation_mappluto_complete | !allocation_allowed_res_area_observed_complete) |> nrow(),
    event_weight_checks |> filter(direct_allowed_weight_sum > 1 + 1e-8) |> nrow(),
    event_weight_checks |> filter(direct_lotarea_weight_sum > 1 + 1e-8) |> nrow(),
    event_weight_checks |> filter(direct_equal_weight_sum > 1 + 1e-8) |> nrow(),
    incidence |> filter(primary_price_alloc_complete, is.na(price_per_allowed_res_sqft) | price_per_allowed_res_sqft <= 0 | !is.finite(price_per_allowed_res_sqft)) |> nrow()
  )
) |>
  mutate(
    passed = failed_rows == 0L,
    audit_note = case_when(
      check_name == "primary_private_events_have_no_exclusion_reason" ~ "Primary private events should not carry a primary exclusion reason.",
      check_name == "primary_private_events_no_low_price" ~ "Primary private events exclude final sale prices at or below the low-price cutoff.",
      check_name == "strict_private_events_no_soft_warning_flags" ~ "Strict sample removes weak related-party, trust/estate, mixed-rights, low-price, and low-opportunity-share flags.",
      check_name == "broad_priced_transfer_events_no_low_price" ~ "Broad priced transfers also exclude final sale prices at or below the low-price cutoff.",
      check_name == "primary_price_complete_incidence_has_complete_denominator" ~ "Complete allocated prices require complete MapPLUTO and allowed-residential-area denominators.",
      TRUE ~ NA_character_
    )
  )

event_column_audit <- audit_columns(events, "events")
incidence_column_audit <- audit_columns(incidence, "incidence")

event_category_counts <- bind_rows(
  count_category(events, "event_inclusion_status", "event_inclusion_status", "event_id", "event_price_final"),
  count_category(events, "event_primary_exclusion_reason", "event_primary_exclusion_reason", "event_id", "event_price_final"),
  count_category(events, "price_resolution_status", "price_resolution_status", "event_id", "event_price_final"),
  count_category(events, "event_count_resolution_status", "event_count_resolution_status", "event_id", "event_price_final"),
  count_category(events, "manual_review_status", "manual_review_status", "event_id", "event_price_final"),
  count_category(events, "review_priority", "review_priority", "event_id", "event_price_final"),
  count_category(events, "ambiguity_type", "ambiguity_type", "event_id", "event_price_final"),
  count_category(events, "source_confidence", "source_confidence", "event_id", "event_price_final"),
  count_category(events, "price_rule", "price_rule", "event_id", "event_price_final"),
  count_category(events, "allocation_denominator_status", "allocation_denominator_status", "event_id", "event_price_final")
) |>
  arrange(category_family, desc(rows), category_value)

incidence_category_counts <- bind_rows(
  count_category(incidence, "event_inclusion_status", "event_inclusion_status", "event_id", "event_price_final"),
  count_category(incidence, "incidence_primary_exclusion_reason", "incidence_primary_exclusion_reason", "event_id", "event_price_final"),
  count_category(incidence, "event_primary_exclusion_reason", "event_primary_exclusion_reason", "event_id", "event_price_final"),
  count_category(incidence, "price_resolution_status", "price_resolution_status", "event_id", "event_price_final"),
  count_category(incidence, "event_count_resolution_status", "event_count_resolution_status", "event_id", "event_price_final"),
  count_category(incidence, "manual_review_status", "manual_review_status", "event_id", "event_price_final"),
  count_category(incidence, "price_rule", "price_rule", "event_id", "event_price_final"),
  count_category(incidence, "source_confidence", "source_confidence", "event_id", "event_price_final"),
  count_category(incidence, "allocation_denominator_status", "allocation_denominator_status", "event_id", "event_price_final"),
  count_category(incidence, "capacity_exposure_quartile_citywide", "capacity_exposure_quartile_citywide", "event_id", "event_price_final")
) |>
  arrange(category_family, desc(rows), category_value)

event_flag_columns <- c(
  "event_primary_private_sale",
  "event_strict_private_sale",
  "event_broad_priced_transfer",
  "event_low_price_flag",
  "event_low_opportunity_share_flag",
  "event_very_low_opportunity_share_flag",
  "unit_churn_flag",
  "rights_only_flag",
  "mixed_rights_flag",
  "public_party_flag",
  "hdfc_party_flag",
  "housing_public_or_regulated_party_flag",
  "nonprofit_religious_party_flag",
  "trust_estate_party_flag",
  "related_party_strong_flag",
  "related_party_weak_flag",
  "allocation_mappluto_complete",
  "allocation_allowed_res_area_observed_complete",
  "allocation_allowed_res_area_positive_denominator",
  "allocation_lotarea_positive_denominator"
)

incidence_flag_columns <- c(
  "event_primary_private_sale",
  "event_strict_private_sale",
  "event_broad_priced_transfer",
  "primary_price_alloc_usable",
  "primary_price_alloc_complete",
  "strict_price_alloc_complete",
  "broad_price_alloc_usable",
  "event_low_price_flag",
  "event_low_opportunity_share_flag",
  "event_very_low_opportunity_share_flag",
  "unit_churn_flag",
  "rights_only_flag",
  "mixed_rights_flag",
  "public_party_flag",
  "hdfc_party_flag",
  "housing_public_or_regulated_party_flag",
  "nonprofit_religious_party_flag",
  "trust_estate_party_flag",
  "related_party_strong_flag",
  "related_party_weak_flag",
  "allocation_mappluto_complete",
  "allocation_allowed_res_area_observed_complete",
  "allocation_allowed_res_area_positive_denominator",
  "allocation_lotarea_positive_denominator"
)

event_flag_counts <- count_flags(events, "events", "event_id", event_flag_columns) |>
  arrange(desc(true_rows), flag_column)

incidence_flag_counts <- count_flags(incidence, "incidence", "event_id", incidence_flag_columns) |>
  arrange(desc(true_rows), flag_column)

event_denominator_completeness <- events |>
  group_by(allocation_denominator_status) |>
  summarise(
    events = n(),
    primary_private_events = sum(event_primary_private_sale),
    strict_private_events = sum(event_strict_private_sale),
    broad_priced_transfer_events = sum(event_broad_priced_transfer),
    complete_mappluto_events = sum(allocation_mappluto_complete),
    complete_allowed_res_area_events = sum(allocation_allowed_res_area_observed_complete),
    positive_allowed_res_denominator_events = sum(allocation_allowed_res_area_positive_denominator),
    positive_lotarea_denominator_events = sum(allocation_lotarea_positive_denominator),
    event_price_final_sum = sum(event_price_final, na.rm = TRUE),
    direct_opportunity_allowed_res_sqft_sum = sum(event_direct_opportunity_allowed_res_sqft_sum, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(events), allocation_denominator_status)

incidence_denominator_completeness <- incidence |>
  group_by(allocation_denominator_status, primary_price_alloc_complete) |>
  summarise(
    incidence_rows = n(),
    distinct_events = n_distinct(event_id),
    primary_price_usable_rows = sum(primary_price_alloc_usable),
    primary_price_complete_rows = sum(primary_price_alloc_complete),
    allocated_allowed_res_area_price_sum = sum(event_price_alloc_allowed_res_area[primary_price_alloc_complete], na.rm = TRUE),
    allocated_lotarea_price_sum = sum(event_price_alloc_lotarea[primary_price_alloc_complete], na.rm = TRUE),
    allocated_equal_price_sum = sum(event_price_alloc_equal[primary_price_alloc_complete], na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(incidence_rows), allocation_denominator_status)

price_distribution_events <- events |>
  group_by(event_inclusion_status, event_primary_exclusion_reason) |>
  summarise(
    dataset = "events",
    rows = n(),
    distinct_events = n_distinct(event_id),
    price_p10 = quantile(event_price_final, 0.10, na.rm = TRUE, names = FALSE),
    price_median = median(event_price_final, na.rm = TRUE),
    price_p90 = quantile(event_price_final, 0.90, na.rm = TRUE, names = FALSE),
    price_sum = sum(event_price_final, na.rm = TRUE),
    low_price_rows = sum(event_low_price_flag),
    low_opportunity_share_rows = sum(event_low_opportunity_share_flag),
    .groups = "drop"
  ) |>
  rename(price_status = event_inclusion_status, exclusion_reason = event_primary_exclusion_reason)

price_distribution_incidence <- incidence |>
  group_by(event_inclusion_status, incidence_primary_exclusion_reason) |>
  summarise(
    dataset = "incidence",
    rows = n(),
    distinct_events = n_distinct(event_id),
    price_p10 = quantile(event_price_alloc_allowed_res_area, 0.10, na.rm = TRUE, names = FALSE),
    price_median = median(event_price_alloc_allowed_res_area, na.rm = TRUE),
    price_p90 = quantile(event_price_alloc_allowed_res_area, 0.90, na.rm = TRUE, names = FALSE),
    price_sum = sum(event_price_alloc_allowed_res_area, na.rm = TRUE),
    low_price_rows = sum(event_low_price_flag),
    low_opportunity_share_rows = sum(event_low_opportunity_share_flag),
    .groups = "drop"
  ) |>
  rename(price_status = event_inclusion_status, exclusion_reason = incidence_primary_exclusion_reason)

price_distributions <- bind_rows(price_distribution_events, price_distribution_incidence) |>
  mutate(
    exclusion_reason = coalesce(exclusion_reason, "missing"),
    price_p10 = if_else(is.infinite(price_p10), NA_real_, price_p10),
    price_median = if_else(is.infinite(price_median), NA_real_, price_median),
    price_p90 = if_else(is.infinite(price_p90), NA_real_, price_p90)
  ) |>
  arrange(dataset, price_status, exclusion_reason)

event_issue_codes <- mapply(
  paste_codes,
  if_else(!events$resolved_priced_event, "E_NOT_RESOLVED_PRICED", NA_character_),
  if_else(is.na(events$event_price_final) | events$event_price_final <= 0, "E_NONPOSITIVE_FINAL_PRICE", NA_character_),
  if_else(events$event_primary_private_sale & !is.na(events$event_primary_exclusion_reason), "E_PRIMARY_HAS_EXCLUSION_REASON", NA_character_),
  if_else(events$event_primary_private_sale & events$unit_churn_flag, "E_PRIMARY_UNIT_CHURN", NA_character_),
  if_else(events$event_primary_private_sale & events$rights_only_flag, "E_PRIMARY_RIGHTS_ONLY", NA_character_),
  if_else(events$event_primary_private_sale & (events$public_party_flag | events$hdfc_party_flag | events$housing_public_or_regulated_party_flag), "E_PRIMARY_PUBLIC_HDFC_HOUSING", NA_character_),
  if_else(events$event_primary_private_sale & events$nonprofit_religious_party_flag, "E_PRIMARY_NONPROFIT_RELIGIOUS", NA_character_),
  if_else(events$event_primary_private_sale & events$related_party_strong_flag, "E_PRIMARY_STRONG_RELATED_PARTY", NA_character_),
  if_else(events$event_primary_private_sale & !events$allocation_mappluto_complete, "W_PRIMARY_INCOMPLETE_MAPPLUTO_DENOMINATOR", NA_character_),
  if_else(events$event_primary_private_sale & !events$allocation_allowed_res_area_observed_complete, "W_PRIMARY_INCOMPLETE_ALLOWED_RES_AREA_DENOMINATOR", NA_character_),
  if_else(events$event_primary_private_sale & events$event_low_price_flag, "W_PRIMARY_LOW_PRICE", NA_character_),
  if_else(events$event_primary_private_sale & events$event_low_opportunity_share_flag, "W_PRIMARY_LOW_OPPORTUNITY_SHARE", NA_character_),
  if_else(events$event_primary_private_sale & events$related_party_weak_flag, "W_PRIMARY_WEAK_RELATED_PARTY", NA_character_),
  if_else(events$event_primary_private_sale & events$trust_estate_party_flag, "W_PRIMARY_TRUST_ESTATE_PARTY", NA_character_),
  if_else(events$event_primary_private_sale & events$mixed_rights_flag, "W_PRIMARY_MIXED_RIGHTS", NA_character_),
  SIMPLIFY = TRUE
)

event_audit_ledger <- events |>
  mutate(
    audit_issue_codes = event_issue_codes,
    audit_needs_review = !is.na(audit_issue_codes)
  ) |>
  arrange(event_inclusion_status, event_primary_exclusion_reason, desc(event_price_final), event_id)

incidence_issue_codes <- mapply(
  paste_codes,
  if_else(incidence$primary_price_alloc_usable & (is.na(incidence$event_price_alloc_allowed_res_area) | incidence$event_price_alloc_allowed_res_area <= 0), "E_PRIMARY_ALLOC_MISSING_OR_NONPOSITIVE", NA_character_),
  if_else(incidence$primary_price_alloc_complete & (!incidence$allocation_mappluto_complete | !incidence$allocation_allowed_res_area_observed_complete), "E_PRIMARY_COMPLETE_WITH_INCOMPLETE_DENOMINATOR", NA_character_),
  if_else(incidence$primary_price_alloc_complete & (is.na(incidence$price_per_allowed_res_sqft) | incidence$price_per_allowed_res_sqft <= 0 | !is.finite(incidence$price_per_allowed_res_sqft)), "E_PRIMARY_BAD_PRICE_PER_ALLOWED_SQFT", NA_character_),
  if_else(incidence$event_primary_private_sale & !incidence$primary_price_alloc_complete, "W_PRIMARY_INCOMPLETE_ALLOCATION", NA_character_),
  if_else(incidence$event_primary_private_sale & incidence$event_low_price_flag, "W_PRIMARY_LOW_PRICE", NA_character_),
  if_else(incidence$event_primary_private_sale & incidence$event_low_opportunity_share_flag, "W_PRIMARY_LOW_OPPORTUNITY_SHARE", NA_character_),
  if_else(incidence$event_primary_private_sale & incidence$related_party_weak_flag, "W_PRIMARY_WEAK_RELATED_PARTY", NA_character_),
  if_else(incidence$event_primary_private_sale & incidence$trust_estate_party_flag, "W_PRIMARY_TRUST_ESTATE_PARTY", NA_character_),
  if_else(incidence$event_primary_private_sale & incidence$mixed_rights_flag, "W_PRIMARY_MIXED_RIGHTS", NA_character_),
  SIMPLIFY = TRUE
)

incidence_audit_ledger <- incidence |>
  mutate(
    audit_issue_codes = incidence_issue_codes,
    audit_needs_review = !is.na(audit_issue_codes)
  ) |>
  arrange(incidence_primary_exclusion_reason, desc(event_price_alloc_allowed_res_area), event_id, opportunity_bbl)

event_locations <- incidence |>
  group_by(event_id) |>
  summarise(
    example_opportunity_bbls = paste(head(sort(unique(opportunity_bbl)), 5L), collapse = ";"),
    example_addresses = paste(head(sort(unique(address[!is.na(address) & address != ""])), 5L), collapse = " | "),
    example_boroughs = paste(head(sort(unique(opportunity_borough)), 5L), collapse = ";"),
    example_zipcodes = paste(head(sort(unique(zipcode[!is.na(zipcode)])), 5L), collapse = ";"),
    .groups = "drop"
  )

event_example_source <- events |>
  left_join(event_locations, by = "event_id", relationship = "one-to-one") |>
  mutate(example_addresses = if_else(example_addresses == "", NA_character_, example_addresses))

event_example_categories <- bind_rows(
  event_example_source |> transmute(event_id, category_family = "event_inclusion_status", category_value = event_inclusion_status),
  event_example_source |> transmute(event_id, category_family = "event_primary_exclusion_reason", category_value = event_primary_exclusion_reason),
  event_example_source |> transmute(event_id, category_family = "price_resolution_status", category_value = price_resolution_status),
  event_example_source |> transmute(event_id, category_family = "allocation_denominator_status", category_value = allocation_denominator_status),
  bind_rows(lapply(event_flag_columns, function(flag_column) {
    event_example_source[coalesce(event_example_source[[flag_column]], FALSE), , drop = FALSE] |>
      transmute(event_id, category_family = "event_flag", category_value = flag_column)
  }))
) |>
  filter(!is.na(category_value), category_value != "")

incidence_warning_categories <- bind_rows(lapply(seq_len(nrow(incidence)), function(row_number) {
  values <- split_codes(incidence$incidence_warning_codes[row_number])
  if (length(values) == 0L) {
    return(tibble())
  }

  tibble(
    event_id = incidence$event_id[row_number],
    category_family = "incidence_warning_code",
    category_value = values
  )
})) |>
  distinct()

examples_by_category <- bind_rows(event_example_categories, incidence_warning_categories) |>
  inner_join(event_example_source, by = "event_id", relationship = "many-to-one") |>
  arrange(category_family, category_value, desc(event_price_final), event_date_primary, event_id) |>
  group_by(category_family, category_value) |>
  mutate(example_rank = row_number()) |>
  filter(example_rank <= 5L) |>
  ungroup() |>
  select(
    category_family, category_value, example_rank,
    event_id, event_date_primary, event_quarter, event_price_final,
    event_inclusion_status, event_primary_exclusion_reason,
    price_resolution_status, event_count_resolution_status,
    allocation_denominator_status,
    event_low_price_flag, event_low_opportunity_share_flag,
    event_very_low_opportunity_share_flag,
    related_party_weak_flag, trust_estate_party_flag, mixed_rights_flag,
    unit_churn_flag, rights_only_flag,
    public_party_flag, hdfc_party_flag, housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag, related_party_strong_flag,
    buyer_names, seller_names, source_document_ids, crfns,
    example_opportunity_bbls, example_addresses, example_boroughs, example_zipcodes,
    reviewer_final_ruling, reviewer_notes, source_urls
  )

write_csv_if_changed(hard_checks, "../output/private_market_sale_hard_checks.csv")
write_csv_if_changed(event_column_audit, "../output/private_market_sale_event_column_audit.csv")
write_csv_if_changed(incidence_column_audit, "../output/private_market_sale_incidence_column_audit.csv")
write_csv_if_changed(event_category_counts, "../output/private_market_sale_event_category_counts.csv")
write_csv_if_changed(incidence_category_counts, "../output/private_market_sale_incidence_category_counts.csv")
write_csv_if_changed(event_flag_counts, "../output/private_market_sale_event_flag_counts.csv")
write_csv_if_changed(incidence_flag_counts, "../output/private_market_sale_incidence_flag_counts.csv")
write_csv_if_changed(event_denominator_completeness, "../output/private_market_sale_event_denominator_completeness.csv")
write_csv_if_changed(incidence_denominator_completeness, "../output/private_market_sale_incidence_denominator_completeness.csv")
write_csv_if_changed(price_distributions, "../output/private_market_sale_price_distributions.csv")
write_csv_if_changed(examples_by_category, "../output/private_market_sale_examples_by_category.csv")
write_csv_if_changed(event_audit_ledger, "../output/private_market_sale_event_audit_ledger.csv")
write_csv_if_changed(incidence_audit_ledger, "../output/private_market_sale_incidence_audit_ledger.csv")
cat("Wrote private-market ACRIS sales-layer audit outputs to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_private_market_site_sales/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

price_low_cutoff <- 250000
opportunity_share_cutoff <- 0.8
low_opportunity_share_cutoff <- 0.2

paste_codes <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(unique(values), collapse = ";")
}

events <- read_parquet("../input/acris_site_events.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    event_id = str_squish(as.character(event_id)),
    event_date_primary = as.Date(event_date_primary)
  )

incidence <- read_parquet("../input/acris_site_event_bbl_incidence.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    event_id = str_squish(as.character(event_id)),
    legal_bbl = normalize_bbl_field(legal_bbl),
    event_date_primary = as.Date(event_date_primary)
  )

mappluto_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    legal_bbl = normalize_bbl_field(bbl),
    mappluto_match = TRUE,
    opportunity_borough = borough,
    opportunity_block = block,
    opportunity_lot = lot,
    address, cd, zipcode, council,
    primary_opp50_850,
    soft_site_opp50_850,
    primary_opportunity_rule,
    lotarea,
    allowed_policy_res_sqft,
    residual_policy_res_sqft,
    capacity_units_850,
    capacity50_850,
    capacity100_850,
    capacity_exposure_pctile_citywide,
    capacity_exposure_quartile_citywide,
    capacity_exposure_pctile_borough,
    capacity_exposure_quartile_borough
  ) |>
  filter(!is.na(legal_bbl))

if (anyDuplicated(events$event_id) > 0L) {
  stop("Reviewed ACRIS site events are not unique by event_id.")
}

if (anyDuplicated(paste(incidence$event_id, incidence$legal_bbl, sep = "::")) > 0L) {
  stop("Reviewed ACRIS event-BBL incidence is not unique by event_id/legal_bbl.")
}

if (anyDuplicated(mappluto_lots$legal_bbl) > 0L) {
  stop("Frozen MapPLUTO lots are not unique by BBL.")
}

missing_incidence_events <- setdiff(incidence$event_id, events$event_id)
if (length(missing_incidence_events) > 0L) {
  stop("At least one incidence event_id is missing from reviewed ACRIS site events.")
}

incidence_with_lots <- incidence |>
  left_join(mappluto_lots, by = "legal_bbl", relationship = "many-to-one") |>
  mutate(
    mappluto_match = coalesce(mappluto_match, FALSE),
    primary_opp50_850 = coalesce(primary_opp50_850, FALSE),
    soft_site_opp50_850 = coalesce(soft_site_opp50_850, FALSE),
    positive_allowed_res_area = !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0,
    observed_allowed_res_area = !is.na(allowed_policy_res_sqft),
    positive_lotarea = !is.na(lotarea) & lotarea > 0
  )

bad_direct_rows <- incidence_with_lots |>
  filter(direct_opportunity_bbl_match, !primary_opp50_850)
if (nrow(bad_direct_rows) > 0L) {
  stop("A direct opportunity BBL incidence row does not match a primary frozen opportunity lot.")
}

event_denominators <- incidence_with_lots |>
  group_by(event_id) |>
  summarise(
    event_legal_bbl_count_incidence = n_distinct(legal_bbl),
    event_legal_bbl_count_mappluto = n_distinct(legal_bbl[mappluto_match]),
    event_legal_bbl_count_allowed_observed = n_distinct(legal_bbl[observed_allowed_res_area]),
    event_legal_bbl_count_allowed_positive = n_distinct(legal_bbl[positive_allowed_res_area]),
    event_legal_bbl_count_lotarea_positive = n_distinct(legal_bbl[positive_lotarea]),
    event_direct_opportunity_bbl_count = n_distinct(legal_bbl[direct_opportunity_bbl_match & primary_opp50_850]),
    event_all_legal_allowed_res_sqft_sum = sum(allowed_policy_res_sqft[positive_allowed_res_area], na.rm = TRUE),
    event_all_legal_lotarea_sum = sum(lotarea[positive_lotarea], na.rm = TRUE),
    event_direct_opportunity_allowed_res_sqft_sum = sum(allowed_policy_res_sqft[direct_opportunity_bbl_match & positive_allowed_res_area], na.rm = TRUE),
    event_direct_opportunity_lotarea_sum = sum(lotarea[direct_opportunity_bbl_match & positive_lotarea], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    event_all_legal_allowed_res_sqft_sum = if_else(event_all_legal_allowed_res_sqft_sum > 0, event_all_legal_allowed_res_sqft_sum, NA_real_),
    event_all_legal_lotarea_sum = if_else(event_all_legal_lotarea_sum > 0, event_all_legal_lotarea_sum, NA_real_),
    event_direct_opportunity_allowed_res_sqft_sum = if_else(event_direct_opportunity_allowed_res_sqft_sum > 0, event_direct_opportunity_allowed_res_sqft_sum, NA_real_),
    event_direct_opportunity_lotarea_sum = if_else(event_direct_opportunity_lotarea_sum > 0, event_direct_opportunity_lotarea_sum, NA_real_),
    allocation_mappluto_complete = event_legal_bbl_count_mappluto == event_legal_bbl_count_incidence,
    allocation_allowed_res_area_observed_complete = event_legal_bbl_count_allowed_observed == event_legal_bbl_count_incidence,
    allocation_allowed_res_area_positive_denominator = !is.na(event_all_legal_allowed_res_sqft_sum),
    allocation_lotarea_positive_denominator = !is.na(event_all_legal_lotarea_sum),
    allocation_denominator_status = case_when(
      !allocation_mappluto_complete ~ "missing_mappluto_for_some_legal_bbls",
      !allocation_allowed_res_area_observed_complete ~ "missing_allowed_res_area_for_some_legal_bbls",
      !allocation_allowed_res_area_positive_denominator ~ "no_positive_allowed_res_area_denominator",
      TRUE ~ "complete_allowed_res_area_denominator"
    )
  )

event_classification <- events |>
  mutate(
    resolved_priced_event = coalesce(has_final_price, FALSE) & !coalesce(exclude_from_default_price_totals, FALSE),
    unit_churn_flag = coalesce(unit_churn_flag, FALSE),
    rights_only_flag = coalesce(rights_only_flag, FALSE),
    mixed_rights_flag = coalesce(mixed_rights_flag, FALSE),
    public_party_flag = coalesce(public_party_flag, FALSE),
    hdfc_party_flag = coalesce(hdfc_party_flag, FALSE),
    housing_public_or_regulated_party_flag = coalesce(housing_public_or_regulated_party_flag, FALSE),
    nonprofit_religious_party_flag = coalesce(nonprofit_religious_party_flag, FALSE),
    trust_estate_party_flag = coalesce(trust_estate_party_flag, FALSE),
    related_party_strong_flag = coalesce(related_party_strong_flag, FALSE),
    related_party_weak_flag = coalesce(related_party_weak_flag, FALSE),
    event_low_price_flag = resolved_priced_event & !is.na(event_price_final) & event_price_final <= price_low_cutoff,
    event_low_opportunity_share_flag = resolved_priced_event &
      (
        (!is.na(event_opp_share_allowed_res_area) & event_opp_share_allowed_res_area < opportunity_share_cutoff) |
          (is.na(event_opp_share_allowed_res_area) & !is.na(event_opp_share_lotarea) & event_opp_share_lotarea < opportunity_share_cutoff)
      ),
    event_very_low_opportunity_share_flag = resolved_priced_event &
      (
        (!is.na(event_opp_share_allowed_res_area) & event_opp_share_allowed_res_area < low_opportunity_share_cutoff) |
          (is.na(event_opp_share_allowed_res_area) & !is.na(event_opp_share_lotarea) & event_opp_share_lotarea < low_opportunity_share_cutoff)
      ),
    event_primary_exclusion_reason = case_when(
      !resolved_priced_event & price_resolution_status == "manual_unresolved_after_review" ~ "unresolved_after_review",
      !resolved_priced_event & price_resolution_status == "manual_confirmed_no_site_price" ~ "no_site_price",
      !resolved_priced_event & !coalesce(has_final_price, FALSE) ~ "no_final_price",
      !resolved_priced_event & coalesce(exclude_from_default_price_totals, FALSE) ~ "excluded_from_default_price_totals",
      unit_churn_flag ~ "unit_condo_timeshare_churn",
      rights_only_flag ~ "rights_only",
      housing_public_or_regulated_party_flag | public_party_flag | hdfc_party_flag ~ "public_hdfc_housing_regulated",
      nonprofit_religious_party_flag ~ "nonprofit_religious_institutional",
      related_party_strong_flag ~ "strong_related_party",
      TRUE ~ NA_character_
    ),
    event_primary_private_candidate = resolved_priced_event & is.na(event_primary_exclusion_reason),
    event_broad_priced_transfer_candidate = resolved_priced_event &
      !unit_churn_flag &
      !rights_only_flag &
      !(housing_public_or_regulated_party_flag | public_party_flag | hdfc_party_flag),
    event_strict_private_candidate = event_primary_private_candidate &
      !related_party_weak_flag &
      !trust_estate_party_flag &
      !mixed_rights_flag &
      !event_low_price_flag &
      !event_low_opportunity_share_flag
  ) |>
  left_join(event_denominators, by = "event_id", relationship = "one-to-one") |>
  mutate(
    event_has_direct_opportunity_bbl = coalesce(event_direct_opportunity_bbl_count, 0L) > 0L,
    event_primary_private_sale = event_primary_private_candidate & event_has_direct_opportunity_bbl,
    event_strict_private_sale = event_strict_private_candidate & event_has_direct_opportunity_bbl,
    event_broad_priced_transfer = event_broad_priced_transfer_candidate & event_has_direct_opportunity_bbl,
    event_primary_exclusion_reason = case_when(
      event_primary_private_candidate & !event_has_direct_opportunity_bbl ~ "no_direct_opportunity_bbl",
      TRUE ~ event_primary_exclusion_reason
    ),
    event_inclusion_status = case_when(
      event_primary_private_sale ~ "primary_private_market_sale",
      event_broad_priced_transfer ~ "broad_priced_transfer_only",
      resolved_priced_event ~ "priced_excluded_from_primary",
      TRUE ~ "not_priced_sale_event"
    )
  )

sale_events <- event_classification |>
  filter(resolved_priced_event) |>
  arrange(event_date_primary, event_id)

sale_incidence <- incidence_with_lots |>
  filter(direct_opportunity_bbl_match, primary_opp50_850) |>
  inner_join(
    sale_events |>
      select(
        event_id, event_price_final,
        event_primary_exclusion_reason, event_inclusion_status,
        event_primary_private_sale, event_strict_private_sale,
        event_broad_priced_transfer, event_low_price_flag,
        event_low_opportunity_share_flag, event_very_low_opportunity_share_flag,
        unit_churn_flag, rights_only_flag, mixed_rights_flag,
        public_party_flag, hdfc_party_flag, housing_public_or_regulated_party_flag,
        nonprofit_religious_party_flag, trust_estate_party_flag,
        related_party_strong_flag, related_party_weak_flag,
        event_opp_share_allowed_res_area, event_opp_share_lotarea,
        event_legal_bbl_count_incidence, event_legal_bbl_count_mappluto,
        event_legal_bbl_count_allowed_observed,
        event_legal_bbl_count_allowed_positive,
        event_legal_bbl_count_lotarea_positive,
        event_direct_opportunity_bbl_count,
        event_all_legal_allowed_res_sqft_sum,
        event_all_legal_lotarea_sum,
        event_direct_opportunity_allowed_res_sqft_sum,
        event_direct_opportunity_lotarea_sum,
        allocation_mappluto_complete,
        allocation_allowed_res_area_observed_complete,
        allocation_allowed_res_area_positive_denominator,
        allocation_lotarea_positive_denominator,
        allocation_denominator_status,
        source_document_ids, crfns, buyer_names, seller_names,
        document_market_statuses, document_exclusion_codes, document_warning_codes,
        review_cluster_id, reviewer_final_ruling, manual_review_status,
        price_rule, source_confidence
      ),
    by = "event_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    event_quarter_start = floor_date(event_date_primary, "quarter"),
    alloc_weight_allowed_res_area_all_legal = if_else(
      allocation_allowed_res_area_positive_denominator & positive_allowed_res_area,
      allowed_policy_res_sqft / event_all_legal_allowed_res_sqft_sum,
      NA_real_
    ),
    alloc_weight_lotarea_all_legal = if_else(
      allocation_lotarea_positive_denominator & positive_lotarea,
      lotarea / event_all_legal_lotarea_sum,
      NA_real_
    ),
    alloc_weight_equal_all_legal = if_else(
      event_legal_bbl_count_incidence > 0L,
      1 / event_legal_bbl_count_incidence,
      NA_real_
    ),
    event_price_alloc_allowed_res_area = event_price_final * alloc_weight_allowed_res_area_all_legal,
    event_price_alloc_lotarea = event_price_final * alloc_weight_lotarea_all_legal,
    event_price_alloc_equal = event_price_final * alloc_weight_equal_all_legal,
    price_per_allowed_res_sqft = event_price_alloc_allowed_res_area / allowed_policy_res_sqft,
    price_per_lot_sqft = event_price_alloc_lotarea / lotarea,
    primary_price_alloc_usable = event_primary_private_sale & !is.na(event_price_alloc_allowed_res_area),
    primary_price_alloc_complete = primary_price_alloc_usable &
      allocation_mappluto_complete &
      allocation_allowed_res_area_observed_complete,
    strict_price_alloc_complete = primary_price_alloc_complete & event_strict_private_sale,
    broad_price_alloc_usable = event_broad_priced_transfer & !is.na(event_price_alloc_allowed_res_area),
    incidence_primary_exclusion_reason = case_when(
      primary_price_alloc_usable ~ "included_primary",
      event_primary_private_sale & is.na(event_price_alloc_allowed_res_area) ~ "allocation_missing_allowed_res_area",
      !is.na(event_primary_exclusion_reason) ~ event_primary_exclusion_reason,
      TRUE ~ "not_primary_private_market_sale"
    ),
    incidence_warning_codes = mapply(
      paste_codes,
      if_else(!allocation_mappluto_complete, "W_INCOMPLETE_MAPPLUTO_LEGAL_BBL_DENOMINATOR", NA_character_),
      if_else(!allocation_allowed_res_area_observed_complete, "W_INCOMPLETE_ALLOWED_RES_AREA_DENOMINATOR", NA_character_),
      if_else(event_low_opportunity_share_flag, "W_LOW_OPPORTUNITY_SHARE", NA_character_),
      if_else(event_very_low_opportunity_share_flag, "W_VERY_LOW_OPPORTUNITY_SHARE", NA_character_),
      if_else(event_low_price_flag, "W_LOW_EVENT_PRICE", NA_character_),
      if_else(related_party_weak_flag, "W_WEAK_RELATED_PARTY", NA_character_),
      if_else(trust_estate_party_flag, "W_TRUST_ESTATE_PARTY", NA_character_),
      if_else(mixed_rights_flag, "W_MIXED_RIGHTS", NA_character_),
      SIMPLIFY = TRUE
    )
  ) |>
  select(
    event_id, opportunity_bbl = legal_bbl, event_date_primary, event_quarter_start,
    event_quarter, event_price_final, price_resolution_status,
    event_count_resolution_status, event_inclusion_status,
    event_primary_private_sale, event_strict_private_sale,
    event_broad_priced_transfer, primary_price_alloc_usable,
    primary_price_alloc_complete, strict_price_alloc_complete,
    broad_price_alloc_usable, event_primary_exclusion_reason,
    incidence_primary_exclusion_reason, incidence_warning_codes,
    legal_borough, legal_block, legal_lot,
    opportunity_borough, opportunity_block, opportunity_lot,
    address, cd, zipcode, council, primary_opportunity_rule,
    primary_opp50_850, soft_site_opp50_850,
    lotarea, allowed_policy_res_sqft, residual_policy_res_sqft,
    capacity_units_850, capacity50_850, capacity100_850,
    capacity_exposure_pctile_citywide, capacity_exposure_quartile_citywide,
    capacity_exposure_pctile_borough, capacity_exposure_quartile_borough,
    event_legal_bbl_count_incidence, event_legal_bbl_count_mappluto,
    event_legal_bbl_count_allowed_observed,
    event_legal_bbl_count_allowed_positive,
    event_legal_bbl_count_lotarea_positive,
    event_direct_opportunity_bbl_count,
    event_all_legal_allowed_res_sqft_sum,
    event_all_legal_lotarea_sum,
    event_direct_opportunity_allowed_res_sqft_sum,
    event_direct_opportunity_lotarea_sum,
    allocation_mappluto_complete,
    allocation_allowed_res_area_observed_complete,
    allocation_allowed_res_area_positive_denominator,
    allocation_lotarea_positive_denominator,
    allocation_denominator_status,
    alloc_weight_allowed_res_area_all_legal,
    alloc_weight_lotarea_all_legal,
    alloc_weight_equal_all_legal,
    event_price_alloc_allowed_res_area,
    event_price_alloc_lotarea,
    event_price_alloc_equal,
    price_per_allowed_res_sqft, price_per_lot_sqft,
    event_low_price_flag, event_low_opportunity_share_flag,
    event_very_low_opportunity_share_flag,
    unit_churn_flag, rights_only_flag, mixed_rights_flag,
    public_party_flag, hdfc_party_flag, housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag, trust_estate_party_flag,
    related_party_strong_flag, related_party_weak_flag,
    event_opp_share_allowed_res_area, event_opp_share_lotarea,
    source_document_ids, crfns, buyer_names, seller_names,
    document_market_statuses, document_exclusion_codes, document_warning_codes,
    review_cluster_id, reviewer_final_ruling, manual_review_status,
    price_rule, source_confidence
  ) |>
  arrange(event_date_primary, event_id, opportunity_bbl)

if (anyDuplicated(sale_events$event_id) > 0L) {
  stop("Private-market site sale event classification is not unique by event_id.")
}

if (anyDuplicated(paste(sale_incidence$event_id, sale_incidence$opportunity_bbl, sep = "::")) > 0L) {
  stop("Private-market site sale incidence is not unique by event_id/opportunity_bbl.")
}

bad_primary_prices <- sale_incidence |>
  filter(primary_price_alloc_usable, is.na(event_price_alloc_allowed_res_area) | event_price_alloc_allowed_res_area <= 0)
if (nrow(bad_primary_prices) > 0L) {
  stop("Primary price-usable incidence rows have missing or nonpositive allocated prices.")
}

event_weight_checks <- sale_incidence |>
  group_by(event_id) |>
  summarise(
    direct_alloc_weight_allowed_res_area_sum = sum(alloc_weight_allowed_res_area_all_legal, na.rm = TRUE),
    direct_alloc_weight_lotarea_sum = sum(alloc_weight_lotarea_all_legal, na.rm = TRUE),
    direct_alloc_weight_equal_sum = sum(alloc_weight_equal_all_legal, na.rm = TRUE),
    .groups = "drop"
  )

if (any(event_weight_checks$direct_alloc_weight_allowed_res_area_sum > 1 + 1e-8, na.rm = TRUE)) {
  stop("Direct opportunity allowed-residential-area allocation weights exceed one for at least one event.")
}

if (any(event_weight_checks$direct_alloc_weight_lotarea_sum > 1 + 1e-8, na.rm = TRUE)) {
  stop("Direct opportunity lot-area allocation weights exceed one for at least one event.")
}

write_parquet_if_changed(sale_events, "../output/acris_private_market_site_sale_events.parquet")
write_parquet_if_changed(sale_incidence, "../output/acris_private_market_site_sale_bbl_incidence.parquet")
cat("Built ACRIS private-market site sale events and BBL incidence to ../output\n")

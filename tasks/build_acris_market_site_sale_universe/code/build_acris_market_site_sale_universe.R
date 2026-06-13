# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_market_site_sale_universe/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

price_nominal_cutoff <- 10000
price_low_cutoff <- 250000
price_per_allowed_sqft_low_cutoff <- 5
primary_opportunity_share_cutoff <- 0.8
sensitivity_opportunity_share_cutoff <- 0.5

clean_upper <- function(x) {
  out <- str_to_upper(str_squish(as.character(x)))
  out[out %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  out
}

normalize_party_name <- function(x) {
  out <- clean_upper(x)
  out <- str_replace_all(out, "&", " AND ")
  out <- str_replace_all(out, "[^A-Z0-9]+", " ")
  out <- str_replace_all(out, "\\bL\\s+L\\s+C\\b", " LLC ")
  out <- str_squish(out)
  out[out == ""] <- NA_character_
  out
}

normalize_party_core <- function(x) {
  out <- normalize_party_name(x)
  out <- str_replace_all(out, "\\b(THE|A|AN)\\b", " ")
  out <- str_replace_all(out, "\\b(LLC|LTD|INC|CORP|CORPORATION|CO|COMPANY|LP|LLP|PC|PLLC)\\b", " ")
  out <- str_replace_all(out, "\\b(REALTY|HOLDINGS|HOLDING|PROPERTIES|PROPERTY|DEVELOPMENT|DEVELOPER|ASSOCIATES|GROUP)\\b", " ")
  out <- str_squish(out)
  out[out == ""] <- NA_character_
  out
}

normalize_address_core <- function(address_1, city, state, zip) {
  out <- clean_upper(paste(
    coalesce(as.character(address_1), ""),
    coalesce(as.character(city), ""),
    coalesce(as.character(state), ""),
    coalesce(as.character(zip), "")
  ))
  out <- str_replace_all(out, "[^A-Z0-9]+", " ")
  out <- str_squish(out)
  out[out == ""] <- NA_character_
  out
}

has_regex_match <- function(x, regex_values) {
  if (length(regex_values) == 0L) {
    return(rep(FALSE, length(x)))
  }

  str_detect(coalesce(x, ""), regex(paste(regex_values, collapse = "|"), ignore_case = TRUE))
}

collapse_unique <- function(x) {
  values <- sort(unique(as.character(x[!is.na(x) & x != ""])))
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(values, collapse = ";")
}

has_set_overlap <- function(a, b) {
  a_values <- unlist(str_split(coalesce(a, ""), ";", simplify = FALSE))
  b_values <- unlist(str_split(coalesce(b, ""), ";", simplify = FALSE))
  a_values <- a_values[!is.na(a_values) & a_values != ""]
  b_values <- b_values[!is.na(b_values) & b_values != ""]

  if (length(a_values) == 0L || length(b_values) == 0L) {
    return(FALSE)
  }

  length(intersect(a_values, b_values)) > 0L
}

paste_codes <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0L) {
    return(NA_character_)
  }

  paste(unique(values), collapse = ";")
}

event_quarter <- function(x) {
  month_value <- suppressWarnings(as.integer(format(x, "%m")))
  quarter_value <- ((month_value - 1L) %/% 3L) + 1L
  out <- paste0(format(x, "%Y"), "Q", quarter_value)
  out[is.na(x)] <- NA_character_
  out
}

party_terms <- read_csv("party_classification_terms.csv", show_col_types = FALSE, na = c("", "NA")) |>
  mutate(
    term_category = str_squish(as.character(term_category)),
    regex = as.character(regex)
  )

deed_master <- read_parquet("../input/acris_deed_master.parquet") |>
  as.data.frame() |>
  as_tibble()

all_legals <- read_parquet("../input/acris_direct_deed_all_legals.parquet") |>
  as.data.frame() |>
  as_tibble()

direct_parties <- read_parquet("../input/acris_direct_opportunity_deed_parties.parquet") |>
  as.data.frame() |>
  as_tibble()

mappluto_lots <- read_parquet("../input/mappluto_opportunity_lots_frozen.parquet") |>
  as.data.frame() |>
  as_tibble()

if (anyDuplicated(deed_master$document_id) > 0L) {
  stop("ACRIS DEED master is not unique by document_id.")
}

if (anyDuplicated(direct_parties$direct_party_record_id) > 0L) {
  stop("Direct party rows are not unique by direct_party_record_id.")
}

mappluto_bbls <- mappluto_lots |>
  mutate(bbl = normalize_bbl_field(bbl)) |>
  filter(!is.na(bbl)) |>
  transmute(
    legal_bbl = bbl,
    mappluto_match = TRUE,
    mappluto_borough = borough,
    mappluto_block = suppressWarnings(as.integer(block)),
    mappluto_lot = suppressWarnings(as.integer(lot)),
    mappluto_address = address,
    primary_opp50_850,
    soft_site_opp50_850,
    allowed_policy_res_sqft,
    lotarea,
    landuse,
    bldgclass,
    zone_detail,
    capacity_units_850,
    capacity100_850,
    capacity_exposure_quartile_citywide,
    capacity_exposure_quartile_borough
  )

if (anyDuplicated(mappluto_bbls$legal_bbl) > 0L) {
  stop("Frozen MapPLUTO BBL file is not unique by BBL.")
}

direct_document_ids <- all_legals |>
  transmute(document_id = str_squish(as.character(document_id))) |>
  filter(!is.na(document_id), document_id != "") |>
  distinct()

if (nrow(direct_document_ids) == 0L) {
  stop("No direct DEED documents are available in all-legals.")
}

party_rows <- direct_parties |>
  mutate(
    party_type = clean_upper(party_type),
    party_side = case_when(
      str_detect(coalesce(party_type, ""), "^1|GRANTOR|SELLER|TRANSFEROR") ~ "seller",
      str_detect(coalesce(party_type, ""), "^2|GRANTEE|BUYER|TRANSFEREE") ~ "buyer",
      TRUE ~ "other"
    ),
    party_name_clean = normalize_party_name(party_name),
    party_name_core = normalize_party_core(party_name),
    party_address_core = normalize_address_core(address_1, city, state, zip),
    public_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "public"]),
    hdfc_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "hdfc"]),
    nonprofit_religious_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "nonprofit_religious"]),
    trust_estate_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "trust_estate"]),
    timeshare_hotel_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "timeshare_hotel"]),
    related_terms_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "related_terms"]),
    llc_flag = has_regex_match(party_name_clean, party_terms$regex[party_terms$term_category == "llc"])
  )

party_summary_side <- party_rows |>
  filter(party_side %in% c("buyer", "seller")) |>
  group_by(document_id, party_side) |>
  summarise(
    party_names = collapse_unique(party_name_clean),
    party_name_cores = collapse_unique(party_name_core),
    party_address_cores = collapse_unique(party_address_core),
    public_flag = any(public_flag, na.rm = TRUE),
    hdfc_flag = any(hdfc_flag, na.rm = TRUE),
    nonprofit_religious_flag = any(nonprofit_religious_flag, na.rm = TRUE),
    trust_estate_flag = any(trust_estate_flag, na.rm = TRUE),
    timeshare_hotel_flag = any(timeshare_hotel_flag, na.rm = TRUE),
    related_terms_flag = any(related_terms_flag, na.rm = TRUE),
    llc_flag = any(llc_flag, na.rm = TRUE),
    .groups = "drop"
  )

buyer_summary <- party_summary_side |>
  filter(party_side == "buyer") |>
  transmute(
    document_id,
    buyer_names = party_names,
    buyer_party_set_key = party_name_cores,
    buyer_address_set_key = party_address_cores,
    buyer_public_flag = public_flag,
    buyer_hdfc_flag = hdfc_flag,
    buyer_nonprofit_religious_flag = nonprofit_religious_flag,
    buyer_trust_estate_flag = trust_estate_flag,
    buyer_timeshare_hotel_flag = timeshare_hotel_flag,
    buyer_related_terms_flag = related_terms_flag,
    buyer_llc_flag = llc_flag
  )

seller_summary <- party_summary_side |>
  filter(party_side == "seller") |>
  transmute(
    document_id,
    seller_names = party_names,
    seller_party_set_key = party_name_cores,
    seller_address_set_key = party_address_cores,
    seller_public_flag = public_flag,
    seller_hdfc_flag = hdfc_flag,
    seller_nonprofit_religious_flag = nonprofit_religious_flag,
    seller_trust_estate_flag = trust_estate_flag,
    seller_timeshare_hotel_flag = timeshare_hotel_flag,
    seller_related_terms_flag = related_terms_flag,
    seller_llc_flag = llc_flag
  )

party_summary <- direct_document_ids |>
  left_join(buyer_summary, by = "document_id", relationship = "one-to-one") |>
  left_join(seller_summary, by = "document_id", relationship = "one-to-one") |>
  mutate(
    has_buyer_party = !is.na(buyer_party_set_key),
    has_seller_party = !is.na(seller_party_set_key),
    party_name_overlap_flag = mapply(has_set_overlap, buyer_party_set_key, seller_party_set_key),
    party_address_overlap_flag = mapply(has_set_overlap, buyer_address_set_key, seller_address_set_key),
    party_related_terms_any_flag = coalesce(buyer_related_terms_flag, FALSE) | coalesce(seller_related_terms_flag, FALSE),
    strong_related_party_flag = party_name_overlap_flag | (party_address_overlap_flag & party_related_terms_any_flag),
    weak_related_party_flag = party_address_overlap_flag & !strong_related_party_flag,
    public_party_flag = coalesce(buyer_public_flag, FALSE) | coalesce(seller_public_flag, FALSE),
    hdfc_party_flag = coalesce(buyer_hdfc_flag, FALSE) | coalesce(seller_hdfc_flag, FALSE),
    housing_public_or_regulated_party_flag = public_party_flag | hdfc_party_flag,
    nonprofit_religious_party_flag = coalesce(buyer_nonprofit_religious_flag, FALSE) | coalesce(seller_nonprofit_religious_flag, FALSE),
    buyer_institutional_nonmarket_flag = coalesce(buyer_nonprofit_religious_flag, FALSE) | coalesce(buyer_public_flag, FALSE) | coalesce(buyer_hdfc_flag, FALSE),
    trust_estate_party_flag = coalesce(buyer_trust_estate_flag, FALSE) | coalesce(seller_trust_estate_flag, FALSE),
    timeshare_hotel_party_flag = coalesce(buyer_timeshare_hotel_flag, FALSE) | coalesce(seller_timeshare_hotel_flag, FALSE),
    llc_party_flag = coalesce(buyer_llc_flag, FALSE) | coalesce(seller_llc_flag, FALSE)
  )

legal_rows_clean <- all_legals |>
  mutate(
    legal_bbl = normalize_bbl_field(legal_bbl),
    legal_borough = standardize_borough_code(legal_borough),
    legal_block = suppressWarnings(as.integer(legal_block)),
    legal_lot = suppressWarnings(as.integer(legal_lot)),
    legal_block_key = if_else(!is.na(legal_borough) & !is.na(legal_block), paste(legal_borough, legal_block, sep = "-"), NA_character_),
    unit_clean = clean_upper(unit),
    unit_present_flag = !is.na(unit_clean) & unit_clean != "(-)",
    property_type_clean = clean_upper(property_type),
    legal_right_flag = (!is.na(easement) & easement != "" & easement != "N") |
      (!is.na(air_rights) & air_rights != "" & air_rights != "N") |
      (!is.na(subterranean_rights) & subterranean_rights != "" & subterranean_rights != "N")
  )

document_legal_bbls <- legal_rows_clean |>
  filter(valid_legal_bbl, !is.na(legal_bbl)) |>
  group_by(document_id, legal_bbl, legal_borough, legal_block, legal_lot, legal_block_key) |>
  summarise(
    legal_rows = n(),
    direct_opportunity_bbl_match = any(direct_opportunity_bbl_match, na.rm = TRUE),
    has_unit_legal_row = any(unit_present_flag, na.rm = TRUE),
    has_right_flag = any(legal_right_flag, na.rm = TRUE),
    has_easement_flag = any(!is.na(easement) & easement != "" & easement != "N", na.rm = TRUE),
    has_air_rights_flag = any(!is.na(air_rights) & air_rights != "" & air_rights != "N", na.rm = TRUE),
    has_subterranean_rights_flag = any(!is.na(subterranean_rights) & subterranean_rights != "" & subterranean_rights != "N", na.rm = TRUE),
    property_types = collapse_unique(property_type_clean),
    units = collapse_unique(unit_clean),
    n_distinct_units = n_distinct(unit_clean[!is.na(unit_clean) & unit_clean != "(-)"]),
    .groups = "drop"
  ) |>
  left_join(mappluto_bbls, by = "legal_bbl", relationship = "many-to-one") |>
  mutate(
    mappluto_match = coalesce(mappluto_match, FALSE),
    primary_opp50_850 = coalesce(primary_opp50_850, FALSE),
    soft_site_opp50_850 = coalesce(soft_site_opp50_850, FALSE),
    allowed_policy_res_sqft_positive = !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0,
    lotarea_positive = !is.na(lotarea) & lotarea > 0
  )

if (anyDuplicated(paste(document_legal_bbls$document_id, document_legal_bbls$legal_bbl, sep = "::")) > 0L) {
  stop("Document legal BBLs are not unique by document_id/legal_bbl.")
}

document_legal_summary <- document_legal_bbls |>
  group_by(document_id) |>
  summarise(
    n_all_legal_bbls = n_distinct(legal_bbl),
    n_opportunity_legal_bbls = n_distinct(legal_bbl[direct_opportunity_bbl_match]),
    legal_bbls = collapse_unique(legal_bbl),
    opportunity_bbls = collapse_unique(legal_bbl[direct_opportunity_bbl_match]),
    n_legal_boroughs = n_distinct(legal_borough[!is.na(legal_borough)]),
    n_legal_blocks = n_distinct(legal_block_key[!is.na(legal_block_key)]),
    n_legal_bbls_with_mappluto = sum(mappluto_match, na.rm = TRUE),
    all_legal_bbls_in_borough_1_4_flag = all(legal_borough %in% c("1", "2", "3", "4")),
    any_legal_bbl_outside_borough_1_4_flag = any(!legal_borough %in% c("1", "2", "3", "4")),
    has_unit_legal_row = any(has_unit_legal_row, na.rm = TRUE),
    n_distinct_units = sum(n_distinct_units, na.rm = TRUE),
    has_right_flag = any(has_right_flag, na.rm = TRUE),
    rights_only_flag = all(has_right_flag),
    mixed_rights_fee_flag = any(has_right_flag) & !all(has_right_flag),
    has_air_rights_flag = any(has_air_rights_flag, na.rm = TRUE),
    has_easement_flag = any(has_easement_flag, na.rm = TRUE),
    has_subterranean_rights_flag = any(has_subterranean_rights_flag, na.rm = TRUE),
    property_types = collapse_unique(property_types),
    unit_property_type_flag = any(str_detect(coalesce(property_types, ""), "CONDO|COOP|CO-OP|UNIT|TIME|TIMESHARE|APART|SC"), na.rm = TRUE),
    timeshare_property_type_flag = any(str_detect(coalesce(property_types, ""), "TIME|TIMESHARE"), na.rm = TRUE),
    all_legal_allowed_res_area_sum = sum(allowed_policy_res_sqft[allowed_policy_res_sqft_positive], na.rm = TRUE),
    opp_legal_allowed_res_area_sum = sum(allowed_policy_res_sqft[allowed_policy_res_sqft_positive & direct_opportunity_bbl_match], na.rm = TRUE),
    all_legal_lotarea_sum = sum(lotarea[lotarea_positive], na.rm = TRUE),
    opp_legal_lotarea_sum = sum(lotarea[lotarea_positive & direct_opportunity_bbl_match], na.rm = TRUE),
    all_legal_capacity_bbls = sum(allowed_policy_res_sqft_positive, na.rm = TRUE),
    all_legal_lotarea_bbls = sum(lotarea_positive, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    all_legal_allowed_res_area_sum = if_else(all_legal_allowed_res_area_sum > 0, all_legal_allowed_res_area_sum, NA_real_),
    opp_legal_allowed_res_area_sum = if_else(opp_legal_allowed_res_area_sum > 0, opp_legal_allowed_res_area_sum, NA_real_),
    all_legal_lotarea_sum = if_else(all_legal_lotarea_sum > 0, all_legal_lotarea_sum, NA_real_),
    opp_legal_lotarea_sum = if_else(opp_legal_lotarea_sum > 0, opp_legal_lotarea_sum, NA_real_),
    event_opp_share_allowed_res_area = opp_legal_allowed_res_area_sum / all_legal_allowed_res_area_sum,
    event_opp_share_lotarea = opp_legal_lotarea_sum / all_legal_lotarea_sum
  )

documents <- direct_document_ids |>
  inner_join(deed_master, by = "document_id", relationship = "many-to-one") |>
  left_join(party_summary, by = "document_id", relationship = "one-to-one") |>
  left_join(document_legal_summary, by = "document_id", relationship = "one-to-one") |>
  mutate(
    document_date_key = format(document_date, "%Y-%m-%d"),
    document_amt_key = as.character(round(document_amt)),
    amount_class = case_when(
      is.na(document_amt) ~ "MISSING",
      document_amt == 0 ~ "ZERO",
      document_amt > 0 & document_amt <= price_nominal_cutoff ~ "NOMINAL",
      document_amt > price_nominal_cutoff & document_amt <= price_low_cutoff ~ "LOW",
      document_amt > price_low_cutoff ~ "MARKET_CANDIDATE",
      TRUE ~ "MISSING"
    ),
    deed_percent_trans_100 = !is.na(percent_trans) & percent_trans == 100,
    percent_trans_missing_flag = is.na(percent_trans),
    percent_trans_partial_flag = !is.na(percent_trans) & percent_trans > 0 & percent_trans < 100,
    percent_trans_invalid_flag = !is.na(percent_trans) & (percent_trans <= 0 | percent_trans > 100),
    unit_churn_flag = coalesce(has_unit_legal_row, FALSE) | coalesce(unit_property_type_flag, FALSE) | coalesce(timeshare_property_type_flag, FALSE) | coalesce(timeshare_hotel_party_flag, FALSE),
    price_per_allowed_res_sqft = document_amt / all_legal_allowed_res_area_sum,
    low_price_flag = amount_class %in% c("LOW") |
      (!is.na(price_per_allowed_res_sqft) & price_per_allowed_res_sqft < price_per_allowed_sqft_low_cutoff),
    local_site_flag = coalesce(n_legal_boroughs, 0L) == 1L & coalesce(n_legal_blocks, 0L) <= 2L & coalesce(n_all_legal_bbls, 0L) <= 10L,
    opportunity_share_primary_flag = coalesce(event_opp_share_allowed_res_area, 0) >= primary_opportunity_share_cutoff |
      (is.na(event_opp_share_allowed_res_area) & coalesce(event_opp_share_lotarea, 0) >= primary_opportunity_share_cutoff),
    opportunity_share_sensitivity_flag = coalesce(event_opp_share_allowed_res_area, 0) >= sensitivity_opportunity_share_cutoff |
      (is.na(event_opp_share_allowed_res_area) & coalesce(event_opp_share_lotarea, 0) >= sensitivity_opportunity_share_cutoff),
    legal_bbl_set_key = coalesce(legal_bbls, ""),
    opportunity_bbl_set_key = coalesce(opportunity_bbls, ""),
    buyer_party_set_key = coalesce(buyer_party_set_key, ""),
    seller_party_set_key = coalesce(seller_party_set_key, ""),
    exact_duplicate_group_key = paste(
      document_date_key,
      document_amt_key,
      buyer_party_set_key,
      seller_party_set_key,
      legal_bbl_set_key,
      sep = "::"
    ),
    buyer_date_amount_key = paste(document_date_key, document_amt_key, buyer_party_set_key, sep = "::"),
    buyer_date_key = paste(document_date_key, buyer_party_set_key, sep = "::")
  )

documents <- documents |>
  group_by(exact_duplicate_group_key) |>
  arrange(document_id, .by_group = TRUE) |>
  mutate(
    exact_duplicate_group_docs = n(),
    exact_duplicate_representative_document_id = first(document_id),
    duplicate_price_excluded_flag = exact_duplicate_group_docs > 1L & document_id != exact_duplicate_representative_document_id,
    event_id = paste0("acris_market_", exact_duplicate_representative_document_id),
    cluster_rule = if_else(exact_duplicate_group_docs > 1L, "exact_duplicate_same_buyer_seller_date_amount_legal_set", "single_document")
  ) |>
  ungroup() |>
  group_by(buyer_date_amount_key) |>
  mutate(same_buyer_date_amount_docs = n_distinct(document_id)) |>
  ungroup() |>
  group_by(buyer_date_key) |>
  mutate(same_buyer_date_docs = n_distinct(document_id)) |>
  ungroup() |>
  mutate(
    ambiguous_same_buyer_date_amount_flag = same_buyer_date_amount_docs > exact_duplicate_group_docs,
    ambiguous_same_buyer_date_flag = same_buyer_date_docs > exact_duplicate_group_docs & amount_class %in% c("MARKET_CANDIDATE", "LOW")
  )

document_bbl_cluster_risk <- document_legal_bbls |>
  select(document_id, legal_bbl) |>
  inner_join(
    documents |>
      select(document_id, buyer_date_key, buyer_party_set_key, document_date, amount_class),
    by = "document_id",
    relationship = "many-to-one"
  ) |>
  filter(amount_class %in% c("MARKET_CANDIDATE", "LOW")) |>
  group_by(buyer_date_key, legal_bbl) |>
  summarise(buyer_date_bbl_docs = n_distinct(document_id), .groups = "drop") |>
  filter(buyer_date_bbl_docs > 1L)

documents <- documents |>
  left_join(
    document_legal_bbls |>
      select(document_id, legal_bbl) |>
      inner_join(
        documents |> select(document_id, buyer_date_key),
        by = "document_id",
        relationship = "many-to-one"
      ) |>
      inner_join(
        document_bbl_cluster_risk,
        by = c("buyer_date_key", "legal_bbl"),
        relationship = "many-to-one"
      ) |>
      distinct(document_id) |>
      mutate(same_bbl_date_buyer_repeated_flag = TRUE),
    by = "document_id",
    relationship = "one-to-one"
  ) |>
  mutate(same_bbl_date_buyer_repeated_flag = coalesce(same_bbl_date_buyer_repeated_flag, FALSE))

documents <- documents |>
  mutate(
    document_exclusion_codes = mapply(
      paste_codes,
      if_else(!has_buyer_party | !has_seller_party, "X_INCOMPLETE_PARTIES", NA_character_),
      if_else(n_opportunity_legal_bbls == 0L | is.na(n_opportunity_legal_bbls), "X_NO_OPPORTUNITY_BBL", NA_character_),
      if_else(amount_class == "ZERO", "X_ZERO_STANDALONE", NA_character_),
      if_else(amount_class == "NOMINAL", "X_NOMINAL_STANDALONE", NA_character_),
      if_else(amount_class == "LOW" | low_price_flag, "X_LOW_PRICE", NA_character_),
      if_else(!deed_percent_trans_100, "X_PERCENT_NOT_100", NA_character_),
      if_else(unit_churn_flag, "X_UNIT_CHURN", NA_character_),
      if_else(coalesce(rights_only_flag, FALSE), "X_RIGHTS_ONLY", NA_character_),
      if_else(coalesce(housing_public_or_regulated_party_flag, FALSE), "X_HOUSING_PUBLIC_OR_REGULATED", NA_character_),
      if_else(coalesce(buyer_institutional_nonmarket_flag, FALSE), "X_INSTITUTIONAL_BUYER", NA_character_),
      if_else(coalesce(strong_related_party_flag, FALSE), "X_RELATED_PARTY_STRONG", NA_character_),
      if_else(!coalesce(local_site_flag, FALSE), "X_PORTFOLIO_NONLOCAL", NA_character_),
      if_else(coalesce(ambiguous_same_buyer_date_amount_flag, FALSE) | coalesce(same_bbl_date_buyer_repeated_flag, FALSE), "X_AMBIGUOUS_CLUSTER", NA_character_),
      if_else(!coalesce(opportunity_share_primary_flag, FALSE), "X_OPPORTUNITY_SHARE_LOW", NA_character_),
      SIMPLIFY = TRUE
    ),
    document_warning_codes = mapply(
      paste_codes,
      if_else(coalesce(llc_party_flag, FALSE), "F_LLC_PARTY", NA_character_),
      if_else(coalesce(trust_estate_party_flag, FALSE), "F_TRUST_ESTATE_PARTY", NA_character_),
      if_else(coalesce(nonprofit_religious_party_flag, FALSE), "F_NONPROFIT_RELIGIOUS_PARTY", NA_character_),
      if_else(coalesce(mixed_rights_fee_flag, FALSE), "F_MIXED_RIGHTS", NA_character_),
      if_else(coalesce(weak_related_party_flag, FALSE), "F_RELATED_PARTY_WEAK", NA_character_),
      if_else(coalesce(exact_duplicate_group_docs, 0L) > 1L, "F_EXACT_DUPLICATE_CLUSTER", NA_character_),
      if_else(coalesce(same_buyer_date_docs, 0L) > 1L, "F_SAME_BUYER_DATE_MULTIDOC", NA_character_),
      SIMPLIFY = TRUE
    ),
    document_market_status = case_when(
      is.na(document_exclusion_codes) ~ "DOC_PRIMARY_CANDIDATE",
      unit_churn_flag ~ "DOC_EXCLUDE_UNIT_CHURN",
      amount_class %in% c("ZERO", "NOMINAL") ~ "DOC_EXCLUDE_ZERO_NOMINAL",
      housing_public_or_regulated_party_flag | buyer_institutional_nonmarket_flag ~ "DOC_EXCLUDE_PUBLIC_OR_INSTITUTIONAL",
      rights_only_flag ~ "DOC_SENS_RIGHTS_COMPLEX",
      strong_related_party_flag ~ "DOC_EXCLUDE_RELATED_PARTY",
      amount_class %in% c("MARKET_CANDIDATE", "LOW") &
        !unit_churn_flag &
        !housing_public_or_regulated_party_flag &
        !buyer_institutional_nonmarket_flag &
        !strong_related_party_flag &
        !rights_only_flag &
        opportunity_share_sensitivity_flag ~ "DOC_SENS_PRIVATE_RELAXED",
      TRUE ~ "DOC_MANUAL_REVIEW_OR_AUDIT_ONLY"
    )
  ) |>
  arrange(document_date, document_id)

event_documents <- documents |>
  group_by(event_id) |>
  summarise(
    document_ids = collapse_unique(document_id),
    crfns = collapse_unique(crfn),
    event_date_min = if (all(is.na(document_date))) as.Date(NA) else min(document_date, na.rm = TRUE),
    event_date_max = if (all(is.na(document_date))) as.Date(NA) else max(document_date, na.rm = TRUE),
    event_date_primary = if (all(is.na(document_date))) as.Date(NA) else min(document_date, na.rm = TRUE),
    event_price_raw_positive_doc_sum = sum(document_amt[amount_class %in% c("MARKET_CANDIDATE", "LOW")], na.rm = TRUE),
    event_price_duplicate_excluded_sum = sum(document_amt[duplicate_price_excluded_flag & amount_class %in% c("MARKET_CANDIDATE", "LOW")], na.rm = TRUE),
    event_price_zero_nominal_excluded_sum = sum(document_amt[amount_class %in% c("ZERO", "NOMINAL")], na.rm = TRUE),
    event_price_final = sum(document_amt[!duplicate_price_excluded_flag & amount_class %in% c("MARKET_CANDIDATE", "LOW")], na.rm = TRUE),
    n_documents = n_distinct(document_id),
    n_price_carrying_docs = n_distinct(document_id[!duplicate_price_excluded_flag & amount_class %in% c("MARKET_CANDIDATE", "LOW")]),
    n_zero_nominal_docs = n_distinct(document_id[amount_class %in% c("ZERO", "NOMINAL")]),
    n_duplicate_docs = n_distinct(document_id[duplicate_price_excluded_flag]),
    buyer_names = collapse_unique(buyer_names),
    seller_names = collapse_unique(seller_names),
    buyer_keys = collapse_unique(buyer_party_set_key),
    seller_keys = collapse_unique(seller_party_set_key),
    percent_trans_min = if (all(is.na(percent_trans))) NA_real_ else min(percent_trans, na.rm = TRUE),
    percent_trans_max = if (all(is.na(percent_trans))) NA_real_ else max(percent_trans, na.rm = TRUE),
    n_all_legal_bbls = max(n_all_legal_bbls, na.rm = TRUE),
    n_opportunity_bbls = max(n_opportunity_legal_bbls, na.rm = TRUE),
    legal_bbls = collapse_unique(legal_bbls),
    opportunity_bbls = collapse_unique(opportunity_bbls),
    n_legal_blocks = max(n_legal_blocks, na.rm = TRUE),
    n_legal_boroughs = max(n_legal_boroughs, na.rm = TRUE),
    all_legal_allowed_res_area_sum = max(all_legal_allowed_res_area_sum, na.rm = TRUE),
    opp_legal_allowed_res_area_sum = max(opp_legal_allowed_res_area_sum, na.rm = TRUE),
    all_legal_lotarea_sum = max(all_legal_lotarea_sum, na.rm = TRUE),
    opp_legal_lotarea_sum = max(opp_legal_lotarea_sum, na.rm = TRUE),
    event_opp_share_allowed_res_area = max(event_opp_share_allowed_res_area, na.rm = TRUE),
    event_opp_share_lotarea = max(event_opp_share_lotarea, na.rm = TRUE),
    unit_churn_flag = any(unit_churn_flag, na.rm = TRUE),
    rights_only_flag = any(rights_only_flag, na.rm = TRUE),
    mixed_rights_flag = any(mixed_rights_fee_flag, na.rm = TRUE),
    public_party_flag = any(public_party_flag, na.rm = TRUE),
    hdfc_party_flag = any(hdfc_party_flag, na.rm = TRUE),
    housing_public_or_regulated_party_flag = any(housing_public_or_regulated_party_flag, na.rm = TRUE),
    nonprofit_religious_party_flag = any(nonprofit_religious_party_flag, na.rm = TRUE),
    trust_estate_party_flag = any(trust_estate_party_flag, na.rm = TRUE),
    related_party_strong_flag = any(strong_related_party_flag, na.rm = TRUE),
    related_party_weak_flag = any(weak_related_party_flag, na.rm = TRUE),
    portfolio_flag = any(!local_site_flag, na.rm = TRUE),
    ambiguous_cluster_flag = any(ambiguous_same_buyer_date_amount_flag | same_bbl_date_buyer_repeated_flag, na.rm = TRUE),
    cluster_rules = collapse_unique(cluster_rule),
    primary_exclusion_codes = collapse_unique(document_exclusion_codes),
    warning_codes = collapse_unique(document_warning_codes),
    .groups = "drop"
  ) |>
  mutate(
    event_date_span_days = as.integer(event_date_max - event_date_min),
    event_quarter = event_quarter(event_date_primary),
    event_price_final = if_else(event_price_final > 0, event_price_final, NA_real_),
    all_legal_allowed_res_area_sum = if_else(is.finite(all_legal_allowed_res_area_sum), all_legal_allowed_res_area_sum, NA_real_),
    opp_legal_allowed_res_area_sum = if_else(is.finite(opp_legal_allowed_res_area_sum), opp_legal_allowed_res_area_sum, NA_real_),
    all_legal_lotarea_sum = if_else(is.finite(all_legal_lotarea_sum), all_legal_lotarea_sum, NA_real_),
    opp_legal_lotarea_sum = if_else(is.finite(opp_legal_lotarea_sum), opp_legal_lotarea_sum, NA_real_),
    event_opp_share_allowed_res_area = if_else(is.finite(event_opp_share_allowed_res_area), event_opp_share_allowed_res_area, NA_real_),
    event_opp_share_lotarea = if_else(is.finite(event_opp_share_lotarea), event_opp_share_lotarea, NA_real_),
    event_market_status = case_when(
      is.na(primary_exclusion_codes) ~ "PRIMARY_MARKET_SITE_SALE",
      unit_churn_flag ~ "AUDIT_ONLY_UNIT_CHURN",
      rights_only_flag ~ "SENS_RIGHTS_COMPLEX",
      housing_public_or_regulated_party_flag ~ "SENS_INSTITUTIONAL_NONMARKET",
      related_party_strong_flag ~ "AUDIT_ONLY_RELATED_PARTY",
      is.na(event_price_final) ~ "AUDIT_ONLY_ZERO_NOMINAL",
      ambiguous_cluster_flag ~ "AUDIT_ONLY_AMBIGUOUS_CLUSTER",
      !unit_churn_flag &
        !rights_only_flag &
        !housing_public_or_regulated_party_flag &
        !related_party_strong_flag &
        !is.na(event_price_final) &
        (coalesce(event_opp_share_allowed_res_area, 0) >= sensitivity_opportunity_share_cutoff |
           coalesce(event_opp_share_lotarea, 0) >= sensitivity_opportunity_share_cutoff) ~ "SENS_PRIVATE_RELAXED",
      TRUE ~ "AUDIT_ONLY_OTHER"
    )
  ) |>
  arrange(event_date_primary, event_id)

if (anyDuplicated(event_documents$event_id) > 0L) {
  stop("Market sale events are not unique by event_id.")
}

documents <- documents |>
  select(
    event_id, document_id, crfn, recorded_borough, doc_type, document_date, document_amt, amount_class,
    percent_trans, document_market_status, document_exclusion_codes, document_warning_codes,
    cluster_rule, exact_duplicate_group_docs, duplicate_price_excluded_flag,
    ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
    buyer_names, seller_names, buyer_party_set_key, seller_party_set_key,
    has_buyer_party, has_seller_party, starts_with("buyer_"), starts_with("seller_"),
    public_party_flag, hdfc_party_flag, housing_public_or_regulated_party_flag,
    nonprofit_religious_party_flag, trust_estate_party_flag, timeshare_hotel_party_flag,
    llc_party_flag, strong_related_party_flag, weak_related_party_flag,
    n_all_legal_bbls, n_opportunity_legal_bbls, legal_bbls, opportunity_bbls,
    n_legal_boroughs, n_legal_blocks, all_legal_allowed_res_area_sum,
    opp_legal_allowed_res_area_sum, all_legal_lotarea_sum, opp_legal_lotarea_sum,
    event_opp_share_allowed_res_area, event_opp_share_lotarea,
    unit_churn_flag, rights_only_flag, mixed_rights_fee_flag,
    local_site_flag, opportunity_share_primary_flag, opportunity_share_sensitivity_flag,
    selected_master_version_rule
  )

cluster_candidates <- documents |>
  select(
    event_id, document_id, document_date, document_amt, amount_class,
    buyer_party_set_key, seller_party_set_key, legal_bbls,
    cluster_rule, exact_duplicate_group_docs, duplicate_price_excluded_flag,
    ambiguous_same_buyer_date_amount_flag, same_bbl_date_buyer_repeated_flag,
    document_market_status, document_exclusion_codes, document_warning_codes
  ) |>
  arrange(event_id, document_id)

event_legal_bbls <- document_legal_bbls |>
  inner_join(
    documents |> select(event_id, document_id),
    by = "document_id",
    relationship = "many-to-one"
  ) |>
  group_by(event_id, legal_bbl) |>
  summarise(
    legal_borough = first(legal_borough),
    legal_block = first(legal_block),
    legal_lot = first(legal_lot),
    direct_opportunity_bbl_match = any(direct_opportunity_bbl_match, na.rm = TRUE),
    allowed_policy_res_sqft = first(allowed_policy_res_sqft),
    lotarea = first(lotarea),
    primary_opp50_850 = any(primary_opp50_850, na.rm = TRUE),
    soft_site_opp50_850 = any(soft_site_opp50_850, na.rm = TRUE),
    capacity_units_850 = first(capacity_units_850),
    capacity100_850 = any(capacity100_850, na.rm = TRUE),
    capacity_exposure_quartile_citywide = first(capacity_exposure_quartile_citywide),
    capacity_exposure_quartile_borough = first(capacity_exposure_quartile_borough),
    .groups = "drop"
  )

event_denominators <- event_legal_bbls |>
  group_by(event_id) |>
  summarise(
    all_legal_allowed_res_area_sum_alloc = sum(allowed_policy_res_sqft[!is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0], na.rm = TRUE),
    all_legal_lotarea_sum_alloc = sum(lotarea[!is.na(lotarea) & lotarea > 0], na.rm = TRUE),
    all_legal_bbls_alloc = n_distinct(legal_bbl),
    .groups = "drop"
  ) |>
  mutate(
    all_legal_allowed_res_area_sum_alloc = if_else(all_legal_allowed_res_area_sum_alloc > 0, all_legal_allowed_res_area_sum_alloc, NA_real_),
    all_legal_lotarea_sum_alloc = if_else(all_legal_lotarea_sum_alloc > 0, all_legal_lotarea_sum_alloc, NA_real_)
  )

event_legal_bbls <- event_legal_bbls |>
  left_join(event_denominators, by = "event_id", relationship = "many-to-one") |>
  mutate(
    alloc_weight_allowed_res_area_all_legal = if_else(!is.na(all_legal_allowed_res_area_sum_alloc) & !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0, allowed_policy_res_sqft / all_legal_allowed_res_area_sum_alloc, NA_real_),
    alloc_weight_lotarea_all_legal = if_else(!is.na(all_legal_lotarea_sum_alloc) & !is.na(lotarea) & lotarea > 0, lotarea / all_legal_lotarea_sum_alloc, NA_real_),
    alloc_weight_equal_all_legal = 1 / all_legal_bbls_alloc
  )

incidence <- event_legal_bbls |>
  filter(direct_opportunity_bbl_match) |>
  left_join(
    event_documents |>
      select(
        event_id, event_market_status, event_date_primary, event_quarter,
        event_price_final, event_opp_share_allowed_res_area, event_opp_share_lotarea,
        primary_exclusion_codes, warning_codes
      ),
    by = "event_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    opportunity_bbl = legal_bbl,
    alloc_price_allowed_res_area = event_price_final * alloc_weight_allowed_res_area_all_legal,
    alloc_price_lotarea = event_price_final * alloc_weight_lotarea_all_legal,
    alloc_price_equal = event_price_final * alloc_weight_equal_all_legal,
    price_per_allowed_res_sqft = alloc_price_allowed_res_area / allowed_policy_res_sqft,
    price_per_lot_sqft = alloc_price_lotarea / lotarea,
    incidence_price_status = case_when(
      event_market_status == "PRIMARY_MARKET_SITE_SALE" &
        !is.na(alloc_price_allowed_res_area) &
        coalesce(event_opp_share_allowed_res_area, 0) >= primary_opportunity_share_cutoff ~ "PRIMARY_ALLOC_USABLE",
      event_market_status == "SENS_PRIVATE_RELAXED" &
        (!is.na(alloc_price_allowed_res_area) | !is.na(alloc_price_lotarea)) ~ "SENS_ALLOC_USABLE",
      is.na(event_price_final) ~ "NO_PRICE_ZERO_NOMINAL",
      event_market_status == "AUDIT_ONLY_UNIT_CHURN" ~ "NO_PRICE_UNIT_CHURN",
      event_market_status == "SENS_RIGHTS_COMPLEX" ~ "NO_PRICE_RIGHTS_ONLY",
      event_market_status == "AUDIT_ONLY_AMBIGUOUS_CLUSTER" ~ "NO_PRICE_AMBIGUOUS_CLUSTER",
      TRUE ~ "SOLD_FLAG_ONLY_PRICE_CONTAMINATED"
    ),
    allocation_warning_codes = mapply(
      paste_codes,
      if_else(is.na(alloc_weight_allowed_res_area_all_legal), "W_MISSING_ALLOWED_RES_AREA_WEIGHT", NA_character_),
      if_else(is.na(alloc_weight_lotarea_all_legal), "W_MISSING_LOTAREA_WEIGHT", NA_character_),
      if_else(coalesce(event_opp_share_allowed_res_area, 0) < primary_opportunity_share_cutoff, "W_LOW_OPPORTUNITY_SHARE_ALLOWED_RES_AREA", NA_character_),
      if_else(coalesce(event_opp_share_lotarea, 0) < primary_opportunity_share_cutoff, "W_LOW_OPPORTUNITY_SHARE_LOTAREA", NA_character_),
      SIMPLIFY = TRUE
    )
  ) |>
  select(
    event_id, opportunity_bbl, event_date_primary, event_quarter,
    event_market_status, event_price_final, incidence_price_status,
    legal_borough, legal_block, legal_lot, primary_opp50_850, soft_site_opp50_850,
    allowed_policy_res_sqft, lotarea, capacity_units_850, capacity100_850,
    capacity_exposure_quartile_citywide, capacity_exposure_quartile_borough,
    alloc_weight_allowed_res_area_all_legal, alloc_weight_lotarea_all_legal,
    alloc_weight_equal_all_legal, alloc_price_allowed_res_area,
    alloc_price_lotarea, alloc_price_equal, event_opp_share_allowed_res_area,
    event_opp_share_lotarea, price_per_allowed_res_sqft, price_per_lot_sqft,
    primary_exclusion_codes, warning_codes, allocation_warning_codes
  ) |>
  arrange(event_date_primary, event_id, opportunity_bbl)

if (anyDuplicated(paste(incidence$event_id, incidence$opportunity_bbl, sep = "::")) > 0L) {
  stop("Market site sale incidence is not unique by event_id/opportunity_bbl.")
}

write_parquet_if_changed(documents, "../output/acris_deed_document_classified.parquet")
write_parquet_if_changed(cluster_candidates, "../output/acris_document_cluster_candidates.parquet")
write_parquet_if_changed(event_documents, "../output/market_site_sale_events.parquet")
write_parquet_if_changed(incidence, "../output/market_site_sale_event_bbl_incidence.parquet")
cat("Built ACRIS market site sale universe to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_parent_cohorts/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# Economic parents: filings linked into one development opportunity, with the
# same rules in both periods. A parent is anchored on its first filing and
# spans at most 365 days.
max_filing_days <- 365L

# Links are applied in order. A link is skipped when the joined parent would
# span more than 365 days, or when it would place a rejected pair in one parent,
# directly or through other links.
assign_components <- function(rows, links, max_days, blocked = tibble(job_number_1 = character(),
    job_number_2 = character())) {
  rows <- rows |> arrange(date_filed, job_number)
  component <- seq_len(nrow(rows))
  left <- match(links$job_number_1, rows$job_number)
  right <- match(links$job_number_2, rows$job_number)
  stopifnot(!anyNA(left), !anyNA(right))
  blocked_left <- match(blocked$job_number_1, rows$job_number)
  blocked_right <- match(blocked$job_number_2, rows$job_number)
  in_rows <- !is.na(blocked_left) & !is.na(blocked_right)
  blocked_left <- blocked_left[in_rows]
  blocked_right <- blocked_right[in_rows]
  for (k in seq_along(left)) {
    a <- component[left[k]]
    b <- component[right[k]]
    if (a == b) next
    merging <- component %in% c(a, b)
    if (as.integer(max(rows$date_filed[merging]) - min(rows$date_filed[merging])) > max_days) next
    if (any((component[blocked_left] == a & component[blocked_right] == b) |
      (component[blocked_left] == b & component[blocked_right] == a))) next
    component[merging] <- min(a, b)
  }
  rows |> mutate(component = component)
}

# Committed decisions from parent_opportunities_manual.
pair_decisions <- read_csv("../input/pair_decisions.csv", col_types = cols(.default = col_character()))
stopifnot(!anyNA(pair_decisions), all(pair_decisions$sample %in% c("historical", "post_policy")),
  all(pair_decisions$review_decision %in% c("accept", "reject")),
  all(pair_decisions$job_number_1 != pair_decisions$job_number_2),
  !anyDuplicated(data.frame(pair_decisions$sample, pmin(pair_decisions$job_number_1, pair_decisions$job_number_2),
    pmax(pair_decisions$job_number_1, pair_decisions$job_number_2))))
post_parent_reviews <- read_csv("../input/post_parent_reviews.csv", col_types = cols(.default = col_character()))
post_filing_roles <- read_csv("../input/post_parent_filing_roles.csv", col_types = cols(.default = col_character()))
historical_filing_roles <- read_csv("../input/historical_filing_roles.csv",
  col_types = cols(.default = col_character()))
unit_decisions <- read_csv("../input/unit_decisions.csv",
  col_types = cols(.default = col_character(), reviewed_units = col_integer()))
stopifnot(!anyDuplicated(post_parent_reviews$reviewed_parent_id),
  all(post_parent_reviews$review_decision %in% c("accept", "reject", "unresolved")),
  all(post_parent_reviews$configuration_action %in% c("keep_additive", "split", "exclude_superseded",
    "split_and_exclude_superseded")),
  !anyDuplicated(post_filing_roles$job_number), all(post_filing_roles$filing_role == "superseded_alternative"),
  !anyDuplicated(historical_filing_roles$job_number),
  all(historical_filing_roles$filing_role %in% c("nonresidential_filing", "superseded_alternative")),
  !anyNA(unit_decisions), all(unit_decisions$unit_definition == "documented_proposed_design"),
  all(unit_decisions$reviewed_units > 0L), !anyDuplicated(unit_decisions[c("sample", "root_job_id")]))

# Historical links: the automatic evidence from construct_historical_parent_links
# plus reviewed decisions, which apply when both filings are in the universe.
historical_rows <- read_parquet("../input/historical_parent_filing_link_fields.parquet") |>
  arrange(date_filed, job_number)
stopifnot(!anyDuplicated(historical_rows$job_number),
  all(historical_filing_roles$job_number %in% historical_rows$job_number))
historical_reviews <- pair_decisions |>
  filter(sample == "historical", job_number_1 %in% historical_rows$job_number,
    job_number_2 %in% historical_rows$job_number) |>
  select(job_number_1, job_number_2, review_decision, review_basis)
historical_links <- read_parquet("../input/historical_parent_pairs.parquet") |>
  full_join(historical_reviews, by = c("job_number_1", "job_number_2"), relationship = "one-to-one") |>
  mutate(across(c(same_filing_bbl, strict_lot_history_link, explicit_job_reference, same_project_code,
    high_confidence_prefiling_signal, corroborated_exact_adjacency), ~ coalesce(.x, FALSE)),
    same_site_linkage_bbl = same_filing_bbl,
    reviewed_accept = coalesce(review_decision == "accept", FALSE),
    enhanced_link = ((high_confidence_prefiling_signal | corroborated_exact_adjacency) &
      !coalesce(review_decision == "reject", FALSE)) | reviewed_accept) |>
  filter(enhanced_link) |>
  mutate(sample = "historical",
    date_filed_1 = historical_rows$date_filed[match(job_number_1, historical_rows$job_number)],
    date_filed_2 = historical_rows$date_filed[match(job_number_2, historical_rows$job_number)],
    filing_days_apart = as.integer(date_filed_2 - date_filed_1))

# Post-policy links, built here from the DOB fields. Lots touch in the fixed
# 2023 MapPLUTO map (23v3.1).
post_rows <- read_parquet("../output/post_policy_filing_link_fields.parquet") |> arrange(filing_date, job_number)
stopifnot(!anyDuplicated(post_rows$job_number), !anyDuplicated(post_rows$root_job_id),
  all(post_filing_roles$job_number %in% post_rows$job_number),
  all(post_filing_roles$replacement_job_number %in% post_rows$job_number))
post_lots <- st_read("/vsizip/../input/nyc_mappluto_23v3_1_arc_shp.zip/MapPLUTO.shp", quiet = TRUE,
  query = paste0("SELECT BBL FROM MapPLUTO WHERE BBL IN (",
    paste(sort(unique(na.omit(post_rows$filing_bbl))), collapse = ","), ")")) |>
  transmute(bbl = normalize_bbl_field(BBL))
stopifnot(!anyDuplicated(post_lots$bbl), all(st_is_valid(post_lots)))
touches <- st_touches(post_lots)
post_touching <- tibble(i = rep(seq_along(touches), lengths(touches)), j = unlist(touches)) |>
  filter(i < j) |>
  transmute(bbl_low = pmin(post_lots$bbl[i], post_lots$bbl[j]), bbl_high = pmax(post_lots$bbl[i], post_lots$bbl[j]),
    exact_polygon_touch = TRUE)

last_partner <- findInterval(post_rows$filing_date + max_filing_days, post_rows$filing_date)
left <- rep(seq_len(nrow(post_rows)), pmax(last_partner - seq_len(nrow(post_rows)), 0L))
right <- left + sequence(pmax(last_partner - seq_len(nrow(post_rows)), 0L))
a <- post_rows[left, ]
b <- post_rows[right, ]
same <- function(x, y) coalesce(x == y, FALSE)
same_lot_history <- same(a$lot_history_group_bbl, b$lot_history_group_bbl) &
  (!is.na(a$historical_appbbl) | !is.na(b$historical_appbbl))
post_pairs <- tibble(job_number_1 = a$job_number, job_number_2 = b$job_number,
    date_filed_1 = a$filing_date, date_filed_2 = b$filing_date,
    filing_days_apart = as.integer(b$filing_date - a$filing_date),
    same_filing_bbl = same(a$filing_bbl, b$filing_bbl),
    same_site_linkage_bbl = same(a$site_linkage_bbl, b$site_linkage_bbl),
    strict_lot_history_link = same_lot_history & !a$appbbl_change_after_filing & !b$appbbl_change_after_filing,
    same_owner_support = same(a$owner_match_key, b$owner_match_key),
    explicit_job_reference = same(a$description_referenced_job_id, b$job_number) |
      same(a$description_referenced_job_id, b$root_job_id) | same(b$description_referenced_job_id, a$job_number) |
      same(b$description_referenced_job_id, a$root_job_id),
    same_project_code = same(a$description_project_code, b$description_project_code),
    bbl_low = pmin(a$filing_bbl, b$filing_bbl), bbl_high = pmax(a$filing_bbl, b$filing_bbl)) |>
  left_join(post_touching, by = c("bbl_low", "bbl_high"), relationship = "many-to-one") |>
  mutate(corroborated_exact_adjacency = coalesce(exact_polygon_touch, FALSE) &
      (filing_days_apart <= 30L | same_owner_support),
    automatic_link = same_filing_bbl | same_site_linkage_bbl | strict_lot_history_link | explicit_job_reference |
      same_project_code | corroborated_exact_adjacency)

# Every automatic post-policy parent formed through a shared site-linkage lot
# with different filing lots has a manual review, keyed by its first filing.
provisional <- assign_components(post_rows |> transmute(job_number, date_filed = filing_date),
  post_pairs |> filter(automatic_link) |> select(job_number_1, job_number_2), Inf) |>
  group_by(component) |>
  mutate(reviewed_parent_id = paste("post_policy", first(job_number), sep = "__")) |>
  ungroup()
site_linked <- post_pairs |> filter(automatic_link, same_site_linkage_bbl, !same_filing_bbl)
post_reviews <- pair_decisions |> filter(sample == "post_policy") |>
  select(job_number_1, job_number_2, review_decision, review_basis)
stopifnot(setequal(provisional$reviewed_parent_id[provisional$job_number %in%
    c(site_linked$job_number_1, site_linked$job_number_2)], post_parent_reviews$reviewed_parent_id),
  nrow(anti_join(post_reviews, post_pairs, by = c("job_number_1", "job_number_2"))) == 0L)

post_links <- post_pairs |>
  left_join(post_reviews, by = c("job_number_1", "job_number_2"), relationship = "one-to-one") |>
  mutate(sample = "post_policy", reviewed_accept = coalesce(review_decision == "accept", FALSE),
    enhanced_link = (automatic_link & !coalesce(review_decision == "reject", FALSE)) | reviewed_accept) |>
  filter(enhanced_link)

# Same-owner companion links (construct_owner_proximity_links.R) come after the
# automatic and reviewed links, oriented with the earlier filing first.
pair_key <- function(x, y) paste(pmin(x, y), pmax(x, y))
rejected <- pair_decisions |> filter(review_decision == "reject") |>
  transmute(sample, pair_key = pair_key(job_number_1, job_number_2))
filing_dates <- bind_rows(historical_rows |> transmute(sample = "historical", job_number, date_filed),
  post_rows |> transmute(sample = "post_policy", job_number, date_filed = filing_date))
owner_links <- read_parquet("../output/owner_proximity_links.parquet") |>
  transmute(sample, job_number_1, job_number_2, pair_key = pair_key(job_number_1, job_number_2)) |>
  anti_join(rejected, by = c("sample", "pair_key")) |>
  left_join(filing_dates |> rename(job_number_1 = job_number, date_a = date_filed), by = c("sample", "job_number_1"),
    relationship = "many-to-one") |>
  left_join(filing_dates |> rename(job_number_2 = job_number, date_b = date_filed), by = c("sample", "job_number_2"),
    relationship = "many-to-one") |>
  mutate(a_first = date_a < date_b | (date_a == date_b & job_number_1 < job_number_2)) |>
  transmute(sample, pair_key, job_number_1 = if_else(a_first, job_number_1, job_number_2),
    job_number_2 = if_else(a_first, job_number_2, job_number_1), date_filed_1 = pmin(date_a, date_b),
    date_filed_2 = pmax(date_a, date_b), filing_days_apart = as.integer(date_filed_2 - date_filed_1))
stopifnot(!anyNA(owner_links$date_filed_1), !anyNA(owner_links$date_filed_2))

flags <- c("same_filing_bbl", "same_site_linkage_bbl", "strict_lot_history_link", "explicit_job_reference",
  "same_project_code", "corroborated_exact_adjacency", "reviewed_accept")
links <- bind_rows(historical_links, post_links) |>
  select(sample, job_number_1, job_number_2, date_filed_1, date_filed_2, filing_days_apart, all_of(flags),
    review_basis, enhanced_link) |>
  mutate(pair_key = pair_key(job_number_1, job_number_2))
links <- bind_rows(links, owner_links |> anti_join(links, by = c("sample", "pair_key"))) |>
  mutate(same_owner_nearby = paste(sample, pair_key) %in% paste(owner_links$sample, owner_links$pair_key),
    across(all_of(c(flags, "enhanced_link")), ~ coalesce(.x, FALSE)),
    link_reason = str_remove(paste0(if_else(same_filing_bbl, "same_filing_bbl;", ""),
      if_else(same_site_linkage_bbl & !same_filing_bbl, "same_site_linkage_bbl;", ""),
      if_else(strict_lot_history_link, "strict_lot_history_link;", ""),
      if_else(explicit_job_reference, "explicit_job_reference;", ""),
      if_else(same_project_code, "same_project_code;", ""),
      if_else(corroborated_exact_adjacency, "corroborated_exact_adjacency;", ""),
      if_else(reviewed_accept, "reviewed_accept;", ""),
      if_else(same_owner_nearby, "same_owner_nearby;", "")), ";$")) |>
  arrange(sample, date_filed_1, job_number_1, job_number_2)

# Units: the Housing Database Class A count, including a recorded zero, with
# the DOB initial-filing count only where HDB is missing.
hdb_post_units <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |>
  select(root_job_id = job_number, hdb_units = classa_prop)
stopifnot(!anyDuplicated(hdb_post_units$root_job_id),
  all(is.na(hdb_post_units$hdb_units) | (hdb_post_units$hdb_units >= 0 &
    hdb_post_units$hdb_units == round(hdb_post_units$hdb_units))))
member_rows <- bind_rows(
  historical_rows |>
    left_join(historical_filing_roles |> select(job_number, filing_role, replacement_job_number),
      by = "job_number", relationship = "one-to-one") |>
    transmute(sample = "historical", root_job_id = job_number, job_number, date_filed, filing_year, units,
      hdb_priority_units = units, unit_source = "hdb", hdb_release, historical_active, hdb_job_status,
      filing_role, replacement_job_number, filing_bbl, site_linkage_bbl = filing_bbl),
  post_rows |>
    left_join(post_filing_roles |> select(job_number, filing_role, replacement_job_number),
      by = "job_number", relationship = "one-to-one") |>
    left_join(hdb_post_units, by = "root_job_id", relationship = "one-to-one") |>
    transmute(sample = "post_policy", root_job_id, job_number, date_filed = filing_date, filing_year,
      units = coalesce(as.integer(hdb_units), units), hdb_priority_units = units,
      unit_source = if_else(!is.na(hdb_units), "hdb", "dob_i1"),
      hdb_release = if_else(unit_source == "hdb", "25Q4", NA_character_), historical_active = NA,
      hdb_job_status = NA_character_, filing_role, replacement_job_number, filing_bbl, site_linkage_bbl)
) |>
  mutate(filing_role = coalesce(filing_role, "additive_component"),
    additive_component = filing_role == "additive_component")

# Accepted reviews first, then the automatic links in date order, then the
# same-owner links in date order.
membership <- bind_rows(lapply(c("historical", "post_policy"), function(s) {
  sample_links <- if (s == "historical") historical_links else post_links
  assign_components(member_rows |> filter(sample == s),
    bind_rows(sample_links |> arrange(desc(reviewed_accept), date_filed_1, date_filed_2) |>
        select(job_number_1, job_number_2),
      owner_links |> filter(sample == s) |> arrange(date_filed_1, date_filed_2) |> select(job_number_1, job_number_2)),
    max_filing_days,
    pair_decisions |> filter(sample == s, review_decision == "reject") |> select(job_number_1, job_number_2))
}))
superseded <- membership |> filter(sample == "post_policy", filing_role == "superseded_alternative")
stopifnot(nrow(superseded) == nrow(post_filing_roles), all(superseded$component ==
  membership$component[match(paste("post_policy", superseded$replacement_job_number),
    paste(membership$sample, membership$job_number))]))

# Links spanning separate parents stay out of the saved links.
member_keys <- paste(membership$sample, membership$job_number)
links <- links |>
  filter(membership$component[match(paste(sample, job_number_1), member_keys)] ==
    membership$component[match(paste(sample, job_number_2), member_keys)])

# Refilings: a superseded application and its replacement describe one
# building. Post-policy: a withdrawn DOB filing with a valid BIN and a named
# owner and applicant, and one later non-withdrawn filing with the same BIN,
# owner and applicant, filed after the withdrawal.
dob_filings <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(root_job_id = job_number, bin = as.character(bin), dob_i1_units = proposed_dwelling_units, filing_status,
    withdrawal_date = current_status_date,
    owner = str_squish(str_to_upper(paste(coalesce(owner_business_name, ""), coalesce(owner_first_name, ""),
      coalesce(owner_last_name, "")))),
    applicant = str_squish(str_to_upper(paste(coalesce(applicant_first_name, ""), coalesce(applicant_last_name, ""),
      coalesce(applicant_business_name, "")))))
stopifnot(!anyDuplicated(dob_filings$root_job_id))
# The DOB count is kept for comparison; legacy BIS jobs have none.
membership$dob_i1_units <- dob_filings$dob_i1_units[match(membership$root_job_id, dob_filings$root_job_id)]
refiling <- membership |> left_join(dob_filings |> select(-dob_i1_units), by = "root_job_id",
  relationship = "many-to-one")
replacement <- rep(NA_integer_, nrow(membership))
for (i in which(refiling$sample == "post_policy" & refiling$filing_status == "Filing Withdrawn" &
    !is.na(refiling$withdrawal_date) & str_detect(refiling$bin, "^[1-5][0-9]{6}$") &
    !refiling$owner %in% c("", "PR", "PRIVATE", "NOT APPLICABLE") & refiling$applicant != "")) {
  candidates <- which(refiling$sample == refiling$sample[i] & refiling$bin == refiling$bin[i] &
    refiling$owner == refiling$owner[i] & refiling$applicant == refiling$applicant[i] &
    refiling$date_filed > refiling$date_filed[i] & refiling$date_filed > refiling$withdrawal_date[i] &
    refiling$filing_status != "Filing Withdrawn")
  if (length(candidates) > 1L) stop("Multiple refiling candidates for ", membership$job_number[i])
  if (length(candidates) == 1L) replacement[i] <- candidates
}

# Historical: in the 23Q4 snapshot, withdrawn versions of a building (same
# archived BIN, lot and exact address, within 365 days) are replaced by the
# single later non-withdrawn application. No withdrawal date is imputed.
historical_index <- which(membership$sample == "historical")
archived <- membership |>
  filter(sample == "historical") |>
  left_join(read_parquet("../input/dcp_housing_database_project_level_23q4.parquet") |>
    select(job_number, hdb_bin = bin, hdb_address = address), by = "job_number", relationship = "one-to-one") |>
  filter(str_detect(hdb_bin, "^[1-5][0-9]{6}$"), !is.na(filing_bbl), !is.na(hdb_address), hdb_address != "") |>
  group_by(component, hdb_bin, filing_bbl, hdb_address) |>
  filter(n() > 1L, sum(hdb_job_status != "9. Withdrawn") == 1L) |>
  mutate(replacement_job = job_number[hdb_job_status != "9. Withdrawn"],
    replacement_date = date_filed[hdb_job_status != "9. Withdrawn"]) |>
  filter(replacement_date == max(date_filed), max(date_filed) - min(date_filed) <= max_filing_days,
    hdb_job_status == "9. Withdrawn", date_filed < replacement_date) |>
  ungroup()
historical_jobs <- membership$job_number[historical_index]
archived_original <- historical_index[match(archived$job_number, historical_jobs)]
archived_replacement <- historical_index[match(archived$replacement_job, historical_jobs)]
stopifnot(!anyNA(archived_original), !anyNA(archived_replacement))
replacement[archived_original] <- archived_replacement
# Reviewed historical alternatives (historical_filing_roles.csv).
manual_original <- which(membership$sample == "historical" & membership$filing_role == "superseded_alternative")
manual_replacement <- historical_index[match(membership$replacement_job_number[manual_original], historical_jobs)]
stopifnot(!anyNA(manual_replacement))
replacement[manual_original] <- manual_replacement

original <- which(!is.na(replacement))
new <- replacement[original]
stopifnot(!anyDuplicated(new[membership$sample[original] == "post_policy"]),
  all(membership$sample[original] == membership$sample[new]),
  all(membership$component[original] == membership$component[new]), all(membership$additive_component[new]),
  all(is.na(membership$replacement_job_number[original]) |
    membership$replacement_job_number[original] == membership$job_number[new]))
membership$original_filing_date <- membership$date_filed
membership$refiled <- FALSE
membership$refiling_date <- as.Date(NA)
membership$refiled[c(original, new)] <- TRUE
membership$refiling_date[original] <- membership$date_filed[new]
membership$refiling_date[new] <- membership$date_filed[new]
for (j in unique(new)) membership$original_filing_date[j] <- min(membership$date_filed[original[new == j]])
membership$refiling_basis <- NA_character_
membership$refiling_basis[c(original, new)] <- if_else(membership$sample[c(original, new)] == "historical",
  "archived_same_building_alternatives", "dated_dob_withdrawal_and_refiling")
membership$refiling_basis[c(manual_original, manual_replacement)] <- "reviewed_archived_alternative"
membership$filing_role[original] <- "superseded_refiling"
membership$additive_component[original] <- FALSE
membership$replacement_job_number[original] <- membership$job_number[new]
stopifnot(all(membership$refiled == !is.na(membership$refiling_date)),
  all(membership$refiling_date[membership$refiled] > membership$original_filing_date[membership$refiled]))

# Parent fields. A recorded zero is a source proposal that adds no units. The
# follow-up window is observed when the source covers 365 days on each side.
membership <- membership |>
  mutate(filing_role = if_else(additive_component & units == 0L, "zero_class_a", filing_role),
    additive_component = additive_component & units > 0L) |>
  left_join(unit_decisions |> select(sample, root_job_id, documented_units = reviewed_units,
    documented_unit_source = review_source), by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  arrange(sample, date_filed, job_number) |>
  group_by(sample, component) |>
  mutate(parent_id = paste(sample, first(job_number), sep = "__"), cohort_date = first(date_filed),
    cohort_year = as.integer(format(cohort_date, "%Y")), parent_last_filing_date = max(date_filed),
    parent_observed_units = sum(units[additive_component]), member_order = row_number()) |>
  group_by(sample) |>
  mutate(source_end_date = max(date_filed),
    left_window_observed = cohort_date - max_filing_days >= min(date_filed),
    right_window_observed = cohort_date + max_filing_days <= source_end_date,
    full_window_observed = left_window_observed & right_window_observed) |>
  ungroup() |>
  mutate(analysis_status = case_when(
    sample == "historical" & cohort_year < 2011L ~ "historical_linkage_padding",
    sample == "historical" & full_window_observed ~ "historical_fully_observed",
    sample == "historical" & !left_window_observed & !right_window_observed ~ "historical_both_boundaries_exposed",
    sample == "historical" & !left_window_observed ~ "historical_left_boundary_exposed",
    sample == "historical" ~ "historical_right_boundary_exposed",
    cohort_year < 2023L ~ "post_linkage_padding",
    cohort_year < 2025L & full_window_observed ~ "completed_pre_policy_comparison_cohort",
    cohort_year < 2025L & !left_window_observed ~ "left_boundary_pre_policy_comparison_cohort",
    cohort_year < 2025L ~ "right_censored_pre_policy_comparison_cohort",
    cohort_year == 2025L & !left_window_observed & !right_window_observed ~ "both_boundaries_exposed_2025_cohort",
    cohort_year == 2025L & !left_window_observed ~ "left_boundary_exposed_2025_cohort",
    cohort_year == 2025L & full_window_observed ~ "completed_2025_cohort",
    cohort_year == 2025L ~ "right_censored_2025_cohort",
    TRUE ~ "later_2026_cohort"))

stopifnot(!anyDuplicated(membership[c("sample", "job_number")]),
  nrow(membership) == nrow(historical_rows) + nrow(post_rows), all(membership$units >= 0L),
  all(as.integer(membership$parent_last_filing_date - membership$cohort_date) <= max_filing_days),
  all(membership$units == membership$hdb_priority_units),
  nrow(anti_join(unit_decisions, membership, by = c("sample", "root_job_id"))) == 0L,
  !anyDuplicated(links[c("sample", "job_number_1", "job_number_2")]), all(links$filing_days_apart <= max_filing_days))

# Every committed decision survives, including through chains of links:
# accepted pairs share a parent and rejected pairs do not. Historical
# decisions apply only when both filings are in the linkage universe.
member_keys <- paste(membership$sample, membership$job_number)
decided <- pair_decisions |>
  mutate(parent_1 = membership$parent_id[match(paste(sample, job_number_1), member_keys)],
    parent_2 = membership$parent_id[match(paste(sample, job_number_2), member_keys)],
    applies = !is.na(parent_1) & !is.na(parent_2))
stopifnot(all(decided$applies[decided$sample == "post_policy"]),
  with(filter(decided, applies), all((parent_1 == parent_2) == (review_decision == "accept"))))

SaveData(membership, c("sample", "job_number"), "../output/symmetric_parent_membership.parquet")
SaveData(links |> select(sample, job_number_1, job_number_2, filing_days_apart, link_reason, same_owner_nearby,
  review_basis, enhanced_link), NULL, "../output/symmetric_parent_links.parquet")

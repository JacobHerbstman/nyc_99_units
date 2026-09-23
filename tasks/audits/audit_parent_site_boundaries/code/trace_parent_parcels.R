# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_site_boundaries/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50)
membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  semi_join(parents, by = "parent_id")
hdb <- bind_rows(
  read_parquet("../input/historical_hdb_mappluto_site_panel.parquet") |> mutate(sample = "historical"),
  read_parquet("../input/hdb_mappluto_site_panel.parquet") |> mutate(sample = "post_policy"))
events <- read_parquet("../output/dof_events.parquet")
condo_links <- read_parquet("../output/dof_condo_links.parquet") |> filter(valid_bbl)
current_lots <- read_parquet("../input/dof_current_lots.parquet")
maps <- read_parquet("../input/dof_map_library.parquet")
applications <- read_parquet("../input/dof_all_applications.parquet")
stopifnot(!anyDuplicated(parents$parent_id), !anyDuplicated(membership$job_number),
          !anyDuplicated(hdb[c("sample", "job_number")]), !anyDuplicated(events$transaction_id))

# Preserve the existing filing-specific historical vintage and fixed post-policy
# 2023 vintage. Each parent/vintage is traced separately if a parent spans releases.
members <- membership |>
  mutate(hdb_job = if_else(sample == "historical", job_number, root_job_id)) |>
  left_join(hdb |> select(sample, hdb_job = job_number, hdb_bbl = bbl,
                         pluto_version_used, pluto_safe_available_date_used),
            by = c("sample", "hdb_job"), relationship = "many-to-one") |>
  mutate(vintage = if_else(sample == "post_policy", "23v3_1",
                          str_to_lower(str_replace_all(pluto_version_used, "\\.", "_"))),
         reference_date = if_else(sample == "post_policy", as.Date("2023-12-28"),
                                  pluto_safe_available_date_used),
         anchor_bbl = if_else(sample == "historical", hdb_bbl, filing_bbl))
stopifnot(!anyNA(members$vintage), !anyNA(members$reference_date))

# These are a real family of DCP parcel releases, linked in the Makefile.
pluto <- bind_rows(read_parquet("../input/dcp_pluto_archive_18v1.parquet") |>
                    transmute(vintage = "18v1", bbl, lotarea, residfar, builtfar),
  bind_rows(lapply(setdiff(sort(unique(members$vintage)), "18v1"), function(vintage) {
  read_parquet(paste0("../input/dcp_mappluto_archive_", vintage, ".parquet")) |>
    transmute(vintage, bbl, lotarea, residfar, builtfar)
})))
stopifnot(!anyDuplicated(pluto[c("vintage", "bbl")]))

condo_sets <- condo_links |>
  group_by(filing_bbl) |>
  summarise(base_bbls = list(sort(unique(base_bbl))), .groups = "drop")
members <- members |>
  left_join(condo_sets, by = c("anchor_bbl" = "filing_bbl"), relationship = "many-to-one") |>
  left_join(condo_sets |> rename(hdb_base_bbls = base_bbls),
            by = c("hdb_bbl" = "filing_bbl"), relationship = "many-to-one")
sites <- members |>
  group_by(parent_id, sample, vintage, reference_date) |>
  summarise(
    filing_bbls = list(sort(unique(anchor_bbl))),
    hdb_recorded_bbls = list(sort(unique(hdb_bbl))),
    hdb_bbls = list(sort(unique(c(unlist(hdb_base_bbls), hdb_bbl[lengths(hdb_base_bbls) == 0L])))),
    condo_scope_review = any(lengths(base_bbls) > 1L),
    condo_link_used = any(lengths(base_bbls) > 0L),
    candidate_bbls = list(sort(unique(c(unlist(base_bbls), anchor_bbl[lengths(base_bbls) == 0L])))),
    .groups = "drop"
  )

# Review unusual physical changes. Pure condominium, REUC and effective-tax-year
# records do not by themselves establish a different ground footprint.
physical_types <- c("Lot Merger", "Lot Apportionment", "Lot Reconfiguration",
                    "Boundary Line", "Lot Number Change", "Block",
                    "Digital Alteration Book", "Digital Alteration Book Wizard")
physical_events <- events |> filter(reversible | change_type %in% physical_types)
event_index <- physical_events |>
  transmute(event_row = row_number(), bbl = all_bbls) |>
  unnest_longer(bbl) |>
  group_by(bbl) |>
  summarise(event_rows = list(event_row), .groups = "drop")
event_lookup <- setNames(event_index$event_rows, event_index$bbl)
mapped_bbls <- unique(c(current_lots$BBL, condo_links$filing_bbl))

parcel_results <- vector("list", nrow(sites))
site_results <- vector("list", nrow(sites))
for (i in seq_len(nrow(sites))) {
  bbls <- sites$candidate_bbls[[i]]
  applied <- partial <- unusual <- integer()

  # Discover the relevant transaction chain, then walk it once in reverse date
  # order. This loop is the same set operation for every parent; no address rules.
  connected_bbls <- bbls
  repeat {
    event_rows <- sort(unique(unlist(event_lookup[connected_bbls])))
    event_rows <- event_rows[physical_events$change_date[event_rows] > sites$reference_date[i]]
    expanded <- union(connected_bbls, unlist(physical_events$all_bbls[event_rows]))
    if (setequal(expanded, connected_bbls)) break
    connected_bbls <- expanded
  }
  for (j in event_rows) {
    event <- physical_events[j, ]
    if (!any(event$all_bbls[[1]] %in% bbls)) next
    if (!event$reversible) {
      unusual <- c(unusual, event$transaction_id)
    } else if (all(event$new_bbls[[1]] %in% bbls)) {
      bbls <- union(setdiff(bbls, event$new_bbls[[1]]), event$old_bbls[[1]])
      applied <- c(applied, event$transaction_id)
    } else if (any(event$new_bbls[[1]] %in% bbls)) {
      partial <- c(partial, event$transaction_id)
    }
  }
  bbls <- sort(unique(bbls))
  # HDB and DOB can name different lots. Accept a common condo base or an alias
  # within a fully reversed event; retain other disagreements for review.
  known_aliases <- unique(c(sites$filing_bbls[[i]], sites$candidate_bbls[[i]], bbls,
    unlist(physical_events$all_bbls[physical_events$transaction_id %in% applied])))
  parcel_results[[i]] <- tibble(parent_id = sites$parent_id[i], vintage = sites$vintage[i], bbl = bbls)
  site_results[[i]] <- sites[i, ] |>
    mutate(applied_transactions = paste(applied, collapse = ";"),
           partial_transactions = paste(partial, collapse = ";"),
           unusual_transactions = paste(unusual, collapse = ";"),
           partial_change = length(partial) > 0L, unusual_change = length(unusual) > 0L,
           source_bbl_disagreement = any(!hdb_bbls[[1]] %in% known_aliases),
           recovered_with_dof = length(applied) > 0L | condo_link_used,
           unmapped_filing_lots = sum(!filing_bbls[[1]] %in% mapped_bbls),
           candidate_bbls = list(bbls))
}

parcels <- bind_rows(parcel_results) |>
  left_join(pluto, by = c("vintage", "bbl"), relationship = "many-to-one") |>
  arrange(parent_id, vintage, bbl)
site_coverage <- bind_rows(site_results) |>
  left_join(parcels |> group_by(parent_id, vintage) |>
              summarise(candidate_lots = n(), unmatched_lots = sum(is.na(lotarea) | lotarea <= 0),
                        candidate_area_sqft = if (all(!is.na(lotarea) & lotarea > 0)) sum(lotarea) else NA_real_,
                        .groups = "drop"),
            by = c("parent_id", "vintage"), relationship = "one-to-one")

# The tracker is supporting evidence, not a source of completed lot boundaries.
# Full BBLs and abbreviated range endpoints are parsed systematically. Malformed
# text remains in the source; an application link never authorizes adding land.
application_sets <- vector("list", nrow(applications))
for (i in seq_len(nrow(applications))) {
  text <- coalesce(applications$Multiple_BBLs[i], "") |>
    str_replace_all(fixed("\\u200b"), "") |>
    str_replace_all(fixed("\\xa0"), " ") |>
    str_replace_all(fixed("\\n"), " ")
  bbls <- str_extract_all(text, "(?<![0-9])[1-5][0-9]{9}(?![0-9])")[[1]]
  ranges <- str_match_all(text, "([1-5][0-9]{9})\\s*[-–]\\s*([0-9]{1,10})")[[1]]
  for (j in seq_len(nrow(ranges))) {
    end <- paste0(substr(ranges[j, 2], 1, 10 - nchar(ranges[j, 3])), ranges[j, 3])
    if (substr(end, 1, 6) == substr(ranges[j, 2], 1, 6) && as.numeric(end) >= as.numeric(ranges[j, 2])) {
      bbls <- union(bbls, sprintf("%.0f", seq(as.numeric(ranges[j, 2]), as.numeric(end))))
    }
  }
  application_sets[[i]] <- unique(c(sprintf("%.0f", applications$Borough_Block_Lot[i]), bbls))
}
applications$bbls <- application_sets

coverage <- site_coverage |>
  group_by(parent_id, sample) |>
  summarise(
    vintages = paste(sort(unique(vintage)), collapse = ";"), mixed_vintages = n() > 1L,
    recovered_with_dof = any(recovered_with_dof), condo_scope_review = any(condo_scope_review),
    partial_change = any(partial_change), unusual_change = any(unusual_change),
    source_bbl_disagreement = any(source_bbl_disagreement),
    unmatched_lots = max(unmatched_lots), unmapped_filing_lots = max(unmapped_filing_lots),
    applied_transactions = paste(applied_transactions[applied_transactions != ""], collapse = ";"),
    partial_transactions = paste(partial_transactions[partial_transactions != ""], collapse = ";"),
    unusual_transactions = paste(unusual_transactions[unusual_transactions != ""], collapse = ";"),
    candidate_bbls = paste(sort(unique(unlist(candidate_bbls))), collapse = ";"),
    filing_bbls = paste(sort(unique(unlist(filing_bbls))), collapse = ";"),
    hdb_bbls = paste(sort(unique(unlist(hdb_recorded_bbls))), collapse = ";"),
    candidate_area_sqft = if (n() == 1L) first(candidate_area_sqft) else NA_real_,
    .groups = "drop"
  ) |>
  left_join(parents |> select(parent_id, composition_eligible, parent_total_units, n_components,
                             component_addresses, lot_area_sqft),
            by = "parent_id", relationship = "one-to-one") |>
  mutate(
    area_difference_sqft = candidate_area_sqft - lot_area_sqft,
    reason = case_when(
      condo_scope_review ~ "multiple_condo_base_lots",
      partial_change ~ "part_of_lot_change",
      unmatched_lots > 0 ~ "parcel_absent_from_reference_map",
      unusual_change ~ "other_physical_change",
      mixed_vintages ~ "multiple_reference_vintages",
      source_bbl_disagreement ~ "hdb_dob_lot_disagreement",
      TRUE ~ "no_flag_from_dof_screen"
    ),
    unresolved = reason != "no_flag_from_dof_screen",
    candidate_area_sqft = if_else(unmatched_lots == 0L, candidate_area_sqft, NA_real_)
  )

# Retain links to every matching application and each block's dated map index.
coverage$application_ids <- vapply(seq_len(nrow(coverage)), function(i) {
  bbls <- union(str_split(coverage$candidate_bbls[i], ";")[[1]],
                str_split(coverage$filing_bbls[i], ";")[[1]])
  paste(applications$OBJECTID[vapply(applications$bbls, function(x) any(x %in% bbls), logical(1))], collapse = ";")
}, character(1))

map_sets <- maps |>
  mutate(block_id = paste0(BOROUGH, str_pad(BLOCK, 5, pad = "0")),
         effective_date = as.Date(EFFECTIVE_DATE, "%Y/%m/%d"),
         end_date = as.Date(END_DATE, "%Y/%m/%d"))
coverage$reference_map_ids <- vapply(seq_len(nrow(coverage)), function(i) {
  blocks <- substr(str_split(coverage$candidate_bbls[i], ";")[[1]], 1, 6)
  dates <- sites$reference_date[sites$parent_id == coverage$parent_id[i]]
  selected <- map_sets |> filter(block_id %in% blocks,
                                 effective_date <= max(dates), end_date >= min(dates))
  paste(sort(unique(selected$ID)), collapse = ";")
}, character(1))
coverage <- coverage |> arrange(sample, parent_id)
summary <- coverage |> count(sample, composition_eligible, reason, name = "parents")
stopifnot(nrow(coverage) == nrow(parents), sum(summary$parents) == nrow(parents))

SaveData(parcels, c("parent_id", "vintage", "bbl"), "../output/dof_parent_parcels.parquet")
SaveData(coverage, "parent_id", "../output/dof_parent_coverage.csv")
SaveData(summary, c("sample", "composition_eligible", "reason"), "../output/dof_coverage_summary.csv")
print(summary, n = Inf)

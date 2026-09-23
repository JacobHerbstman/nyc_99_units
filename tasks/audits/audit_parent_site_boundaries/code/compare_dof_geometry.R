# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_site_boundaries/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)
library(tidyr)
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/dof_parent_coverage.csv", show_col_types = FALSE) |>
  filter(composition_eligible) |> arrange(parent_id)
parcels <- read_parquet("../output/dof_parent_parcels.parquet") |>
  semi_join(parents, by = "parent_id")
condo_links <- read_parquet("../output/dof_condo_links.parquet") |> filter(valid_bbl)
condos <- condo_links |>
  group_by(filing_bbl) |> summarise(base_bbls = list(sort(unique(base_bbl))), .groups = "drop")
maps <- read_parquet("../output/dof_geometry_lots.parquet") |> st_as_sf(wkt = "wkt", crs = 2263)
later <- maps |> filter(vintage == "25v4") |> mutate(map_row = row_number())
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id),
          !anyDuplicated(parcels[c("parent_id", "vintage", "bbl")]))

# Keep the physical-base lookup as a coverage diagnostic. For drawing, use the
# filing BBL when MapPLUTO supplies it; condo billing polygons represent land.
filings <- parents |> select(parent_id, filing_bbls) |>
  separate_longer_delim(filing_bbls, ";") |> rename(filing_bbl = filing_bbls)
base_anchors <- bind_rows(
  filings |> anti_join(condos, by = "filing_bbl") |>
    transmute(parent_id, bbl = filing_bbl),
  filings |> inner_join(condos, by = "filing_bbl", relationship = "many-to-one") |>
    select(parent_id, base_bbls) |> unnest_longer(base_bbls, values_to = "bbl")
) |> distinct(parent_id, bbl)
base_counts <- base_anchors |> group_by(parent_id) |>
  summarise(base_requested_lots = n(), base_mapped_lots = sum(bbl %in% later$bbl),
    base_mapped_bbls = paste(sort(bbl[bbl %in% later$bbl]), collapse = ";"),
    base_missing_bbls = paste(sort(bbl[!bbl %in% later$bbl]), collapse = ";"), .groups = "drop")

# A missing physical base can also be drawn under a unique mapped condo BBL.
# Multiple mapped aliases remain unresolved rather than choosing one.
aliases <- condo_links |> filter(filing_bbl %in% later$bbl,
    as.integer(substr(filing_bbl, 7, 10)) >= 7500) |>
  group_by(base_bbl) |> summarise(alias_count = n_distinct(filing_bbl),
    map_bbl = if (n_distinct(filing_bbl) == 1L) first(filing_bbl) else NA_character_, .groups = "drop")
direct <- filings |> filter(filing_bbl %in% later$bbl)
remaining <- filings |> anti_join(direct, by = c("parent_id", "filing_bbl"))
fallback <- bind_rows(
  remaining |> anti_join(condos, by = "filing_bbl") |> transmute(parent_id, bbl = filing_bbl),
  remaining |> inner_join(condos, by = "filing_bbl", relationship = "many-to-one") |>
    select(parent_id, base_bbls) |> unnest_longer(base_bbls, values_to = "bbl")
) |> left_join(aliases, by = c("bbl" = "base_bbl"), relationship = "many-to-one") |>
  mutate(bbl = if_else(bbl %in% later$bbl, bbl, coalesce(map_bbl, bbl)))
anchors <- bind_rows(direct |> transmute(parent_id, bbl = filing_bbl),
                     fallback |> select(parent_id, bbl)) |> distinct(parent_id, bbl) |>
  left_join(later |> st_drop_geometry() |> select(bbl, map_row, recorded_area_sqft),
            by = "bbl", relationship = "many-to-one") |>
  mutate(seen_earlier = bbl %in% maps$bbl[maps$vintage != "25v4"])
anchor_counts <- anchors |> group_by(parent_id) |>
  summarise(requested_lots = n(), mapped_lots = sum(!is.na(map_row)),
    missing_later_bbls = paste(bbl[is.na(map_row)], collapse = ";"),
    missing_lots_seen_earlier = sum(is.na(map_row) & seen_earlier),
    mapped_bbls = paste(sort(bbl[!is.na(map_row)]), collapse = ";"),
    later_recorded_sqft = if (all(!is.na(map_row) & recorded_area_sqft > 0 &
                                !is.na(recorded_area_sqft))) sum(recorded_area_sqft) else NA_real_,
    .groups = "drop")
matched <- anchors |> filter(!is.na(map_row))
sites <- st_sf(matched |> select(parent_id), geometry = st_geometry(later)[matched$map_row]) |>
  group_by(parent_id) |> summarise(.groups = "drop") |>
  mutate(later_geometry_sqft = as.numeric(st_area(geometry)))

# Intersect all sites with earlier parcels in batches by reference vintage.
# Store every overlap above one sq. ft. Material overlaps exceed 1% of either
# parcel or site, so thin map slivers do not add a whole neighboring parcel.
overlaps <- list()
measurements <- list()
for (vintage in sort(unique(parcels$vintage))) {
  reference <- parcels |> filter(.data$vintage == .env$vintage) |> distinct(parent_id, vintage)
  earlier <- maps |> filter(.data$vintage == .env$vintage)
  current <- sites |> semi_join(reference, by = "parent_id")
  intersection <- st_intersection(st_geometry(current), st_geometry(earlier))
  indices <- attr(intersection, "idx")
  pieces <- tibble(parent_id = current$parent_id[indices[, 1]], vintage,
    bbl = earlier$bbl[indices[, 2]], old_row = indices[, 2],
    old_geometry_sqft = earlier$geometry_area_sqft[indices[, 2]],
    old_recorded_sqft = earlier$recorded_area_sqft[indices[, 2]],
    overlap_sqft = as.numeric(st_area(intersection)),
    later_geometry_sqft = current$later_geometry_sqft[indices[, 1]]) |>
    mutate(old_share = overlap_sqft / old_geometry_sqft,
           site_share = overlap_sqft / later_geometry_sqft,
           material = overlap_sqft > 1 & (old_share >= 0.01 | site_share >= 0.01))
  stopifnot(!anyDuplicated(pieces[c("parent_id", "bbl")]),
            all(pieces$old_share <= 1.00001), all(pieces$site_share <= 1.00001))
  overlaps[[vintage]] <- pieces |> filter(overlap_sqft > 1) |> select(-old_row)

  # Union areas prevent overlaps between source polygons from double-counting.
  intersections <- st_sf(pieces |> select(parent_id), geometry = intersection)
  covered <- intersections |> filter(pieces$overlap_sqft > 1) |>
    group_by(parent_id) |> summarise(.groups = "drop") |>
    transmute(parent_id, covered_sqft = as.numeric(st_area(geometry))) |> st_drop_geometry()
  material_overlap <- intersections |> filter(pieces$material) |>
    group_by(parent_id) |> summarise(.groups = "drop") |>
    transmute(parent_id, material_overlap_sqft = as.numeric(st_area(geometry))) |> st_drop_geometry()
  whole_old <- st_sf(pieces |> filter(material) |> select(parent_id),
                    geometry = st_geometry(earlier)[pieces$old_row[pieces$material]]) |>
    group_by(parent_id) |> summarise(.groups = "drop") |>
    transmute(parent_id, whole_old_geometry_sqft = as.numeric(st_area(geometry))) |> st_drop_geometry()
  old_counts <- pieces |> filter(material) |> group_by(parent_id) |>
    summarise(old_lots = n(), old_bbls = paste(sort(bbl), collapse = ";"),
      partial_old_lots = sum(old_share < 0.98),
      old_recorded_sqft = if (all(!is.na(old_recorded_sqft) & old_recorded_sqft > 0))
        sum(old_recorded_sqft) else NA_real_, .groups = "drop")
  measurements[[vintage]] <- reference |>
    left_join(old_counts, by = "parent_id", relationship = "one-to-one") |>
    left_join(covered, by = "parent_id", relationship = "one-to-one") |>
    left_join(material_overlap, by = "parent_id", relationship = "one-to-one") |>
    left_join(whole_old, by = "parent_id", relationship = "one-to-one")
}
overlaps <- bind_rows(overlaps) |> arrange(parent_id, vintage, bbl)
comparison <- bind_rows(measurements) |>
  left_join(parents |> select(parent_id, sample, component_addresses, parent_total_units,
    n_components, production_area_sqft = lot_area_sqft, reason, mixed_vintages,
    condo_scope_review, source_bbl_disagreement, unusual_change),
    by = "parent_id", relationship = "many-to-one") |>
  left_join(anchor_counts, by = "parent_id", relationship = "many-to-one") |>
  left_join(base_counts, by = "parent_id", relationship = "many-to-one") |>
  left_join(sites |> st_drop_geometry(), by = "parent_id", relationship = "many-to-one") |>
  mutate(covered_sqft = coalesce(covered_sqft, 0),
    material_overlap_sqft = coalesce(material_overlap_sqft, 0),
    old_lots = coalesce(old_lots, 0L), partial_old_lots = coalesce(partial_old_lots, 0L),
    earlier_coverage_share = covered_sqft / later_geometry_sqft,
    later_uncovered_share = 1 - material_overlap_sqft / later_geometry_sqft,
    old_outside_share = 1 - material_overlap_sqft / whole_old_geometry_sqft,
    geometry_pattern = case_when(
      mapped_lots < requested_lots ~ "Missing later parcels",
      earlier_coverage_share < 0.98 ~ "Earlier map coverage gap",
      later_uncovered_share <= 0.02 & old_outside_share <= 0.02 ~ "Whole earlier parcels align",
      TRUE ~ "Part of earlier parcels"),
    source_scope_review = mixed_vintages | condo_scope_review | source_bbl_disagreement | unusual_change,
    old_recorded_difference_pct = 100 * (old_recorded_sqft / whole_old_geometry_sqft - 1),
    later_recorded_difference_pct = 100 * (later_recorded_sqft / later_geometry_sqft - 1),
    later_vs_production_pct = if_else(mapped_lots == requested_lots,
      100 * (later_geometry_sqft / production_area_sqft - 1), NA_real_),
    whole_lot_candidate_sqft = if_else(geometry_pattern == "Whole earlier parcels align",
      whole_old_geometry_sqft, NA_real_),
    candidate_vs_production_pct = 100 * (whole_lot_candidate_sqft / production_area_sqft - 1)) |>
  arrange(sample, parent_id, vintage)
stopifnot(setequal(comparison$parent_id, parents$parent_id),
          all(comparison$earlier_coverage_share <= 1.00001, na.rm = TRUE))

# The full weighting sample feeds the site-coverage audit. Preserve the original
# 166-parent comparison and atlas as a separately identified diagnostic cohort.
SaveData(overlaps, c("parent_id", "vintage", "bbl"), "../output/dof_all_parent_overlaps.parquet")
SaveData(comparison, c("parent_id", "vintage"), "../output/dof_all_parent_geometry.csv")
reviewed_parents <- parents |> filter(unresolved)
comparison <- comparison |> semi_join(reviewed_parents, by = "parent_id")
overlaps <- overlaps |> semi_join(reviewed_parents, by = "parent_id")

# Count each parent once. Mixed-vintage parents retain both rows above, and a
# separate category here rather than selecting a convenient reference map.
parent_summary <- comparison |> group_by(parent_id, sample) |>
  summarise(geometry_pattern = if (n() > 1L) "Multiple reference vintages" else first(geometry_pattern),
    source_scope_review = any(source_scope_review),
    candidate_vs_production_pct = if (n() == 1L) first(candidate_vs_production_pct) else NA_real_,
    .groups = "drop")
summary <- parent_summary |> group_by(sample, geometry_pattern) |>
  summarise(parents = n(), additional_source_reviews = sum(source_scope_review),
    area_comparisons = sum(!is.na(candidate_vs_production_pct)),
    median_candidate_change_pct = if (any(!is.na(candidate_vs_production_pct)))
      median(candidate_vs_production_pct, na.rm = TRUE) else NA_real_, .groups = "drop")
stopifnot(sum(summary$parents) == nrow(reviewed_parents))
SaveData(overlaps, c("parent_id", "vintage", "bbl"), "../output/dof_geometry_overlaps.parquet")
SaveData(comparison, c("parent_id", "vintage"), "../output/dof_geometry_comparison.csv")
SaveData(summary, c("sample", "geometry_pattern"), "../output/dof_geometry_summary.csv")
print(summary, n = Inf)

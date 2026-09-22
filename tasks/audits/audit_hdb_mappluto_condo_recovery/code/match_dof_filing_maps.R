# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)
library(tidyr)
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/dof_geometry_comparison.csv", show_col_types = FALSE) |>
  filter(!mixed_vintages, base_mapped_lots < base_requested_lots) |>
  rename(reference_vintage = vintage)
filing_dates <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  select(parent_id, cohort_date, parent_last_filing_date)
calendar <- read_csv("../input/mappluto_release_calendar.csv", show_col_types = FALSE) |>
  filter(source_id == "dcp_mappluto_archive", usable_for_training) |>
  transmute(vintage = tolower(gsub(".", "_", vintage, fixed = TRUE)),
            map_date = safe_available_date)
maps <- read_parquet("../output/dof_filing_map_lots.parquet") |>
  mutate(map_row = row_number()) |> st_as_sf(wkt = "wkt", crs = 2263)
reference_lots <- read_parquet("../output/dof_parent_parcels.parquet") |>
  semi_join(parents, by = "parent_id")
reference_maps <- read_parquet("../output/dof_geometry_lots.parquet")
events <- read_parquet("../output/dof_events.parquet") |> filter(reversible)
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id),
          !anyDuplicated(calendar$vintage), setequal(maps$vintage, calendar$vintage),
          !anyDuplicated(reference_lots[c("parent_id", "bbl")]))

anchors <- parents |> select(parent_id, base_mapped_bbls, base_missing_bbls) |>
  pivot_longer(-parent_id, values_to = "bbl") |> filter(!is.na(bbl)) |>
  separate_longer_delim(bbl, ";") |> distinct(parent_id, bbl)
# Evaluate every parent in every archive. A complete footprint requires every
# physical filing/base lot in ONE release; polygons never mix release dates.
mapped <- cross_join(anchors, calendar) |>
  left_join(maps |> st_drop_geometry() |> select(vintage, bbl, map_row),
            by = c("vintage", "bbl"), relationship = "many-to-one")
coverage <- mapped |> group_by(parent_id, vintage, map_date) |>
  summarise(requested_lots = n(), mapped_lots = sum(!is.na(map_row)),
    mapped_bbls = paste(sort(bbl[!is.na(map_row)]), collapse = ";"),
    missing_bbls = paste(sort(bbl[is.na(map_row)]), collapse = ";"),
    complete = all(!is.na(map_row)), .groups = "drop") |>
  left_join(filing_dates, by = "parent_id", relationship = "many-to-one") |>
  mutate(days_from_filing = as.integer(map_date - cohort_date)) |>
  arrange(parent_id, map_date)
stopifnot(nrow(coverage) == nrow(parents) * nrow(calendar),
          setequal(coverage$parent_id, parents$parent_id), !anyNA(coverage$cohort_date),
          all(coverage$mapped_lots <= coverage$requested_lots))

# Closest complete map to the first filing; an equally close earlier map wins.
# Calendar dates are archive-file dates, not legal dates of parcel changes.
complete <- coverage |> filter(complete)
selected <- complete |> arrange(parent_id, abs(days_from_filing), days_from_filing > 0) |>
  group_by(parent_id) |> slice_head(n = 1) |> ungroup()
before <- complete |> filter(days_from_filing <= 0) |>
  group_by(parent_id) |> slice_max(map_date, n = 1, with_ties = FALSE) |> ungroup() |>
  select(parent_id, prior_vintage = vintage, prior_map_date = map_date,
         prior_days_from_filing = days_from_filing)
after <- complete |> filter(days_from_filing > 0) |>
  group_by(parent_id) |> slice_min(map_date, n = 1, with_ties = FALSE) |> ungroup() |>
  select(parent_id, following_vintage = vintage, following_map_date = map_date,
         following_days_from_filing = days_from_filing)
availability <- coverage |> group_by(parent_id) |>
  summarise(complete_releases = sum(complete), most_lots_mapped = max(mapped_lots), .groups = "drop")

# A reused lot number cannot establish that an old map depicts the later site.
# Save every later physical transaction involving the selected base identifiers.
changes <- lapply(seq_len(nrow(selected)), function(i) {
  bbls <- strsplit(selected$mapped_bbls[i], ";")[[1]]
  relevant <- events |> filter(change_date > selected$map_date[i],
    vapply(all_bbls, function(x) any(x %in% bbls), logical(1)))
  tibble(parent_id = selected$parent_id[i], later_physical_changes = nrow(relevant),
    later_transactions = paste(relevant$transaction_id, collapse = ";"))
}) |> bind_rows()

chosen <- mapped |> semi_join(selected, by = c("parent_id", "vintage"))
stopifnot(!anyNA(chosen$map_row))
sites <- st_sf(chosen |> select(parent_id), geometry = st_geometry(maps)[chosen$map_row]) |>
  group_by(parent_id) |> summarise(.groups = "drop") |>
  mutate(filing_geometry_sqft = as.numeric(st_area(geometry)))
recorded <- chosen |> mutate(recorded_area_sqft = maps$recorded_area_sqft[map_row]) |>
  group_by(parent_id) |> summarise(filing_recorded_sqft =
    if (all(!is.na(recorded_area_sqft) & recorded_area_sqft > 0)) sum(recorded_area_sqft) else NA_real_,
    .groups = "drop")

# Compare with the existing DOF predecessor candidates, not an inferred project
# boundary. This asks whether those candidates contain the dated filing land.
earlier <- reference_lots |>
  left_join(reference_maps |> select(vintage, bbl, wkt),
            by = c("vintage", "bbl"), relationship = "many-to-one")
reference_coverage <- earlier |> group_by(parent_id) |>
  summarise(reference_lots = n(), missing_reference_lots = sum(is.na(wkt)), .groups = "drop")
earlier <- earlier |> filter(!is.na(wkt)) |> st_as_sf(wkt = "wkt", crs = 2263)
reference_sites <- earlier |> group_by(parent_id) |> summarise(.groups = "drop")
reference_sites$reference_geometry_sqft <- as.numeric(st_area(reference_sites))
intersection <- st_intersection(st_geometry(sites), st_geometry(reference_sites))
indices <- attr(intersection, "idx")
overlap <- tibble(parent_id = sites$parent_id[indices[, 1]],
  reference_parent = reference_sites$parent_id[indices[, 2]],
  overlap_sqft = as.numeric(st_area(intersection))) |>
  filter(parent_id == reference_parent) |> select(-reference_parent)
stopifnot(!anyDuplicated(overlap$parent_id))

matches <- parents |> transmute(parent_id, sample, component_addresses, parent_total_units,
    requested_lots = base_requested_lots, reference_vintage, production_area_sqft, source_scope_review,
    current_map_complete = geometry_pattern != "Missing later parcels", current_geometry_sqft = later_geometry_sqft) |>
  left_join(filing_dates, by = "parent_id", relationship = "one-to-one") |>
  left_join(selected |> select(parent_id, selected_vintage = vintage, selected_map_date = map_date,
                               days_from_filing, mapped_bbls),
            by = "parent_id", relationship = "one-to-one") |>
  left_join(calendar |> rename(reference_vintage = vintage, reference_map_date = map_date),
            by = "reference_vintage", relationship = "many-to-one") |>
  left_join(before, by = "parent_id", relationship = "one-to-one") |>
  left_join(after, by = "parent_id", relationship = "one-to-one") |>
  left_join(availability, by = "parent_id", relationship = "one-to-one") |>
  left_join(changes, by = "parent_id", relationship = "one-to-one") |>
  left_join(sites |> st_drop_geometry(), by = "parent_id", relationship = "one-to-one") |>
  left_join(recorded, by = "parent_id", relationship = "one-to-one") |>
  left_join(reference_coverage, by = "parent_id", relationship = "one-to-one") |>
  left_join(reference_sites |> st_drop_geometry(), by = "parent_id", relationship = "one-to-one") |>
  left_join(overlap, by = "parent_id", relationship = "one-to-one") |>
  mutate(overlap_sqft = if_else(is.na(selected_vintage), NA_real_, coalesce(overlap_sqft, 0)),
    filing_outside_reference_share = if_else(missing_reference_lots == 0,
      1 - overlap_sqft / filing_geometry_sqft, NA_real_),
    reference_outside_filing_share = if_else(missing_reference_lots == 0,
      1 - overlap_sqft / reference_geometry_sqft, NA_real_),
    map_availability = case_when(
      is.na(selected_vintage) ~ "No complete archived map",
      abs(days_from_filing) <= 180 ~ "Complete map within 180 days",
      abs(days_from_filing) <= 365 ~ "Complete map 181-365 days away",
      TRUE ~ "Complete map more than a year away"),
    boundary_comparison = case_when(
      is.na(selected_vintage) ~ "No complete archived map",
      later_physical_changes > 0 ~ "Later DOF changes require parcel tracing",
      missing_reference_lots > 0 ~ "Incomplete reference candidates",
      selected_map_date <= reference_map_date ~ "No later boundary comparison",
      filing_outside_reference_share <= 0.02 & reference_outside_filing_share <= 0.02 ~
        "DOF candidates align with filing parcels",
      filing_outside_reference_share > 0.02 ~ "DOF candidates miss some filing land",
      TRUE ~ "DOF candidates include land outside filing parcels"),
    filing_geometry_vs_production_pct = 100 * (filing_geometry_sqft / production_area_sqft - 1),
    filing_recorded_vs_production_pct = 100 * (filing_recorded_sqft / production_area_sqft - 1)) |>
  arrange(sample, parent_id)
stopifnot(nrow(matches) == nrow(parents), setequal(matches$parent_id, parents$parent_id),
          all(matches$overlap_sqft <= matches$filing_geometry_sqft + 0.01, na.rm = TRUE),
          all(matches$overlap_sqft <= matches$reference_geometry_sqft + 0.01, na.rm = TRUE))
SaveData(coverage, c("parent_id", "vintage"), "../output/dof_filing_map_coverage.csv")
SaveData(matches, "parent_id", "../output/dof_filing_map_matches.csv")
print(count(matches, sample, map_availability), n = Inf)
print(count(matches, boundary_comparison), n = Inf)

# Draw the same comparison for every parent, including unmatched parents.
pdf("../output/dof_filing_map_footprints.pdf", width = 10, height = 8)
par(mar = c(4, 1, 6, 1))
for (i in seq_len(nrow(matches))) {
  row <- matches[i, ]
  old <- earlier |> filter(parent_id == row$parent_id)
  current <- maps |> filter(vintage == row$selected_vintage,
                           bbl %in% strsplit(coalesce(row$mapped_bbls, ""), ";")[[1]])
  if (nrow(old) + nrow(current) > 0) {
    extent <- st_bbox(c(st_geometry(old), st_geometry(current)))
    plot(c(st_geometry(old), st_geometry(current)), col = NA, border = NA,
         xlim = extent[c("xmin", "xmax")], ylim = extent[c("ymin", "ymax")])
    if (nrow(old)) plot(st_geometry(old), add = TRUE, col = "#d6e5ef", border = "#57778b")
    if (nrow(current)) plot(st_geometry(current), add = TRUE, col = NA, border = "#b54228", lwd = 2)
  } else {
    plot.new()
    text(0.5, 0.5, "Requested lots are absent from the saved maps.")
  }
  title(main = paste(strwrap(gsub(";", " / ", row$component_addresses), 80), collapse = "\n"),
        line = 3, cex.main = 1)
  mtext(paste0("First filing: ", row$cohort_date, " | Reference: ", row$reference_vintage,
    " | Selected: ", coalesce(row$selected_vintage, "none"),
    " | Days from filing: ", coalesce(as.character(row$days_from_filing), "NA")), side = 3, line = 1, cex = 0.8)
  mtext(row$boundary_comparison, side = 1, line = 1, cex = 0.85)
  mtext("Blue: DOF predecessor candidates. Red: complete filing lots in the selected map.\nParcel outlines do not establish the original project boundary.",
        side = 1, line = 2.5, cex = 0.75)
}
dev.off()

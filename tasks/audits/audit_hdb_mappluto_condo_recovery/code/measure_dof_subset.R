# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(dplyr)
library(readr)
library(arrow)
library(sf)
library(ggplot2)
source("../../../shared/code/write_data_report.R")

# The September 15 draw selected nine historical and three post-policy flags
# (seed 20260915). These are the reviewed parcel definitions saved before the
# historical source correction; this physical measurement exercise keeps them fixed.
coverage <- read_csv("dof_subset_parent_definitions_2026-09-22.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(coverage$parent_id))
reviews <- read_csv("dof_subset_review.csv", show_col_types = FALSE,
                    col_types = cols(before_map_id = col_character(), after_map_id = col_character()))
selected <- coverage |> semi_join(reviews, by = "parent_id") |> arrange(sample, parent_id)
stopifnot(!anyDuplicated(reviews$parent_id), setequal(selected$parent_id, reviews$parent_id))
selected <- selected |> left_join(reviews, by = "parent_id", relationship = "one-to-one")

# Published 25v4 areas describe the later filing parcels. They are a comparison,
# not adopted replacements for the land available at the original filing date.
pluto <- read_csv(unz("../input/nyc_pluto_25v4_csv.zip", "pluto_25v4.csv"),
                  col_select = c(bbl, lotarea), col_types = cols(bbl = col_double())) |>
  mutate(bbl = sprintf("%.0f", bbl))
stopifnot(!anyDuplicated(pluto$bbl))
dof <- rbind(
  st_read("../input/dof_subset_filing_parcels.geojson", quiet = TRUE),
  st_read("../input/dof_subset_godwin_companion.geojson", quiet = TRUE))
stopifnot(!anyDuplicated(dof$BBL), st_crs(dof)$epsg == 2263)

# Include blocks touched by the selected DOF transactions, including changes
# crossing a block boundary. This supplies the old maps without address rules.
events <- read_parquet("../output/dof_events.parquet")
event_ids <- unique(unlist(strsplit(selected$reviewed_transaction_ids, ";")))
blocks <- unique(substr(c(unlist(strsplit(selected$filing_bbls, ";")),
  unlist(events$all_bbls[events$transaction_id %in% event_ids])), 1, 6))
archives <- c(
  "18v2beta" = "../input/nyc_mappluto_18v2_arc_shp.zip",
  "20v5" = "../input/nyc_mappluto_20v5_arc_shp.zip",
  "20v8" = "../input/nyc_mappluto_20v8_arc_shp.zip",
  "21v1" = "../input/nyc_mappluto_21v1_arc_shp.zip",
  "23v3_1" = "../input/nyc_mappluto_23v3_1_arc_shp.zip",
  "25v4" = "../input/nyc_mappluto_25v4_shp.zip"
)
maps <- list()
for (vintage in names(archives)) {
  archive <- archives[[vintage]]
  shape <- unzip(archive, list = TRUE)$Name
  shape <- shape[grepl("(^|/)MapPLUTO.shp$", shape, ignore.case = TRUE)]
  stopifnot(length(shape) == 1)
  query <- paste0("SELECT BBL, Lot, LotArea FROM ", tools::file_path_sans_ext(basename(shape)),
    " WHERE ", paste0("(BBL >= ", blocks, "0000 AND BBL <= ", blocks, "9999)", collapse = " OR "))
  maps[[vintage]] <- st_read(paste0("/vsizip/", normalizePath(archive), "/", shape),
                             query = query, quiet = TRUE) |>
    mutate(bbl = sprintf("%.0f", BBL)) |> st_make_valid()
  stopifnot(!anyDuplicated(maps[[vintage]]$bbl), st_crs(maps[[vintage]])$epsg == 2263)
}

measurements <- list()
figures <- list()
for (i in seq_len(nrow(selected))) {
  parent <- selected[i, ]
  bbls <- strsplit(parent$filing_bbls, ";")[[1]]
  earlier <- maps[[parent$vintages]]
  later <- maps[["25v4"]] |> filter(bbl %in% bbls)
  site <- st_union(st_geometry(later))
  nearby <- earlier[lengths(st_intersects(earlier, site)) > 0, ]

  # Intersect geometry only, then attach its original parcel attributes by index.
  overlap <- st_intersection(st_geometry(nearby), site)
  old_index <- attr(overlap, "idx")[, 1]
  pieces <- tibble(bbl = nearby$bbl[old_index], old_area_sqft = nearby$LotArea[old_index],
    overlap_sqft = as.numeric(st_area(overlap)),
    old_polygon_sqft = as.numeric(st_area(nearby))[old_index]) |>
    filter(overlap_sqft > 1) |>
    mutate(overlap_share = overlap_sqft / old_polygon_sqft)
  stopifnot(!anyDuplicated(pieces$bbl), all(pieces$overlap_share <= 1.00001))

  dof_site <- st_union(st_geometry(dof[dof$BBL %in% bbls, ]))
  dof_agreement <- NA_real_
  if (length(dof_site) && !st_is_empty(dof_site)) {
    dof_agreement <- as.numeric(st_area(st_intersection(site, dof_site)) /
                                 st_area(st_union(site, dof_site)))
  }
  missing_bbls <- setdiff(bbls, later$bbl)
  matched_area <- sum(pluto$lotarea[match(later$bbl, pluto$bbl)])
  use_comparison <- parent$review_status == "comparison"
  if (use_comparison) stopifnot(length(missing_bbls) == 0, matched_area > 0,
                                !is.na(dof_agreement), dof_agreement > 0.99)
  measurements[[i]] <- parent |>
    transmute(parent_id, sample, component_addresses, parent_total_units, n_components,
      reference_vintage = vintages, filing_bbls, production_area_sqft = lot_area_sqft,
      matched_25v4_area_sqft = matched_area,
      missing_25v4_bbls = paste(missing_bbls, collapse = ";"),
      comparison_area_sqft = if (use_comparison) matched_area else NA_real_,
      old_overlap_bbls = paste(pieces$bbl, collapse = ";"),
      old_overlap_shares = paste(round(pieces$overlap_share, 4), collapse = ";"),
      earlier_attribute_allocation_sqft = sum(pieces$old_area_sqft * pieces$overlap_share),
      old_geometry_coverage = sum(pieces$overlap_sqft) / as.numeric(st_area(site)),
      dof_geometry_agreement = dof_agreement,
      review_status, before_map_id, after_map_id, reviewed_transaction_ids, review_note)

  # Show entire predecessor parcels so excluded portions remain visible.
  shown <- nearby |> filter(bbl %in% pieces$bbl)
  bounds <- st_bbox(st_union(c(st_geometry(shown), site)))
  pad <- max(bounds[c("xmax", "ymax")] - bounds[c("xmin", "ymin")]) * 0.08
  labels <- st_coordinates(st_point_on_surface(st_geometry(shown)))
  labels <- tibble(x = labels[, 1], y = labels[, 2], lot = shown$Lot)
  subtitle <- paste0("Blue: earlier parcels (", parent$vintages,
    "); red: mapped filing parcels (PLUTO 25v4)\nRecorded area: ",
    format(parent$lot_area_sqft, big.mark = ","), " sq. ft.; ",
    if (use_comparison) paste0("comparison: ", format(matched_area, big.mark = ","), " sq. ft.")
    else "project extent unresolved; omitted from averages")
  figures[[i]] <- ggplot() +
    geom_sf(data = shown, fill = "#d6e5ef", color = "#57778b", linewidth = 0.5) +
    geom_sf(data = later, fill = NA, color = "#b54228", linewidth = 1) +
    geom_text(data = labels, aes(x, y, label = lot), size = 3.5) +
    coord_sf(xlim = bounds[c("xmin", "xmax")] + c(-pad, pad),
             ylim = bounds[c("ymin", "ymax")] + c(-pad, pad), datum = NA) +
    labs(title = paste(strwrap(gsub(";", " / ", parent$component_addresses), 70), collapse = "\n"),
         subtitle = subtitle,
         caption = paste("Earlier lot numbers are printed inside blue parcels. DOF map:", parent$after_map_id)) +
    theme_void() + theme(plot.title = element_text(size = 13, face = "bold"),
                         plot.subtitle = element_text(size = 10), plot.caption = element_text(size = 8))
}

comparison <- bind_rows(measurements) |>
  mutate(change_sqft = comparison_area_sqft - production_area_sqft,
         change_pct = 100 * change_sqft / production_area_sqft)
SaveData(comparison, "parent_id", "../output/dof_subset_comparison.csv")

# Each parent counts once. The pooled row is descriptive for these ten cases;
# it is not an estimate for all 166 flags, and the unresolved cases are missing.
usable <- comparison |> filter(review_status == "comparison")
summary <- bind_rows(usable |> mutate(group = "all_compared"),
                     usable |> mutate(group = sample)) |>
  group_by(group) |>
  summarise(n = n(), decreases = sum(change_sqft < 0), increases = sum(change_sqft > 0),
    mean_production_sqft = mean(production_area_sqft),
    mean_comparison_sqft = mean(comparison_area_sqft), mean_change_sqft = mean(change_sqft),
    change_in_mean_pct = 100 * (sum(comparison_area_sqft) / sum(production_area_sqft) - 1),
    median_change_pct = median(change_pct), mean_change_pct = mean(change_pct),
    mean_absolute_change_sqft = mean(abs(change_sqft)),
    median_absolute_change_pct = median(abs(change_pct)), .groups = "drop")
SaveData(summary, "group", "../output/dof_subset_summary.csv")

pdf("../output/dof_subset_footprints.pdf", width = 10, height = 8)
for (figure in figures) print(figure)
dev.off()

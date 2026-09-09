# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
# map_type <- "earnings"
suppressPackageStartupMessages({library(readr); library(dplyr); library(sf); library(ggplot2)})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
map_type <- args[1]
stopifnot(map_type %in% c("earnings", "overlay"))
if (map_type == "overlay") {
  filings <- arrow::read_parquet("../input/geographic_filings.parquet") |>
    filter(sample == "post_policy", constituent_units == 99)
  stopifnot(!anyDuplicated(filings$root_job_id))
  points <- filings |> filter(coordinate_status == "inside reported borough") |>
    mutate(parent_type = if_else(parent_total_units == 99, "99-unit parent", "Larger parent")) |>
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |> st_transform(2263)
  cat("Post-period exact-99 filings mapped:", nrow(points), "of", nrow(filings), "\n")
}
earnings <- read_csv("../output/community_district_earnings.csv", col_types = cols(puma = col_character()))
cd <- st_read("../input/community_districts_2026-09-08.geojson", quiet = TRUE) |>
  mutate(boro_cd = as.integer(boro_cd)) |> filter(boro_cd %% 100 < 20) |>
  st_transform(2263) |> st_make_valid()
stopifnot(nrow(cd) == 59, !anyDuplicated(cd$boro_cd))
borough_labels <- data.frame(label = c("BRONX", "BROOKLYN", "MANHATTAN", "QUEENS", "STATEN ISLAND"),
                             longitude = c(-73.855, -73.955, -74.04, -73.775, -74.16),
                             latitude = c(40.917, 40.572, 40.79, 40.805, 40.49)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |> st_transform(2263)
# One common scale across both worker universes; no bins based on the outcomes.
color_limits <- range(earnings$earnings, na.rm = TRUE)
if (map_type == "overlay") {
  pdf("../output/community_district_99_overlay.pdf", width = 11, height = 11)
} else {
  pdf("../output/community_district_earnings_map.pdf", width = 11, height = 11)
}
for (worker_universe in c("All employed", "Full-time, year-round")) {
  estimates <- earnings |> filter(universe == worker_universe)
  stopifnot(!anyDuplicated(estimates$boro_cd))
  map <- cd |> left_join(estimates, by = "boro_cd", relationship = "one-to-one")
  labels <- suppressWarnings(st_point_on_surface(map)) |>
    mutate(label = paste0(community_district, if_else(pooled, "p", ""), if_else(coalesce(imprecise, FALSE), "*", "")))
  figure <- ggplot(map) +
    geom_sf(aes(fill = earnings), color = "white", linewidth = .3) +
    geom_sf_text(data = labels, aes(label = label), size = 2.8, color = "black") +
    geom_sf_text(data = borough_labels, aes(label = label), size = 3.8, fontface = "bold", color = "#414141") +
    scale_fill_gradientn(colors = c("#EFF3FF", "#BDD7E7", "#6BAED6", "#2171B5"),
                         limits = color_limits, labels = scales::label_dollar(scale = .001, suffix = "k"),
                         na.value = "grey80", name = "Median annual\nearnings") +
    coord_sf(datum = NA) +
    labs(title = "Construction earnings across NYC community districts",
         subtitle = paste0(worker_universe, ": 2019-2023 ACS, in 2023 dollars"),
         caption = "59 district outlines; 55 published Census PUMA estimates. District numbers are within each borough.\np = paired districts share one estimate: Bronx 1+2 and 3+6; Manhattan 1+2 and 5+6. PUMA and district borders approximate each other.\n* = 90% margin of error exceeds 50% of the estimate. Both pages use the same color scale.\nEarnings describe residents, not wages on local construction sites. Sources: Census B24031/B24041; NYC DCP boundaries.") +
    theme_void(base_size = 12) +
    theme(plot.title = element_text(face = "bold", size = 18), plot.subtitle = element_text(size = 13),
          legend.position = "right", plot.caption = element_text(hjust = 0, size = 8.5),
          plot.margin = margin(14, 14, 14, 14))
  if (map_type == "overlay") {
    figure <- figure +
      geom_sf(data = points, aes(shape = parent_type), color = "white", size = 3.1,
              inherit.aes = FALSE, show.legend = FALSE) +
      geom_sf(data = points, aes(color = parent_type, shape = parent_type), size = 2.3,
              inherit.aes = FALSE) +
      scale_color_manual(values = c("99-unit parent" = "#BD242A", "Larger parent" = "#C76C00")) +
      scale_shape_manual(values = c("99-unit parent" = 16, "Larger parent" = 17)) +
      guides(fill = guide_colorbar(order = 1), color = guide_legend(order = 2), shape = guide_legend(order = 2)) +
      labs(title = "99-unit filings over pre-policy construction earnings",
           color = "99-unit filing", shape = "99-unit filing",
           subtitle = paste0(worker_universe, ": 2019-2023 earnings; filings Jan 2025-Jul 8, 2026"),
           caption = paste0("Post-period A/B sample: ", nrow(points), " of ", nrow(filings), " exact-99 filings mapped. Coincident points overlap; this is not a local bunching rate.\n",
             "Circles: parent totals 99. Triangles: 99-unit filing within a larger linked parent.\n",
             "59 district outlines use 55 Census estimates. p = paired districts (BX 1+2, 3+6; MN 1+2, 5+6). * = relative 90% MOE above 50%.\n",
             "Annual resident earnings in 2023 dollars, not local job-site wages. Sources: ACS B24031/B24041, DOB NOW filings, NYC DCP."))
  }
  print(figure)
}
dev.off()

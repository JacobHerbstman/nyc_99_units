# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)
library(ggplot2)

comparison <- read_csv("../output/dof_geometry_comparison.csv", show_col_types = FALSE)
summary <- read_csv("../output/dof_geometry_summary.csv", show_col_types = FALSE)
overlaps <- read_parquet("../output/dof_geometry_overlaps.parquet")
parcels <- read_parquet("../output/dof_parent_parcels.parquet")
maps <- read_parquet("../output/dof_geometry_lots.parquet") |> st_as_sf(wkt = "wkt", crs = 2263)

overview <- ggplot(summary, aes(parents, geometry_pattern, fill = sample)) +
  geom_col(position = "stack", width = 0.7) +
  geom_text(aes(label = parents), position = position_stack(vjust = 0.5), color = "white", size = 4) +
  scale_fill_manual(values = c(historical = "#436d8a", post_policy = "#b46832"),
                    labels = c(historical = "2019-2022", post_policy = "2025-July 8, 2026")) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.04))) +
  labs(title = "What the parcel maps establish for 166 flagged parents",
    subtitle = "Each parent counts once; two parents have multiple reference vintages",
    x = "Parents", y = NULL, fill = NULL,
    caption = "Map agreement allows a 2% area difference on each side. It does not establish ownership or the original development boundary.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", panel.grid.major.y = element_blank(),
    plot.caption = element_text(hjust = 0, size = 9), plot.margin = margin(12, 12, 12, 12))
ggsave("../output/dof_geometry_overview.pdf", overview, width = 11, height = 5.5, bg = "white")
ggsave("../output/dof_geometry_overview.png", overview, width = 11, height = 5.5, dpi = 180, bg = "white")

# One page per parent/reference vintage, with the same drawing rules throughout.
pdf("../output/dof_geometry_footprints.pdf", width = 10, height = 8)
for (i in seq_len(nrow(comparison))) {
  row <- comparison[i, ]
  old_bbls <- overlaps |>
    filter(parent_id == row$parent_id, vintage == row$vintage, material) |> pull(bbl)
  if (!length(old_bbls)) {
    old_bbls <- parcels |> filter(parent_id == row$parent_id, vintage == row$vintage) |> pull(bbl)
  }
  earlier <- maps |> filter(vintage == row$vintage, bbl %in% old_bbls)
  later <- maps |> filter(vintage == "25v4", bbl %in% strsplit(coalesce(row$mapped_bbls, ""), ";")[[1]])
  all_geometry <- c(st_geometry(earlier), st_geometry(later))
  figure <- ggplot() + theme_void() +
    labs(title = paste(strwrap(gsub(";", " / ", row$component_addresses), 70), collapse = "\n"),
      subtitle = paste0(row$geometry_pattern, "; reference: ", row$vintage,
        "\nCurrent input: ", format(round(row$production_area_sqft), big.mark = ","),
        " sq. ft.; mapped later land: ", format(round(row$later_geometry_sqft), big.mark = ","),
        " sq. ft.\nMapped lots: ", row$mapped_lots, "/", row$requested_lots,
        "; other DOF flags: ", ifelse(row$source_scope_review, "yes", "no")),
      caption = paste0(row$parent_id, " | Blue: overlapping earlier parcels; red: mapped later parcels.\n",
        "MapPLUTO shoreline-clipped geometry. Later outlines do not establish the original land endowment.")) +
    theme(plot.title = element_text(size = 13, face = "bold"),
      plot.subtitle = element_text(size = 10), plot.caption = element_text(size = 8),
      plot.margin = margin(12, 12, 12, 12))
  if (length(all_geometry)) {
    box <- st_bbox(st_union(all_geometry))
    pad <- max(box[c("xmax", "ymax")] - box[c("xmin", "ymin")]) * 0.08
    labels <- st_coordinates(st_point_on_surface(st_geometry(earlier)))
    labels <- tibble(x = labels[, 1], y = labels[, 2], lot = as.integer(substr(earlier$bbl, 7, 10)))
    figure <- figure + geom_sf(data = earlier, fill = "#d6e5ef", color = "#57778b", linewidth = 0.4) +
      geom_sf(data = later, fill = NA, color = "#b54228", linewidth = 0.9) +
      geom_text(data = labels, aes(x, y, label = lot), size = 3) +
      coord_sf(xlim = box[c("xmin", "xmax")] + c(-pad, pad),
               ylim = box[c("ymin", "ymax")] + c(-pad, pad), datum = NA)
  }
  print(figure)
}
dev.off()

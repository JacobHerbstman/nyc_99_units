# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_borough_bunching/code")
suppressPackageStartupMessages({library(arrow); library(dplyr); library(sf); library(ggplot2)})
filings <- read_parquet("../output/geographic_filings.parquet") |> filter(constituent_units == 99)
coverage <- filings |> group_by(sample) |>
  summarise(total = n(), mapped = sum(coordinate_status == "inside reported borough"), .groups = "drop")
print(coverage)
boroughs <- st_read("../input/borough_boundaries_2026-09-08.geojson", quiet = TRUE) |>
  st_transform(2263) |> st_make_valid()
points <- filings |> filter(coordinate_status == "inside reported borough") |>
  mutate(period = factor(sample, levels = c("historical", "post_policy"),
                         labels = c("Pre: 2019-2022", "Post: Jan 2025-Jul 8, 2026")),
         parent_type = if_else(parent_total_units == 99, "Parent totals 99", "Part of a larger parent")) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |> st_transform(2263)
labels <- data.frame(label = c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten\nIsland"),
                     longitude = c(-73.855, -73.955, -74.025, -73.79, -74.16),
                     latitude = c(40.889, 40.60, 40.79, 40.735, 40.59)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |> st_transform(2263)
figure <- ggplot() + geom_sf(data = boroughs, fill = "#F1F0EB", color = "#B7B8B5", linewidth = .25) +
  geom_sf(data = points, aes(color = parent_type, shape = parent_type), size = 2.2, alpha = .8) +
  geom_sf_text(data = labels, aes(label = label), size = 3.1, color = "#555555") +
  facet_wrap(~period, nrow = 1) +
  scale_color_manual(values = c("Parent totals 99" = "#B74437", "Part of a larger parent" = "#246FAD")) +
  scale_shape_manual(values = c("Parent totals 99" = 16, "Part of a larger parent" = 17)) +
  coord_sf(datum = NA) +
  labs(title = "Where are the exact 99-unit filings?",
       subtitle = "A/B rental-opportunity sample; each point is a constituent filing with 99 proposed units",
       color = NULL, shape = NULL,
       caption = paste0("Mapped filings: pre ", coverage$mapped[coverage$sample == "historical"], "/", coverage$total[coverage$sample == "historical"],
                        "; post ", coverage$mapped[coverage$sample == "post_policy"], "/", coverage$total[coverage$sample == "post_policy"],
                        ". Coincident points overlap; counts are not annualized.\n",
                        "Sources: DCP Housing Database 23Q4 (pre); DOB NOW initial filings (post); NYC DCP borough boundaries, Sep 8, 2026 extract.\n",
                        "Larger-parent membership describes linked filings and does not by itself establish policy-induced splitting.")) +
  theme_void(base_size = 11) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold", size = 12), plot.caption = element_text(hjust = 0, size = 8.5),
        plot.margin = margin(12, 12, 12, 12))
ggsave("../output/exact_99_map.pdf", figure, width = 12, height = 7.7)

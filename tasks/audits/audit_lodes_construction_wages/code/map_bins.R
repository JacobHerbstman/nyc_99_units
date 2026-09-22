# setwd("tasks/audits/audit_lodes_construction_wages/code")
library(readr)
library(dplyr)
library(sf)
library(ggplot2)
d <- read_csv("../output/district_construction_bins.csv", show_col_types = FALSE)
cd <- st_read("../input/community_districts.geojson", quiet = TRUE) |> mutate(boro_cd = as.integer(boro_cd)) |> filter(boro_cd %% 100 < 20) |> st_transform(2263) |> st_make_valid()
stopifnot(nrow(cd) == 59, !anyDuplicated(cd$boro_cd))
labels <- suppressWarnings(st_point_on_surface(cd)) |> mutate(label = paste0(c("MN", "BX", "BK", "QN", "SI")[boro_cd %/% 100], " ", boro_cd %% 100))
pdf("../output/workplace_earnings_maps.pdf", width = 10, height = 10)
for (period_year in c(0, 2019:2023)) {
  for (bin in if (period_year == 0) c("SE01", "SE02", "SE03") else "SE03") {
    estimates <- d |> filter(year == period_year)
    stopifnot(!anyDuplicated(estimates$boro_cd))
    map <- cd |> left_join(estimates, by = "boro_cd", relationship = "one-to-one")
    print(ggplot(map) + geom_sf(aes(fill = .data[[paste0("share_", bin)]]), color = "white", linewidth = 0.3) +
      geom_sf_text(data = labels, aes(label = label), size = 2.5) +
      scale_fill_viridis_c(limits = c(0, 1), labels = scales::label_percent(), name = "Share of jobs", na.value = "grey80") +
      coord_sf(datum = NA) + theme_void(base_size = 11) +
      labs(title = paste0("Construction workplace jobs: ", c(SE01 = "at most $1,250/month", SE02 = "$1,251-$3,333/month", SE03 = "over $3,333/month")[[bin]]),
        subtitle = if (period_year == 0) "2019-2023 pooled job counts, by community district" else paste(period_year, "job counts, by community district"),
        caption = "Source: Census LODES WAC, all private jobs, construction industry. 59 NYC community districts.\nWorkplace blocks assigned using internal points. Employer offices may differ from construction sites.\nMonthly earnings bins are nominal and do not measure hourly pay. Gray indicates no construction jobs.") +
      theme(plot.title = element_text(face = "bold", size = 15), plot.caption = element_text(hjust = 0), plot.margin = margin(12,12,12,12)))
  }
}
dev.off()

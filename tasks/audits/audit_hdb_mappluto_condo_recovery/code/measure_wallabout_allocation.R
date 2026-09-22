# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(sf)
source("../../../shared/code/write_data_report.R")

maps <- read_parquet("../output/dof_geometry_lots.parquet")
lots <- read_parquet("../input/dcp_mappluto_archive_18v2_1.parquet")
# The completed sites are identified in the 2023 appraisal pp289/320 and
# corroborated by DOF's 2021 map. 251 Wallabout is outside this cohort parent.
old <- maps |>
  filter(vintage == "18v2_1", bbl %in% c("3022490023", "3022490037", "3022490041", "3022490122")) |>
  st_as_sf(wkt = "wkt", crs = 2263)
new <- maps |>
  filter(vintage == "25v4", bbl %in% c("3022490023", "3022490122", "3022497504")) |>
  st_as_sf(wkt = "wkt", crs = 2263)
stopifnot(nrow(old) == 4, nrow(new) == 3, !anyDuplicated(old$bbl),
  !anyDuplicated(new$bbl), sum(new$recorded_area_sqft) == 39323)
intersection <- st_intersection(st_geometry(new), st_geometry(old))
index <- attr(intersection, "idx")
overlap <- tibble(development_bbl = new$bbl[index[, 1]], reference_bbl = old$bbl[index[, 2]],
  overlap_sqft = as.numeric(st_area(intersection)),
  development_map_sqft = new$geometry_area_sqft[index[, 1]],
  development_recorded_sqft = new$recorded_area_sqft[index[, 1]]) |>
  group_by(development_bbl) |>
  mutate(map_coverage = sum(overlap_sqft) / development_map_sqft,
    # Preserve each recorded land total. GIS overlap allocates it across the
    # earlier zoning parcels; these shares are a mapped approximation.
    allocated_recorded_sqft = development_recorded_sqft * overlap_sqft / sum(overlap_sqft)) |>
  ungroup()
allocation <- overlap |>
  group_by(reference_bbl) |>
  summarise(development_area_sqft = sum(allocated_recorded_sqft), .groups = "drop") |>
  left_join(lots |> select(reference_bbl = bbl, reference_recorded_area_sqft = lotarea,
    earlier_floor_sqft = bldgarea, residential_far = residfar),
    by = "reference_bbl", relationship = "one-to-one")
stopifnot(all(overlap$map_coverage > .999), nrow(allocation) == 3,
  abs(sum(allocation$development_area_sqft) - 39323) < 1e-8,
  all(allocation$earlier_floor_sqft == 0), !anyNA(allocation$residential_far))
SaveData(overlap, c("development_bbl", "reference_bbl"), "../output/wallabout_map_overlaps.csv")
SaveData(allocation, "reference_bbl", "../output/wallabout_land_allocation.csv")

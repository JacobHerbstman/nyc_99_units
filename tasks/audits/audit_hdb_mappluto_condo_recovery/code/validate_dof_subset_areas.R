# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(dplyr)
library(readr)
library(jsonlite)
library(sf)
source("../../../shared/code/write_data_report.R")

# DOF assessment years 2023-27, retrieved September 15, 2026. The separate
# count query verifies complete retrieval of the 34 requested filing/nearby BBLs.
assessments <- fromJSON("../input/dof_subset_assessments.json") |> as_tibble()
source_count <- fromJSON("../input/dof_subset_assessment_count.json")
stopifnot(nrow(assessments) == as.integer(source_count$rows),
          !anyDuplicated(assessments[c("parid", "year", "period", "rectype")]),
          all(assessments$rectype == "1"), !"easement" %in% names(assessments))
# Socrata omits the requested easement field because it is null in every row.

# The DOF record layout defines period 3 as the published final roll. Year 2027
# means fiscal 2026/27; its May 15, 2026 extract is not a 2027-calendar snapshot.
history <- assessments |> filter(period == "3") |>
  transmute(bbl = parid, fiscal_year_end = as.integer(year),
    extract_date = as.Date(substr(extracrdt, 1, 10)),
    area_sqft = as.numeric(land_area), frontage_ft = as.numeric(lot_frt),
    depth_ft = as.numeric(lot_dep), irregular = lot_irreg) |>
  arrange(bbl, fiscal_year_end)
stopifnot(!anyDuplicated(history[c("bbl", "fiscal_year_end")]))

review <- read_csv("dof_lot_measurement_review.csv", show_col_types = FALSE,
                   col_types = cols(.default = col_character()))
comparison <- read_csv("../output/dof_subset_comparison.csv", show_col_types = FALSE,
  col_types = cols(before_map_id = col_character(), after_map_id = col_character()))
stopifnot(!anyDuplicated(review$bbl),
          setequal(review$parent_id, comparison$parent_id))
pluto <- read_csv(unz("../input/nyc_pluto_25v4_csv.zip", "pluto_25v4.csv"),
  col_select = c(bbl, lotarea), col_types = cols(bbl = col_double())) |>
  transmute(bbl = sprintf("%.0f", bbl), pluto_25v4_area_sqft = lotarea)
stopifnot(!anyDuplicated(pluto$bbl))
parcels <- st_read(paste0("/vsizip/", normalizePath("../input/nyc_mappluto_25v4_shp.zip"),
                         "/MapPLUTO.shp"),
  query = paste0("SELECT BBL FROM MapPLUTO WHERE BBL IN (", paste(review$bbl, collapse = ","), ")"),
  quiet = TRUE) |> mutate(bbl = sprintf("%.0f", BBL), pluto_geometry_sqft = as.numeric(st_area(geometry)))
stopifnot(!anyDuplicated(parcels$bbl), st_crs(parcels)$epsg == 2263)

# Calculate checks from the printed boundary dimensions, not the map's pixels.
# Sackett's deed supplies right-angle directions. The other map calculations
# approximate orthogonal block edges; they are not substitute surveys.
godwin <- tibble(x = c(0, -61.15, -61.15, -83.71, -133.93, -125, -125, -20, -20, 0),
                y = c(0, 0, 55.88, 55.88, 125, 125, 145, 145, 100, 100))
godwin_area <- abs(sum(godwin$x * lead(godwin$y, default = godwin$y[1]) -
                      lead(godwin$x, default = godwin$x[1]) * godwin$y)) / 2
dimensions <- tribble(
  ~bbl, ~dimension_area_sqft,
  "3022650022", (28.33 + 152.12) * 200 / 2,
  "2029740030", 100 * 100.15,
  "2037970033", 200.16 * 105.58,
  "2039630057", mean(c(138.21, 138.30)) * mean(c(64.67, 64.78)),
  "4099990001", 175.20 * 100.13 + 125 * 100.09,
  "2057000079", godwin_area,
  "2036720020", 224.50 * 91.53,
  "2036720001", mean(c(564.86, 564.87)) * 200.03,
  "3004260017", 265 * 100 - 10 * 10 + 10 * 100,
  "3004260047", 125 * 100,
  "3004260016", 85 * 100 + 10 * 10
)

lot_checks <- review |>
  mutate(map_file = paste0("dof_map_", map_id, ".pdf")) |> select(-map_id) |>
  left_join(history |> filter(fiscal_year_end == 2027) |>
    select(bbl, assessment_extract_date = extract_date, assessment_area_sqft = area_sqft),
    by = "bbl", relationship = "one-to-one") |>
  left_join(history |> filter(fiscal_year_end == 2026) |>
    select(bbl, preceding_assessment_area_sqft = area_sqft),
    by = "bbl", relationship = "one-to-one") |>
  left_join(pluto, by = "bbl", relationship = "one-to-one") |>
  left_join(parcels |> st_drop_geometry() |> select(bbl, pluto_geometry_sqft),
            by = "bbl", relationship = "one-to-one") |>
  left_join(dimensions, by = "bbl", relationship = "one-to-one") |>
  mutate(dimension_difference_sqft = dimension_area_sqft - assessment_area_sqft,
         dimension_difference_pct = 100 * dimension_difference_sqft / assessment_area_sqft,
         geometry_difference_pct = 100 * (pluto_geometry_sqft / assessment_area_sqft - 1))
stopifnot(nrow(lot_checks) == nrow(review), setequal(lot_checks$bbl, review$bbl),
  identical(lot_checks$bbl[is.na(lot_checks$assessment_area_sqft)], "3025670010"),
  all(abs(lot_checks$dimension_difference_pct[lot_checks$measurement_status == "dimensions_agree"]) < 0.1))

# Check the earlier ten comparisons without turning them into production inputs.
parent_checks <- lot_checks |> filter(role == "filing") |>
  group_by(parent_id) |> summarise(assessment_sum = sum(assessment_area_sqft), .groups = "drop") |>
  inner_join(comparison |> filter(review_status == "comparison"),
             by = "parent_id", relationship = "one-to-one")
stopifnot(nrow(parent_checks) == 10,
          all(parent_checks$assessment_sum == parent_checks$comparison_area_sqft))

# MapPLUTO's supplied layer is shoreline clipped; DOF retains the full tax lot.
# Keep these different measurements visible instead of calling their difference
# a failed match. The dated CB1 notice documents the proposed split and site area.
dof <- st_read("../input/dof_subset_filing_parcels.geojson", quiet = TRUE) |>
  filter(BBL == "3025670001")
noble <- parcels |> filter(bbl == "3025670001")
stopifnot(nrow(dof) == 1, nrow(noble) == 1,
          st_crs(dof)$epsg == 2263, st_crs(noble)$epsg == 2263)
waterfront <- tibble(bbl = "3025670001",
  assessment_area_sqft = lot_checks$assessment_area_sqft[lot_checks$bbl == "3025670001"],
  dof_polygon_sqft = as.numeric(st_area(dof)),
  shoreline_clipped_polygon_sqft = as.numeric(st_area(noble)),
  cb1_reported_site_sqft = 173834,
  clipped_area_outside_dof_sqft = as.numeric(st_area(st_difference(st_union(noble), st_union(dof)))))
stopifnot(waterfront$clipped_area_outside_dof_sqft < 1)

SaveData(history, c("bbl", "fiscal_year_end"), "../output/dof_subset_assessment_history.csv")
SaveData(lot_checks, "bbl", "../output/dof_subset_lot_checks.csv")
SaveData(waterfront, "bbl", "../output/dof_subset_waterfront_areas.csv")

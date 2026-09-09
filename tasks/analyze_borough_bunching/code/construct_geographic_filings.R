# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_borough_bunching/code")
suppressPackageStartupMessages({library(arrow); library(dplyr); library(sf)})

filings <- read_parquet("../input/constituent_filing_panel.parquet") |>
  filter(included_ab)
filing_count <- nrow(filings)
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  select(root_job_id = job_number, latitude, longitude) |>
  mutate(sample = "post_policy", coordinate_source = "DOB NOW initial filing")
hdb <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
  transmute(root_job_id = job_number, latitude = as.numeric(latitude),
            longitude = as.numeric(longitude), sample = "historical",
            coordinate_source = "DCP Housing Database 25Q4")
coordinates <- bind_rows(hdb, dob)
stopifnot(!anyDuplicated(filings[c("sample", "root_job_id")]),
          !anyNA(filings$root_job_id), !anyNA(filings$borough_name),
          !anyDuplicated(coordinates[c("sample", "root_job_id")]))
parents <- filings |> group_by(sample, parent_id) |>
  summarise(boroughs = n_distinct(borough_name), totals = n_distinct(parent_total_units),
            reconciles = sum(constituent_units) == first(parent_total_units), .groups = "drop")
stopifnot(all(parents$boroughs == 1), all(parents$totals == 1), all(parents$reconciles))

filings <- filings |>
  left_join(coordinates, by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  mutate(coordinate_status = case_when(
    is.na(coordinate_source) ~ "unmatched source job",
    is.na(latitude) | is.na(longitude) ~ "missing coordinates",
    latitude < 40.45 | latitude > 40.95 | longitude < -74.3 | longitude > -73.65 ~ "outside NYC bounding box",
    TRUE ~ "pending borough check"))
stopifnot(nrow(filings) == filing_count, !anyNA(filings$coordinate_source))
boroughs <- st_read("../input/borough_boundaries_2026-09-08.geojson", quiet = TRUE) |>
  st_transform(2263) |> st_make_valid()
stopifnot(nrow(boroughs) == 5, !anyDuplicated(boroughs$boroname),
          setequal(boroughs$boroname, unique(filings$borough_name)))
located <- which(filings$coordinate_status == "pending borough check")
points <- st_as_sf(filings[located, ], coords = c("longitude", "latitude"), crs = 4326) |>
  st_transform(2263)
inside <- st_intersects(points, boroughs)
filings$coordinate_status[located] <- vapply(seq_along(inside), function(i) {
  if (filings$borough_name[located[i]] %in% boroughs$boroname[inside[[i]]]) {
    "inside reported borough"
  } else { "outside reported borough" }
}, character(1))
filings <- filings |> arrange(sample, borough_name, parent_id, root_job_id)
write_parquet(filings, "../output/geographic_filings.parquet")
print(filings |> count(sample, coordinate_status))
print(filings |> filter(constituent_units == 99) |> count(sample, coordinate_status))

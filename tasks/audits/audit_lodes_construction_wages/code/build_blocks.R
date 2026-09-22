# setwd("tasks/audits/audit_lodes_construction_wages/code")
library(readr)
library(dplyr)
library(sf)
rows <- list()
for (year in 2019:2023) {
  counts <- read_csv(paste0("../input/ny_wac_S000_JT02_", year, ".csv.gz"), col_types = cols_only(w_geocode = col_character(), CNS04 = col_double())) |>
    filter(substr(w_geocode, 1, 5) %in% c("36005", "36047", "36061", "36081", "36085")) |> rename(total = CNS04)
  stopifnot(!anyDuplicated(counts$w_geocode))
  for (segment in c("SE01", "SE02", "SE03")) {
    bin <- read_csv(paste0("../input/ny_wac_", segment, "_JT02_", year, ".csv.gz"), col_types = cols_only(w_geocode = col_character(), CNS04 = col_double())) |>
      filter(substr(w_geocode, 1, 5) %in% c("36005", "36047", "36061", "36081", "36085"))
    stopifnot(!anyDuplicated(bin$w_geocode), all(bin$w_geocode %in% counts$w_geocode))
    names(bin)[2] <- segment
    counts <- left_join(counts, bin, by = "w_geocode", relationship = "one-to-one")
    # An absent earnings-segment block has no jobs in that segment.
    counts[[segment]][is.na(counts[[segment]])] <- 0
  }
  stopifnot(all(counts$total == counts$SE01 + counts$SE02 + counts$SE03), all(counts$SE01 >= 0), all(counts$SE02 >= 0), all(counts$SE03 >= 0))
  rows[[as.character(year)]] <- counts |> filter(total > 0) |> mutate(year = year)
}
counts <- bind_rows(rows)
xwalk <- read_csv("../input/ny_xwalk.csv.gz", col_types = cols_only(tabblk2020 = col_character(), blklatdd = col_double(), blklondd = col_double())) |>
  filter(tabblk2020 %in% counts$w_geocode)
stopifnot(!anyDuplicated(xwalk$tabblk2020), all(counts$w_geocode %in% xwalk$tabblk2020), !anyNA(xwalk))
cd <- st_read("../input/community_districts.geojson", quiet = TRUE) |> mutate(boro_cd = as.integer(boro_cd)) |> st_transform(2263) |> st_make_valid()
stopifnot(nrow(cd) == 71, !anyDuplicated(cd$boro_cd))
points <- st_as_sf(xwalk, coords = c("blklondd", "blklatdd"), crs = 4326) |> st_transform(2263)
hits <- st_intersects(points, cd)
stopifnot(all(lengths(hits) <= 1))
xwalk$boro_cd <- NA_integer_
xwalk$boro_cd[lengths(hits) == 1] <- cd$boro_cd[unlist(hits)]
xwalk$assignment <- case_when(is.na(xwalk$boro_cd) ~ "outside district polygons", xwalk$boro_cd %% 100 >= 20 ~ "park/special area", TRUE ~ "standard district")
counts <- counts |> left_join(xwalk, by = c("w_geocode" = "tabblk2020"), relationship = "many-to-one") |> arrange(year, w_geocode)
stopifnot(!anyDuplicated(counts[c("year", "w_geocode")]))
write_csv(counts, "../output/block_construction_bins.csv")

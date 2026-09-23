# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_site_boundaries/code")
library(arrow)
library(dplyr)
library(jsonlite)
library(readr)
library(stringr)
library(tidyr)
source("../../../shared/code/write_data_report.R")

# These are the displayed DOB fields captured in the browser, not adjudicated
# replacement areas. The public page may incorporate post-filing amendments.
dob <- fromJSON("../input/bis_site_fields.json") |> as_tibble()
hdb <- read_parquet("../input/historical_hdb_mappluto_site_panel.parquet") |>
  transmute(job_number, block_bbl = substr(bbl, 1, 6),
    vintage = tolower(gsub(".", "_", pluto_version_used, fixed = TRUE)))
members <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  filter(sample == "historical") |>
  select(job_number, parent_id)
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  select(parent_id, component_addresses, parent_total_units, production_area_sqft = lot_area_sqft)
geometry <- read_csv("../output/dof_geometry_comparison.csv", show_col_types = FALSE)
overlaps <- read_parquet("../output/dof_geometry_overlaps.parquet") |> filter(material)
stopifnot(nrow(dob) == 17, !anyDuplicated(dob$job_number))
filings <- dob |> left_join(hdb, by = "job_number", relationship = "one-to-one") |>
  left_join(members, by = "job_number", relationship = "one-to-one")
stopifnot(!anyNA(filings$parent_id), !anyNA(filings$vintage),
          nrow(filings) == nrow(dob), setequal(filings$job_number, dob$job_number))

# Several reference releases can give the identical site comparison. Count
# that comparison once; conflicting values must be resolved before this join.
geometry <- geometry |> semi_join(filings, by = "parent_id") |>
  select(parent_id, later_recorded_sqft, later_geometry_sqft,
    old_bbls, old_recorded_sqft, geometry_pattern) |> distinct()
stopifnot(!anyDuplicated(geometry$parent_id))

# Join the lot numbers printed in each filing to its block and the SAME earlier
# reference release used in production. Missing old lots stay missing.
lots <- filings |> select(job_number, parent_id, block_bbl, vintage, original_lots, zoning_lots, tentative_lots) |>
  pivot_longer(ends_with("_lots"), names_to = "lot_definition", values_to = "lot_text") |>
  mutate(lot = str_extract_all(lot_text, "\\b[0-9]{5}\\b")) |>
  unnest_longer(lot) |>
  mutate(bbl = paste0(block_bbl, sprintf("%04d", as.integer(lot))))
stopifnot(!anyDuplicated(lots[c("job_number", "lot_definition", "bbl")]))
pluto <- bind_rows(lapply(sort(unique(filings$vintage)), function(vintage) {
  read_parquet(paste0("../input/dcp_mappluto_archive_", vintage, ".parquet")) |>
    transmute(vintage, bbl, lotarea)
}))
stopifnot(!anyDuplicated(pluto[c("vintage", "bbl")]))
lots <- lots |> left_join(pluto, by = c("vintage", "bbl"), relationship = "many-to-one")

# Shared zoning lists flag possible shared land; they do not authorize merging
# parents or giving the full zoning-lot area to each separate residential filing.
zoning <- lots |> filter(lot_definition == "zoning_lots") |> group_by(job_number, parent_id) |>
  summarise(zoning_key = paste(sort(bbl), collapse = ";"), .groups = "drop") |>
  group_by(zoning_key) |> mutate(parents_sharing_zoning_list = n_distinct(parent_id)) |> ungroup()
original <- lots |> filter(lot_definition == "original_lots") |> group_by(job_number) |>
  summarise(original_lot_count = n(), original_missing_lots = sum(is.na(lotarea) | lotarea <= 0),
    original_recorded_sqft = if (all(!is.na(lotarea) & lotarea > 0)) sum(lotarea) else NA_real_,
    .groups = "drop")
filings <- filings |> left_join(original, by = "job_number", relationship = "one-to-one") |>
  left_join(zoning |> select(-parent_id), by = "job_number", relationship = "one-to-one") |>
  arrange(parent_id, job_number)

# A parent counts an original parcel once even if several constituent filings
# name it. Preserve the reference vintage when combining their lot lists.
original <- lots |> filter(lot_definition == "original_lots") |>
  distinct(parent_id, vintage, bbl, lotarea) |> group_by(parent_id) |>
  summarise(original_bbls = paste(sort(unique(bbl)), collapse = ";"),
    original_lot_count = n_distinct(bbl), reference_vintages = n_distinct(vintage),
    original_missing_lots = sum(is.na(lotarea) | lotarea <= 0),
    original_recorded_sqft = if (n_distinct(vintage) == 1L && all(!is.na(lotarea) & lotarea > 0))
      sum(lotarea) else NA_real_, .groups = "drop")
review <- parents |> semi_join(filings, by = "parent_id") |>
  left_join(original, by = "parent_id", relationship = "one-to-one") |>
  left_join(geometry, by = "parent_id", relationship = "one-to-one") |>
  mutate(original_area_vs_production_pct = 100 * (original_recorded_sqft / production_area_sqft - 1)) |>
  arrange(parent_id)
review$original_lots_match_spatial_lots <- vapply(seq_len(nrow(review)), function(i) {
  if (is.na(review$original_bbls[i])) return(NA)
  setequal(strsplit(review$original_bbls[i], ";")[[1]],
           overlaps$bbl[overlaps$parent_id == review$parent_id[i]])
}, logical(1))
stopifnot(setequal(review$parent_id, filings$parent_id))
SaveData(filings, "job_number", "../output/bis_filing_sites.csv")
SaveData(review, "parent_id", "../output/bis_parent_site_comparison.csv")
print(review |> select(component_addresses, production_area_sqft, original_recorded_sqft,
                       original_missing_lots, original_lots_match_spatial_lots), n = Inf)

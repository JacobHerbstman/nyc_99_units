# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})
source("../../../shared/code/write_data_report.R")

# Five parents selected from the pilot: at least three filings and two exact 99s.
stacks <- read_csv("../output/post_three_plus_parents.csv", show_col_types = FALSE) |>
  filter(n_constituents_at_99 >= 2)
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  semi_join(stacks, by = "parent_id")
filings <- read_parquet("../input/constituent_filing_panel.parquet") |>
  semi_join(stacks, by = "parent_id")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
hdb <- read_parquet("../input/hdb_mappluto_site_panel.parquet")
archive <- read_parquet("../input/dcp_mappluto_archive_23v3_1.parquet")
current <- jsonlite::fromJSON("../input/pluto_26v2.json") |>
  as_tibble() |>
  mutate(bbl = sprintf("%.0f", as.numeric(bbl)),
         appbbl = sprintf("%.0f", as.numeric(appbbl)),
         lotarea = as.numeric(lotarea))
stopifnot(nrow(stacks) == 5L, nrow(filings) == 20L,
          !anyDuplicated(parents$parent_id), !anyDuplicated(filings$root_job_id),
          !anyDuplicated(dob$job_number), !anyDuplicated(hdb$job_number),
          !anyDuplicated(archive$bbl), !anyDuplicated(current$bbl),
          all(current$version == "26v2"))

# Reproduce the automatic lookup before reviewed parent allocations:
# recovered HDB parcel first, filing BBL second.
filing_lots <- filings |>
  select(parent_id, root_job_id, address, constituent_units, date_filed, filing_bbl,
         hpd_response_number, hpd_reported_bbl, hpd_intended_separate_sub100) |>
  left_join(dob |> select(root_job_id = job_number, dob_bin = bin),
            by = "root_job_id", relationship = "one-to-one") |>
  left_join(hdb |> select(root_job_id = job_number, hdb_feature_bbl = pluto_feature_bbl,
                         hdb_match_method = pluto_match_method),
            by = "root_job_id", relationship = "one-to-one") |>
  mutate(archive_bbl = case_when(
    hdb_feature_bbl %in% archive$bbl ~ hdb_feature_bbl,
    filing_bbl %in% archive$bbl ~ filing_bbl,
    TRUE ~ NA_character_),
    filing_bbl_in_2023 = filing_bbl %in% archive$bbl,
    filing_bbl_in_26v2 = filing_bbl %in% current$bbl) |>
  left_join(archive |> select(archive_bbl = bbl, archive_lot_area = lotarea),
            by = "archive_bbl", relationship = "many-to-one") |>
  left_join(current |> select(filing_bbl = bbl, current_lot_area = lotarea,
                             current_appbbl = appbbl, current_appdate = appdate),
            by = "filing_bbl", relationship = "many-to-one") |>
  arrange(parent_id, root_job_id)
stopifnot(nrow(filing_lots) == 20L, !anyNA(filing_lots$archive_bbl),
          n_distinct(filing_lots$dob_bin) == 20L,
          sum(filing_lots$constituent_units) == sum(parents$parent_total_units))
SaveData(filing_lots, "root_job_id", "../output/stack_parcel_filings.csv")

# Documents supply the old parcel SET; all areas still come from 2023 PLUTO.
# Jamaica's eight-parcel extent includes retained terminal land. The approved
# housing footprint enters through the canonical parent panel below.
reviewed_lots <- read_csv("stack_source_lots.csv", show_col_types = FALSE,
                          col_types = cols(archive_bbl = col_character())) |>
  left_join(archive |> select(archive_bbl = bbl, archive_address = address,
                             lot_area_sqft = lotarea, lotfront, lotdepth),
            by = "archive_bbl", relationship = "many-to-one")
stopifnot(!anyDuplicated(reviewed_lots[c("parent_id", "archive_bbl")]),
          !anyNA(reviewed_lots$lot_area_sqft),
          setequal(reviewed_lots$parent_id, stacks$parent_id))
SaveData(reviewed_lots, c("parent_id", "archive_bbl"), "../output/stack_reviewed_lots.csv")

matched <- filing_lots |> distinct(parent_id, archive_bbl, archive_lot_area) |>
  group_by(parent_id) |>
  summarise(matched_2023_lots = n(), matched_2023_area = sum(archive_lot_area), .groups = "drop")
reviewed <- reviewed_lots |> group_by(parent_id) |>
  summarise(reviewed_associated_lots = n(), reviewed_associated_area = sum(lot_area_sqft),
            reviewed_2023_bbls = paste(sort(archive_bbl), collapse = ";"),
            .groups = "drop")
parcel_summary <- filing_lots |> group_by(parent_id) |>
  summarise(filing_lots = n_distinct(filing_bbl),
            filing_lots_present_in_26v2 = n_distinct(filing_bbl[filing_bbl_in_26v2]),
            .groups = "drop") |>
  left_join(parents |> select(parent_id, parent_total_units, n_components,
                             sorted_component_vector, number_unique_lots, lot_area_sqft, site_feature_method),
            by = "parent_id", relationship = "one-to-one") |>
  left_join(matched, by = "parent_id", relationship = "one-to-one") |>
  left_join(reviewed, by = "parent_id", relationship = "one-to-one") |>
  left_join(read_csv("stack_case_review.csv", show_col_types = FALSE),
            by = "parent_id", relationship = "one-to-one") |>
  mutate(associated_area_gap = reviewed_associated_area - matched_2023_area,
         observed_filings_exceed_reviewed_lots = n_components > reviewed_associated_lots)
# Automatic matches must reproduce automatic production sites. Reviewed sites
# intentionally replace that footprint; keep both measures visible above.
automatic_sites <- parcel_summary |> filter(site_feature_method != "reviewed_parcel_allocation")
stopifnot(all(automatic_sites$matched_2023_lots == automatic_sites$number_unique_lots),
          all(abs(automatic_sites$matched_2023_area - automatic_sites$lot_area_sqft) < 1e-8),
          !anyNA(parcel_summary$site_feature_method), !anyNA(parcel_summary$case_name))
SaveData(parcel_summary, "parent_id", "../output/stack_parcel_summary.csv")

# ACRIS can contain older and amended index rows for one document. Retain the
# latest modification, require a unique record, and aggregate searched parcels
# before joining the document metadata. The index is not the document's text.
master <- jsonlite::fromJSON("../input/acris_master.json") |> as_tibble() |>
  group_by(document_id) |> filter(modified_date == max(modified_date)) |> ungroup()
stopifnot(!anyDuplicated(master$document_id))
blocks <- filing_lots |>
  transmute(parent_id, borough = as.integer(substr(filing_bbl, 1, 1)),
            block = as.integer(substr(filing_bbl, 2, 6))) |> distinct()
stopifnot(!anyDuplicated(blocks[c("borough", "block")]))
legals <- jsonlite::fromJSON("../input/acris_legals.json") |> as_tibble() |>
  mutate(borough = as.integer(borough), block = as.integer(block)) |>
  left_join(blocks, by = c("borough", "block"), relationship = "many-to-one") |>
  group_by(parent_id, document_id) |>
  summarise(searched_lots = paste(sort(unique(as.integer(lot))), collapse = ";"), .groups = "drop")
documents <- legals |>
  left_join(master |> select(document_id, crfn, doc_type, document_date, recorded_datetime),
            by = "document_id", relationship = "many-to-one") |>
  filter(doc_type %in% c("ZONE", "CDEC", "TERDECL", "DECL"),
         as.Date(recorded_datetime) >= as.Date("2020-01-01")) |>
  mutate(source_url = paste0("https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=", document_id)) |>
  arrange(parent_id, recorded_datetime, document_id)
SaveData(documents, c("parent_id", "document_id"), "../output/stack_acris_documents.csv")
print(parcel_summary |> select(case_name, n_components, matched_2023_lots,
  reviewed_associated_lots, filing_lots, matched_2023_area, reviewed_associated_area), width = Inf)

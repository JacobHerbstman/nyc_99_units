# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)

# These are the seven cases already identified by the full nearby-filings screen.
cases <- tibble(
  companion = c("B01178945", "B01372886", "Q01177738", "Q01332594", "X01223350", "S00661600", "B00678680"),
  anchor = c("B01172199", "B01350174", "Q01177691", "Q01288130", "X01228107", "S00661661", "B00678516"),
  sample = c(rep("post_policy", 5), rep("historical", 2))
)
post <- read_parquet("../input/post_policy_filing_link_fields.parquet")
historical <- read_parquet("../input/historical_parent_filing_link_fields.parquet")
candidates <- read_parquet("../input/historical_parent_candidate_pairs.parquet")
site <- read_parquet("../input/hdb_mappluto_site_panel.parquet")
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
stopifnot(!anyDuplicated(membership[c("sample", "root_job_id")]))
links <- read_parquet("../input/symmetric_parent_links.parquet")
stopifnot(!anyDuplicated(post$root_job_id), !anyDuplicated(historical$job_number),
  !anyDuplicated(site$job_number))

archive <- system2("unzip", c("-Z1", "../input/nyc_mappluto_23v3_1_arc_shp.zip"), stdout = TRUE)
shapefile <- archive[tolower(basename(archive)) == "mappluto.shp"]
stopifnot(length(shapefile) == 1)
needed <- post |> filter(root_job_id %in% c(cases$companion, cases$anchor))
lots <- st_read(paste0("/vsizip/../input/nyc_mappluto_23v3_1_arc_shp.zip/", shapefile),
  query = paste0("SELECT BBL FROM MapPLUTO WHERE BBL IN (", paste(needed$filing_bbl, collapse = ","), ")"), quiet = TRUE)
stopifnot(!anyDuplicated(lots$BBL), all(st_is_valid(lots)))

cases$in_linking_universe <- FALSE
cases$geometry_present_23v3_1 <- NA
cases$exact_touch_23v3_1 <- NA
cases$polygon_distance_metres <- NA_real_
cases$same_owner <- NA
cases$existing_owner_candidate <- NA
cases$later_lot_history <- NA
cases$site_exclusion <- NA_character_
cases$accepted_link <- FALSE
for (i in seq_len(nrow(cases))) {
  if (cases$sample[i] == "post_policy") {
    left <- post[post$root_job_id == cases$companion[i], ]
    right <- post[post$root_job_id == cases$anchor[i], ]
    stopifnot(nrow(left) == 1, nrow(right) == 1)
    cases$in_linking_universe[i] <- TRUE
    cases$same_owner[i] <- !is.na(left$owner_match_key) && identical(left$owner_match_key, right$owner_match_key)
    cases$later_lot_history[i] <- left$appbbl_change_after_filing
    a <- lots[as.character(lots$BBL) == left$filing_bbl, ]
    b <- lots[as.character(lots$BBL) == right$filing_bbl, ]
    cases$geometry_present_23v3_1[i] <- nrow(a) == 1
    if (nrow(a) == 1 && nrow(b) == 1) {
      cases$exact_touch_23v3_1[i] <- st_touches(a, b, sparse = FALSE)[1, 1]
      cases$polygon_distance_metres[i] <- as.numeric(units::set_units(st_distance(a, b), "m"))
    }
  } else {
    left <- historical[historical$job_number == cases$companion[i], ]
    right <- historical[historical$job_number == cases$anchor[i], ]
    cases$in_linking_universe[i] <- nrow(left) == 1
    if (nrow(left) == 1 && nrow(right) == 1) {
      cases$same_owner[i] <- !is.na(left$dob_owner_match_key) && identical(left$dob_owner_match_key, right$dob_owner_match_key)
    }
    pair <- candidates[(candidates$job_number_1 == cases$companion[i] & candidates$job_number_2 == cases$anchor[i]) |
      (candidates$job_number_2 == cases$companion[i] & candidates$job_number_1 == cases$anchor[i]), ]
    cases$existing_owner_candidate[i] <- any(pair$owner_supported_candidate)
    row <- site[site$job_number == cases$companion[i], ]
    stopifnot(nrow(row) == 1)
    cases$site_exclusion[i] <- row$exclusion_reason
  }
  pair <- links[links$sample == cases$sample[i] &
    ((sub("-I1$", "", links$job_number_1) == cases$companion[i] & sub("-I1$", "", links$job_number_2) == cases$anchor[i]) |
     (sub("-I1$", "", links$job_number_2) == cases$companion[i] & sub("-I1$", "", links$job_number_1) == cases$anchor[i])), ]
  cases$accepted_link[i] <- any(pair$enhanced_link)
}
cases <- cases |>
  left_join(membership |> select(sample, companion = root_job_id, companion_parent = parent_id),
    by = c("sample", "companion"), relationship = "one-to-one") |>
  left_join(membership |> select(sample, anchor = root_job_id, anchor_parent = parent_id),
    by = c("sample", "anchor"), relationship = "many-to-one") |>
  mutate(same_parent = companion_parent == anchor_parent) |>
  select(-companion_parent, -anchor_parent)
stopifnot(!anyNA(cases$same_parent), all(cases$same_parent))
stopifnot(nrow(cases) == 7, !anyDuplicated(cases$companion))
write_csv(cases, "../output/companion_link_trace.csv")

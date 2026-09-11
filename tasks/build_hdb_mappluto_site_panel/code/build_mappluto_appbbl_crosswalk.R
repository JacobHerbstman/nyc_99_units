# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_hdb_mappluto_site_panel/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

paste_unique <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & as.character(x) != ""])))
  if (length(x) == 0) {
    return(NA_character_)
  }
  paste(x, collapse = ";")
}

release <- read_csv("../input/mappluto_files.csv", show_col_types = FALSE) |>
  filter(source_id == "dcp_pluto_current", file_role == "pluto_csv_zip")
stopifnot(nrow(release) == 1L, release$vintage == "25v4")

# APPBBL identifies the former tax lot associated with a current lot.
raw_table <- read_csv(
  unzip("../input/nyc_pluto_25v4_csv.zip", files = "pluto_25v4.csv", exdir = tempdir()),
  col_types = cols(.default = col_character()), lazy = FALSE
)
names(raw_table) <- normalize_names(names(raw_table))

appbbl_rows <- raw_table |>
  select(current_bbl = bbl, borough, block, lot, condono, appbbl, appdate, plutomapid)

missing_bbl <- is.na(appbbl_rows$current_bbl) | appbbl_rows$current_bbl == ""
appbbl_rows$current_bbl[missing_bbl] <- build_bbl(appbbl_rows$borough, appbbl_rows$block, appbbl_rows$lot)[missing_bbl]

appbbl_rows <- appbbl_rows |>
  mutate(
    source_id = release$source_id,
    vintage = release$vintage,
    current_bbl = normalize_bbl_field(current_bbl),
    appbbl = normalize_bbl_field(appbbl),
    condono = suppressWarnings(as.integer(condono)),
    appdate = parse_mixed_date(appdate),
    plutomapid = suppressWarnings(as.integer(plutomapid)),
    current_borough = substr(as.character(current_bbl), 1L, 1L),
    current_block = suppressWarnings(as.integer(substr(as.character(current_bbl), 2L, 6L))),
    current_lot = suppressWarnings(as.integer(substr(as.character(current_bbl), 7L, 10L))),
    appbbl_borough = substr(as.character(appbbl), 1L, 1L),
    appbbl_block = suppressWarnings(as.integer(substr(as.character(appbbl), 2L, 6L))),
    appbbl_lot = suppressWarnings(as.integer(substr(as.character(appbbl), 7L, 10L)))
  )

mappluto_appbbl_crosswalk <- appbbl_rows |>
  filter(
    !is.na(current_bbl),
    !is.na(appbbl),
    current_bbl != appbbl
  ) |>
  group_by(source_id, vintage, current_bbl, appbbl) |>
  summarise(
    evidence_rows = n(),
    condono_values = paste_unique(condono),
    plutomapid_values = paste_unique(plutomapid),
    appdate_min = if (all(is.na(appdate))) as.Date(NA) else min(appdate, na.rm = TRUE),
    appdate_max = if (all(is.na(appdate))) as.Date(NA) else max(appdate, na.rm = TRUE),
    current_borough = first(current_borough),
    current_block = first(current_block),
    current_lot = first(current_lot),
    appbbl_borough = first(appbbl_borough),
    appbbl_block = first(appbbl_block),
    appbbl_lot = first(appbbl_lot),
    same_boro_block = first(current_borough) == first(appbbl_borough) & first(current_block) == first(appbbl_block),
    .groups = "drop"
  ) |>
  arrange(current_bbl, appbbl, source_id, vintage)

duplicate_crosswalk_keys <- mappluto_appbbl_crosswalk |>
  count(source_id, vintage, current_bbl, appbbl, name = "rows") |>
  filter(rows > 1)

if (nrow(duplicate_crosswalk_keys) > 0) {
  stop("APPBBL crosswalk is not unique by source/vintage/current_bbl/appbbl.")
}

write_csv_atomic(mappluto_appbbl_crosswalk, "../output/mappluto_appbbl_crosswalk.csv")
cat("Wrote MapPLUTO APPBBL crosswalk to ../output/mappluto_appbbl_crosswalk.csv\n")

write_data_report(
  readr::read_csv("../output/mappluto_appbbl_crosswalk.csv", show_col_types = FALSE, guess_max = Inf),
  c("current_bbl"), "../output/mappluto_appbbl_crosswalk.csv", "../report/mappluto_appbbl_crosswalk.txt")

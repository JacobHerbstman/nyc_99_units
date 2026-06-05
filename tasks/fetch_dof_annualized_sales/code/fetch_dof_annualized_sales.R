# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/fetch_dof_annualized_sales/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
  library(xml2)
})

source("../../_lib/source_pipeline_utils.R")

selected_years <- 2010:2025
expected_boroughs <- c("manhattan", "bronx", "brooklyn", "queens", "staten_island")

source_catalog <- read_csv("../input/source_catalog.csv", show_col_types = FALSE, na = c("", "NA"))
source_row <- source_catalog |>
  filter(source_id == "dof_annualized_sales")

if (nrow(source_row) != 1) {
  stop("Source catalog must contain exactly one dof_annualized_sales row.")
}

dir.create("../../../data_raw/dof_annualized_sales/metadata", recursive = TRUE, showWarnings = FALSE)

if (!file.exists("../../../data_raw/dof_annualized_sales/metadata/property-annualized-sales-update.html")) {
  download_with_status(
    source_row$official_url[1],
    "../../../data_raw/dof_annualized_sales/metadata/property-annualized-sales-update.html"
  )
}

annualized_page <- read_html("../../../data_raw/dof_annualized_sales/metadata/property-annualized-sales-update.html")
sales_links <- tibble(
  href = xml_attr(xml_find_all(annualized_page, ".//a"), "href")
) |>
  filter(!is.na(href)) |>
  mutate(
    href = str_squish(href),
    file_name = basename(href),
    year = suppressWarnings(as.integer(str_extract(href, "20[0-9]{2}|19[0-9]{2}"))),
    borough = str_remove(file_name, "^[0-9]{4}_"),
    borough = str_remove(borough, "[.](xls|xlsx)$"),
    borough = str_replace_all(borough, "_sales$", ""),
    borough = str_replace_all(borough, "statenisland", "staten_island"),
    borough = str_replace_all(borough, "staten_island_sales", "staten_island"),
    borough = str_to_lower(borough),
    official_url = case_when(
      str_detect(href, "^https?://") ~ href,
      str_starts(href, "//") ~ paste0("https:", href),
      str_starts(href, "/") ~ paste0("https://www.nyc.gov", href),
      TRUE ~ paste0("https://www.nyc.gov/", href)
    )
  ) |>
  filter(
    str_detect(href, "annualized-sales"),
    str_detect(file_name, "[.](xls|xlsx)$"),
    year %in% selected_years,
    borough %in% expected_boroughs
  ) |>
  distinct(year, borough, .keep_all = TRUE)

expected_links <- expand_grid(
  year = selected_years,
  borough = expected_boroughs
)

missing_links <- expected_links |>
  anti_join(sales_links, by = c("year", "borough"))

if (nrow(missing_links) > 0) {
  stop("Missing DOF annualized sales links: ", paste(paste(missing_links$year, missing_links$borough, sep = "/"), collapse = ", "))
}

file_rows <- sales_links |>
  arrange(year, borough) |>
  mutate(
    source_id = "dof_annualized_sales",
    vintage = as.character(year),
    file_role = "detailed_annualized_sales_xlsx",
    raw_path = file.path("..", "..", "..", "data_raw", "dof_annualized_sales", as.character(year), file_name)
  )

download_status <- character(nrow(file_rows))

for (i in seq_len(nrow(file_rows))) {
  dir.create(dirname(file_rows$raw_path[i]), recursive = TRUE, showWarnings = FALSE)
  download_status[i] <- if (file.exists(file_rows$raw_path[i])) {
    "already_present"
  } else {
    download_with_status(file_rows$official_url[i], file_rows$raw_path[i])
  }
}

file_inventory <- bind_rows(
  tibble(
    source_id = "dof_annualized_sales",
    vintage = "metadata",
    year = NA_integer_,
    borough = NA_character_,
    file_role = "source_page_html",
    file_name = "property-annualized-sales-update.html",
    raw_path = "../../../data_raw/dof_annualized_sales/metadata/property-annualized-sales-update.html",
    status = "saved_source_page",
    official_url = source_row$official_url[1]
  ),
  file_rows |>
    mutate(status = download_status) |>
    select(source_id, vintage, year, borough, file_role, file_name, raw_path, status, official_url)
)

if (any(file_inventory$file_role == "detailed_annualized_sales_xlsx" & file_inventory$status != "already_present" & file_inventory$status != "downloaded")) {
  stop("At least one DOF annualized sales file failed to download.")
}

write_csv_if_changed(file_inventory, "../output/dof_annualized_sales_files.csv")
cat("Wrote DOF annualized sales fetch outputs to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_developer_responses/code")
# hist_pre_start_year <- 2010L
# design_pre_start_year <- 2021L
# pre_end_year <- 2023L
# post_year <- 2025L
# min_units <- 50L
# design_max_units <- 150L
# site_plot_max_units <- 400L
# hist_bin_width <- 5L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 8L) {
  stop("Expected eight arguments: histogram pre start, design pre start, pre end, post year, minimum units, design maximum units, site-plot maximum units, and histogram bin width.")
}

hist_pre_start_year <- as.integer(args[1])
design_pre_start_year <- as.integer(args[2])
pre_end_year <- as.integer(args[3])
post_year <- as.integer(args[4])
min_units <- as.integer(args[5])
design_max_units <- as.integer(args[6])
site_plot_max_units <- as.integer(args[7])
hist_bin_width <- as.integer(args[8])

if (
  any(is.na(c(
    hist_pre_start_year, design_pre_start_year, pre_end_year, post_year,
    min_units, design_max_units, site_plot_max_units, hist_bin_width
  ))) ||
    hist_pre_start_year > pre_end_year ||
    design_pre_start_year > pre_end_year ||
    pre_end_year >= post_year ||
    min_units >= design_max_units ||
    design_max_units > site_plot_max_units ||
    hist_bin_width <= 0L
) {
  stop("Audit year and unit-count arguments are not internally consistent.")
}

hist_pre_years <- pre_end_year - hist_pre_start_year + 1L
hist_pre_label <- paste0("Pre: ", hist_pre_start_year, "-", pre_end_year, " annual average")
design_pre_label <- paste0("Pre: ", design_pre_start_year, "-", pre_end_year)
post_label <- paste0("Post: ", post_year)

hdb_raw <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |>
  as.data.frame() |>
  as_tibble()

dob_raw <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  as.data.frame() |>
  as_tibble()

hdb_applications <- hdb_raw |>
  mutate(
    job_number = str_squish(job_number),
    filing_year = as.integer(format(date_filed, "%Y")),
    integer_proposed_units = !is.na(classa_prop) &
      abs(classa_prop - round(classa_prop)) < 1e-8
  ) |>
  filter(
    job_type == "New Building",
    !is.na(date_filed),
    filing_year >= hist_pre_start_year,
    filing_year <= post_year,
    !is.na(classa_prop),
    classa_prop > 0,
    integer_proposed_units
  ) |>
  transmute(
    job_number,
    hdb_filing_date = date_filed,
    filing_year,
    hdb_job_status = job_status,
    hdb_units = as.integer(round(classa_prop)),
    hdb_bbl = normalize_bbl_field(bbl),
    hdb_bin = str_squish(bin),
    hdb_address = address,
    hdb_borough_name = borough_name,
    hdb_date_permit = date_permit,
    hdb_date_completed = date_completed
  ) |>
  arrange(hdb_filing_date, job_number)

dob_applications <- dob_raw |>
  mutate(
    job_number = str_squish(job_number),
    filing_year = as.integer(format(filing_date, "%Y")),
    integer_proposed_units = !is.na(proposed_dwelling_units) &
      abs(proposed_dwelling_units - round(proposed_dwelling_units)) < 1e-8
  ) |>
  filter(
    job_type == "New Building",
    !is.na(filing_date),
    filing_year >= design_pre_start_year,
    filing_year <= post_year,
    !is.na(proposed_dwelling_units),
    proposed_dwelling_units > 0,
    integer_proposed_units
  ) |>
  transmute(
    job_number,
    dob_job_filing_number = job_filing_number,
    dob_filing_date = filing_date,
    filing_year,
    dob_filing_status = filing_status,
    dob_units = as.integer(round(proposed_dwelling_units)),
    dob_bbl = bbl,
    dob_bin = bin,
    dob_address = address,
    dob_borough_name = borough_name,
    total_construction_floor_area,
    gross_construction_square_feet_per_unit = total_construction_floor_area / dob_units,
    proposed_stories,
    proposed_height,
    initial_cost,
    owner_business_name,
    applicant_business_name
  ) |>
  arrange(dob_filing_date, job_number)

hdb_duplicate_jobs <- hdb_applications |>
  count(job_number, name = "rows") |>
  filter(rows > 1L)

dob_duplicate_jobs <- dob_applications |>
  count(job_number, name = "rows") |>
  filter(rows > 1L)

if (nrow(hdb_duplicate_jobs) > 0L) {
  stop("HDB job_number is not unique in the audit sample.")
}

if (nrow(dob_duplicate_jobs) > 0L) {
  stop("DOB initial job_number is not unique in the audit sample.")
}

if (any(is.na(hdb_applications$hdb_bbl))) {
  stop("HDB audit sample contains a missing or invalid BBL.")
}

if (any(is.na(dob_applications$dob_bbl))) {
  stop("DOB audit sample contains a missing or invalid BBL.")
}

application_panel <- hdb_applications |>
  left_join(
    dob_applications |>
      select(-filing_year),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  mutate(
    dob_initial_match = !is.na(dob_job_filing_number),
    units_agree = dob_initial_match & hdb_units == dob_units,
    bbl_agree = dob_initial_match & hdb_bbl == dob_bbl,
    bin_agree = dob_initial_match & hdb_bin == dob_bin
  )

hdb_dob_join_qc <- application_panel |>
  filter(filing_year >= design_pre_start_year) |>
  group_by(filing_year) |>
  summarise(
    hdb_applications = n(),
    matched_dob_initial_filings = sum(dob_initial_match),
    match_share = mean(dob_initial_match),
    matched_units_agree = sum(units_agree, na.rm = TRUE),
    matched_units_disagree = sum(dob_initial_match & !units_agree, na.rm = TRUE),
    matched_bbl_agree = sum(bbl_agree, na.rm = TRUE),
    matched_bbl_disagree = sum(dob_initial_match & !bbl_agree, na.rm = TRUE),
    matched_bin_agree = sum(bin_agree, na.rm = TRUE),
    matched_bin_disagree = sum(dob_initial_match & !bin_agree, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(filing_year)

hdb_sites <- hdb_applications |>
  group_by(filing_year, hdb_bbl) |>
  summarise(
    site_definition = "HDB BBL by filing year",
    provisional_site_bbl = first(hdb_bbl),
    application_count = n_distinct(job_number),
    building_count = n_distinct(hdb_bin),
    site_units = sum(hdb_units),
    exact_99_application_count = sum(hdb_units == 99L),
    total_construction_floor_area = NA_real_,
    job_numbers = paste(sort(unique(job_number)), collapse = ";"),
    bins = paste(sort(unique(hdb_bin)), collapse = ";"),
    addresses = paste(sort(unique(hdb_address)), collapse = " | "),
    .groups = "drop"
  ) |>
  mutate(
    provisional_site_id = paste("hdb", filing_year, provisional_site_bbl, sep = "_"),
    all_applications_exact_99 = exact_99_application_count == application_count
  ) |>
  select(provisional_site_id, everything(), -hdb_bbl)

dob_sites <- dob_applications |>
  group_by(filing_year, dob_bbl) |>
  summarise(
    site_definition = "DOB initial-filing BBL by filing year",
    provisional_site_bbl = first(dob_bbl),
    application_count = n_distinct(job_number),
    building_count = n_distinct(dob_bin),
    site_units = sum(dob_units),
    exact_99_application_count = sum(dob_units == 99L),
    total_construction_floor_area = sum(total_construction_floor_area),
    job_numbers = paste(sort(unique(job_number)), collapse = ";"),
    bins = paste(sort(unique(dob_bin)), collapse = ";"),
    addresses = paste(sort(unique(dob_address)), collapse = " | "),
    .groups = "drop"
  ) |>
  mutate(
    provisional_site_id = paste("dob", filing_year, provisional_site_bbl, sep = "_"),
    all_applications_exact_99 = exact_99_application_count == application_count
  ) |>
  select(provisional_site_id, everything(), -dob_bbl)

provisional_site_panel <- bind_rows(hdb_sites, dob_sites) |>
  arrange(site_definition, filing_year, provisional_site_bbl)

site_definition_qc <- provisional_site_panel |>
  group_by(site_definition, filing_year) |>
  summarise(
    applications = sum(application_count),
    provisional_sites = n(),
    multi_application_sites = sum(application_count > 1L),
    multi_building_sites = sum(building_count > 1L),
    exact_99_applications = sum(exact_99_application_count),
    exact_99_provisional_sites = sum(site_units == 99L),
    exact_198_provisional_sites = sum(site_units == 198L),
    .groups = "drop"
  ) |>
  arrange(site_definition, filing_year)

repeated_99_cluster_bbls <- hdb_sites |>
  filter(
    filing_year == post_year,
    exact_99_application_count >= 2L
  ) |>
  pull(provisional_site_bbl)

cluster_source_comparison <- application_panel |>
  filter(
    filing_year == post_year,
    hdb_bbl %in% repeated_99_cluster_bbls
  ) |>
  group_by(hdb_bbl) |>
  summarise(
    all_jobs_matched_to_dob_initial = all(dob_initial_match),
    dob_initial_units_total = sum(dob_units, na.rm = TRUE),
    dob_reported_bbl_count = n_distinct(dob_bbl, na.rm = TRUE),
    dob_reported_bbls = paste(sort(unique(dob_bbl[!is.na(dob_bbl)])), collapse = ";"),
    dob_initial_bin_count = n_distinct(dob_bin, na.rm = TRUE),
    dob_initial_bins = paste(sort(unique(dob_bin[!is.na(dob_bin)])), collapse = ";"),
    .groups = "drop"
  )

if (nrow(cluster_source_comparison) != length(repeated_99_cluster_bbls)) {
  stop("Repeated-99 HDB clusters did not produce one DOB comparison row per HDB BBL.")
}

exact_99_site_clusters <- hdb_sites |>
  filter(
    filing_year == post_year,
    exact_99_application_count >= 2L
  ) |>
  left_join(
    cluster_source_comparison,
    by = c("provisional_site_bbl" = "hdb_bbl"),
    relationship = "one-to-one"
  ) |>
  arrange(desc(exact_99_application_count), provisional_site_bbl)

area_field_coverage <- tibble(
  field = c("total_construction_floor_area", "proposed_residential_floor_area"),
  source = c("DOB NOW initial New Building filing", "Not reported in DOB NOW Open Data"),
  available = c(TRUE, FALSE),
  coverage_share_in_design_sample = c(
    mean(
      !is.na(dob_applications$total_construction_floor_area) &
        dob_applications$total_construction_floor_area > 0
    ),
    0
  ),
  interpretation = c(
    "Gross construction floor area for the proposed job; includes more than dwelling interiors.",
    "Requires plans, Schedule A, HPD workbooks, or another project-level source."
  )
)

design_sample <- dob_applications |>
  mutate(
    period = case_when(
      filing_year >= design_pre_start_year & filing_year <= pre_end_year ~ design_pre_label,
      filing_year == post_year ~ post_label,
      TRUE ~ NA_character_
    ),
    unit_group = case_when(
      dob_units >= min_units & dob_units <= 89L ~ paste0(min_units, "-89"),
      dob_units >= 90L & dob_units <= 98L ~ "90-98",
      dob_units == 99L ~ "99",
      dob_units >= 100L & dob_units <= 109L ~ "100-109",
      dob_units >= 110L & dob_units <= design_max_units ~ paste0("110-", design_max_units),
      TRUE ~ NA_character_
    )
  ) |>
  filter(
    !is.na(period),
    dob_units >= min_units,
    dob_units <= design_max_units,
    !is.na(total_construction_floor_area),
    total_construction_floor_area > 0,
    !is.na(gross_construction_square_feet_per_unit),
    gross_construction_square_feet_per_unit > 0
  ) |>
  mutate(
    period = factor(period, levels = c(design_pre_label, post_label))
  )

design_summary <- design_sample |>
  group_by(period, unit_group) |>
  summarise(
    applications = n(),
    median_total_construction_floor_area = median(total_construction_floor_area),
    median_gross_construction_square_feet_per_unit = median(gross_construction_square_feet_per_unit),
    median_proposed_stories = median(proposed_stories, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(period, unit_group)

near_threshold_histogram_data <- bind_rows(
  hdb_applications |>
    transmute(
      aggregation_level = "Individual HDB application",
      filing_year,
      units = hdb_units
    ),
  hdb_sites |>
    transmute(
      aggregation_level = "Provisional HDB BBL-year site",
      filing_year,
      units = site_units
    )
) |>
  mutate(
    period = case_when(
      filing_year >= hist_pre_start_year & filing_year <= pre_end_year ~ hist_pre_label,
      filing_year == post_year ~ post_label,
      TRUE ~ NA_character_
    ),
    observation_weight = if_else(
      filing_year >= hist_pre_start_year & filing_year <= pre_end_year,
      1 / hist_pre_years,
      1
    )
  ) |>
  filter(
    !is.na(period),
    units >= min_units,
    units <= design_max_units
  ) |>
  mutate(
    aggregation_level = factor(
      aggregation_level,
      levels = c("Individual HDB application", "Provisional HDB BBL-year site")
    ),
    period = factor(period, levels = c(hist_pre_label, post_label))
  )

site_multiple_histogram_data <- hdb_sites |>
  mutate(
    period = case_when(
      filing_year >= hist_pre_start_year & filing_year <= pre_end_year ~ hist_pre_label,
      filing_year == post_year ~ post_label,
      TRUE ~ NA_character_
    ),
    observation_weight = if_else(
      filing_year >= hist_pre_start_year & filing_year <= pre_end_year,
      1 / hist_pre_years,
      1
    )
  ) |>
  filter(
    !is.na(period),
    site_units > design_max_units,
    site_units <= site_plot_max_units
  ) |>
  mutate(period = factor(period, levels = c(hist_pre_label, post_label)))

theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title.position = "plot",
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

histogram_figure <- ggplot(
  near_threshold_histogram_data,
  aes(x = units, weight = observation_weight)
) +
  geom_histogram(
    binwidth = hist_bin_width,
    boundary = min_units,
    color = "white",
    fill = "#B8B8B8"
  ) +
  geom_vline(xintercept = 100, color = "#2166AC", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(
    vars(aggregation_level, period),
    ncol = 2,
    scales = "free_y",
    labeller = labeller(.multi_line = TRUE)
  ) +
  scale_x_continuous(breaks = seq(min_units, design_max_units, 10)) +
  labs(
    title = "Pre/post histograms of proposed units",
    subtitle = paste0(
      hist_bin_width,
      "-unit bins; the pre-period is annualized and 2024 is omitted.\n",
      "The dashed line marks the 100-unit threshold."
    ),
    x = "Proposed dwelling units",
    y = "Applications or provisional sites per year",
    caption = "A BBL-year is an audit proxy, not a legally validated 485-x eligible site."
  )

ggsave(
  "../output/developer_response_provisional_site_unit_histogram.pdf",
  histogram_figure,
  width = 9,
  height = 7
)

site_multiple_figure <- ggplot(
  site_multiple_histogram_data,
  aes(x = site_units, weight = observation_weight)
) +
  geom_histogram(
    binwidth = hist_bin_width,
    boundary = design_max_units,
    color = "white",
    fill = "#B8B8B8"
  ) +
  geom_vline(
    xintercept = c(198, 297, 396),
    color = "#2166AC",
    linewidth = 0.5,
    linetype = "dashed"
  ) +
  facet_wrap(~period, ncol = 1, scales = "free_y") +
  scale_x_continuous(
    breaks = sort(unique(c(design_max_units, 198, 250, 297, 350, 396)))
  ) +
  labs(
    title = "Provisional site aggregation creates mass at multiples of 99",
    subtitle = paste0(
      hist_bin_width,
      "-unit bins above ",
      design_max_units,
      " units; the pre-period is annualized. Dashed lines mark 198, 297, and 396."
    ),
    x = "Proposed dwelling units per provisional HDB BBL-year site",
    y = "Provisional sites per year",
    caption = "This supplemental wide-range view preserves the multi-building clusters omitted from the near-threshold histogram."
  )

ggsave(
  "../output/developer_response_provisional_site_unit_multiples.pdf",
  site_multiple_figure,
  width = 8,
  height = 7
)

write_parquet_if_changed(
  provisional_site_panel,
  "../output/developer_response_provisional_site_panel.parquet"
)

write_parquet_if_changed(
  application_panel,
  "../output/developer_response_application_panel.parquet"
)

write_csv_if_changed(
  hdb_dob_join_qc,
  "../output/developer_response_hdb_dob_join_qc.csv"
)

write_csv_if_changed(
  site_definition_qc,
  "../output/developer_response_site_definition_qc.csv"
)

write_csv_if_changed(
  area_field_coverage,
  "../output/developer_response_area_field_coverage.csv"
)

write_csv_if_changed(
  design_summary,
  "../output/developer_response_design_summary.csv"
)

write_csv_if_changed(
  exact_99_site_clusters,
  "../output/developer_response_exact_99_site_clusters.csv"
)

cat("Wrote the developer-response audit outputs to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/summarize_dcp_hdb_unit_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

analysis_start <- as.Date("2010-01-01")
analysis_end <- as.Date("2025-12-31")
policy_date <- as.Date("2024-04-20")
pre_start_year <- 2010L
pre_end_year <- 2023L
post_year <- 2025L
pre_years <- pre_end_year - pre_start_year + 1L
display_min_units <- 50L
display_max_units <- 150L
near_min_units <- 95L
near_max_units <- 105L

hdb <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") %>%
  as.data.frame() %>%
  as_tibble()

hdb_with_flags <- hdb %>%
  mutate(
    filed_year = as.integer(format(date_filed, "%Y")),
    proposed_units = suppressWarnings(as.integer(classa_prop)),
    integer_classa_prop = !is.na(classa_prop) & abs(classa_prop - round(classa_prop)) < 1e-8,
    in_main_sample = job_type == "New Building" &
      !is.na(date_filed) &
      date_filed >= analysis_start &
      date_filed <= analysis_end &
      !is.na(classa_prop) &
      classa_prop > 0 &
      integer_classa_prop
  )

sample_qc <- tibble(
  release = paste(sort(unique(hdb$release)), collapse = ";"),
  source_rows = nrow(hdb),
  new_building_rows = sum(hdb$job_type == "New Building", na.rm = TRUE),
  missing_date_filed_new_building = sum(hdb$job_type == "New Building" & is.na(hdb$date_filed), na.rm = TRUE),
  outside_2010_2025_new_building = sum(
    hdb$job_type == "New Building" &
      !is.na(hdb$date_filed) &
      (hdb$date_filed < analysis_start | hdb$date_filed > analysis_end),
    na.rm = TRUE
  ),
  nonpositive_or_missing_classa_prop_new_building_2010_2025 = sum(
    hdb$job_type == "New Building" &
      !is.na(hdb$date_filed) &
      hdb$date_filed >= analysis_start &
      hdb$date_filed <= analysis_end &
      (is.na(hdb$classa_prop) | hdb$classa_prop <= 0),
    na.rm = TRUE
  ),
  noninteger_classa_prop_new_building_2010_2025 = sum(
    hdb_with_flags$job_type == "New Building" &
      !is.na(hdb_with_flags$date_filed) &
      hdb_with_flags$date_filed >= analysis_start &
      hdb_with_flags$date_filed <= analysis_end &
      !is.na(hdb_with_flags$classa_prop) &
      hdb_with_flags$classa_prop > 0 &
      !hdb_with_flags$integer_classa_prop,
    na.rm = TRUE
  ),
  main_sample_rows = sum(hdb_with_flags$in_main_sample),
  policy_date = as.character(policy_date),
  note = "Primary audit sample is DCP HDB New Building application records with positive integer proposed Class A units by DateFiled."
)

analysis_df <- hdb_with_flags %>%
  filter(in_main_sample) %>%
  mutate(
    proposed_units = as.integer(round(classa_prop)),
    policy_period = case_when(
      date_filed < as.Date("2024-01-01") ~ "pre_2010_2023",
      date_filed >= as.Date("2024-01-01") & date_filed < policy_date ~ "transition_2024_pre_adoption",
      date_filed >= policy_date & date_filed <= as.Date("2024-12-31") ~ "transition_2024_post_adoption",
      filed_year == 2025 ~ "post_2025",
      TRUE ~ "other"
    )
  )

exact_counts <- analysis_df %>%
  count(filed_year, proposed_units, name = "building_count") %>%
  arrange(filed_year, proposed_units)

year_summary <- analysis_df %>%
  group_by(filed_year) %>%
  summarise(
    total_new_building_projects = n(),
    count_50_150 = sum(proposed_units >= 50 & proposed_units <= 150),
    count_90_110 = sum(proposed_units >= 90 & proposed_units <= 110),
    count_95_105 = sum(proposed_units >= 95 & proposed_units <= 105),
    count_99 = sum(proposed_units == 99),
    count_100 = sum(proposed_units == 100),
    count_95_98 = sum(proposed_units >= 95 & proposed_units <= 98),
    count_100_104 = sum(proposed_units >= 100 & proposed_units <= 104),
    neighbor_count_90_98_100_109 = sum((proposed_units >= 90 & proposed_units <= 98) | (proposed_units >= 100 & proposed_units <= 109)),
    neighbor_mean_90_98_100_109 = neighbor_count_90_98_100_109 / 19,
    count_99_to_neighbor_mean = ifelse(neighbor_mean_90_98_100_109 > 0, count_99 / neighbor_mean_90_98_100_109, NA_real_),
    share_99_among_90_110 = ifelse(count_90_110 > 0, count_99 / count_90_110, NA_real_),
    .groups = "drop"
  ) %>%
  arrange(filed_year)

period_specs <- tibble(
  period = c(
    "pre_2010_2023",
    "transition_2024_pre_adoption",
    "transition_2024_post_adoption",
    "post_2025",
    "statutory_post_2024_04_20_to_2025"
  ),
  start_date = as.Date(c("2010-01-01", "2024-01-01", "2024-04-20", "2025-01-01", "2024-04-20")),
  end_date = as.Date(c("2023-12-31", "2024-04-19", "2024-12-31", "2025-12-31", "2025-12-31"))
) %>%
  mutate(period_years = as.numeric(end_date - start_date + 1) / 365.25)

period_summary <- lapply(seq_len(nrow(period_specs)), function(i) {
  spec <- period_specs[i, ]
  period_df <- analysis_df %>%
    filter(date_filed >= spec$start_date, date_filed <= spec$end_date)

  tibble(
    period = spec$period,
    start_date = as.character(spec$start_date),
    end_date = as.character(spec$end_date),
    period_years = spec$period_years,
    total_new_building_projects = nrow(period_df),
    annualized_total_new_building_projects = nrow(period_df) / spec$period_years,
    count_50_150 = sum(period_df$proposed_units >= 50 & period_df$proposed_units <= 150),
    count_99 = sum(period_df$proposed_units == 99),
    annualized_count_99 = sum(period_df$proposed_units == 99) / spec$period_years,
    count_100 = sum(period_df$proposed_units == 100),
    count_95_98 = sum(period_df$proposed_units >= 95 & period_df$proposed_units <= 98),
    count_100_104 = sum(period_df$proposed_units >= 100 & period_df$proposed_units <= 104),
    neighbor_count_90_98_100_109 = sum(
      (period_df$proposed_units >= 90 & period_df$proposed_units <= 98) |
        (period_df$proposed_units >= 100 & period_df$proposed_units <= 109)
    ),
    annualized_neighbor_mean_90_98_100_109 = (
      sum(
        (period_df$proposed_units >= 90 & period_df$proposed_units <= 98) |
          (period_df$proposed_units >= 100 & period_df$proposed_units <= 109)
      ) / 19
    ) / spec$period_years,
    count_99_to_neighbor_mean = ifelse(
      sum(
        (period_df$proposed_units >= 90 & period_df$proposed_units <= 98) |
          (period_df$proposed_units >= 100 & period_df$proposed_units <= 109)
      ) > 0,
      sum(period_df$proposed_units == 99) / (
        sum(
          (period_df$proposed_units >= 90 & period_df$proposed_units <= 98) |
            (period_df$proposed_units >= 100 & period_df$proposed_units <= 109)
        ) / 19
      ),
      NA_real_
    )
  )
}) %>%
  bind_rows()

pre_post_exact_comparison <- full_join(
  analysis_df %>%
    filter(filed_year >= pre_start_year, filed_year <= pre_end_year) %>%
    count(proposed_units, name = "pre_total"),
  analysis_df %>%
    filter(filed_year == post_year) %>%
    count(proposed_units, name = "count_2025"),
  by = "proposed_units"
) %>%
  mutate(
    pre_total = ifelse(is.na(pre_total), 0L, pre_total),
    count_2025 = ifelse(is.na(count_2025), 0L, count_2025),
    pre_years = pre_years,
    pre_per_year = pre_total / pre_years,
    difference_2025_minus_pre_per_year = count_2025 - pre_per_year,
    ratio_2025_to_pre_per_year = ifelse(pre_per_year > 0, count_2025 / pre_per_year, NA_real_),
    in_display_range = proposed_units >= display_min_units & proposed_units <= display_max_units
  ) %>%
  arrange(proposed_units)

top_spikes <- pre_post_exact_comparison %>%
  filter(in_display_range) %>%
  arrange(desc(difference_2025_minus_pre_per_year), proposed_units)

near_threshold_by_year <- analysis_df %>%
  filter(proposed_units >= near_min_units, proposed_units <= near_max_units) %>%
  count(filed_year, proposed_units, name = "building_count") %>%
  tidyr::complete(
    filed_year = pre_start_year:post_year,
    proposed_units = near_min_units:near_max_units,
    fill = list(building_count = 0L)
  ) %>%
  arrange(filed_year, proposed_units)

date_basis_sensitivity <- bind_rows(
  analysis_df %>%
    mutate(
      date_basis = "DateFiled",
      year = as.integer(format(date_filed, "%Y"))
    ) %>%
    filter(year >= pre_start_year, year <= post_year) %>%
    group_by(date_basis, year) %>%
    summarise(
      total_new_building_applications = n(),
      count_50_150 = sum(proposed_units >= display_min_units & proposed_units <= display_max_units),
      count_99 = sum(proposed_units == 99),
      count_100 = sum(proposed_units == 100),
      .groups = "drop"
    ),
  analysis_df %>%
    filter(!is.na(date_permit)) %>%
    mutate(
      date_basis = "DatePermit_nonmissing",
      year = as.integer(format(date_permit, "%Y"))
    ) %>%
    filter(year >= pre_start_year, year <= post_year) %>%
    group_by(date_basis, year) %>%
    summarise(
      total_new_building_applications = n(),
      count_50_150 = sum(proposed_units >= display_min_units & proposed_units <= display_max_units),
      count_99 = sum(proposed_units == 99),
      count_100 = sum(proposed_units == 100),
      .groups = "drop"
    )
) %>%
  arrange(date_basis, year)

status_sensitivity <- analysis_df %>%
  mutate(
    audit_period = case_when(
      filed_year >= pre_start_year & filed_year <= pre_end_year ~ "pre_2010_2023",
      filed_year == 2024L & date_filed < policy_date ~ "transition_2024_pre_adoption",
      filed_year == 2024L & date_filed >= policy_date ~ "transition_2024_post_adoption",
      filed_year == post_year ~ "post_2025",
      TRUE ~ "other"
    )
  ) %>%
  filter(audit_period != "other") %>%
  group_by(audit_period, job_status) %>%
  summarise(
    total_new_building_applications = n(),
    count_50_150 = sum(proposed_units >= display_min_units & proposed_units <= display_max_units),
    count_99 = sum(proposed_units == 99),
    count_100 = sum(proposed_units == 100),
    .groups = "drop"
  ) %>%
  arrange(audit_period, job_status)

pre_period_specs <- tibble(
  period = c(
    "full_pre_2010_2023",
    "old_421a_pre_lapse_2010_2015",
    "lapse_revival_transition_2016_2017",
    "affordable_ny_2018_to_2022_06_15",
    "pre_gap_2010_to_2022_06_15",
    "post_421a_gap_2022_06_16_to_2023",
    "recent_pre_2018_2023",
    "recent_pre_2020_2023",
    "post_2025_reference"
  ),
  start_date = as.Date(c(
    "2010-01-01",
    "2010-01-01",
    "2016-01-01",
    "2018-01-01",
    "2010-01-01",
    "2022-06-16",
    "2018-01-01",
    "2020-01-01",
    "2025-01-01"
  )),
  end_date = as.Date(c(
    "2023-12-31",
    "2015-12-31",
    "2017-12-31",
    "2022-06-15",
    "2022-06-15",
    "2023-12-31",
    "2023-12-31",
    "2023-12-31",
    "2025-12-31"
  )),
  notes = c(
    "Headline pooled pre-period.",
    "Older 421-a program years before the January 2016 lapse.",
    "Lapse and revival transition before using 2018 as a cleaner post-revival baseline.",
    "Affordable New York years through the June 15, 2022 construction-commencement cutoff.",
    "All pre-gap years through the June 15, 2022 cutoff.",
    "Post-421-a gap years before 485-x adoption.",
    "Recent baseline that includes the 2022-2023 gap.",
    "Very recent baseline that includes the 2022-2023 gap.",
    "Post-policy comparison year."
  )
) %>%
  mutate(period_years = as.numeric(end_date - start_date + 1) / 365.25)

pre_period_sensitivity <- lapply(seq_len(nrow(pre_period_specs)), function(i) {
  spec <- pre_period_specs[i, ]
  period_df <- analysis_df %>%
    filter(date_filed >= spec$start_date, date_filed <= spec$end_date)
  neighbor_count <- sum(
    (period_df$proposed_units >= 90 & period_df$proposed_units <= 98) |
      (period_df$proposed_units >= 100 & period_df$proposed_units <= 109)
  )

  tibble(
    period = spec$period,
    start_date = as.character(spec$start_date),
    end_date = as.character(spec$end_date),
    period_years = spec$period_years,
    total_new_building_applications = nrow(period_df),
    annualized_total_new_building_applications = nrow(period_df) / spec$period_years,
    count_50_150 = sum(period_df$proposed_units >= display_min_units & period_df$proposed_units <= display_max_units),
    annualized_count_50_150 = sum(period_df$proposed_units >= display_min_units & period_df$proposed_units <= display_max_units) / spec$period_years,
    count_99 = sum(period_df$proposed_units == 99),
    annualized_count_99 = sum(period_df$proposed_units == 99) / spec$period_years,
    count_100 = sum(period_df$proposed_units == 100),
    count_95_98 = sum(period_df$proposed_units >= 95 & period_df$proposed_units <= 98),
    count_100_104 = sum(period_df$proposed_units >= 100 & period_df$proposed_units <= 104),
    neighbor_count_90_98_100_109 = neighbor_count,
    annualized_neighbor_mean_90_98_100_109 = (neighbor_count / 19) / spec$period_years,
    count_99_to_neighbor_mean = ifelse(
      neighbor_count > 0,
      sum(period_df$proposed_units == 99) / (neighbor_count / 19),
      NA_real_
    ),
    share_99_among_90_110 = ifelse(
      sum(period_df$proposed_units >= 90 & period_df$proposed_units <= 110) > 0,
      sum(period_df$proposed_units == 99) / sum(period_df$proposed_units >= 90 & period_df$proposed_units <= 110),
      NA_real_
    ),
    notes = spec$notes
  )
}) %>%
  bind_rows()

post_2025_count_99 <- pre_period_sensitivity$count_99[
  pre_period_sensitivity$period == "post_2025_reference"
]
pre_period_sensitivity <- pre_period_sensitivity %>%
  mutate(
    count_2025_99 = post_2025_count_99,
    difference_2025_99_minus_annualized_99 = count_2025_99 - annualized_count_99,
    ratio_2025_99_to_annualized_99 = ifelse(
      annualized_count_99 > 0,
      count_2025_99 / annualized_count_99,
      NA_real_
    )
  )

pre_period_plot_specs <- pre_period_specs %>%
  filter(period != "post_2025_reference") %>%
  mutate(
    cut_label = factor(
      c(
        "2010-2023 full pre",
        "2010-2015 old 421-a",
        "2016-2017 lapse/revival",
        "2018-Jun 15 2022 Affordable NY",
        "2010-Jun 15 2022 pre-gap",
        "Jun 16 2022-2023 post-421-a gap",
        "2018-2023 recent pre",
        "2020-2023 very recent pre"
      ),
      levels = c(
        "2010-2023 full pre",
        "2010-2015 old 421-a",
        "2016-2017 lapse/revival",
        "2018-Jun 15 2022 Affordable NY",
        "2010-Jun 15 2022 pre-gap",
        "Jun 16 2022-2023 post-421-a gap",
        "2018-2023 recent pre",
        "2020-2023 very recent pre"
      )
    )
  )

post_2025_unit_counts <- analysis_df %>%
  filter(filed_year == post_year) %>%
  filter(proposed_units >= display_min_units, proposed_units <= display_max_units) %>%
  count(proposed_units, name = "building_count") %>%
  tidyr::complete(
    proposed_units = display_min_units:display_max_units,
    fill = list(building_count = 0L)
  )

pre_period_cut_plot_counts <- lapply(seq_len(nrow(pre_period_plot_specs)), function(i) {
  spec <- pre_period_plot_specs[i, ]

  baseline_counts <- analysis_df %>%
    filter(date_filed >= spec$start_date, date_filed <= spec$end_date) %>%
    filter(proposed_units >= display_min_units, proposed_units <= display_max_units) %>%
    count(proposed_units, name = "building_count") %>%
    tidyr::complete(
      proposed_units = display_min_units:display_max_units,
      fill = list(building_count = 0L)
    ) %>%
    mutate(
      buildings_per_year = building_count / spec$period_years,
      comparison_panel = "Baseline average year"
    )

  post_counts <- post_2025_unit_counts %>%
    mutate(
      buildings_per_year = building_count,
      comparison_panel = "2025"
    )

  bind_rows(baseline_counts, post_counts) %>%
    mutate(
      period = spec$period,
      cut_label = spec$cut_label,
      start_date = as.character(spec$start_date),
      end_date = as.character(spec$end_date),
      period_years = spec$period_years,
      comparison_panel = factor(
        comparison_panel,
        levels = c("Baseline average year", "2025")
      )
    )
}) %>%
  bind_rows() %>%
  select(
    period,
    cut_label,
    start_date,
    end_date,
    period_years,
    comparison_panel,
    proposed_units,
    building_count,
    buildings_per_year
  )

pre_period_cut_histogram_counts <- pre_period_cut_plot_counts %>%
  mutate(
    bin_width = 5L,
    bin_left = display_min_units + floor((proposed_units - display_min_units) / bin_width) * bin_width,
    bin_mid = bin_left + (bin_width / 2)
  ) %>%
  group_by(period, cut_label, comparison_panel, bin_width, bin_left, bin_mid) %>%
  summarise(
    building_count = sum(building_count),
    buildings_per_year = sum(buildings_per_year),
    .groups = "drop"
  )

monthly_2024_2025_99 <- analysis_df %>%
  filter(filed_year %in% c(2024L, post_year)) %>%
  mutate(filed_month = format(date_filed, "%Y-%m")) %>%
  group_by(filed_month) %>%
  summarise(
    total_new_building_applications = n(),
    count_50_150 = sum(proposed_units >= display_min_units & proposed_units <= display_max_units),
    count_99 = sum(proposed_units == 99),
    count_100 = sum(proposed_units == 100),
    count_95_105 = sum(proposed_units >= near_min_units & proposed_units <= near_max_units),
    .groups = "drop"
  ) %>%
  arrange(filed_month)

applications_2025_99 <- analysis_df %>%
  filter(filed_year == post_year, proposed_units == 99) %>%
  select(
    job_number,
    bbl,
    bin,
    address,
    borough_name,
    community_district,
    council_district,
    date_filed,
    date_permit,
    date_updated,
    job_status,
    classa_prop,
    classa_net,
    units_co,
    release,
    source_raw_path
  ) %>%
  arrange(date_filed, borough_name, bbl, job_number)

geography_2025_99 <- bind_rows(
  applications_2025_99 %>%
    count(geography_type = "borough_name", geography_value = borough_name, name = "count_2025_99"),
  applications_2025_99 %>%
    count(geography_type = "community_district", geography_value = as.character(community_district), name = "count_2025_99"),
  applications_2025_99 %>%
    count(geography_type = "council_district", geography_value = as.character(council_district), name = "count_2025_99"),
  applications_2025_99 %>%
    count(geography_type = "job_status", geography_value = job_status, name = "count_2025_99")
) %>%
  arrange(geography_type, desc(count_2025_99), geography_value)

duplicate_site_qc <- bind_rows(
  applications_2025_99 %>%
    filter(!is.na(bbl), bbl != "") %>%
    group_by(key_type = "bbl", key_value = bbl) %>%
    summarise(
      n_2025_99_applications = n(),
      job_numbers = paste(sort(unique(job_number)), collapse = ";"),
      addresses = paste(sort(unique(address)), collapse = ";"),
      filed_dates = paste(sort(unique(as.character(date_filed))), collapse = ";"),
      .groups = "drop"
    ),
  applications_2025_99 %>%
    filter(!is.na(bin), bin != "") %>%
    group_by(key_type = "bin", key_value = bin) %>%
    summarise(
      n_2025_99_applications = n(),
      job_numbers = paste(sort(unique(job_number)), collapse = ";"),
      addresses = paste(sort(unique(address)), collapse = ";"),
      filed_dates = paste(sort(unique(as.character(date_filed))), collapse = ";"),
      .groups = "drop"
    ),
  applications_2025_99 %>%
    filter(!is.na(address), address != "") %>%
    group_by(key_type = "address", key_value = address) %>%
    summarise(
      n_2025_99_applications = n(),
      job_numbers = paste(sort(unique(job_number)), collapse = ";"),
      addresses = paste(sort(unique(address)), collapse = ";"),
      filed_dates = paste(sort(unique(as.character(date_filed))), collapse = ";"),
      .groups = "drop"
    ),
  applications_2025_99 %>%
    filter(!is.na(bbl), bbl != "") %>%
    mutate(key_value = paste(bbl, as.character(date_filed), sep = "|")) %>%
    group_by(key_type = "bbl_date_filed", key_value) %>%
    summarise(
      n_2025_99_applications = n(),
      job_numbers = paste(sort(unique(job_number)), collapse = ";"),
      addresses = paste(sort(unique(address)), collapse = ";"),
      filed_dates = paste(sort(unique(as.character(date_filed))), collapse = ";"),
      .groups = "drop"
    )
) %>%
  arrange(key_type, desc(n_2025_99_applications), key_value)

audit_theme <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      text = element_text(color = "#222222"),
      axis.text = element_text(color = "#222222"),
      axis.title = element_text(color = "#222222"),
      strip.text = element_text(color = "#222222"),
      plot.title = element_text(color = "#222222"),
      plot.subtitle = element_text(color = "#444444")
    )
}

headline_counts <- analysis_df %>%
  filter((filed_year >= pre_start_year & filed_year <= pre_end_year) | filed_year == post_year) %>%
  filter(proposed_units >= display_min_units, proposed_units <= display_max_units) %>%
  mutate(
    headline_period = factor(
      ifelse(filed_year <= pre_end_year, "Pre: 2010-2023 average year", "Post: 2025"),
      levels = c("Pre: 2010-2023 average year", "Post: 2025")
    ),
    headline_years = ifelse(filed_year <= pre_end_year, pre_years, 1)
  ) %>%
  count(headline_period, headline_years, proposed_units, name = "building_count") %>%
  mutate(buildings_per_year = building_count / headline_years)

prepost_exact_plot <- ggplot(headline_counts, aes(x = proposed_units, y = buildings_per_year)) +
  geom_col(fill = "#b8b8b8", width = 0.9) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(~ headline_period, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(display_min_units, display_max_units, 10)) +
  labs(
    title = "Filed New Building applications show a 99-unit spike in 2025",
    subtitle = "Years use DateFiled; bars are DCP-edited Class A proposed units.\nPre-period is annualized; 2024 is omitted as a transition year.",
    x = "Proposed Class A dwelling units",
    y = "Filed applications per year"
  ) +
  audit_theme(base_size = 11)

histogram_df <- analysis_df %>%
  filter((filed_year >= pre_start_year & filed_year <= pre_end_year) | filed_year == post_year) %>%
  filter(proposed_units >= display_min_units, proposed_units <= display_max_units) %>%
  mutate(
    headline_period = factor(
      ifelse(filed_year <= pre_end_year, "Pre: 2010-2023 average year", "Post: 2025"),
      levels = c("Pre: 2010-2023 average year", "Post: 2025")
    ),
    observation_weight = ifelse(filed_year <= pre_end_year, 1 / pre_years, 1)
  )

prepost_histogram_plot <- ggplot(histogram_df, aes(x = proposed_units, weight = observation_weight)) +
  geom_histogram(binwidth = 5, boundary = 50, color = "white", fill = "#b8b8b8") +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(~ headline_period, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(display_min_units, display_max_units, 10)) +
  labs(
    title = "Pre/post histogram of proposed units in filed New Building applications",
    subtitle = "Five-unit bins; years use DateFiled and 2024 is omitted as a transition year.\nDashed line marks the 100-unit threshold.",
    x = "Proposed Class A dwelling units",
    y = "Filed applications per year"
  ) +
  audit_theme(base_size = 11)

pre_period_cut_exact_plot <- ggplot(
  pre_period_cut_plot_counts,
  aes(x = proposed_units, y = buildings_per_year)
) +
  geom_col(fill = "#b8b8b8", width = 0.9) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.45, linetype = "dashed") +
  facet_grid(cut_label ~ comparison_panel, scales = "free_y") +
  scale_x_continuous(breaks = seq(display_min_units, display_max_units, 25)) +
  labs(
    title = "The 2025 99-unit spike is visible against multiple pre-period regimes",
    subtitle = "Left panels annualize each baseline; right panels repeat the 2025 filed-application distribution.\nBars are exact proposed Class A unit counts from DCP HDB DateFiled records.",
    x = "Proposed Class A dwelling units",
    y = "Filed applications per year"
  ) +
  audit_theme(base_size = 8) +
  theme(
    strip.text.y = element_text(angle = 0, hjust = 0),
    panel.spacing.y = grid::unit(0.45, "lines")
  )

pre_period_cut_histogram_plot <- ggplot(
  pre_period_cut_histogram_counts,
  aes(x = bin_mid, y = buildings_per_year)
) +
  geom_col(fill = "#b8b8b8", width = 4.5) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.45, linetype = "dashed") +
  facet_grid(cut_label ~ comparison_panel, scales = "free_y") +
  scale_x_continuous(breaks = seq(display_min_units, display_max_units, 25)) +
  labs(
    title = "Five-unit-bin regime cuts also show the post-policy mass near 99 units",
    subtitle = "Left panels annualize each baseline; right panels repeat the 2025 filed-application distribution.\nThe 95-99 bin contains the exact 99-unit bunching mass.",
    x = "Proposed Class A dwelling units",
    y = "Filed applications per year"
  ) +
  audit_theme(base_size = 8) +
  theme(
    strip.text.y = element_text(angle = 0, hjust = 0),
    panel.spacing.y = grid::unit(0.45, "lines")
  )

bin_widths <- c(1, 2, 5, 10)

bin_counts <- lapply(bin_widths, function(bin_width) {
  analysis_df %>%
    filter((filed_year >= pre_start_year & filed_year <= pre_end_year) | filed_year == post_year) %>%
    filter(proposed_units >= display_min_units, proposed_units <= display_max_units) %>%
    mutate(
      headline_period = factor(
        ifelse(filed_year <= pre_end_year, "Pre: 2010-2023 average year", "Post: 2025"),
        levels = c("Pre: 2010-2023 average year", "Post: 2025")
      ),
      headline_years = ifelse(filed_year <= pre_end_year, pre_years, 1),
      bin_width = bin_width,
      bin_left = display_min_units + floor((proposed_units - display_min_units) / bin_width) * bin_width,
      bin_mid = bin_left + (bin_width / 2),
      includes_99 = bin_left <= 99 & 99 < bin_left + bin_width
    ) %>%
    count(headline_period, headline_years, bin_width, bin_left, bin_mid, includes_99, name = "building_count") %>%
    mutate(buildings_per_year = building_count / headline_years)
}) %>%
  bind_rows() %>%
  mutate(bin_width_label = factor(
    paste0(bin_width, "-unit bins"),
    levels = paste0(bin_widths, "-unit bins")
  ))

bin_sensitivity_plot <- ggplot(bin_counts, aes(x = bin_mid, y = buildings_per_year)) +
  geom_col(fill = "#b8b8b8", width = 0.9) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.5, linetype = "dashed") +
  facet_grid(bin_width_label ~ headline_period, scales = "free_y") +
  scale_x_continuous(breaks = seq(display_min_units, display_max_units, 25)) +
  labs(
    title = "Bunching remains visible under multiple unit-bin widths",
    subtitle = "Filed New Building applications are assigned by DateFiled.\nDashed line marks the 100-unit threshold.",
    x = "Proposed Class A dwelling units",
    y = "Filed applications per year"
  ) +
  audit_theme(base_size = 10)

year_plot_df <- year_summary %>%
  select(filed_year, count_99, neighbor_mean_90_98_100_109) %>%
  rename(
    `Exact 99-unit filings` = count_99,
    `Mean exact count among 90-98 and 100-109` = neighbor_mean_90_98_100_109
  ) %>%
  tidyr::pivot_longer(
    cols = c(`Exact 99-unit filings`, `Mean exact count among 90-98 and 100-109`),
    names_to = "series",
    values_to = "count"
  )

year_start_plot <- ggplot(year_plot_df, aes(x = filed_year, y = count, color = series)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  geom_vline(xintercept = 2024 + 110 / 366, color = "#555555", linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = c(
    "Exact 99-unit filings" = "#4d4d4d",
    "Mean exact count among 90-98 and 100-109" = "#2166ac"
  )) +
  scale_x_continuous(breaks = seq(2010, 2025, 1)) +
  labs(
    title = "The exact 99-unit spike starts in the 2024 transition year and jumps in 2025",
    subtitle = "Dashed line marks April 20, 2024, shown within calendar year 2024.",
    x = "Filed year",
    y = "Buildings",
    color = NULL
  ) +
  audit_theme(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

write_csv_if_changed(year_summary, "../output/dcp_hdb_unit_bunching_year_summary.csv")
write_csv_if_changed(sample_qc, "../output/dcp_hdb_unit_bunching_sample_qc.csv")
write_csv_if_changed(exact_counts, "../output/dcp_hdb_unit_bunching_exact_counts.csv")
write_csv_if_changed(period_summary, "../output/dcp_hdb_unit_bunching_period_summary.csv")
write_csv_if_changed(pre_post_exact_comparison, "../output/dcp_hdb_unit_bunching_pre_post_exact_comparison.csv")
write_csv_if_changed(top_spikes, "../output/dcp_hdb_unit_bunching_top_spikes.csv")
write_csv_if_changed(near_threshold_by_year, "../output/dcp_hdb_unit_bunching_near_threshold_by_year.csv")
write_csv_if_changed(date_basis_sensitivity, "../output/dcp_hdb_unit_bunching_date_basis_sensitivity.csv")
write_csv_if_changed(status_sensitivity, "../output/dcp_hdb_unit_bunching_status_sensitivity.csv")
write_csv_if_changed(pre_period_sensitivity, "../output/dcp_hdb_unit_bunching_pre_period_sensitivity.csv")
write_csv_if_changed(pre_period_cut_plot_counts, "../output/dcp_hdb_unit_bunching_pre_period_cut_plot_counts.csv")
write_csv_if_changed(monthly_2024_2025_99, "../output/dcp_hdb_unit_bunching_2024_2025_monthly_99.csv")
write_csv_if_changed(applications_2025_99, "../output/dcp_hdb_unit_bunching_2025_99_applications.csv")
write_csv_if_changed(geography_2025_99, "../output/dcp_hdb_unit_bunching_2025_99_geography.csv")
write_csv_if_changed(duplicate_site_qc, "../output/dcp_hdb_unit_bunching_duplicate_site_qc.csv")

ggsave("../output/dcp_hdb_unit_bunching_pre_post_exact.pdf", prepost_exact_plot, width = 8, height = 8)
ggsave("../output/dcp_hdb_unit_bunching_pre_post_histogram.pdf", prepost_histogram_plot, width = 8, height = 8)
ggsave("../output/dcp_hdb_unit_bunching_pre_period_cut_exact.pdf", pre_period_cut_exact_plot, width = 11, height = 13)
ggsave("../output/dcp_hdb_unit_bunching_pre_period_cut_histogram.pdf", pre_period_cut_histogram_plot, width = 11, height = 13)
ggsave("../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf", bin_sensitivity_plot, width = 10, height = 9)
ggsave("../output/dcp_hdb_unit_bunching_year_start.pdf", year_start_plot, width = 9, height = 5)

cat("Wrote DCP HDB unit bunching audit outputs to ../output\n")

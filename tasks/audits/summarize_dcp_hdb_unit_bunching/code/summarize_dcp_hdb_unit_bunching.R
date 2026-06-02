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
  note = "Primary audit sample is DCP HDB New Building records with positive integer proposed Class A units by date_filed."
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
  filter(filed_year <= 2023 | filed_year == 2025) %>%
  filter(proposed_units >= 50, proposed_units <= 150) %>%
  mutate(
    headline_period = factor(
      ifelse(filed_year <= 2023, "Pre: 2010-2023 average year", "Post: 2025"),
      levels = c("Pre: 2010-2023 average year", "Post: 2025")
    ),
    headline_years = ifelse(filed_year <= 2023, 14, 1)
  ) %>%
  count(headline_period, headline_years, proposed_units, name = "building_count") %>%
  mutate(buildings_per_year = building_count / headline_years)

prepost_exact_plot <- ggplot(headline_counts, aes(x = proposed_units, y = buildings_per_year)) +
  geom_col(aes(fill = proposed_units == 99), width = 0.9, show.legend = FALSE) +
  geom_vline(xintercept = 99, color = "#b2182b", linewidth = 0.6) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(~ headline_period, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("FALSE" = "#b8b8b8", "TRUE" = "#b2182b")) +
  scale_x_continuous(breaks = seq(50, 150, 10)) +
  labs(
    title = "DCP Housing Database new-building filings show a 99-unit spike in 2025",
    subtitle = "Bars are proposed Class A unit counts for DOB-approved New Building jobs; pre-period is annualized.",
    x = "Proposed Class A units",
    y = "Buildings per year"
  ) +
  audit_theme(base_size = 11)

histogram_df <- analysis_df %>%
  filter(filed_year <= 2023 | filed_year == 2025) %>%
  filter(proposed_units >= 50, proposed_units <= 150) %>%
  mutate(
    headline_period = factor(
      ifelse(filed_year <= 2023, "Pre: 2010-2023 average year", "Post: 2025"),
      levels = c("Pre: 2010-2023 average year", "Post: 2025")
    ),
    observation_weight = ifelse(filed_year <= 2023, 1 / 14, 1)
  )

prepost_histogram_plot <- ggplot(histogram_df, aes(x = proposed_units, weight = observation_weight)) +
  geom_histogram(binwidth = 5, boundary = 50, color = "white", fill = "#b8b8b8") +
  geom_vline(xintercept = 99, color = "#b2182b", linewidth = 0.6) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(~ headline_period, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(50, 150, 10)) +
  labs(
    title = "Pre/post histogram of proposed units in DCP HDB new-building filings",
    subtitle = "Five-unit bins; pre-period is annualized. Red line marks 99 and dashed blue line marks 100.",
    x = "Proposed Class A units",
    y = "Buildings per year"
  ) +
  audit_theme(base_size = 11)

bin_widths <- c(1, 2, 5, 10)

bin_counts <- lapply(bin_widths, function(bin_width) {
  analysis_df %>%
    filter(filed_year <= 2023 | filed_year == 2025) %>%
    filter(proposed_units >= 50, proposed_units <= 150) %>%
    mutate(
      headline_period = factor(
        ifelse(filed_year <= 2023, "Pre: 2010-2023 average year", "Post: 2025"),
        levels = c("Pre: 2010-2023 average year", "Post: 2025")
      ),
      headline_years = ifelse(filed_year <= 2023, 14, 1),
      bin_width = bin_width,
      bin_left = 50 + floor((proposed_units - 50) / bin_width) * bin_width,
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
  geom_col(aes(fill = includes_99), width = 0.9, show.legend = FALSE) +
  geom_vline(xintercept = 100, color = "#2166ac", linewidth = 0.5, linetype = "dashed") +
  facet_grid(bin_width_label ~ headline_period, scales = "free_y") +
  scale_fill_manual(values = c("FALSE" = "#b8b8b8", "TRUE" = "#b2182b")) +
  scale_x_continuous(breaks = seq(50, 150, 25)) +
  labs(
    title = "Bunching remains visible under multiple unit-bin widths",
    subtitle = "Highlighted bins contain 99 proposed units; dashed line marks the 100-unit threshold.",
    x = "Proposed Class A units",
    y = "Buildings per year"
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
    "Exact 99-unit filings" = "#b2182b",
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

write_csv_if_changed(sample_qc, "../output/dcp_hdb_unit_bunching_sample_qc.csv")
write_csv_if_changed(exact_counts, "../output/dcp_hdb_unit_bunching_exact_counts.csv")
write_csv_if_changed(year_summary, "../output/dcp_hdb_unit_bunching_year_summary.csv")
write_csv_if_changed(period_summary, "../output/dcp_hdb_unit_bunching_period_summary.csv")

ggsave("../output/dcp_hdb_unit_bunching_pre_post_exact.pdf", prepost_exact_plot, width = 8, height = 8)
ggsave("../output/dcp_hdb_unit_bunching_pre_post_histogram.pdf", prepost_histogram_plot, width = 8, height = 8)
ggsave("../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf", bin_sensitivity_plot, width = 10, height = 9)
ggsave("../output/dcp_hdb_unit_bunching_year_start.pdf", year_start_plot, width = 9, height = 5)

cat("Wrote DCP HDB unit bunching audit outputs to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/summarize_hdb_unit_bunching/code")
# pre_start_year <- 2010L
# pre_end_year <- 2023L
# post_year <- 2025L
# min_units <- 50L
# max_units <- 150L
# max_parent_units <- 400L
# bin_width <- 5L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7L) {
  stop(
    "Expected seven arguments: pre-period start and end years, post year, ",
    "minimum and maximum displayed units, maximum parent units, and bin width."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
max_units <- as.integer(args[5])
max_parent_units <- as.integer(args[6])
bin_width <- as.integer(args[7])

if (
  any(is.na(c(
    pre_start_year, pre_end_year, post_year, min_units, max_units,
    max_parent_units, bin_width
  ))) ||
    pre_start_year > pre_end_year ||
    pre_end_year >= post_year ||
    min_units >= max_units ||
    max_units >= max_parent_units ||
    bin_width <= 0L
) {
  stop("Unit-bunching arguments are not internally consistent.")
}

pre_years <- pre_end_year - pre_start_year + 1L
pre_label <- paste0("Pre: ", pre_start_year, "-", pre_end_year, " annual average")
post_label <- paste0("Post: ", post_year)

hdb <- read_parquet(
  "../input/dcp_housing_database_project_level_25q4.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    job_number = str_squish(job_number),
    filing_year = as.integer(format(date_filed, "%Y")),
    integer_units = !is.na(classa_prop) &
      abs(classa_prop - round(classa_prop)) < 1e-8
  ) |>
  filter(
    job_type == "New Building",
    !is.na(date_filed),
    filing_year >= pre_start_year,
    filing_year <= post_year,
    filing_year <= pre_end_year | filing_year == post_year,
    !is.na(classa_prop),
    classa_prop > 0,
    integer_units
  ) |>
  transmute(
    job_number,
    filing_year,
    units = as.integer(round(classa_prop)),
    bbl = normalize_bbl_field(bbl)
  )

if (anyDuplicated(hdb$job_number)) {
  stop("HDB job_number is not unique in the main bunching sample.")
}

if (any(is.na(hdb$bbl))) {
  stop("HDB main bunching sample contains an invalid BBL.")
}

application_counts <- hdb |>
  mutate(aggregation_level = "Individual HDB application") |>
  count(aggregation_level, filing_year, units, name = "observations")

parent_counts <- hdb |>
  group_by(filing_year, bbl) |>
  summarise(units = sum(units), .groups = "drop") |>
  mutate(aggregation_level = "Provisional HDB BBL-year parent") |>
  count(aggregation_level, filing_year, units, name = "observations")

unit_counts <- bind_rows(application_counts, parent_counts) |>
  mutate(
    period = if_else(filing_year <= pre_end_year, pre_label, post_label),
    years = if_else(filing_year <= pre_end_year, pre_years, 1L)
  ) |>
  group_by(aggregation_level, period, units, years) |>
  summarise(observations = sum(observations), .groups = "drop") |>
  mutate(
    observations_per_year = observations / years,
    aggregation_level = factor(
      aggregation_level,
      levels = c(
        "Individual HDB application",
        "Provisional HDB BBL-year parent"
      )
    ),
    period = factor(period, levels = c(pre_label, post_label))
  ) |>
  arrange(aggregation_level, period, units)

near_threshold_counts <- unit_counts |>
  filter(units >= min_units, units <= max_units) |>
  complete(
    aggregation_level,
    period,
    units = min_units:max_units,
    fill = list(observations = 0L, observations_per_year = 0)
  )

application_plot_data <- near_threshold_counts |>
  filter(aggregation_level == "Individual HDB application")

histogram_counts <- near_threshold_counts |>
  mutate(
    bin_left = min_units + floor((units - min_units) / bin_width) * bin_width,
    bin_mid = bin_left + bin_width / 2
  ) |>
  group_by(aggregation_level, period, bin_mid) |>
  summarise(
    observations_per_year = sum(observations_per_year),
    .groups = "drop"
  )

parent_multiple_counts <- unit_counts |>
  filter(
    aggregation_level == "Provisional HDB BBL-year parent",
    units > max_units,
    units <= max_parent_units
  ) |>
  mutate(
    bin_left = max_units + floor((units - max_units) / bin_width) * bin_width,
    bin_mid = bin_left + bin_width / 2
  ) |>
  group_by(period, bin_mid) |>
  summarise(
    observations_per_year = sum(observations_per_year),
    .groups = "drop"
  )

main_theme <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )

histogram_figure <- ggplot(
  histogram_counts,
  aes(x = bin_mid, y = observations_per_year)
) +
  geom_col(
    width = bin_width * 0.9,
    color = "white",
    fill = "#B8B8B8"
  ) +
  geom_vline(
    xintercept = 100,
    color = "#2166AC",
    linewidth = 0.6,
    linetype = "dashed"
  ) +
  facet_grid(aggregation_level ~ period, scales = "free_y") +
  scale_x_continuous(breaks = seq(min_units, max_units, 10)) +
  labs(
    title = "Proposed unit counts bunch at 99 after 485-x",
    subtitle = paste0(
      bin_width,
      "-unit bins; the pre-period is annualized and 2024 is omitted."
    ),
    x = "Proposed dwelling units",
    y = "Applications or provisional parents per year",
    caption = paste0(
      "A BBL-year is a provisional parent, not a legally validated 485-x ",
      "eligible site."
    )
  ) +
  main_theme

exact_figure <- ggplot(
  application_plot_data,
  aes(x = units, y = observations_per_year)
) +
  geom_col(fill = "#B8B8B8", width = 0.9) +
  geom_vline(
    xintercept = 100,
    color = "#2166AC",
    linewidth = 0.6,
    linetype = "dashed"
  ) +
  facet_wrap(~period, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(min_units, max_units, 10)) +
  labs(
    title = "Filed New Building applications show a 99-unit spike in 2025",
    subtitle = "Exact proposed Class A unit counts; 2024 is omitted as a transition year.",
    x = "Proposed dwelling units",
    y = "Filed applications per year"
  ) +
  main_theme

parent_multiple_figure <- ggplot(
  parent_multiple_counts,
  aes(x = bin_mid, y = observations_per_year)
) +
  geom_col(
    width = bin_width * 0.9,
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
    breaks = sort(unique(c(max_units, 198, 250, 297, 350, 396)))
  ) +
  labs(
    title = "Provisional parent totals show mass at multiples of 99",
    subtitle = paste0(
      bin_width,
      "-unit bins above ",
      max_units,
      " units; the pre-period is annualized."
    ),
    x = "Proposed dwelling units per provisional HDB BBL-year parent",
    y = "Provisional parents per year",
    caption = "Dashed lines mark 198, 297, and 396 units."
  ) +
  main_theme

ggsave(
  "../output/hdb_unit_bunching_histogram.pdf",
  histogram_figure,
  width = 9,
  height = 7
)
ggsave(
  "../output/hdb_unit_bunching_exact.pdf",
  exact_figure,
  width = 8,
  height = 8
)
ggsave(
  "../output/hdb_parent_unit_multiples.pdf",
  parent_multiple_figure,
  width = 8,
  height = 7
)
write_csv_if_changed(
  unit_counts,
  "../output/hdb_unit_bunching_counts.csv"
)

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_parent_unit_distribution/code")
# pre_start_year <- 2011L
# pre_end_year <- 2022L
# post_start_date_text <- "2025-01-01"
# min_units <- 80L
# max_units <- 120L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
  library(tidyr)
})

source("../../shared/code/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- c(as.character(pre_start_year), as.character(pre_end_year), as.character(post_start_date_text), as.character(min_units), as.character(max_units))

if (length(args) != 5L) {
  stop(
    "Expected pre start year, pre end year, post start date, minimum units, ",
    "and maximum units."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_start_date_text <- args[3]
post_start_date <- as.Date(post_start_date_text)
min_units <- as.integer(args[4])
max_units <- as.integer(args[5])

if (
  any(is.na(c(
    pre_start_year, pre_end_year, post_start_date, min_units, max_units
  ))) ||
    pre_start_year > pre_end_year ||
    min_units >= max_units
) {
  stop("Parent-unit distribution arguments are not internally consistent.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

parent_exposure <- read_csv(
  "../input/parent_485x_exposure.csv",
  show_col_types = FALSE,
  guess_max = Inf
) |>
  filter(
    parent_total_units >= min_units,
    parent_total_units <= max_units
  )

parent_rows <- membership |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    total_units = first(parent_observed_units),
    component_filings = n(),
    full_window_observed = first(full_window_observed),
    left_window_observed = first(left_window_observed),
    source_end_date = first(source_end_date),
    .groups = "drop"
  )

if (
  nrow(parent_rows) == 0L ||
    anyDuplicated(parent_rows[c("sample", "parent_id")]) ||
    any(is.na(parent_rows$total_units)) ||
    any(parent_rows$total_units <= 0L)
) {
  stop("Parent-unit distribution inputs failed parent-level QC.")
}

post_end_dates <- parent_rows |>
  filter(sample == "post_policy") |>
  distinct(source_end_date) |>
  pull(source_end_date)

if (length(post_end_dates) != 1L || is.na(post_end_dates)) {
  stop("Post-policy source end date is missing or inconsistent.")
}

post_end_date <- post_end_dates[1]
post_end_label <- paste0(
  format(post_end_date, "%b"), " ",
  as.integer(format(post_end_date, "%d")), ", ",
  format(post_end_date, "%Y")
)
pre_exposure_years <- pre_end_year - pre_start_year + 1L
post_exposure_years <- as.numeric(post_end_date - post_start_date + 1L) / 365.25

pre_rows <- parent_rows |>
  filter(
    sample == "historical",
    full_window_observed,
    cohort_year >= pre_start_year,
    cohort_year <= pre_end_year
  )

post_rows <- parent_rows |>
  filter(
    sample == "post_policy",
    left_window_observed,
    cohort_date >= post_start_date,
    cohort_date <= post_end_date
  )

period_levels <- c(
  paste0(pre_start_year, "–", pre_end_year),
  paste0("2025–", post_end_label)
)

distribution <- bind_rows(
  pre_rows |>
    count(unit_count = total_units) |>
    mutate(
      period = period_levels[1],
      exposure_years = pre_exposure_years
    ),
  post_rows |>
    count(unit_count = total_units) |>
    mutate(
      period = period_levels[2],
      exposure_years = post_exposure_years
    )
) |>
  filter(unit_count >= min_units, unit_count <= max_units) |>
  complete(
    period = factor(period, levels = period_levels),
    unit_count = seq.int(min_units, max_units),
    fill = list(n = 0L)
  ) |>
  group_by(period) |>
  fill(exposure_years, .direction = "downup") |>
  ungroup() |>
  transmute(
    period,
    unit_count,
    parent_count = as.integer(n),
    exposure_years,
    parents_per_year = parent_count / exposure_years
  ) |>
  arrange(period, unit_count)

exposure_sample_levels <- c(
  "A/B rental opportunities",
  "A/B + Option D opportunities"
)

analysis_parents <- bind_rows(
  pre_rows |>
    mutate(
      period = period_levels[1],
      exposure_years = as.numeric(pre_exposure_years)
    ),
  post_rows |>
    mutate(
      period = period_levels[2],
      exposure_years = post_exposure_years
    )
) |>
  filter(total_units >= min_units, total_units <= max_units) |>
  select(
    sample,
    parent_id,
    period,
    exposure_years,
    unit_count = total_units
  )

parent_exposure <- parent_exposure |>
  semi_join(
    analysis_parents,
    by = c("sample", "parent_id")
  )

if (
  anyDuplicated(parent_exposure[c("sample", "parent_id")]) ||
    nrow(anti_join(
      analysis_parents,
      parent_exposure,
      by = c("sample", "parent_id")
    )) > 0L ||
    nrow(anti_join(
      parent_exposure,
      analysis_parents,
      by = c("sample", "parent_id")
    )) > 0L
) {
  stop("Exposure classifications do not match the plotted parent universe.")
}

analysis_exposure <- analysis_parents |>
  left_join(
    parent_exposure |>
      select(
        sample,
        parent_id,
        exposure_status,
        included_ab,
        included_ab_plus_d,
        confidence,
        classification_reason
      ),
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  )

exposure_rows <- bind_rows(
  analysis_exposure |>
    filter(included_ab) |>
    mutate(exposure_sample = exposure_sample_levels[1]),
  analysis_exposure |>
    filter(included_ab_plus_d) |>
    mutate(exposure_sample = exposure_sample_levels[2])
)

period_exposure <- tibble(
  period = period_levels,
  exposure_years = c(
    as.numeric(pre_exposure_years),
    post_exposure_years
  )
)

exposure_distribution <- exposure_rows |>
  count(exposure_sample, period, unit_count, name = "parent_count") |>
  complete(
    exposure_sample = factor(
      exposure_sample,
      levels = exposure_sample_levels
    ),
    period = factor(period, levels = period_levels),
    unit_count = seq.int(min_units, max_units),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    period_exposure,
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(
    exposure_sample = factor(
      as.character(exposure_sample),
      levels = exposure_sample_levels
    ),
    parent_count = as.integer(parent_count),
    parents_per_year = parent_count / exposure_years
  ) |>
  arrange(exposure_sample, period, unit_count)

excluded_status_counts <- analysis_exposure |>
  group_by(period) |>
  summarise(
    classified_not_exposed = sum(exposure_status == "not_exposed"),
    classified_unresolved = sum(exposure_status == "unresolved"),
    .groups = "drop"
  )

exposure_sample_summary <- exposure_rows |>
  group_by(exposure_sample, period) |>
  summarise(
    exposure_years = first(exposure_years),
    included_parents_80_120 = n(),
    exact_99_parents = sum(unit_count == 99L),
    exact_105_parents = sum(unit_count == 105L),
    .groups = "drop"
  ) |>
  left_join(
    excluded_status_counts,
    by = "period",
    relationship = "many-to-one"
  ) |>
  arrange(
    factor(exposure_sample, levels = exposure_sample_levels),
    factor(period, levels = period_levels)
  )

left_boundary_exclusions <- parent_rows |>
  filter(
    sample == "post_policy",
    cohort_date >= post_start_date,
    cohort_date <= post_end_date,
    !left_window_observed
  ) |>
  nrow()

sample_summary <- bind_rows(
  tibble(
    period = period_levels[1],
    period_start = as.Date(paste0(pre_start_year, "-01-01")),
    period_end = as.Date(paste0(pre_end_year, "-12-31")),
    exposure_years = as.numeric(pre_exposure_years),
    included_parents_all_unit_counts = nrow(pre_rows),
    included_parents_80_120 = sum(
      pre_rows$total_units >= min_units & pre_rows$total_units <= max_units
    ),
    exact_99_parents = sum(pre_rows$total_units == 99L),
    excluded_for_left_boundary = 0L,
    parent_status = "complete 365-day linkage windows"
  ),
  tibble(
    period = period_levels[2],
    period_start = post_start_date,
    period_end = post_end_date,
    exposure_years = post_exposure_years,
    included_parents_all_unit_counts = nrow(post_rows),
    included_parents_80_120 = sum(
      post_rows$total_units >= min_units & post_rows$total_units <= max_units
    ),
    exact_99_parents = sum(post_rows$total_units == 99L),
    excluded_for_left_boundary = left_boundary_exclusions,
    parent_status = "provisional through the source end date"
  )
)


if (
  nrow(distribution) != length(period_levels) *
    (max_units - min_units + 1L) ||
    anyDuplicated(distribution[c("period", "unit_count")]) ||
    any(distribution$parent_count < 0L) ||
    any(!is.finite(distribution$parents_per_year)) ||
    any(is.na(analysis_exposure$exposure_status)) ||
    any(is.na(analysis_exposure$included_ab)) ||
    any(is.na(analysis_exposure$included_ab_plus_d)) ||
    nrow(exposure_distribution) !=
      length(exposure_sample_levels) * length(period_levels) *
        (max_units - min_units + 1L) ||
    anyDuplicated(exposure_distribution[
      c("exposure_sample", "period", "unit_count")
    ]) ||
    any(exposure_distribution$parent_count < 0L) ||
    any(!is.finite(exposure_distribution$parents_per_year)) ||
    sum(distribution$parent_count[distribution$period == period_levels[1]]) !=
      sample_summary$included_parents_80_120[1] ||
    sum(distribution$parent_count[distribution$period == period_levels[2]]) !=
      sample_summary$included_parents_80_120[2]
) {
  stop("Parent-unit distribution outputs failed final QC.")
}

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

make_distribution_plot <- function(value_column, y_label, subtitle, out_path) {
  plot_rows <- distribution |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, color = period, group = period)
  ) +
    geom_vline(xintercept = 99, color = "grey45", linetype = "dashed") +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.8) +
    annotate(
      "text", x = 99, y = Inf, label = "99", vjust = 1.5,
      color = "grey30", size = 3.5
    ) +
    scale_color_manual(values = period_colors) +
    scale_x_continuous(
      breaks = seq(min_units, max_units, by = 5L),
      minor_breaks = seq.int(min_units, max_units),
      limits = c(min_units, max_units)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(
      title = "Proposed parent developments by exact unit count",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      color = NULL,
      caption = paste0(
        "One-unit bins. Parent linkage prevents multi-filing developments ",
        "from appearing more than once. Post-period parents are provisional."
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot"
    )

  temp_path <- tempfile(fileext = ".png")
  ggsave(
    temp_path,
    figure,
    width = 11,
    height = 6.5,
    dpi = 180,
    bg = "white"
  )
  publish_file(temp_path, out_path)
}

make_exposure_distribution_plot <- function(
  value_column,
  y_label,
  subtitle,
  out_path
) {
  plot_rows <- exposure_distribution |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, color = period, group = period)
  ) +
    geom_vline(xintercept = 99, color = "grey45", linetype = "dashed") +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.6) +
    facet_wrap(~ exposure_sample, ncol = 1, scales = "free_y") +
    scale_color_manual(values = period_colors) +
    scale_x_continuous(
      breaks = seq(min_units, max_units, by = 5L),
      minor_breaks = seq.int(min_units, max_units),
      limits = c(min_units, max_units)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(
      title = "Proposed 485-x-exposed parents by exact unit count",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      color = NULL,
      caption = paste0(
        "One-unit bins. Not-exposed and unresolved parents are excluded. ",
        "The lower panel adds plausible outer-borough Option D projects."
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      strip.text = element_text(face = "bold", hjust = 0)
    )

  temp_path <- tempfile(fileext = ".png")
  ggsave(
    temp_path,
    figure,
    width = 11,
    height = 9,
    dpi = 180,
    bg = "white"
  )
  publish_file(temp_path, out_path)
}

write_csv_atomic(
  distribution,
  "../output/parent_unit_distribution_80_120.csv"
)
write_csv_atomic(
  sample_summary,
  "../output/parent_unit_distribution_sample_summary.csv"
)
write_csv_atomic(
  exposure_distribution,
  "../output/parent_unit_distribution_exposure_80_120.csv"
)
write_csv_atomic(
  exposure_sample_summary,
  "../output/parent_unit_distribution_exposure_sample_summary.csv"
)

make_distribution_plot(
  "parent_count",
  "Parent developments (total)",
  paste0(
    "Totals: ", period_levels[1], " (12 years) versus Jan. 1, 2025–",
    post_end_label, " (",
    round(post_exposure_years, 2), " observed years)"
  ),
  "../output/parent_unit_distribution_total_80_120.png"
)

make_distribution_plot(
  "parents_per_year",
  "Parent developments per observed year",
  paste0(
    "Annualized: historical counts ÷ ", pre_exposure_years,
    " years; post counts ÷ ", round(post_exposure_years, 3),
    " years (", as.integer(post_end_date - post_start_date + 1L),
    " days)"
  ),
  "../output/parent_unit_distribution_annualized_80_120.png"
)

make_exposure_distribution_plot(
  "parent_count",
  "Classified exposed parent developments (total)",
  paste0(
    "Totals: ", period_levels[1], " (12 years) versus Jan. 1, 2025–",
    post_end_label, " (",
    round(post_exposure_years, 2), " observed years)"
  ),
  "../output/parent_unit_distribution_exposure_total_80_120.png"
)

make_exposure_distribution_plot(
  "parents_per_year",
  "Classified exposed parents per observed year",
  paste0(
    "Annualized: historical counts ÷ ", pre_exposure_years,
    " years; post counts ÷ ", round(post_exposure_years, 3),
    " years (", as.integer(post_end_date - post_start_date + 1L),
    " days)"
  ),
  "../output/parent_unit_distribution_exposure_annualized_80_120.png"
)

cat("Wrote parent-level 80–120 unit distributions to ../output\n")

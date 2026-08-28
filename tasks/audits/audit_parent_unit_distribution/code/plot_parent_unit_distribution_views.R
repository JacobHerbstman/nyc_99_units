# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_unit_distribution/code")
# pre_start_year <- 2011L
# pre_end_year <- 2022L
# post_start_date_text <- "2025-01-01"
# zoom_min_units <- 50L
# zoom_max_units <- 150L
# wide_max_units <- 300L
# full_bin_width <- 25L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7L) {
  stop(
    "Expected pre start year, pre end year, post start date, zoom minimum, ",
    "zoom maximum, wide-view maximum, and full-distribution histogram bin ",
    "width."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_start_date_text <- args[3]
post_start_date <- as.Date(post_start_date_text)
zoom_min_units <- as.integer(args[4])
zoom_max_units <- as.integer(args[5])
wide_max_units <- as.integer(args[6])
full_bin_width <- as.integer(args[7])

if (
  any(is.na(c(
    pre_start_year,
    pre_end_year,
    post_start_date,
    zoom_min_units,
    zoom_max_units,
    wide_max_units,
    full_bin_width
  ))) ||
    pre_start_year > pre_end_year ||
    zoom_min_units >= zoom_max_units ||
    zoom_max_units >= wide_max_units ||
    full_bin_width <= 0L
) {
  stop("Distribution-view arguments are not internally consistent.")
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
    parent_total_units >= zoom_min_units,
    parent_total_units <= wide_max_units
  )

parent_rows <- membership |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    unit_count = first(parent_observed_units),
    full_window_observed = first(full_window_observed),
    left_window_observed = first(left_window_observed),
    source_end_date = first(source_end_date),
    .groups = "drop"
  )

if (
  nrow(parent_rows) == 0L ||
    anyDuplicated(parent_rows[c("sample", "parent_id")]) ||
    any(is.na(parent_rows$unit_count)) ||
    any(parent_rows$unit_count <= 0L)
) {
  stop("Parent rows failed identifier or unit-count QC.")
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
period_levels <- c(
  paste0(pre_start_year, "–", pre_end_year),
  paste0("2025–", post_end_label)
)

broad_parents <- bind_rows(
  parent_rows |>
    filter(
      sample == "historical",
      full_window_observed,
      cohort_year >= pre_start_year,
      cohort_year <= pre_end_year
    ) |>
    mutate(
      period = period_levels[1],
      exposure_years = as.numeric(pre_exposure_years)
    ),
  parent_rows |>
    filter(
      sample == "post_policy",
      left_window_observed,
      cohort_date >= post_start_date,
      cohort_date <= post_end_date
    ) |>
    mutate(
      period = period_levels[2],
      exposure_years = post_exposure_years
    )
)

full_min_units <- min(broad_parents$unit_count)
full_max_units <- max(broad_parents$unit_count)

period_exposure <- tibble(
  period = period_levels,
  exposure_years = c(
    as.numeric(pre_exposure_years),
    post_exposure_years
  )
)

full_distribution <- broad_parents |>
  count(period, unit_count, name = "parent_count") |>
  complete(
    period = factor(period, levels = period_levels),
    unit_count = seq.int(full_min_units, full_max_units),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    period_exposure,
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(
    parent_count = as.integer(parent_count),
    parents_per_year = parent_count / exposure_years
  ) |>
  arrange(period, unit_count)

full_histogram_bins <- broad_parents |>
  mutate(
    bin_start = floor(unit_count / full_bin_width) * full_bin_width,
    bin_end = bin_start + full_bin_width - 1L,
    bin_midpoint = bin_start + (full_bin_width - 1) / 2
  ) |>
  count(
    period,
    exposure_years,
    bin_start,
    bin_end,
    bin_midpoint,
    name = "parent_count"
  ) |>
  mutate(parents_per_year = parent_count / exposure_years) |>
  arrange(period, bin_start)

wide_parents <- broad_parents |>
  filter(
    unit_count >= zoom_min_units,
    unit_count <= wide_max_units
  ) |>
  select(
    sample,
    parent_id,
    cohort_date,
    cohort_year,
    period,
    exposure_years,
    unit_count
  )

parent_exposure <- parent_exposure |>
  semi_join(
    wide_parents,
    by = c("sample", "parent_id")
  )

if (
  anyDuplicated(parent_exposure[c("sample", "parent_id")]) ||
    nrow(anti_join(
      wide_parents,
      parent_exposure,
      by = c("sample", "parent_id")
    )) > 0L ||
    nrow(anti_join(
      parent_exposure,
      wide_parents,
      by = c("sample", "parent_id")
    )) > 0L
) {
  stop("Exposure classifications do not match the wide parent universe.")
}

wide_exposure <- wide_parents |>
  left_join(
    parent_exposure |>
      select(
        sample,
        parent_id,
        exposure_status,
        included_ab,
        included_ab_plus_d
      ),
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  )

zoom_exposure <- wide_exposure |>
  filter(unit_count <= zoom_max_units)

exposure_sample_levels <- c(
  "A/B rental opportunities",
  "A/B + Option D opportunities"
)

exposure_rows <- bind_rows(
  zoom_exposure |>
    filter(included_ab) |>
    mutate(exposure_sample = exposure_sample_levels[1]),
  zoom_exposure |>
    filter(included_ab_plus_d) |>
    mutate(exposure_sample = exposure_sample_levels[2])
)

exposure_distribution <- exposure_rows |>
  count(exposure_sample, period, unit_count, name = "parent_count") |>
  complete(
    exposure_sample = factor(
      exposure_sample,
      levels = exposure_sample_levels
    ),
    period = factor(period, levels = period_levels),
    unit_count = seq.int(zoom_min_units, zoom_max_units),
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

wide_sample_levels <- c(
  "All 6+ parent filings",
  "A/B rental opportunities"
)

wide_distribution <- bind_rows(
  wide_parents |>
    mutate(sample_scope = wide_sample_levels[1]),
  wide_exposure |>
    filter(included_ab) |>
    mutate(sample_scope = wide_sample_levels[2])
) |>
  count(sample_scope, period, unit_count, name = "parent_count") |>
  complete(
    sample_scope = factor(sample_scope, levels = wide_sample_levels),
    period = factor(period, levels = period_levels),
    unit_count = seq.int(zoom_min_units, wide_max_units),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    period_exposure,
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(
    sample_scope = factor(
      as.character(sample_scope),
      levels = wide_sample_levels
    ),
    parent_count = as.integer(parent_count),
    parents_per_year = parent_count / exposure_years
  ) |>
  arrange(sample_scope, period, unit_count)

density_period_levels <- c(
  "2011-2022 full pre",
  "2011-2014 early pre",
  "2019-2022 late pre",
  paste0("2025-", post_end_label, " post")
)

normalized_density <- bind_rows(
  wide_exposure |>
    filter(
      included_ab,
      sample == "historical",
      cohort_year >= 2011L,
      cohort_year <= 2022L
    ) |>
    mutate(density_period = density_period_levels[1]),
  wide_exposure |>
    filter(
      included_ab,
      sample == "historical",
      cohort_year >= 2011L,
      cohort_year <= 2014L
    ) |>
    mutate(density_period = density_period_levels[2]),
  wide_exposure |>
    filter(
      included_ab,
      sample == "historical",
      cohort_year >= 2019L,
      cohort_year <= 2022L
    ) |>
    mutate(density_period = density_period_levels[3]),
  wide_exposure |>
    filter(
      included_ab,
      sample == "post_policy",
      cohort_date >= post_start_date,
      cohort_date <= post_end_date
    ) |>
    mutate(density_period = density_period_levels[4])
) |>
  count(density_period, unit_count, name = "parent_count") |>
  complete(
    density_period = factor(
      density_period,
      levels = density_period_levels
    ),
    unit_count = seq.int(zoom_min_units, wide_max_units),
    fill = list(parent_count = 0L)
  ) |>
  group_by(density_period) |>
  mutate(
    parent_count = as.integer(parent_count),
    density_percent = 100 * parent_count / sum(parent_count)
  ) |>
  ungroup() |>
  arrange(density_period, unit_count)

if (
  nrow(full_distribution) !=
    length(period_levels) * (full_max_units - full_min_units + 1L) ||
    anyDuplicated(full_distribution[c("period", "unit_count")]) ||
    sum(full_distribution$parent_count) != nrow(broad_parents) ||
    any(!is.finite(full_distribution$parents_per_year)) ||
    nrow(exposure_distribution) !=
      length(exposure_sample_levels) * length(period_levels) *
        (zoom_max_units - zoom_min_units + 1L) ||
    anyDuplicated(exposure_distribution[
      c("exposure_sample", "period", "unit_count")
    ]) ||
    nrow(wide_distribution) !=
      length(wide_sample_levels) * length(period_levels) *
        (wide_max_units - zoom_min_units + 1L) ||
    anyDuplicated(wide_distribution[
      c("sample_scope", "period", "unit_count")
    ]) ||
    nrow(normalized_density) !=
      length(density_period_levels) *
        (wide_max_units - zoom_min_units + 1L) ||
    anyDuplicated(normalized_density[
      c("density_period", "unit_count")
    ]) ||
    any(abs(
      normalized_density |>
        group_by(density_period) |>
        summarise(density_sum = sum(density_percent), .groups = "drop") |>
        pull(density_sum) - 100
    ) > 1e-8) ||
    any(is.na(wide_exposure$exposure_status)) ||
    any(!is.finite(exposure_distribution$parents_per_year)) ||
    any(!is.finite(wide_distribution$parents_per_year))
) {
  stop("Distribution views failed final QC.")
}

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

save_plot <- function(figure, out_path, height = 7) {
  temp_path <- tempfile(fileext = ".png")
  ggsave(
    temp_path,
    figure,
    width = 11,
    height = height,
    dpi = 180,
    bg = "white"
  )
  copy_if_changed(temp_path, out_path)
}

save_pdf <- function(figure, out_path, height) {
  temp_path <- tempfile(fileext = ".pdf")
  ggsave(
    temp_path,
    figure,
    width = 11,
    height = height,
    bg = "white"
  )
  copy_if_changed(temp_path, out_path)
}

make_full_histogram <- function(value_column, y_label, subtitle, out_path) {
  plot_rows <- full_histogram_bins |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = bin_midpoint, y = plot_value, fill = period)
  ) +
    geom_col(
      position = "identity",
      alpha = 0.58,
      width = full_bin_width * 0.9
    ) +
    geom_vline(xintercept = 99, color = "grey35", linetype = "dashed") +
    scale_fill_manual(values = period_colors) +
    scale_x_continuous(
      breaks = c(0, 100, 250, 500, 750, 1000, 1250, 1500, 1750),
      limits = c(0, max(full_histogram_bins$bin_end))
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
    labs(
      title = "Full distribution of proposed parent-development sizes",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      fill = NULL,
      caption = paste0(
        "All linked parent proposals from ", full_min_units, " to ",
        full_max_units, " units; ", full_bin_width,
        "-unit histogram bins. Dashed line marks 99 units."
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "top",
      panel.grid.minor = element_blank(),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      plot.margin = margin(10, 12, 10, 28)
    )

  save_plot(figure, out_path)
}

make_full_line <- function(value_column, y_label, subtitle, out_path) {
  plot_rows <- full_distribution |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, color = period, group = period)
  ) +
    geom_vline(xintercept = 99, color = "grey35", linetype = "dashed") +
    geom_line(linewidth = 0.65) +
    scale_color_manual(values = period_colors) +
    scale_x_continuous(
      breaks = c(0, 100, 250, 500, 750, 1000, 1250, 1500, 1750),
      limits = c(full_min_units, full_max_units)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
    labs(
      title = "Full exact-unit distribution of proposed parent developments",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      color = NULL,
      caption = paste0(
        "One-unit bins over the entire observed support. The 50–150 figures ",
        "provide the readable policy-margin view."
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "top",
      panel.grid.minor = element_blank(),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      plot.margin = margin(10, 12, 10, 28)
    )

  save_plot(figure, out_path)
}

make_exposure_histogram <- function(
  value_column,
  y_label,
  subtitle,
  out_path
) {
  plot_rows <- exposure_distribution |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, fill = period)
  ) +
    geom_col(
      position = position_dodge(width = 0.9),
      width = 0.42
    ) +
    geom_vline(xintercept = 99, color = "grey35", linetype = "dashed") +
    facet_wrap(~ exposure_sample, ncol = 1, scales = "free_y") +
    scale_fill_manual(values = period_colors) +
    scale_x_continuous(
      breaks = seq(zoom_min_units, zoom_max_units, by = 10L),
      minor_breaks = seq.int(zoom_min_units, zoom_max_units),
      limits = c(zoom_min_units - 0.5, zoom_max_units + 0.5)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(
      title = "485-x opportunity samples from 50 to 150 units",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      fill = NULL,
      caption = paste0(
        "One-unit histogram bins. Not-exposed and unresolved parents are ",
        "excluded; the lower panel adds plausible Option D projects."
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

  save_plot(figure, out_path, height = 9)
}

make_exposure_line <- function(value_column, y_label, subtitle, out_path) {
  plot_rows <- exposure_distribution |>
    mutate(plot_value = .data[[value_column]])

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, color = period, group = period)
  ) +
    geom_vline(xintercept = 99, color = "grey35", linetype = "dashed") +
    geom_line(linewidth = 0.75) +
    geom_point(size = 1.1) +
    facet_wrap(~ exposure_sample, ncol = 1, scales = "free_y") +
    scale_color_manual(values = period_colors) +
    scale_x_continuous(
      breaks = seq(zoom_min_units, zoom_max_units, by = 10L),
      minor_breaks = seq.int(zoom_min_units, zoom_max_units),
      limits = c(zoom_min_units, zoom_max_units)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(
      title = "485-x opportunity samples from 50 to 150 units",
      subtitle = subtitle,
      x = "Total proposed units in the parent development",
      y = y_label,
      color = NULL,
      caption = paste0(
        "One-unit bins. Not-exposed and unresolved parents are excluded; ",
        "the lower panel adds plausible Option D projects."
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

  save_plot(figure, out_path, height = 9)
}

make_wide_annualized <- function(sample_name, title, out_path, height) {
  plot_rows <- wide_distribution

  if (!is.null(sample_name)) {
    plot_rows <- plot_rows |>
      filter(as.character(sample_scope) == sample_name) |>
      droplevels()
  }

  highlighted_rows <- plot_rows |>
    filter(
      as.character(period) == period_levels[2],
      unit_count %in% c(99L, 198L)
    ) |>
    mutate(label = paste0(unit_count, ": ", round(parents_per_year, 1)))

  caption_text <- if (identical(sample_name, wide_sample_levels[1])) {
    "Dashed reference lines mark 99, 150, and 198 units."
  } else {
    paste0(
      "Dashed reference lines mark 99, 150, and 198 units. The A/B sample ",
      "keeps plausible taxable rental opportunities."
    )
  }

  figure <- ggplot(
    plot_rows,
    aes(
      x = unit_count,
      y = parents_per_year,
      color = period,
      group = period
    )
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.7) +
    geom_point(
      data = highlighted_rows,
      size = 2.2,
      show.legend = FALSE
    ) +
    geom_text(
      data = highlighted_rows,
      aes(label = label),
      hjust = -0.08,
      vjust = -0.35,
      color = "grey15",
      size = 3.4,
      show.legend = FALSE
    ) +
    scale_color_manual(
      values = period_colors,
      labels = c(
        "2011-2022 average",
        "2025-Jul 8, 2026 annualized"
      )
    ) +
    scale_x_continuous(
      breaks = seq(50, 300, by = 50),
      minor_breaks = seq(50, 300, by = 25),
      limits = c(50, 300),
      expand = expansion(mult = c(0, 0.025))
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(
      title = title,
      subtitle = paste0(
        "One-unit bins. Historical counts divided by 12 years; post counts ",
        "divided by the exact ", round(post_exposure_years, 4),
        "-year window."
      ),
      x = "Proposed units in linked parent filing",
      y = "Parent filings per year",
      color = NULL,
      caption = caption_text
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      strip.text = element_text(face = "bold", hjust = 0),
      plot.margin = margin(10, 18, 10, 16)
    )

  if (is.null(sample_name)) {
    figure <- figure + facet_wrap(~ sample_scope, ncol = 1)
  }

  save_pdf(figure, out_path, height)
}

make_normalized_density <- function(out_path) {
  density_colors <- c("#4C78A8", "#9C755F", "#54A24B", "#E45756")
  names(density_colors) <- density_period_levels
  density_linetypes <- c("solid", "dotdash", "dashed", "solid")
  names(density_linetypes) <- density_period_levels

  highlighted_rows <- normalized_density |>
    filter(
      as.character(density_period) == density_period_levels[4],
      unit_count %in% c(99L, 198L)
    ) |>
    mutate(label = paste0(unit_count, ": ", round(density_percent, 1), "%"))

  figure <- ggplot(
    normalized_density,
    aes(
      x = unit_count,
      y = density_percent,
      color = density_period,
      linetype = density_period,
      group = density_period
    )
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(
      aes(linewidth = density_period)
    ) +
    geom_point(
      data = highlighted_rows,
      size = 2.4,
      show.legend = FALSE
    ) +
    geom_text(
      data = highlighted_rows,
      aes(label = label),
      hjust = -0.08,
      vjust = -0.35,
      color = "grey15",
      size = 3.5,
      show.legend = FALSE
    ) +
    scale_color_manual(values = density_colors) +
    scale_linetype_manual(values = density_linetypes) +
    scale_linewidth_manual(
      values = c(0.8, 0.55, 0.65, 1.0),
      guide = "none"
    ) +
    scale_x_continuous(
      breaks = c(50, 75, 99, 125, 150, 175, 198, 225, 250, 275, 300),
      minor_breaks = seq(50, 300, by = 25),
      limits = c(50, 300),
      expand = expansion(mult = c(0, 0.025))
    ) +
    scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      expand = expansion(mult = c(0, 0.08))
    ) +
    labs(
      title = "Normalized distribution of A/B parent filings",
      subtitle = paste0(
        "Each line sums to 100% among A/B rental opportunities proposing ",
        "50-300 units; exact one-unit bins."
      ),
      x = "Proposed units in linked parent filing",
      y = "Share of 50-300-unit parent filings",
      color = NULL,
      linetype = NULL,
      caption = paste0(
        "Post-policy covers Jan. 1, 2025 through ", post_end_label,
        ". Reference lines mark 99, 150, and 198 units."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      legend.text = element_text(size = 9.5),
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      plot.margin = margin(10, 22, 10, 16)
    )

  save_pdf(figure, out_path, 6.3)
}

make_normalized_density_comparison <- function(
  pre_level,
  pre_label,
  out_path
) {
  post_label <- paste0("Post: 2025-", post_end_label)
  comparison_levels <- c(paste0("Pre: ", pre_label), post_label)

  plot_rows <- normalized_density |>
    filter(
      as.character(density_period) %in%
        c(pre_level, density_period_levels[4])
    ) |>
    mutate(
      comparison_period = if_else(
        as.character(density_period) == pre_level,
        comparison_levels[1],
        comparison_levels[2]
      ),
      comparison_period = factor(
        comparison_period,
        levels = comparison_levels
      )
    )

  highlighted_rows <- plot_rows |>
    filter(unit_count %in% c(99L, 198L)) |>
    mutate(
      label = paste0(
        if_else(comparison_period == comparison_levels[1], "Pre ", "Post "),
        round(density_percent, 1), "%"
      ),
      label_hjust = if_else(
        comparison_period == comparison_levels[1],
        1.08,
        -0.08
      ),
      label_vjust = if_else(
        comparison_period == comparison_levels[1],
        -0.65,
        -0.45
      )
    )

  comparison_colors <- c("#4C78A8", "#E45756")
  names(comparison_colors) <- comparison_levels
  comparison_linetypes <- c("solid", "solid")
  names(comparison_linetypes) <- comparison_levels

  figure <- ggplot(
    plot_rows,
    aes(
      x = unit_count,
      y = density_percent,
      color = comparison_period,
      linetype = comparison_period,
      group = comparison_period
    )
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.9) +
    geom_point(
      data = highlighted_rows,
      size = 2.4,
      show.legend = FALSE
    ) +
    geom_text(
      data = highlighted_rows,
      aes(
        label = label,
        hjust = label_hjust,
        vjust = label_vjust
      ),
      color = "grey15",
      size = 3.4,
      show.legend = FALSE
    ) +
    scale_color_manual(values = comparison_colors) +
    scale_linetype_manual(values = comparison_linetypes) +
    scale_x_continuous(
      breaks = c(50, 75, 99, 125, 150, 175, 198, 225, 250, 275, 300),
      minor_breaks = seq(50, 300, by = 25),
      limits = c(50, 300),
      expand = expansion(mult = c(0, 0.025))
    ) +
    scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      expand = expansion(mult = c(0, 0.08))
    ) +
    labs(
      title = paste0("Normalized A/B distribution: post vs ", pre_label),
      subtitle = paste0(
        "Each period sums to 100% among A/B rental opportunities proposing ",
        "50-300 units; exact one-unit bins."
      ),
      x = "Proposed units in linked parent filing",
      y = "Share of 50-300-unit parent filings",
      color = NULL,
      linetype = NULL,
      caption = "Reference lines mark 99, 150, and 198 units."
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      plot.margin = margin(10, 22, 10, 16)
    )

  save_pdf(figure, out_path, 5.8)
}

make_ab_count_comparison <- function(
  pre_level,
  pre_label,
  pre_years,
  annualized,
  out_path
) {
  post_label <- paste0("Post: 2025-", post_end_label)
  comparison_levels <- c(paste0("Pre: ", pre_label), post_label)

  plot_rows <- normalized_density |>
    filter(
      as.character(density_period) %in%
        c(pre_level, density_period_levels[4])
    ) |>
    mutate(
      comparison_period = if_else(
        as.character(density_period) == pre_level,
        comparison_levels[1],
        comparison_levels[2]
      ),
      comparison_period = factor(
        comparison_period,
        levels = comparison_levels
      ),
      exposure_years = if_else(
        as.character(density_period) == pre_level,
        as.numeric(pre_years),
        post_exposure_years
      )
    )

  if (annualized) {
    plot_rows <- plot_rows |>
      mutate(plot_value = parent_count / exposure_years)
  } else {
    plot_rows <- plot_rows |>
      mutate(plot_value = as.numeric(parent_count))
  }

  highlighted_rows <- plot_rows |>
    filter(unit_count %in% c(99L, 198L))

  if (annualized) {
    highlighted_rows <- highlighted_rows |>
      mutate(label_value = format(
        round(plot_value, 1),
        nsmall = 1,
        trim = TRUE
      ))
  } else {
    highlighted_rows <- highlighted_rows |>
      mutate(label_value = format(
        round(plot_value),
        nsmall = 0,
        trim = TRUE
      ))
  }

  highlighted_rows <- highlighted_rows |>
    mutate(
      label = paste0(
        if_else(comparison_period == comparison_levels[1], "Pre ", "Post "),
        label_value
      ),
      label_hjust = if_else(
        comparison_period == comparison_levels[1],
        1.08,
        -0.08
      ),
      label_vjust = -0.65
    )

  comparison_colors <- c("#4C78A8", "#E45756")
  names(comparison_colors) <- comparison_levels

  subtitle_text <- if (annualized) {
    paste0(
      "Historical counts divided by ", pre_years,
      " years; post counts divided by the exact ",
      round(post_exposure_years, 4), "-year window."
    )
  } else {
    paste0(
      "Raw totals over unequal windows: ", pre_label, " spans ",
      pre_years, " years; post spans ",
      round(post_exposure_years, 4), " years."
    )
  }

  title_prefix <- if (annualized) "Annualized" else "Total"
  y_label <- if (annualized) {
    "A/B parent filings per year"
  } else {
    "A/B parent filings"
  }

  figure <- ggplot(
    plot_rows,
    aes(
      x = unit_count,
      y = plot_value,
      color = comparison_period,
      group = comparison_period
    )
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.9) +
    geom_point(
      data = highlighted_rows,
      size = 2.4,
      show.legend = FALSE
    ) +
    geom_text(
      data = highlighted_rows,
      aes(
        label = label,
        hjust = label_hjust,
        vjust = label_vjust
      ),
      color = "grey15",
      size = 3.4,
      show.legend = FALSE
    ) +
    scale_color_manual(values = comparison_colors) +
    scale_x_continuous(
      breaks = c(50, 75, 99, 125, 150, 175, 198, 225, 250, 275, 300),
      minor_breaks = seq(50, 300, by = 25),
      limits = c(50, 300),
      expand = expansion(mult = c(0, 0.025))
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(
      title = paste0(
        title_prefix,
        " A/B parent filings: post vs ", pre_label
      ),
      subtitle = subtitle_text,
      x = "Proposed units in linked parent filing",
      y = y_label,
      color = NULL,
      caption = "Exact one-unit bins. Reference lines mark 99, 150, and 198 units."
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
      plot.caption = element_text(hjust = 0, color = "grey35"),
      plot.title.position = "plot",
      plot.margin = margin(10, 22, 10, 16)
    )

  save_pdf(figure, out_path, 5.8)
}

total_subtitle <- paste0(
  "Totals: ", period_levels[1], " (12 years) versus Jan. 1, 2025–",
  post_end_label, " (", round(post_exposure_years, 2), " observed years)"
)
annualized_subtitle <- paste0(
  "Annualized: historical counts ÷ ", pre_exposure_years,
  " years; post counts ÷ ", round(post_exposure_years, 3),
  " years (", as.integer(post_end_date - post_start_date + 1L),
  " days)"
)

write_csv_if_changed(
  full_distribution,
  "../output/parent_unit_distribution_full.csv"
)
write_csv_if_changed(
  full_histogram_bins,
  "../output/parent_unit_distribution_full_histogram_bins.csv"
)
write_csv_if_changed(
  exposure_distribution,
  "../output/parent_unit_distribution_exposure_50_150.csv"
)
write_csv_if_changed(
  wide_distribution,
  "../output/parent_unit_distribution_annualized_50_300.csv"
)
write_csv_if_changed(
  normalized_density,
  "../output/parent_unit_distribution_normalized_density_50_300_ab.csv"
)

make_full_histogram(
  "parent_count",
  "Parent developments (total)",
  total_subtitle,
  "../output/parent_unit_distribution_full_histogram_total.png"
)
make_full_histogram(
  "parents_per_year",
  "Parent developments per observed year",
  annualized_subtitle,
  "../output/parent_unit_distribution_full_histogram_annualized.png"
)
make_full_line(
  "parent_count",
  "Parent developments (total)",
  total_subtitle,
  "../output/parent_unit_distribution_full_line_total.png"
)
make_full_line(
  "parents_per_year",
  "Parent developments per observed year",
  annualized_subtitle,
  "../output/parent_unit_distribution_full_line_annualized.png"
)
make_exposure_histogram(
  "parent_count",
  "Classified exposed parent developments (total)",
  total_subtitle,
  "../output/parent_unit_distribution_exposure_histogram_total_50_150.png"
)
make_exposure_histogram(
  "parents_per_year",
  "Classified exposed parents per observed year",
  annualized_subtitle,
  "../output/parent_unit_distribution_exposure_histogram_annualized_50_150.png"
)
make_exposure_line(
  "parent_count",
  "Classified exposed parent developments (total)",
  total_subtitle,
  "../output/parent_unit_distribution_exposure_line_total_50_150.png"
)
make_exposure_line(
  "parents_per_year",
  "Classified exposed parents per observed year",
  annualized_subtitle,
  "../output/parent_unit_distribution_exposure_line_annualized_50_150.png"
)

make_wide_annualized(
  NULL,
  "Annual parent filings by proposed unit count",
  "../output/pdf/parent_unit_distribution_annualized_50_300.pdf",
  8.5
)
make_wide_annualized(
  wide_sample_levels[1],
  "Annual parent filings by proposed unit count: all 6+ parents",
  "../output/pdf/parent_unit_distribution_annualized_50_300_all.pdf",
  5.5
)
make_wide_annualized(
  wide_sample_levels[2],
  "Annual parent filings by proposed unit count: A/B rental opportunities",
  "../output/pdf/parent_unit_distribution_annualized_50_300_ab.pdf",
  5.5
)
make_normalized_density(
  "../output/pdf/parent_unit_distribution_normalized_density_50_300_ab.pdf"
)
make_normalized_density_comparison(
  density_period_levels[1],
  "2011-2022",
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_normalized_density_50_300_ab_",
    "post_vs_2011_2022.pdf"
  )
)
make_normalized_density_comparison(
  density_period_levels[2],
  "2011-2014",
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_normalized_density_50_300_ab_",
    "post_vs_2011_2014.pdf"
  )
)
make_normalized_density_comparison(
  density_period_levels[3],
  "2019-2022",
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_normalized_density_50_300_ab_",
    "post_vs_2019_2022.pdf"
  )
)
make_ab_count_comparison(
  density_period_levels[1],
  "2011-2022",
  12,
  FALSE,
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_total_50_300_ab_",
    "post_vs_2011_2022.pdf"
  )
)
make_ab_count_comparison(
  density_period_levels[1],
  "2011-2022",
  12,
  TRUE,
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_annualized_50_300_ab_",
    "post_vs_2011_2022.pdf"
  )
)
make_ab_count_comparison(
  density_period_levels[3],
  "2019-2022",
  4,
  FALSE,
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_total_50_300_ab_",
    "post_vs_2019_2022.pdf"
  )
)
make_ab_count_comparison(
  density_period_levels[3],
  "2019-2022",
  4,
  TRUE,
  paste0(
    "../output/pdf/",
    "parent_unit_distribution_annualized_50_300_ab_",
    "post_vs_2019_2022.pdf"
  )
)

cat("Wrote full-support, 50-150, and 50-300 distribution views to ../output\n")

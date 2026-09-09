# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_parent_unit_distribution/code")
# full_pre_years <- 12
# recent_pre_years <- 4

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

source("../../shared/code/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- c(as.character(full_pre_years), as.character(recent_pre_years))
if (length(args) != 2L) {
  stop("Expected full-period and recent-period historical exposure years.")
}
full_pre_years <- as.numeric(args[1])
recent_pre_years <- as.numeric(args[2])
if (any(is.na(c(full_pre_years, recent_pre_years))) || recent_pre_years >= full_pre_years) {
  stop("Historical exposure-year arguments are inconsistent.")
}

normalized_density <- read_csv(
  "../output/parent_unit_distribution_normalized_density_50_300_ab.csv",
  show_col_types = FALSE
)
annualized_distribution <- read_csv(
  "../output/parent_unit_distribution_annualized_50_300.csv",
  show_col_types = FALSE
)

post_density_period <- unique(
  normalized_density$density_period[grepl(" post$", normalized_density$density_period)]
)
density_period_levels <- c(
  "2011-2022 full pre",
  "2011-2014 early pre",
  "2019-2022 late pre",
  post_density_period
)
normalized_density <- normalized_density |>
  mutate(density_period = factor(density_period, levels = density_period_levels))

post_period <- annualized_distribution |>
  filter(
    sample_scope == "A/B rental opportunities",
    grepl("^2025", period)
  ) |>
  distinct(period, exposure_years)

if (
  nrow(post_period) != 1L ||
    any(is.na(post_period)) ||
    length(post_density_period) != 1L ||
    !all(density_period_levels %in% as.character(normalized_density$density_period))
) {
  stop("Comparison-plot inputs are missing an expected period.")
}

post_label <- paste0(
  "Post: ",
  gsub("–", "-", post_period$period, fixed = TRUE)
)
post_exposure_years <- post_period$exposure_years

save_pdf <- function(figure, out_path) {
  temporary_pdf <- tempfile(fileext = ".pdf")
  ggsave(temporary_pdf, figure, width = 11, height = 5.8, bg = "white")
  publish_file(temporary_pdf, out_path)
}

make_normalized_comparison <- function(pre_level, pre_label, out_path) {
  comparison_levels <- c(paste0("Pre: ", pre_label), post_label)
  plot_rows <- normalized_density |>
    filter(as.character(density_period) %in% c(pre_level, density_period_levels[4])) |>
    mutate(
      comparison_period = if_else(
        as.character(density_period) == pre_level,
        comparison_levels[1],
        comparison_levels[2]
      ),
      comparison_period = factor(comparison_period, levels = comparison_levels)
    )
  highlighted_rows <- plot_rows |>
    filter(unit_count %in% c(99L, 198L)) |>
    mutate(
      label = paste0(
        if_else(comparison_period == comparison_levels[1], "Pre ", "Post "),
        round(density_percent, 1), "%"
      ),
      label_hjust = if_else(comparison_period == comparison_levels[1], 1.08, -0.08),
      label_vjust = if_else(comparison_period == comparison_levels[1], -0.65, -0.45)
    )
  comparison_colors <- c("#4C78A8", "#E45756")
  names(comparison_colors) <- comparison_levels

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = density_percent, color = comparison_period, group = comparison_period)
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.9) +
    geom_point(data = highlighted_rows, size = 2.4, show.legend = FALSE) +
    geom_text(
      data = highlighted_rows,
      aes(label = label, hjust = label_hjust, vjust = label_vjust),
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
    scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      expand = expansion(mult = c(0, 0.08))
    ) +
    labs(
      title = paste0("Normalized A/B distribution: post vs ", pre_label),
      subtitle = paste(
        "Each period sums to 100% among A/B rental opportunities proposing",
        "50-300 units; exact one-unit bins."
      ),
      x = "Proposed units in linked parent filing",
      y = "Share of 50-300-unit parent filings",
      color = NULL,
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
  save_pdf(figure, out_path)
}

make_count_comparison <- function(pre_level, pre_label, pre_years, annualized, out_path) {
  comparison_levels <- c(paste0("Pre: ", pre_label), post_label)
  plot_rows <- normalized_density |>
    filter(as.character(density_period) %in% c(pre_level, density_period_levels[4])) |>
    mutate(
      comparison_period = if_else(
        as.character(density_period) == pre_level,
        comparison_levels[1],
        comparison_levels[2]
      ),
      comparison_period = factor(comparison_period, levels = comparison_levels),
      exposure_years = if_else(
        as.character(density_period) == pre_level,
        pre_years,
        post_exposure_years
      ),
      plot_value = if (annualized) parent_count / exposure_years else parent_count
    )
  highlighted_rows <- plot_rows |>
    filter(unit_count %in% c(99L, 198L)) |>
    mutate(
      label_value = if (annualized) {
        format(round(plot_value, 1), nsmall = 1, trim = TRUE)
      } else {
        format(round(plot_value), nsmall = 0, trim = TRUE)
      },
      label = paste0(
        if_else(comparison_period == comparison_levels[1], "Pre ", "Post "),
        label_value
      ),
      label_hjust = if_else(comparison_period == comparison_levels[1], 1.08, -0.08)
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
  y_label <- if (annualized) "A/B parent filings per year" else "A/B parent filings"

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = plot_value, color = comparison_period, group = comparison_period)
  ) +
    geom_vline(
      xintercept = c(99, 150, 198),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.9) +
    geom_point(data = highlighted_rows, size = 2.4, show.legend = FALSE) +
    geom_text(
      data = highlighted_rows,
      aes(label = label, hjust = label_hjust),
      vjust = -0.65,
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
      title = paste0(title_prefix, " A/B parent filings: post vs ", pre_label),
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
  save_pdf(figure, out_path)
}

make_normalized_comparison(
  density_period_levels[1],
  "2011-2022",
  "../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf"
)
make_normalized_comparison(
  density_period_levels[2],
  "2011-2014",
  "../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2014.pdf"
)
make_normalized_comparison(
  density_period_levels[3],
  "2019-2022",
  "../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2019_2022.pdf"
)
make_count_comparison(
  density_period_levels[1],
  "2011-2022",
  full_pre_years,
  FALSE,
  "../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2011_2022.pdf"
)
make_count_comparison(
  density_period_levels[1],
  "2011-2022",
  full_pre_years,
  TRUE,
  "../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2011_2022.pdf"
)
make_count_comparison(
  density_period_levels[3],
  "2019-2022",
  recent_pre_years,
  FALSE,
  "../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2019_2022.pdf"
)
make_count_comparison(
  density_period_levels[3],
  "2019-2022",
  recent_pre_years,
  TRUE,
  "../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2019_2022.pdf"
)

cat("Wrote pairwise parent-distribution comparison figures to ../output/pdf\n")

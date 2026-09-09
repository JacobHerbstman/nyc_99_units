# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# plot_minimum <- 50L
# plot_maximum <- 150L
# measure <- "normalized"
# plot_style <- "line"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

source("../../shared/code/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- c(as.character(plot_minimum), as.character(plot_maximum), as.character(measure), as.character(plot_style))

if (length(args) != 4L) {
  stop("Expected the minimum, maximum, measure, and style for the filing-size plot.")
}

plot_minimum <- as.integer(args[1])
plot_maximum <- as.integer(args[2])
measure <- args[3]
plot_style <- args[4]

if (
  is.na(plot_minimum) ||
    is.na(plot_maximum) ||
    plot_minimum >= plot_maximum ||
    !measure %in% c("annualized", "normalized") ||
    !plot_style %in% c("line", "histogram")
) {
  stop("The filing-size plot bounds are invalid.")
}

constituents <- read_parquet(
  "../input/constituent_filing_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(included_ab, constituent_units >= plot_minimum)

if (
  nrow(constituents) == 0L ||
    anyDuplicated(constituents[c("sample", "root_job_id")])
) {
  stop("The constituent filing panel failed identifier QC.")
}

period_levels <- constituents |>
  distinct(sample, period) |>
  arrange(match(sample, c("historical", "post_policy"))) |>
  pull(period)

if (length(period_levels) != 2L) {
  stop("Expected exactly one historical and one post-policy period.")
}

filing_distribution <- constituents |>
  count(period, exposure_years, constituent_units, name = "filing_count") |>
  complete(
    period = period_levels,
    constituent_units = seq.int(plot_minimum, plot_maximum),
    fill = list(filing_count = 0L)
  ) |>
  left_join(
    constituents |>
      distinct(period, exposure_years),
    by = "period",
    relationship = "many-to-one",
    suffix = c("", "_period")
  ) |>
  left_join(
    constituents |>
      count(period, name = "all_filing_count"),
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(
    period = factor(period, levels = period_levels),
    exposure_years = coalesce(exposure_years, exposure_years_period),
    annualized_count = filing_count / exposure_years,
    normalized_share = filing_count / all_filing_count,
    plot_value = if (measure == "annualized") {
      annualized_count
    } else {
      normalized_share
    }
  ) |>
  filter(constituent_units <= plot_maximum) |>
  select(-exposure_years_period)

y_axis_label <- if (measure == "annualized") {
  "Constituent filings per year"
} else {
  "Share of all 50+ constituent filings"
}

subtitle_text <- if (measure == "annualized") {
  "Each cleaned filing/building component is counted once and divided by its period's exact duration."
} else {
  "Each cleaned filing/building component is counted once; each period is normalized over all 50+ constituents."
}

output_path <- if (
  measure == "normalized" && plot_maximum == 150L && plot_style == "line"
) {
  "../output/pdf/constituent_filing_distribution_50_150.pdf"
} else {
  paste0(
    "../output/pdf/",
    measure,
    "_constituent_filing_distribution_",
    plot_minimum,
    "_",
    plot_maximum,
    ifelse(plot_style == "histogram", "_histogram", ""),
    ".pdf"
  )
}

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

figure <- ggplot(
  filing_distribution,
  aes(
    x = constituent_units,
    y = plot_value,
    color = period,
    group = period
  )
) +
  geom_vline(
    xintercept = 99,
    color = "grey65",
    linetype = "dashed",
    linewidth = 0.45
  ) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = sort(unique(c(
      plot_minimum,
      75,
      99,
      120,
      150,
      198,
      250,
      plot_maximum
    ))),
    limits = c(plot_minimum, plot_maximum) +
      if (plot_style == "histogram") c(-0.5, 0.5) else c(0, 0)
  ) +
  scale_y_continuous(
    labels = if (measure == "normalized") {
      label_percent(accuracy = 0.1)
    } else {
      label_number(accuracy = 0.1)
    },
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = paste0(
      ifelse(measure == "annualized", "Annualized", "Normalized"),
      " distribution of constituent filing sizes"
    ),
    subtitle = subtitle_text,
    x = "Proposed units in the constituent filing",
    y = y_axis_label,
    color = NULL,
    caption = paste0(
      "A linked parent filed as 99+57 contributes one observation at 99 and one at 57. ",
      "The dashed line marks 99 units."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9)
  )

if (plot_style == "histogram") {
  figure <- figure +
    geom_col(aes(fill = period), width = 1, linewidth = 0) +
    scale_fill_manual(values = period_colors) +
    facet_wrap(vars(period), ncol = 1) +
    labs(
      subtitle = paste0(
        "One-unit bins; each period normalized over all 50+ constituent filings. ",
        "Both panels use the same scales."
      )
    ) +
    theme(
      legend.position = "none",
      strip.text = element_text(size = 12, face = "bold", hjust = 0),
      panel.spacing = grid::unit(1.2, "lines")
    )
} else {
  figure <- figure + geom_line(linewidth = 0.9)
}

temp_path <- tempfile(fileext = ".pdf")
ggsave(
  temp_path, figure, width = 11,
  height = ifelse(plot_style == "histogram", 8.5, 6.1), bg = "white"
)
publish_file(
  temp_path,
  output_path
)

cat("Wrote the constituent filing-size distribution to ../output/pdf\n")

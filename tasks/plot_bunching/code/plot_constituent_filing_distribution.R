# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

# Sizes of A/B constituent filings of at least 50 units over exact one-unit
# bins: filings per year, or shares of all 50+ filings in each period.
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |> filter(included_ab, constituent_units >= 50)
stopifnot(!anyDuplicated(constituents[c("sample", "root_job_id")]))
periods <- constituents |> distinct(sample, period) |> arrange(sample) |> pull(period)
stopifnot(length(periods) == 2L)
colors <- setNames(c("#4C78A8", "#E45756"), periods)

filing_plot <- function(maximum, measure, histogram = FALSE) {
  data <- constituents |>
    count(period, constituent_units, name = "filings") |>
    complete(period = periods, constituent_units = 50:maximum, fill = list(filings = 0L)) |>
    left_join(constituents |> count(period, exposure_years, name = "all_filings"), by = "period",
      relationship = "many-to-one") |>
    filter(constituent_units <= maximum) |>
    mutate(period = factor(period, levels = periods),
      value = if (measure == "annualized") filings / exposure_years else filings / all_filings)
  figure <- ggplot(data, aes(constituent_units, value, color = period, group = period)) +
    geom_vline(xintercept = 99, color = "grey65", linetype = "dashed", linewidth = 0.45) +
    scale_color_manual(values = colors) +
    scale_x_continuous(breaks = sort(unique(c(50, 75, 99, 120, 150, 198, 250, maximum))),
      limits = c(50, maximum) + if (histogram) c(-0.5, 0.5) else c(0, 0)) +
    scale_y_continuous(labels = if (measure == "normalized") label_percent(accuracy = 0.1) else
      label_number(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) +
    labs(title = paste(if (measure == "annualized") "Annualized" else "Normalized",
        "distribution of constituent filing sizes"),
      subtitle = if (measure == "annualized") {
        "Each cleaned filing/building component is counted once and divided by its period's exact duration."
      } else {
        "Each cleaned filing/building component is counted once; each period is normalized over all 50+ constituents."
      },
      x = "Proposed units in the constituent filing",
      y = if (measure == "annualized") "Constituent filings per year" else "Share of all 50+ constituent filings",
      color = NULL,
      caption = paste0("A linked parent filed as 99+57 contributes one observation at 99 and one at 57. ",
        "The dashed line marks 99 units.")) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top", panel.grid.minor = element_blank(), plot.caption = element_text(size = 9))
  if (!histogram) return(figure + geom_line(linewidth = 0.9))
  figure +
    geom_col(aes(fill = period), width = 1, linewidth = 0) +
    scale_fill_manual(values = colors) +
    facet_wrap(vars(period), ncol = 1) +
    labs(subtitle = paste0("One-unit bins; each period normalized over all 50+ constituent filings. ",
      "Both panels use the same scales.")) +
    theme(legend.position = "none", strip.text = element_text(size = 12, face = "bold", hjust = 0),
      panel.spacing = grid::unit(1.2, "lines"))
}

ggsave("../output/pdf/constituent_filing_distribution_50_150.pdf", filing_plot(150, "normalized"),
  width = 11, height = 6.1, bg = "white")
ggsave("../output/pdf/annualized_constituent_filing_distribution_50_300.pdf", filing_plot(300, "annualized"),
  width = 11, height = 6.1, bg = "white")
ggsave("../output/pdf/normalized_constituent_filing_distribution_50_300.pdf", filing_plot(300, "normalized"),
  width = 11, height = 6.1, bg = "white")
ggsave("../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf",
  filing_plot(300, "normalized", histogram = TRUE), width = 11, height = 8.5, bg = "white")

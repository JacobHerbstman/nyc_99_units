# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

# CDFs of A/B constituent filing sizes from a minimum size, over detail
# (to 300 units) and full-support panels, marking where the recent CDF first
# overtakes the historical one and where both reach 100 percent.
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |> filter(included_ab)
stopifnot(!anyDuplicated(constituents[c("sample", "root_job_id")]))
periods <- constituents |> distinct(sample, period) |> arrange(sample) |> pull(period)
stopifnot(length(periods) == 2L)
colors <- setNames(c("#4C78A8", "#E45756"), periods)

cdf_plot <- function(minimum) {
  filings <- constituents |> filter(constituent_units >= minimum)
  support <- max(filings$constituent_units)
  cdf <- filings |>
    count(period, constituent_units, name = "filings") |>
    complete(period = periods, constituent_units = minimum:support, fill = list(filings = 0L)) |>
    group_by(period) |>
    arrange(constituent_units, .by_group = TRUE) |>
    mutate(cumulative_share = cumsum(filings) / sum(filings)) |>
    ungroup() |>
    mutate(period = factor(period, levels = periods))
  gap <- cdf |>
    pivot_wider(id_cols = constituent_units, names_from = period, values_from = cumulative_share) |>
    mutate(difference = .data[[periods[1]]] - .data[[periods[2]]])
  overtakes <- gap$constituent_units[which(gap$difference < 0 & lag(gap$difference) >= 0)[1]]
  converges <- gap$constituent_units[which(gap[[periods[1]]] >= 1 - 1e-12 & gap[[periods[2]]] >= 1 - 1e-12)[1]]
  stopifnot(!is.na(overtakes), !is.na(converges))

  panels <- paste0(c("Detail: ", "Full support: "), minimum, "-", c(300, support), " units")
  data <- bind_rows(cdf |> filter(constituent_units <= 300) |> mutate(panel = panels[1]),
    cdf |> mutate(panel = panels[2])) |>
    mutate(panel = factor(panel, levels = panels))
  label <- paste0(minimum, "+")
  ggplot(data, aes(constituent_units, cumulative_share, color = period, group = period)) +
    geom_vline(xintercept = 99, color = "grey65", linetype = "dashed", linewidth = 0.45) +
    geom_vline(xintercept = overtakes, color = "grey35", linetype = "dotted", linewidth = 0.55) +
    geom_vline(data = tibble(panel = factor(panels[2], levels = panels), converges = converges),
      aes(xintercept = converges), color = "grey35", linetype = "longdash", linewidth = 0.55) +
    geom_step(linewidth = 0.85, direction = "hv") +
    facet_wrap(vars(panel), ncol = 1, scales = "free_x") +
    scale_color_manual(values = colors) +
    scale_x_continuous(breaks = function(limits) {
      if (diff(limits) > 300) sort(unique(c(minimum, 99, 150, 198, 300, 500, 1000, converges))) else
        sort(unique(c(minimum, overtakes, 99, 150, 198, 300)))
    }, expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(labels = label_percent(accuracy = 1), breaks = seq(0, 1, by = 0.25), limits = c(0, 1),
      expand = expansion(mult = c(0, 0.02))) +
    labs(title = paste0("CDF of constituent filing sizes: ", label, " filings"),
      subtitle = paste0("Each line is the share of all ", label, " filings at or below a given size. ",
        "Post overtakes pre at ", overtakes, "; pre catches up only when both CDFs reach 100% at ", converges, "."),
      x = "Proposed units in the constituent filing",
      y = paste0("Cumulative share of all ", label, " constituent filings"), color = NULL,
      caption = paste0("Dashed: 99 units. Dotted: post first overtakes pre at ", overtakes,
        ". Long-dashed: both distributions reach 100% at ", converges,
        ". Shares describe composition, not total construction.")) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top", panel.grid.minor = element_blank(), panel.spacing = grid::unit(1.1, "lines"),
      plot.caption = element_text(size = 9), strip.text = element_text(size = 11, face = "bold", hjust = 0))
}

ggsave("../output/pdf/constituent_filing_cdf.pdf", cdf_plot(50), width = 11, height = 8.5, bg = "white")
ggsave("../output/pdf/constituent_filing_cdf_6_plus.pdf", cdf_plot(6), width = 11, height = 8.5, bg = "white")

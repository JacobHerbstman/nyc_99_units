# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# plot_minimum <- 50L
# detail_maximum <- 300L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

source("../../shared/code/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- c(as.character(plot_minimum), as.character(detail_maximum))

if (length(args) != 2L) {
  stop("Expected the minimum and detail maximum for the filing-size CDF.")
}

plot_minimum <- as.integer(args[1])
detail_maximum <- as.integer(args[2])

if (
  is.na(plot_minimum) ||
    is.na(detail_maximum) ||
    plot_minimum >= detail_maximum
) {
  stop("The filing-size CDF bounds are invalid.")
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

support_maximum <- max(constituents$constituent_units)

cdf <- constituents |>
  count(period, constituent_units, name = "filing_count") |>
  complete(
    period = period_levels,
    constituent_units = seq.int(plot_minimum, support_maximum),
    fill = list(filing_count = 0L)
  ) |>
  group_by(period) |>
  arrange(constituent_units, .by_group = TRUE) |>
  mutate(cumulative_share = cumsum(filing_count) / sum(filing_count)) |>
  ungroup() |>
  mutate(period = factor(period, levels = period_levels))

cdf_comparison <- cdf |>
  select(period, constituent_units, cumulative_share) |>
  pivot_wider(names_from = period, values_from = cumulative_share) |>
  mutate(
    pre_minus_post =
      .data[[period_levels[1]]] - .data[[period_levels[2]]],
    previous_difference = lag(pre_minus_post)
  )

post_overtakes <- cdf_comparison |>
  filter(pre_minus_post < 0, previous_difference >= 0) |>
  slice_head(n = 1L) |>
  pull(constituent_units)

full_convergence <- cdf_comparison |>
  filter(
    .data[[period_levels[1]]] >= 1 - 1e-12,
    .data[[period_levels[2]]] >= 1 - 1e-12
  ) |>
  slice_head(n = 1L) |>
  pull(constituent_units)

if (length(post_overtakes) != 1L || length(full_convergence) != 1L) {
  stop("The CDF crossing points could not be identified uniquely.")
}

plot_data <- bind_rows(
  cdf |>
    filter(constituent_units <= detail_maximum) |>
    mutate(panel = paste0("Detail: ", plot_minimum, "-", detail_maximum, " units")),
  cdf |>
    mutate(panel = paste0("Full support: ", plot_minimum, "-", support_maximum, " units"))
) |>
  mutate(
    panel = factor(
      panel,
      levels = c(
        paste0("Detail: ", plot_minimum, "-", detail_maximum, " units"),
        paste0("Full support: ", plot_minimum, "-", support_maximum, " units")
      )
    )
  )

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

sample_label <- paste0(plot_minimum, "+")

figure <- ggplot(
  plot_data,
  aes(
    x = constituent_units,
    y = cumulative_share,
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
  geom_vline(
    xintercept = post_overtakes,
    color = "grey35",
    linetype = "dotted",
    linewidth = 0.55
  ) +
  geom_vline(
    data = tibble(
      panel = factor(
        paste0("Full support: ", plot_minimum, "-", support_maximum, " units"),
        levels = levels(plot_data$panel)
      ),
      full_convergence = full_convergence
    ),
    aes(xintercept = full_convergence),
    color = "grey35",
    linetype = "longdash",
    linewidth = 0.55
  ) +
  geom_step(linewidth = 0.85, direction = "hv") +
  facet_wrap(vars(panel), ncol = 1, scales = "free_x") +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = function(limits) {
      if (diff(limits) > detail_maximum) {
        sort(unique(c(
          plot_minimum, 99, 150, 198, detail_maximum,
          500, 1000, full_convergence
        )))
      } else {
        sort(unique(c(
          plot_minimum, post_overtakes, 99, 150, 198, detail_maximum
        )))
      }
    },
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    breaks = seq(0, 1, by = 0.25),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = paste0("CDF of constituent filing sizes: ", sample_label, " filings"),
    subtitle = paste0(
      "Each line is the share of all ",
      sample_label,
      " filings at or below a given size. ",
      "Post overtakes pre at ",
      post_overtakes,
      "; pre catches up only when both CDFs reach 100% at ",
      full_convergence,
      "."
    ),
    x = "Proposed units in the constituent filing",
    y = paste0("Cumulative share of all ", sample_label, " constituent filings"),
    color = NULL,
    caption = paste0(
      "Dashed: 99 units. Dotted: post first overtakes pre at ",
      post_overtakes,
      ". Long-dashed: both distributions reach 100% at ",
      full_convergence,
      ". Shares describe composition, not total construction."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    panel.spacing = grid::unit(1.1, "lines"),
    plot.caption = element_text(size = 9),
    strip.text = element_text(size = 11, face = "bold", hjust = 0)
  )

temp_path <- tempfile(fileext = ".pdf")
ggsave(temp_path, figure, width = 11, height = 8.5, bg = "white")
publish_file(
  temp_path,
  if (plot_minimum == 50L) {
    "../output/pdf/constituent_filing_cdf.pdf"
  } else {
    paste0("../output/pdf/constituent_filing_cdf_", plot_minimum, "_plus.pdf")
  }
)

cat("Wrote the constituent filing-size CDF to ../output/pdf\n")

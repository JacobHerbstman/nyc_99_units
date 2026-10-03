# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/presentation_figures/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

# Shares of A/B parents of 50 to 300 units by exact size, out of all parents
# of at least 50 units in each period: 2019-2022 alone, then with 2025-2026
# drawn over it on the same axes.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |> filter(included_ab, parent_total_units >= 50)
stopifnot(!anyDuplicated(parents$parent_id))
shares <- parents |>
  count(sample, parent_total_units, name = "parents") |>
  group_by(sample) |>
  mutate(share = parents / sum(parents)) |>
  ungroup() |>
  filter(parent_total_units <= 300) |>
  complete(sample, parent_total_units = 50:300, fill = list(parents = 0L, share = 0))
colors <- c(historical = "#4C78A8", post_policy = "#E45756")
labels <- c(historical = "2019-2022", post_policy = "2025-2026")

reveal <- function(samples) {
  ggplot(shares |> filter(sample %in% samples), aes(parent_total_units, share, fill = sample)) +
    geom_col(width = 1, position = "identity", alpha = 0.75) +
    scale_fill_manual(values = colors, labels = labels, limits = names(colors), drop = FALSE) +
    scale_x_continuous(breaks = c(50, 99, 150, 198, 250, 300), limits = c(49, 301), expand = c(0, 0)) +
    scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, max(shares$share) * 1.05),
      expand = c(0, 0)) +
    labs(x = "Units in the project", y = "Share of projects", fill = NULL) +
    theme_minimal(base_size = 14) +
    theme(legend.position = "top", panel.grid.minor = element_blank())
}
ggsave("../output/pdf/parent_bunching_2019_2022.pdf", reveal("historical"), width = 10, height = 5.2, bg = "white")
ggsave("../output/pdf/parent_bunching_both_periods.pdf", reveal(c("historical", "post_policy")), width = 10,
  height = 5.2, bg = "white")

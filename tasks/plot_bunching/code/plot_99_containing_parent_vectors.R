# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

parents <- read_parquet("../input/parent_opportunity_panel.parquet")

if (
  nrow(parents) == 0L ||
    anyDuplicated(parents[c("sample", "parent_id")])
) {
  stop("The parent opportunity panel failed identifier QC.")
}

period_levels <- parents |>
  distinct(sample, period) |>
  arrange(match(sample, c("historical", "post_policy"))) |>
  pull(period)

splitting_parents <- parents |>
  filter(included_ab, multi_component, n_components_eq_99 > 0L)

period_counts <- splitting_parents |>
  count(period, name = "parent_count")

pre_count <- period_counts |>
  filter(period == period_levels[1]) |>
  pull(parent_count)

post_count <- period_counts |>
  filter(period == period_levels[2]) |>
  pull(parent_count)

pre_count <- ifelse(length(pre_count) == 0L, 0L, pre_count)
post_count <- ifelse(length(post_count) == 0L, 0L, post_count)

if (post_count == 0L) {
  stop("No post-policy multi-component parents contain a 99-unit constituent.")
}

vector_totals <- splitting_parents |>
  filter(period == period_levels[2]) |>
  count(sorted_component_vector, name = "vector_total")

vector_distribution <- splitting_parents |>
  filter(period == period_levels[2]) |>
  count(
    sorted_component_vector,
    splitting_verification_status,
    name = "parent_count"
  ) |>
  left_join(
    vector_totals,
    by = "sorted_component_vector",
    relationship = "many-to-one"
  ) |>
  mutate(
    sorted_component_vector = reorder(
      sorted_component_vector,
      vector_total
    )
  )

verification_colors <- c(
  "suggestive_separate_components" = "#E68666",
  "unable_to_verify" = "#B8B8B8",
  "verified_separate_485x_units" = "#4C78A8"
)

verification_labels <- c(
  "suggestive_separate_components" = "Suggestive separate components",
  "unable_to_verify" = "Unable to verify",
  "verified_separate_485x_units" = "Verified separate 485-x units"
)

figure <- ggplot(
  vector_distribution,
  aes(
    x = parent_count,
    y = sorted_component_vector,
    fill = splitting_verification_status
  )
) +
  geom_col(width = 0.72) +
  geom_text(
    data = vector_totals |>
      mutate(
        sorted_component_vector = reorder(
          sorted_component_vector,
          vector_total
        )
      ),
    aes(
      x = vector_total,
      y = sorted_component_vector,
      label = vector_total
    ),
    inherit.aes = FALSE,
    hjust = -0.3,
    size = 3.4
  ) +
  scale_fill_manual(
    values = verification_colors,
    labels = verification_labels
  ) +
  scale_x_continuous(
    breaks = pretty_breaks(),
    expand = expansion(mult = c(0, 0.1))
  ) +
  labs(
    title = "Linked parents containing a 99-unit constituent",
    subtitle = paste0(
      post_count,
      " post-policy parents and ",
      pre_count,
      " in the 2019-2022 comparison period."
    ),
    x = "Parent opportunities",
    y = "Constituent filing vector",
    fill = "Separation evidence",
    caption = paste0(
      "Each bar is one linked parent configuration. Filing vectors describe observed ",
      "components and do not by themselves prove separate legal 485-x projects."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

ggsave("../output/pdf/parents_with_99_unit_constituents.pdf", figure, width = 11, height = 7.2, bg = "white")

cat("Wrote the 99-containing parent-vector figure to ../output/pdf\n")

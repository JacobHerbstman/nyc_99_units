# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

# Recent A/B parents with several constituents, at least one of 99 units, by
# their constituent vector and the evidence that the constituents are separate.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, multi_component, n_components_eq_99 > 0L)
stopifnot(!anyDuplicated(parents[c("sample", "parent_id")]))
post <- parents |> filter(sample == "post_policy")
stopifnot(nrow(post) > 0L)

vectors <- post |>
  count(sorted_component_vector, splitting_verification_status, name = "parents") |>
  group_by(sorted_component_vector) |>
  mutate(vector_total = sum(parents)) |>
  ungroup() |>
  mutate(sorted_component_vector = reorder(sorted_component_vector, vector_total))
totals <- vectors |> distinct(sorted_component_vector, vector_total)

figure <- ggplot(vectors, aes(parents, sorted_component_vector, fill = splitting_verification_status)) +
  geom_col(width = 0.72) +
  geom_text(data = totals, aes(vector_total, sorted_component_vector, label = vector_total), inherit.aes = FALSE,
    hjust = -0.3, size = 3.4) +
  scale_fill_manual(values = c(suggestive_separate_components = "#E68666", unable_to_verify = "#B8B8B8",
      verified_separate_485x_units = "#4C78A8"),
    labels = c(suggestive_separate_components = "Suggestive separate components",
      unable_to_verify = "Unable to verify", verified_separate_485x_units = "Verified separate 485-x units")) +
  scale_x_continuous(breaks = pretty_breaks(), expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Linked parents containing a 99-unit constituent",
    subtitle = paste0(nrow(post), " post-policy parents and ", sum(parents$sample == "historical"),
      " in the 2019-2022 comparison period."),
    x = "Parent opportunities", y = "Constituent filing vector", fill = "Separation evidence",
    caption = paste0("Each bar is one linked parent configuration. Filing vectors describe observed ",
      "components and do not by themselves prove separate legal 485-x projects.")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

ggsave("../output/pdf/parents_with_99_unit_constituents.pdf", figure, width = 11, height = 7.2, bg = "white")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})
source("../../../shared/code/write_data_report.R")

# The pilot saves the adopted sample and weights, normalized within each period.
parents <- read_csv("../output/analysis_parents.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(parents[c("sample", "parent_id")]),
          setequal(parents$sample, c("historical", "post_policy")),
          all(is.finite(parents$weight) & parents$weight > 0),
          all(is.finite(parents$parent_total_units) & parents$parent_total_units >= 50))
weight_totals <- parents |> group_by(sample) |> summarise(weight = sum(weight))
stopifnot(all(abs(weight_totals$weight - 1) < 1e-10))
n_post <- sum(parents$sample == "post_policy")
stopifnot(all(abs(parents$weight[parents$sample == "post_policy"] - 1 / n_post) < 1e-10))

# These display bins leave 99 and 198 visible. All exact units enter the sums.
size_bins <- c("50-98", "99", "100-149", "150-197", "198", "199-300", "301+")
parents <- parents |>
  mutate(size_bin = cut(parent_total_units, c(50, 99, 100, 150, 198, 199, 301, Inf),
                        labels = size_bins, right = FALSE))
stopifnot(!anyNA(parents$size_bin))

# Scale the historical distribution to the observed number of post parents.
# Fractional historical counts are weighted equivalents, not additional filings.
historical <- parents |> filter(sample == "historical") |>
  group_by(size_bin, .drop = FALSE) |>
  summarise(historical_raw_parents = n(),
            historical_parents = n_post * sum(weight),
            historical_units = n_post * sum(weight * parent_total_units),
            .groups = "drop") |>
  mutate(historical_mean_units = historical_units / na_if(historical_parents, 0))
post <- parents |> filter(sample == "post_policy") |>
  group_by(size_bin, .drop = FALSE) |>
  summarise(post_parents = n(), post_units = sum(parent_total_units), .groups = "drop") |>
  mutate(post_mean_units = post_units / na_if(post_parents, 0))

gap <- historical |> left_join(post, by = "size_bin", relationship = "one-to-one") |>
  mutate(parent_difference = historical_parents - post_parents,
         unit_gap = historical_units - post_units)
total_gap <- sum(gap$unit_gap)
direct_gap <- n_post * sum(with(filter(parents, sample == "historical"), weight * parent_total_units)) -
  sum(parents$parent_total_units[parents$sample == "post_policy"])
stopifnot(abs(sum(gap$parent_difference)) < 1e-8,
          sum(gap$historical_raw_parents) == sum(parents$sample == "historical"),
          sum(gap$post_parents) == n_post, abs(total_gap - direct_gap) < 1e-8)
SaveData(gap, "size_bin", "../output/unit_gap_by_size.csv")

gap_plot <- ggplot(gap, aes(unit_gap, factor(size_bin, levels = rev(size_bins)))) +
  geom_vline(xintercept = 0, color = "#777777", linewidth = .4) +
  geom_col(aes(fill = unit_gap > 0), width = .65, show.legend = FALSE) +
  geom_text(aes(label = paste0(if_else(unit_gap > 0, "+", ""),
                              scales::comma(unit_gap, accuracy = 1)),
                hjust = if_else(unit_gap > 0, -.12, 1.12)), size = 4) +
  scale_fill_manual(values = c("FALSE" = "#19638D", "TRUE" = "#C06B38")) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = .18)) +
  labs(title = paste0("Where the ", scales::comma(total_gap, accuracy = 1), "-unit gap sits"),
       subtitle = paste0("Weighted 2019-2022 benchmark minus observed 2025-2026; ",
                         n_post, " parents in each distribution"),
       x = "Difference in total proposed units", y = "Parent units",
       caption = paste("Left: more units in the observed post period. Right: more in the historical benchmark.",
                       "Each period uses its own observed size bins; bars do not track individual project changes.",
                       "Post period: January 2025 through July 8, 2026. Exact units retained above 300.", sep = "\n")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        plot.title = element_text(face = "bold", size = 17),
        plot.caption = element_text(hjust = 0, lineheight = 1.2),
        plot.margin = margin(12, 18, 12, 12))
ggsave("../output/unit_gap_by_size.png", gap_plot, width = 11, height = 6.5, dpi = 160, bg = "white")
ggsave("../output/pdf/unit_gap_by_size.pdf", gap_plot, width = 11, height = 6.5, device = "pdf")

print(gap, n = Inf, width = Inf)
cat("\nTotal unit gap:", total_gap, "\n")

# Inspect large organizations directly. The pilot already checks these vectors
# against additive constituent filings; below-100 flags describe its unit rule.
three_plus <- parents |> filter(sample == "post_policy", n_components >= 3) |>
  select(parent_id, borough, component_addresses, cohort_date, parent_total_units,
         n_components, sorted_component_vector, splitting_verification_status,
         right_window_observed) |>
  arrange(parent_total_units, parent_id)
component_units <- lapply(strsplit(three_plus$sorted_component_vector, "+", fixed = TRUE), as.integer)
stopifnot(all(lengths(component_units) == three_plus$n_components),
          all(vapply(component_units, sum, integer(1)) == three_plus$parent_total_units))
three_plus$n_constituents_at_99 <- vapply(component_units, function(n) sum(n == 99), integer(1))
three_plus$n_constituents_100plus <- vapply(component_units, function(n) sum(n >= 100), integer(1))
three_plus$all_constituents_below_100 <- three_plus$n_constituents_100plus == 0L
SaveData(three_plus, "parent_id", "../output/post_three_plus_parents.csv")
print(three_plus, n = Inf, width = Inf)

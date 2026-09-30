# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

# The share of A/B parents of at least 50 units with more than one building,
# by year of first filing, 2014-2022 and 2025-2026. Recent parents can still
# add buildings, so a second series counts, in every year, only buildings
# filed within 180 days of the first filing, and keeps recent parents observed
# for at least 180 days.
horizon_days <- 180L
parents <- read_parquet("../input/extended_parent_opportunity_panel.parquet") |> filter(included_ab)
constituents <- read_parquet("../input/extended_constituent_filing_panel.parquet") |>
  filter(parent_id %in% parents$parent_id) |>
  mutate(days_after_first_filing = as.integer(as.Date(date_filed) - as.Date(cohort_date)))
stopifnot(!anyDuplicated(parents[c("sample", "parent_id")]), !anyDuplicated(constituents[c("sample", "root_job_id")]),
  !anyNA(constituents$days_after_first_filing), all(constituents$days_after_first_filing >= 0))

within_horizon <- constituents |>
  filter(days_after_first_filing <= horizon_days) |>
  group_by(sample, parent_id) |>
  summarise(units = sum(constituent_units), buildings = n(), .groups = "drop") |>
  inner_join(parents |> select(sample, parent_id, cohort_year, observed_followup_days),
    by = c("sample", "parent_id"), relationship = "one-to-one") |>
  filter(sample == "historical" | observed_followup_days >= horizon_days)
measures <- c("All linked filings", paste("Buildings filed within", horizon_days, "days"))
data <- bind_rows(
  parents |> transmute(measure = measures[1], sample, cohort_year, units = parent_total_units, buildings = n_components),
  within_horizon |> transmute(measure = measures[2], sample, cohort_year, units, buildings)
) |>
  filter(units >= 50) |>
  mutate(measure = factor(measure, levels = measures))

# Shares with exact binomial intervals; a year enters only with at least 20
# parents.
by_year <- data |>
  group_by(measure, sample, cohort_year) |>
  summarise(parents = n(), multi = sum(buildings > 1), .groups = "drop") |>
  filter(parents >= 20L) |>
  rowwise() |>
  mutate(share = multi / parents, lower = binom.test(multi, parents)$conf.int[1],
    upper = binom.test(multi, parents)$conf.int[2]) |>
  ungroup()

# The pooled increase over 2019-2022, the main comparison period.
pooled <- data |>
  filter(measure == measures[1], sample == "post_policy" | cohort_year >= 2019L) |>
  group_by(sample) |>
  summarise(parents = n(), multi = sum(buildings > 1), .groups = "drop") |>
  arrange(desc(sample))
stopifnot(identical(pooled$sample, c("post_policy", "historical")))
test <- prop.test(pooled$multi, pooled$parents)
pre_share <- pooled$multi[2] / pooled$parents[2]

figure <- ggplot(by_year, aes(cohort_year, share, color = measure, shape = measure)) +
  annotate("rect", xmin = 2022.5, xmax = 2024.5, ymin = -Inf, ymax = Inf, fill = "grey93") +
  annotate("text", x = 2023.5, y = 0.02, label = "Not in the\ncomparison", size = 3.2, color = "grey45") +
  geom_hline(yintercept = pre_share, color = "grey55", linetype = "dashed", linewidth = 0.45) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.18, linewidth = 0.5,
    position = position_dodge(width = 0.45)) +
  geom_point(size = 2.4, fill = "white", position = position_dodge(width = 0.45)) +
  scale_color_manual(values = setNames(c("#E45756", "#4C78A8"), measures)) +
  scale_shape_manual(values = setNames(c(16, 21), measures)) +
  scale_x_continuous(breaks = c(2014:2022, 2025, 2026)) +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Share of parents with more than one building, by year of first filing",
    subtitle = paste0("2025-July 8, 2026: ", percent(pooled$multi[1] / pooled$parents[1], 0.1), " of ",
      pooled$parents[1], " parents, against ", percent(pre_share, 0.1), " of ", pooled$parents[2],
      " in 2019-2022 (dashed); difference ", number(100 * (pooled$multi[1] / pooled$parents[1] - pre_share), 0.1),
      " points, p = ", format.pval(test$p.value, digits = 2), "."),
    x = "Year of first filing", y = "Parents with more than one building", color = NULL, shape = NULL,
    caption = paste0("A/B rental parents of at least 50 units; 95 percent exact binomial intervals; years with at least ",
      "20 parents. Historical parents have a full 365-day linkage window;\nrecent parents can still add buildings. ",
      "The ", horizon_days, "-day series keeps recent parents observed for at least ", horizon_days, " days.")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank(), plot.caption = element_text(size = 9))

ggsave("../output/pdf/splitting_by_year.pdf", figure, width = 11, height = 6.1, bg = "white")

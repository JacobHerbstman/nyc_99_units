# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_scale_shape_splitting/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible)
stopifnot(!anyDuplicated(parents$parent_id),
          !anyNA(parents[c("cohort_year", "n_components", "number_unique_lots",
                          "right_window_observed")]))

# Each parent counts once, in the year of its original first filing.
annual <- parents |>
  group_by(sample, cohort_year) |>
  summarise(
    parents = n(),
    multiple_constituent_parents = sum(n_components > 1L),
    multi_lot_parents = sum(number_unique_lots > 1L),
    full_followup_parents = sum(right_window_observed),
    .groups = "drop"
  ) |>
  mutate(
    multiple_constituent_share = multiple_constituent_parents / parents,
    multi_lot_share = multi_lot_parents / parents,
    full_followup_share = full_followup_parents / parents
  ) |>
  arrange(cohort_year)
stopifnot(sum(annual$parents) == nrow(parents), !anyDuplicated(annual$cohort_year))
SaveData(annual, "cohort_year", "../output/annual_split_shares.csv")

plot_data <- annual |>
  select(sample, cohort_year, multiple_constituent_share, multi_lot_share) |>
  pivot_longer(ends_with("share"), names_to = "measure", values_to = "share") |>
  mutate(measure = factor(measure,
    levels = c("multiple_constituent_share", "multi_lot_share"),
    labels = c("Multiple constituent filings", "Multiple archival tax lots")))

figure <- ggplot(plot_data, aes(cohort_year, share, color = measure,
                                linetype = measure,
                                group = interaction(sample, measure))) +
  annotate("rect", xmin = 2022.5, xmax = 2024.5, ymin = -Inf, ymax = Inf,
           fill = "grey95") +
  annotate("text", x = 2023.5, y = 0.155,
           label = "2023-2024\noutside comparison\nsample", color = "grey45", size = 3.5) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.7) +
  geom_text(aes(label = sprintf("%.1f%%", 100 * share),
                vjust = if_else(measure == "Multiple constituent filings", -0.95, 1.65),
                hjust = if_else(cohort_year == 2026, -0.15, 0.5)),
            size = 3.5, show.legend = FALSE) +
  scale_color_manual(values = c("#24689B", "#BF6E25")) +
  scale_linetype_manual(values = c("solid", "dashed")) +
  scale_x_continuous(breaks = 2019:2026, expand = expansion(mult = c(0.04, 0.09)),
    labels = c("2019", "2020", "2021", "2022", "2023", "2024", "2025", "2026*")) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                     breaks = seq(0, 0.25, 0.05), limits = c(0, 0.25),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Parents with multiple filings or tax lots, by filing year",
    subtitle = "Eligible rental parents with 50+ units; unweighted annual shares",
    x = "Year of the parent's first filing", y = "Share of parents", color = NULL, linetype = NULL,
    caption = paste(
      paste0("Parent counts: ", paste(paste0(annual$cohort_year, ": ", annual$parents),
                                      collapse = "; "), "."),
      "*2026 through July 8. Recent parents have shorter follow-up for finding companion filings.",
      "Tax-lot counts describe matched archival parcels; they do not date legal subdivision events.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.caption = element_text(hjust = 0, size = 8.5),
        plot.margin = margin(12, 15, 10, 12))

ggsave("../output/pdf/annual_split_shares.pdf", figure, width = 9, height = 5.5)
ggsave("../output/annual_split_shares.png", figure, width = 9, height = 5.5,
       dpi = 180, bg = "white")

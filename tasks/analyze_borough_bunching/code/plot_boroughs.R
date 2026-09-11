# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_borough_bunching/code")
# measure <- "filings"
suppressPackageStartupMessages({library(arrow); library(dplyr); library(readr); library(tidyr); library(ggplot2)})
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  measure <- args[1]
}
stopifnot(measure %in% c("filings", "parents"))
filings <- read_parquet("../output/geographic_filings.parquet")
counts <- read_csv("../output/borough_summary.csv", show_col_types = FALSE) |>
  filter(.data$measure == .env$measure)
if (measure == "filings") {
  observations <- filings |> transmute(sample, borough_name, units = constituent_units)
} else {
  observations <- filings |> distinct(sample, parent_id, borough_name, parent_total_units) |>
    transmute(sample, borough_name, units = parent_total_units)
}
distribution <- observations |> filter(units >= 50) |>
  count(borough_name, sample, units) |>
  complete(borough_name, sample, units = 50:300, fill = list(n = 0L)) |>
  left_join(counts, by = c("borough_name", "sample"), relationship = "many-to-one") |>
  mutate(share = n / n_50_plus,
         period = factor(sample, levels = c("historical", "post_policy"),
                         labels = c("Pre: 2019-2022", "Post: Jan 2025-Jul 8, 2026")))
stopifnot(all(abs((distribution |> group_by(borough_name, sample) |>
                    summarise(total = sum(share), .groups = "drop"))$total - 1) < 1e-10))
labels <- distribution |> distinct(borough_name, period, n_50_plus, n_99, share_99) |>
  mutate(label = sprintf("N = %d\nAt 99: %d (%.1f%%)", n_50_plus, n_99, 100 * share_99))
figure <- ggplot(filter(distribution, units <= 300), aes(units, share, fill = period)) +
  geom_vline(xintercept = c(99, 198), color = "grey60", linetype = "dashed", linewidth = 0.3) +
  geom_col(width = 1) +
  geom_text(data = labels, aes(x = 292, y = Inf, label = label),
            inherit.aes = FALSE, hjust = 1, vjust = 1.3, size = 3.1) +
  facet_grid(borough_name ~ period, scales = "free_y") +
  scale_fill_manual(values = c("#4979A5", "#D6604D")) +
  scale_x_continuous(breaks = c(50, 99, 150, 198, 250, 300), limits = c(49, 301)) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1), expand = expansion(mult = c(0, .25))) +
  labs(title = paste("Proposed", ifelse(measure == "filings", "filing sizes", "parent totals"), "by borough"),
       subtitle = "Share of each borough-period's 50+ observations; one-unit bins",
       x = ifelse(measure == "filings", "Units in constituent filing", "Total units in linked parent"),
       y = "Share of 50+ observations",
       caption = paste0("A/B rental-opportunity sample. Denominators include sizes above 300. Dashed lines: 99 and 198.\n",
                        "Pre and post share a vertical scale within each borough; scales differ across boroughs. Small samples are unstable.\n",
                        ifelse(measure == "filings", "A 99+99 parent contributes two filings at 99.", "A 99+99 parent contributes one parent at 198."),
                        " Unadjusted comparisons; post linkage windows remain incomplete.")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none", panel.grid.minor = element_blank(),
        strip.text.y = element_text(angle = 0), plot.caption = element_text(hjust = 0, size = 8.5),
        panel.spacing = grid::unit(.7, "lines"))
ggsave(paste0("../output/borough_", measure, ".pdf"), figure, width = 11, height = 10.5)

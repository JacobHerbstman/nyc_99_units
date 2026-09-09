# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(readr); library(dplyr); library(ggplot2)})
data <- read_csv("../output/acs_construction_earnings.csv", show_col_types = FALSE) |>
  filter(geography == "tract") |> count(universe, borough, precision) |>
  group_by(universe, borough) |> mutate(share = n / sum(n), total = sum(n)) |> ungroup() |>
  mutate(borough = factor(borough, levels = rev(c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island"))),
         precision = factor(precision, levels = c("MOE at most 50%", "MOE exceeds 50%", "Bounded median", "Unavailable")))
stopifnot(!anyNA(data$precision))
figure <- ggplot(data, aes(share, borough, fill = precision)) +
  geom_col(width = .65, position = position_stack(reverse = TRUE)) +
  facet_wrap(~universe, nrow = 1) +
  scale_fill_manual(values = c("#397A90", "#DE9D58", "#9B73A0", "#D6D6D6"), drop = FALSE) +
  scale_x_continuous(labels = scales::label_percent(), expand = expansion(mult = c(0, .01))) +
  labs(title = "Tract construction earnings are often unavailable or imprecise",
       subtitle = "Share of all returned census tracts in each borough; 2019-2023 ACS",
       x = "Share of tracts", y = NULL, fill = NULL,
       caption = "Categories compare the 90% margin of error with the tract median. The 50% cutoff is descriptive, not a Census rule.\nBounded medians are reported only above/below a limit. Unavailable does not mean zero earnings.\nThe denominator includes tracts without an estimable construction-worker median. Source: Census ACS B24031 and B24041.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", panel.spacing = grid::unit(1.5, "lines"), panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 9), plot.margin = margin(12, 12, 12, 12))
ggsave("../output/tract_precision.pdf", figure, width = 11, height = 6)

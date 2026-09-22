# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(readr); library(dplyr); library(ggplot2)})
data <- read_csv("../output/acs_construction_earnings.csv", show_col_types = FALSE) |>
  filter(geography == "county") |>
  mutate(borough = factor(borough, levels = rev(c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island"))))
figure <- ggplot(data, aes(earnings, borough)) +
  geom_errorbar(aes(xmin = ci90_lower, xmax = ci90_upper), orientation = "y", width = .15, color = "#477FA4") +
  geom_point(size = 3, color = "#245D82") +
  geom_text(aes(label = scales::dollar(earnings, accuracy = 1)), nudge_y = .25, size = 3.4) +
  facet_wrap(~universe, nrow = 1) +
  scale_x_continuous(labels = scales::label_dollar(scale = .001, suffix = "k"), limits = c(30000, 105000)) +
  labs(title = "Construction earnings are lower among Bronx and Brooklyn residents",
       subtitle = "2019-2023 ACS five-year estimates; medians and 90% margins of error",
       x = "Median annual earnings (2023 dollars)", y = NULL,
       caption = "Published county estimates for employed residents age 16+ in the construction industry.\nIncludes all construction-industry occupations and self-employment earnings. Residence is not job-site location.\nAnnual earnings are not hourly wage rates or prevailing wages. Source: Census ACS B24031 and B24041.") +
  theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 9), plot.margin = margin(12, 12, 12, 12))
ggsave("../output/construction_earnings.pdf", figure, width = 11, height = 6)

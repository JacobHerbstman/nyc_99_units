# setwd("tasks/audits/audit_qcew_construction_wages/code")
library(readr)
library(dplyr)
library(ggplot2)
pay <- read_csv("../output/borough_construction_pay.csv", show_col_types = FALSE)
manhattan <- pay |> filter(borough == "Manhattan") |> select(year, industry_code, manhattan_pay = annual_avg_wkly_wage)
stopifnot(!anyDuplicated(manhattan[c("year", "industry_code")]))
pay <- pay |> left_join(manhattan, by = c("year", "industry_code"), relationship = "many-to-one") |>
  mutate(relative_pay = annual_avg_wkly_wage / manhattan_pay,
         industry = factor(industry, levels = c("All construction", "Building construction", "Residential building", "Heavy/civil engineering", "Specialty trades")))
colors <- c(Bronx = "#0072B2", Brooklyn = "#D55E00", Manhattan = "#222222", Queens = "#009E73", `Staten Island` = "#CC79A7")
pdf("../output/borough_construction_pay.pdf", width = 11, height = 7.5)
for (measure in c("annual_avg_wkly_wage", "relative_pay")) {
  p <- ggplot(pay, aes(year, .data[[measure]], color = borough)) + geom_line(linewidth = 0.8) + geom_point(size = 1.7) +
    facet_wrap(~industry, ncol = 3) + scale_color_manual(values = colors) + scale_x_continuous(breaks = 2019:2023) +
    theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank()) +
    labs(x = NULL, color = NULL, y = if (measure == "relative_pay") "Ratio to Manhattan" else "Average weekly pay (nominal dollars)",
         title = if (measure == "relative_pay") "Construction pay relative to Manhattan" else "Construction payroll by borough, 2019-2023",
         subtitle = "Private establishments; all occupations within each industry",
         caption = "Source: BLS QCEW annual area files. Categories overlap. Employer location may differ from construction site.\nWeekly pay reflects hours and workforce composition; these are not hourly wage rates.")
  if (measure == "relative_pay") p <- p + geom_hline(yintercept = 1, linetype = "dashed", color = "grey60")
  print(p)
}
dev.off()

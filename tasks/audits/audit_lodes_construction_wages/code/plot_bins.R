# setwd("tasks/audits/audit_lodes_construction_wages/code")
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
d <- read_csv("../output/district_construction_bins.csv", show_col_types = FALSE) |> filter(year == 0)
pdf("../output/district_earnings_bins.pdf", width = 10, height = 7)
for (borough_name in c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island")) {
  bars <- d |> filter(borough == borough_name) |> mutate(label = paste0("CD ", boro_cd %% 100, "  (", scales::comma(total), ")"), label = factor(label, levels = rev(label))) |>
    pivot_longer(c(share_SE01, share_SE02, share_SE03), names_to = "bin", values_to = "share")
  print(ggplot(bars, aes(share, label, fill = bin)) + geom_col(position = position_stack(reverse = TRUE)) +
    scale_fill_manual(values = c(share_SE01 = "#D9E5E8", share_SE02 = "#67A9CF", share_SE03 = "#2166AC"), labels = c("At most $1,250", "$1,251-$3,333", "Over $3,333")) +
    scale_x_continuous(labels = scales::label_percent(), limits = c(0,1)) + theme_minimal(base_size = 12) +
    labs(title = paste(borough_name, "construction workplace earnings"), subtitle = "2019-2023 pooled private-sector job counts", x = "Share of construction jobs", y = NULL, fill = "Monthly earnings", caption = "Parentheses show pooled job-years, not unique workers. Workplace location may be an employer office.\nSource: Census LODES. Nominal earnings bins; not hourly wage rates.") +
    theme(legend.position = "bottom", panel.grid.major.y = element_blank()))
}
dev.off()

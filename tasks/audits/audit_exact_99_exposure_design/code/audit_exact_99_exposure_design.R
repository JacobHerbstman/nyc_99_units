# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_exact_99_exposure_design/code")
# post_year <- 2025L
# bunch_units <- 99L
# exposure_cut_1 <- 0.25
# exposure_cut_2 <- 0.50
# exposure_cut_3 <- 0.75

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop("Expected year, bunching count, and three exposure cutoffs.")
}

post_year <- as.integer(args[1])
bunch_units <- as.integer(args[2])
exposure_cut_1 <- as.numeric(args[3])
exposure_cut_2 <- as.numeric(args[4])
exposure_cut_3 <- as.numeric(args[5])

if (
  any(is.na(c(
    post_year, bunch_units, exposure_cut_1, exposure_cut_2, exposure_cut_3
  ))) ||
    post_year < 2010L || bunch_units < 1L ||
    exposure_cut_1 <= 0 ||
    exposure_cut_2 <= exposure_cut_1 ||
    exposure_cut_3 <= exposure_cut_2 || exposure_cut_3 >= 1
) {
  stop("Exposure-design arguments are not internally consistent.")
}

scores <- read_parquet(
  "../input/no_notch_post_policy_exposure_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    model_role == "preferred_full_distribution",
    filing_year == post_year
  )

developer_panel <- read_parquet(
  "../input/developer_response_application_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(scores) == 0L ||
    anyDuplicated(scores$job_number) ||
    anyDuplicated(developer_panel$job_number)
) {
  stop("Exposure-design inputs failed identifier QC.")
}

same_bbl_exact_99 <- scores |>
  filter(observed_units == bunch_units, !is.na(bbl), bbl != "") |>
  count(bbl, name = "same_bbl_scoreable_exact_99_count")

exact_99_design <- scores |>
  filter(observed_units == bunch_units) |>
  left_join(
    developer_panel |>
      select(
        job_number, total_construction_floor_area,
        gross_construction_square_feet_per_unit, proposed_stories,
        proposed_height, owner_business_name, applicant_business_name,
        dob_initial_match, units_agree, bbl_agree, bin_agree
      ),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  left_join(
    same_bbl_exact_99,
    by = "bbl",
    relationship = "many-to-one"
  ) |>
  mutate(
    same_bbl_scoreable_exact_99_count = coalesce(
      same_bbl_scoreable_exact_99_count, 0L
    ),
    repeated_99_same_bbl = same_bbl_scoreable_exact_99_count >= 2L,
    exposure_group = cut(
      probability_at_least_100,
      breaks = c(
        -Inf, exposure_cut_1, exposure_cut_2, exposure_cut_3, Inf
      ),
      labels = c(
        paste0("Below ", exposure_cut_1),
        paste0(exposure_cut_1, " to below ", exposure_cut_2),
        paste0(exposure_cut_2, " to below ", exposure_cut_3),
        paste0(exposure_cut_3, " or above")
      ),
      right = FALSE
    )
  ) |>
  arrange(desc(probability_at_least_100), job_number)

group_summary <- exact_99_design |>
  group_by(exposure_group) |>
  summarise(
    exact_99_filings = n(),
    dob_area_rows = sum(
      !is.na(total_construction_floor_area) &
        total_construction_floor_area > 0
    ),
    median_probability_at_least_100 = median(probability_at_least_100),
    median_predicted_no_notch_units = median(predicted_median_units),
    median_total_construction_floor_area = median(
      total_construction_floor_area,
      na.rm = TRUE
    ),
    median_gross_construction_square_feet_per_unit = median(
      gross_construction_square_feet_per_unit,
      na.rm = TRUE
    ),
    median_proposed_stories = median(proposed_stories, na.rm = TRUE),
    median_proposed_height = median(proposed_height, na.rm = TRUE),
    repeated_99_same_bbl_filings = sum(repeated_99_same_bbl),
    .groups = "drop"
  ) |>
  mutate(summary_group = as.character(exposure_group)) |>
  select(summary_group, everything(), -exposure_group)

all_summary <- exact_99_design |>
  summarise(
    summary_group = "All scored exact-99 filings",
    exact_99_filings = n(),
    dob_area_rows = sum(
      !is.na(total_construction_floor_area) &
        total_construction_floor_area > 0
    ),
    median_probability_at_least_100 = median(probability_at_least_100),
    median_predicted_no_notch_units = median(predicted_median_units),
    median_total_construction_floor_area = median(
      total_construction_floor_area,
      na.rm = TRUE
    ),
    median_gross_construction_square_feet_per_unit = median(
      gross_construction_square_feet_per_unit,
      na.rm = TRUE
    ),
    median_proposed_stories = median(proposed_stories, na.rm = TRUE),
    median_proposed_height = median(proposed_height, na.rm = TRUE),
    repeated_99_same_bbl_filings = sum(repeated_99_same_bbl)
  )

design_summary <- bind_rows(all_summary, group_summary)

correlation_rows <- exact_99_design |>
  select(
    probability_at_least_100,
    total_construction_floor_area,
    gross_construction_square_feet_per_unit,
    proposed_stories,
    proposed_height
  ) |>
  pivot_longer(
    cols = -probability_at_least_100,
    names_to = "design_measure",
    values_to = "design_value"
  ) |>
  filter(!is.na(design_value), is.finite(design_value)) |>
  group_by(design_measure) |>
  summarise(
    rows = n(),
    spearman_correlation_with_exposure = cor(
      probability_at_least_100,
      design_value,
      method = "spearman"
    ),
    .groups = "drop"
  )

plot_rows <- exact_99_design |>
  select(
    job_number, probability_at_least_100, exposure_group,
    repeated_99_same_bbl, total_construction_floor_area,
    gross_construction_square_feet_per_unit
  ) |>
  pivot_longer(
    cols = c(
      total_construction_floor_area,
      gross_construction_square_feet_per_unit
    ),
    names_to = "design_measure",
    values_to = "design_value"
  ) |>
  filter(!is.na(design_value), is.finite(design_value), design_value > 0) |>
  mutate(
    design_measure = recode(
      design_measure,
      total_construction_floor_area = "Total construction floor area",
      gross_construction_square_feet_per_unit =
        "Gross construction square feet per unit"
    ),
    repeated_label = if_else(
      repeated_99_same_bbl,
      "At least two scored 99s on BBL",
      "One scored 99 on BBL"
    )
  )

plot_medians <- plot_rows |>
  group_by(design_measure, exposure_group) |>
  summarise(
    probability_at_least_100 = median(probability_at_least_100),
    design_value = median(design_value),
    .groups = "drop"
  )

design_plot <- ggplot(
  plot_rows,
  aes(x = probability_at_least_100, y = design_value)
) +
  geom_point(
    aes(shape = repeated_label),
    color = "#6B6B6B",
    alpha = 0.7,
    size = 2.1
  ) +
  geom_point(
    data = plot_medians,
    color = "#D95F02",
    shape = 18,
    size = 3.4
  ) +
  facet_wrap(vars(design_measure), ncol = 1L, scales = "free_y") +
  scale_x_continuous(
    limits = c(0, 1),
    labels = percent_format(accuracy = 1),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  scale_shape_manual(values = c(
    "One scored 99 on BBL" = 16,
    "At least two scored 99s on BBL" = 17
  )) +
  labs(
    title = "Higher no-notch exposure coincides with larger gross building envelopes",
    subtitle = paste0(
      "Orange diamonds are exposure-group medians; gray points are individual ",
      "scoreable 2025 filings."
    ),
    x = "Predicted probability of at least 100 units without the notch",
    y = NULL,
    shape = NULL,
    caption = paste0(
      "DOB total construction area includes common, mechanical, parking, and ",
      "nonresidential space. It is not apartment size or residential floor area."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "#F2F2F2", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(exact_99_design) != sum(scores$observed_units == bunch_units) ||
    anyDuplicated(exact_99_design$job_number) ||
    nrow(design_summary) != 5L ||
    any(design_summary$dob_area_rows == 0L) ||
    nrow(correlation_rows) != 4L
) {
  stop("Exposure-design outputs failed final QC.")
}

write_csv_if_changed(
  exact_99_design,
  "../output/exact_99_exposure_design_ledger.csv"
)
write_csv_if_changed(
  design_summary,
  "../output/exact_99_exposure_design_summary.csv"
)
write_csv_if_changed(
  correlation_rows,
  "../output/exact_99_exposure_design_correlations.csv"
)
ggsave(
  "../output/exact_99_exposure_design.pdf",
  design_plot,
  width = 9,
  height = 8,
  device = "pdf"
)
ggsave(
  "../output/exact_99_exposure_design.png",
  design_plot,
  width = 9,
  height = 8,
  dpi = 180,
  bg = "white"
)

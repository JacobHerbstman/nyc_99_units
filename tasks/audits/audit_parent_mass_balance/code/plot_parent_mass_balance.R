# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_mass_balance/code")
# training_start_year <- 2019L
# training_end_year <- 2023L
# post_year <- 2025L
# threshold_units <- 100L
# local_lower_units <- 50L
# local_upper_units <- 150L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected training years, post year, policy threshold, and local range."
  )
}

training_start_year <- as.integer(args[1])
training_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
threshold_units <- as.integer(args[4])
local_lower_units <- as.integer(args[5])
local_upper_units <- as.integer(args[6])

if (
  any(is.na(c(
    training_start_year, training_end_year, post_year,
    threshold_units, local_lower_units, local_upper_units
  ))) ||
    training_start_year >= training_end_year ||
    post_year <= training_end_year ||
    local_lower_units >= threshold_units ||
    local_upper_units < threshold_units
) {
  stop("Parent mass-balance plot arguments are not internally consistent.")
}

mass_balance_by_bin <- read_csv(
  "../output/parent_mass_balance_by_unit_bin.csv",
  show_col_types = FALSE
)
annual_parent_local_mass <- read_csv(
  "../output/annual_parent_local_mass.csv",
  show_col_types = FALSE
)
preferred_exact_99_broad_link_sensitivity <- read_csv(
  "../output/preferred_exact_99_broad_link_sensitivity.csv",
  show_col_types = FALSE
)
parent_composition_comparison <- read_csv(
  "../output/parent_composition_comparison.csv",
  show_col_types = FALSE
)
parent_covariate_support <- read_csv(
  "../output/parent_covariate_support.csv",
  show_col_types = FALSE
)
parent_prediction_support_scores <- read_parquet(
  "../output/parent_prediction_support_scores.parquet"
) |>
  as.data.frame()
parent_placebo_conservation_gaps <- read_csv(
  "../output/parent_placebo_conservation_gaps.csv",
  show_col_types = FALSE
)

if (
    nrow(mass_balance_by_bin) == 0L ||
    nrow(annual_parent_local_mass) == 0L ||
    nrow(preferred_exact_99_broad_link_sensitivity) == 0L ||
    nrow(parent_composition_comparison) == 0L ||
    nrow(parent_covariate_support) == 0L ||
    nrow(parent_prediction_support_scores) == 0L ||
    nrow(parent_placebo_conservation_gaps) == 0L
) {
  stop("A parent mass-balance plotting input is empty.")
}

preferred_exact_99_total <-
  preferred_exact_99_broad_link_sensitivity$preferred_exact_99_parents[
    preferred_exact_99_broad_link_sensitivity$broad_link_class ==
      "all_preferred_exact_99"
  ]
preferred_exact_99_unlinked <-
  preferred_exact_99_broad_link_sensitivity$preferred_exact_99_parents[
    preferred_exact_99_broad_link_sensitivity$broad_link_class ==
      "unlinked_single_99"
  ]

if (
  length(preferred_exact_99_total) != 1L ||
    length(preferred_exact_99_unlinked) != 1L
) {
  stop("Broad-link sensitivity totals are not unique.")
}

unit_bin_levels <- mass_balance_by_bin$unit_bin
policy_bin <- paste0(threshold_units - 1L, "-", threshold_units - 1L)

bin_balance_plot <- mass_balance_by_bin |>
  mutate(
    unit_bin = if_else(
      unit_bin == policy_bin,
      paste0("Exact ", threshold_units - 1L),
      unit_bin
    ),
    unit_bin = factor(
      unit_bin,
      levels = if_else(
        unit_bin_levels == policy_bin,
        paste0("Exact ", threshold_units - 1L),
        unit_bin_levels
      )
    ),
    is_policy_bin = unit_bin == paste0("Exact ", threshold_units - 1L)
  ) |>
  ggplot(aes(
    x = unit_bin,
    y = residual_observed_minus_expected,
    fill = is_policy_bin
  )) +
  geom_hline(yintercept = 0, color = "grey55", linewidth = 0.4) +
  geom_col(width = 0.72) +
  geom_text(
    aes(
      label = sprintf("%+.1f", residual_observed_minus_expected),
      vjust = if_else(residual_observed_minus_expected >= 0, -0.35, 1.25)
    ),
    size = 3.1
  ) +
  scale_fill_manual(values = c(`FALSE` = "grey55", `TRUE` = "#E6550D")) +
  labs(
    title = "The exact-99 excess is only part of a broader distribution shift",
    subtitle = paste0(
      "Observed minus no-notch expected parents in ", post_year,
      "; positive bars contain more parents than predicted"
    ),
    x = "Parent dwelling units",
    y = "Observed minus expected parents"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title.position = "plot"
  )

local_region_levels <- c(
  paste0(local_lower_units, "-", threshold_units - 2L),
  paste0("Exact ", threshold_units - 1L),
  paste0(threshold_units, "-", local_upper_units)
)

annual_local_plot <- annual_parent_local_mass |>
  mutate(
    local_region = factor(local_region, levels = local_region_levels)
  ) |>
  ggplot(aes(
    x = factor(display_year),
    y = parents,
    fill = local_region
  )) +
  geom_col(width = 0.72) +
  geom_text(
    aes(label = if_else(parents > 0L, as.character(parents), "")),
    position = position_stack(vjust = 0.5),
    size = 3,
    color = "white"
  ) +
  scale_fill_manual(values = c("#4C78A8", "#E6550D", "#8C510A")) +
  labs(
    title = paste0(
      post_year,
      " has more 50-99 parents and fewer nearby 100-plus parents"
    ),
    subtitle = "Observed enhanced-parent counts by first filing year",
    x = "First filing year",
    y = "Parents",
    fill = "Parent units"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot"
  )

broad_link_plot <- preferred_exact_99_broad_link_sensitivity |>
  filter(broad_link_class != "all_preferred_exact_99") |>
  mutate(
    broad_link_label = recode(
      broad_link_class,
      unlinked_single_99 = "Still unlinked",
      repeated_99_parent = "Repeated-99 broad parent",
      one_99_with_other_jobs = "99 with other jobs",
      dob_source_disagreement_multi_job = "DOB source disagreement",
      unmatched_to_broad_universe = "Unmatched"
    ),
    broad_link_label = reorder(
      broad_link_label,
      preferred_exact_99_parents
    ),
    is_still_unlinked = broad_link_class == "unlinked_single_99"
  ) |>
  ggplot(aes(
    x = preferred_exact_99_parents,
    y = broad_link_label,
    fill = is_still_unlinked
  )) +
  geom_col(width = 0.65) +
  geom_text(
    aes(label = preferred_exact_99_parents),
    hjust = -0.35,
    size = 3.5
  ) +
  scale_fill_manual(values = c(`FALSE` = "#E6550D", `TRUE` = "#1769AA")) +
  scale_x_continuous(
    limits = c(0, max(
      preferred_exact_99_broad_link_sensitivity$preferred_exact_99_parents[
        preferred_exact_99_broad_link_sensitivity$broad_link_class !=
          "all_preferred_exact_99"
      ]
    ) * 1.15)
  ) +
  labs(
    title = paste0(
      "Broader candidate links absorb ",
      preferred_exact_99_total - preferred_exact_99_unlinked,
      " of ", preferred_exact_99_total,
      " preferred exact-99 parents"
    ),
    subtitle = paste0(
      "Sensitivity uses the 365-day universal link graph; the preferred model ",
      "retains the conservative parent definition"
    ),
    x = "Preferred exact-99 parents",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.title.position = "plot"
  )

composition_plot <- parent_composition_comparison |>
  mutate(
    level = recode(
      level,
      existing_residential_units = "Existing residential units",
      mixed_prior_use = "Mixed prior use",
      commercial_industrial = "Commercial or industrial",
      mixed_res_commercial = "Mixed residential-commercial",
      vacant_land = "Vacant land",
      missing_landuse = "Missing land use",
      public_transport_utility = "Public, transport, or utility",
      other_no_res_units = "Other without residential units",
      R1_R5 = "R1-R5",
      MX_slash = "Mixed zoning",
      R8_R10 = "R8-R10",
      M_non_slash = "Manufacturing",
      .default = level
    ),
    level = reorder(level, post_minus_historical_percentage_points),
    variable = recode(
      variable,
      borough = "Borough",
      zone_detail = "Zoning group",
      prior_site_use = "Prior site use"
    )
  ) |>
  ggplot(aes(
    x = post_minus_historical_percentage_points,
    y = level,
    color = post_outside_historical_annual_range
  )) +
  geom_vline(xintercept = 0, color = "grey65", linewidth = 0.4) +
  geom_segment(
    aes(x = 0, xend = post_minus_historical_percentage_points, yend = level),
    linewidth = 0.7
  ) +
  geom_point(size = 2) +
  facet_wrap(vars(variable), scales = "free_y", ncol = 3) +
  scale_color_manual(values = c(`FALSE` = "#1769AA", `TRUE` = "#E6550D")) +
  labs(
    title = paste0(post_year, " differs in borough and zoning composition"),
    subtitle = paste0(
      "Percentage-point difference from pooled ",
      training_start_year, "-", training_end_year,
      "; orange lies outside all historical annual shares"
    ),
    x = paste0(
      post_year,
      " share minus historical share (percentage points)"
    ),
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title.position = "plot"
  )

post_prediction_support <- parent_covariate_support |>
  filter(
    variable == "predicted_log_units",
    post_group == "all_2025_parents"
  )

if (nrow(post_prediction_support) != 1L) {
  stop("Prediction-support summary is not unique for all post parents.")
}

prediction_support_plot <- parent_prediction_support_scores |>
  ggplot(aes(x = predicted_log_units, color = sample)) +
  stat_ecdf(linewidth = 0.9) +
  scale_color_manual(values = c("grey45", "#1769AA")) +
  labs(
    title = paste0(post_year, " predictions remain inside historical support"),
    subtitle = paste0(
      post_prediction_support$post_outside_historical_range,
      " of ", post_prediction_support$post_parents,
      " post-policy predictions lie outside the historical min-max range"
    ),
    x = "Predicted log dwelling units under the no-notch model",
    y = "Cumulative share of parents",
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot"
  )

placebo_gap_plot <- parent_placebo_conservation_gaps |>
  mutate(is_post = sample == "post_policy") |>
  ggplot(aes(
    x = factor(sample_year),
    y = conservation_gap,
    fill = is_post
  )) +
  geom_hline(yintercept = 0, color = "grey55", linewidth = 0.4) +
  geom_col(width = 0.65) +
  geom_text(
    aes(
      label = sprintf("%+.1f", conservation_gap),
      vjust = if_else(conservation_gap >= 0, -0.35, 1.25)
    ),
    size = 3.3
  ) +
  scale_fill_manual(values = c(`FALSE` = "grey55", `TRUE` = "#E6550D")) +
  labs(
    title = "The conservation gap is not unique to the post-policy year",
    subtitle = paste0(
      "Gap equals excess exact-", threshold_units - 1L,
      " mass minus missing ", threshold_units,
      "+ mass; historical years are expanding-window placebos"
    ),
    x = "Scored year",
    y = "Conservation gap (parents)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title.position = "plot"
  )

pdf(
  "../output/parent_mass_balance_audit.pdf",
  width = 10,
  height = 6.5,
  onefile = TRUE
)
print(bin_balance_plot)
print(annual_local_plot)
print(broad_link_plot)
print(composition_plot)
print(prediction_support_plot)
print(placebo_gap_plot)
dev.off()

cat("Wrote parent mass-balance audit figure to ../output\n")

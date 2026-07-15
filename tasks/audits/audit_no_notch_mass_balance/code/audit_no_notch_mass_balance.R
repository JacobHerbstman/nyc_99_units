# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_mass_balance/code")
# universe_min_units <- 6L
# threshold_units <- 100L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2L) {
  stop("Expected two arguments: universe floor and policy threshold.")
}

universe_min_units <- as.integer(args[1])
threshold_units <- as.integer(args[2])
bunch_units <- threshold_units - 1L

if (
  any(is.na(c(universe_min_units, threshold_units))) ||
    universe_min_units < 1L ||
    threshold_units <= universe_min_units
) {
  stop("Mass-balance arguments are not internally consistent.")
}

expected_bunching_mass <- function(frontier, predicted_log_units, sigma) {
  lower_z <- (
    log(threshold_units - 0.5) - predicted_log_units
  ) / sigma
  upper_z <- (log(frontier) - predicted_log_units) / sigma
  floor_z <- (
    log(universe_min_units - 0.5) - predicted_log_units
  ) / sigma
  interval_probability <- pmax(
    pnorm(lower_z, lower.tail = FALSE) -
      pnorm(upper_z, lower.tail = FALSE),
    0
  )
  sum(interval_probability / pnorm(floor_z, lower.tail = FALSE))
}

solve_frontier <- function(target_mass, predicted_log_units, sigma) {
  lower_frontier <- threshold_units - 0.5
  maximum_mass <- expected_bunching_mass(
    Inf, predicted_log_units, sigma
  )

  if (target_mass < 0 || target_mass > maximum_mass) {
    return(NA_real_)
  }

  if (target_mass == 0) {
    return(lower_frontier)
  }

  upper_frontier <- threshold_units * 2

  while (
    expected_bunching_mass(
      upper_frontier, predicted_log_units, sigma
    ) < target_mass
  ) {
    upper_frontier <- upper_frontier * 2
  }

  uniroot(
    function(frontier) {
      expected_bunching_mass(
        frontier, predicted_log_units, sigma
      ) - target_mass
    },
    interval = c(lower_frontier, upper_frontier),
    tol = 1e-8
  )$root
}

scores <- read_parquet(
  "../input/no_notch_post_policy_exposure_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(scores) == 0L ||
    anyDuplicated(scores[c("job_number", "model_role")]) ||
    any(!is.finite(scores$predicted_log_units)) ||
    any(!is.finite(scores$shock_sigma)) ||
    any(scores$shock_sigma <= 0)
) {
  stop("Exposure scores failed mass-balance input QC.")
}

summary_rows <- list()
model_roles <- unique(scores$model_role)

for (model_role_value in model_roles) {
  model_scores <- scores |>
    filter(model_role == model_role_value)
  observed_exact_99 <- sum(model_scores$observed_units == bunch_units)
  expected_exact_99 <- sum(model_scores$probability_exact_99)
  observed_100_plus <- sum(model_scores$observed_units >= threshold_units)
  expected_100_plus <- sum(model_scores$probability_at_least_100)
  excess_exact_99 <- observed_exact_99 - expected_exact_99
  missing_100_plus <- expected_100_plus - observed_100_plus
  frontier_from_exact_99 <- solve_frontier(
    excess_exact_99,
    model_scores$predicted_log_units,
    model_scores$shock_sigma
  )
  frontier_from_missing_100_plus <- solve_frontier(
    missing_100_plus,
    model_scores$predicted_log_units,
    model_scores$shock_sigma
  )

  summary_rows[[length(summary_rows) + 1L]] <- tibble(
    model_role = model_role_value,
    model = unique(model_scores$model),
    scoreable_filings = nrow(model_scores),
    observed_exact_99,
    expected_no_notch_exact_99 = expected_exact_99,
    excess_exact_99,
    observed_100_plus,
    expected_no_notch_100_plus = expected_100_plus,
    missing_100_plus,
    conservation_gap_excess_99_minus_missing_100_plus =
      excess_exact_99 - missing_100_plus,
    frontier_from_exact_99,
    unit_distance_from_99_using_exact_99 = frontier_from_exact_99 - bunch_units,
    normalized_cost_T_over_gamma_using_exact_99 =
      (frontier_from_exact_99 - bunch_units)^2 / 2,
    predicted_100_plus_if_fit_exact_99 =
      expected_100_plus - excess_exact_99,
    actual_minus_predicted_100_plus_if_fit_exact_99 =
      observed_100_plus - (expected_100_plus - excess_exact_99),
    frontier_from_missing_100_plus,
    unit_distance_from_99_using_missing_100_plus =
      frontier_from_missing_100_plus - bunch_units,
    normalized_cost_T_over_gamma_using_missing_100_plus =
      (frontier_from_missing_100_plus - bunch_units)^2 / 2,
    predicted_exact_99_if_fit_missing_100_plus =
      expected_exact_99 + missing_100_plus,
    actual_minus_predicted_exact_99_if_fit_missing_100_plus =
      observed_exact_99 - (expected_exact_99 + missing_100_plus)
  )
}

mass_balance_summary <- bind_rows(summary_rows) |>
  arrange(model_role)

plot_max_frontier <- ceiling(max(
  mass_balance_summary$frontier_from_exact_99,
  mass_balance_summary$frontier_from_missing_100_plus,
  na.rm = TRUE
) + 20)
frontier_grid <- seq(
  threshold_units - 0.5,
  plot_max_frontier,
  length.out = 300L
)
curve_rows <- list()

for (model_role_value in model_roles) {
  model_scores <- scores |>
    filter(model_role == model_role_value)

  curve_rows[[length(curve_rows) + 1L]] <- tibble(
    model_role = model_role_value,
    frontier_units = frontier_grid,
    expected_mass_moved_to_99 = vapply(
      frontier_grid,
      expected_bunching_mass,
      numeric(1),
      predicted_log_units = model_scores$predicted_log_units,
      sigma = model_scores$shock_sigma
    )
  )
}

mass_balance_curve <- bind_rows(curve_rows) |>
  arrange(model_role, frontier_units)

model_labels <- c(
  preferred_full_distribution = "Preferred: floor 6, expanding history",
  required_sample_robustness = "Robustness: floor 11, rolling five years"
)

target_lines <- bind_rows(
  mass_balance_summary |>
    transmute(
      model_role,
      target = "Observed excess at 99",
      target_mass = excess_exact_99
    ),
  mass_balance_summary |>
    transmute(
      model_role,
      target = "Missing mass at 100+",
      target_mass = missing_100_plus
    )
)

mass_balance_plot <- mass_balance_curve |>
  mutate(
    model_label = factor(
      model_labels[model_role],
      levels = unname(model_labels)
    )
  ) |>
  ggplot(aes(x = frontier_units, y = expected_mass_moved_to_99)) +
  geom_line(color = "#1769AA", linewidth = 0.9) +
  geom_hline(
    data = target_lines |>
      mutate(
        model_label = factor(
          model_labels[model_role],
          levels = unname(model_labels)
        )
      ),
    aes(yintercept = target_mass, color = target),
    linewidth = 0.7,
    linetype = "dashed"
  ) +
  facet_wrap(vars(model_label), ncol = 1L) +
  scale_color_manual(values = c(
    "Observed excess at 99" = "#D95F02",
    "Missing mass at 100+" = "#1B9E77"
  )) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
  labs(
    title = "The two mass-balance moments imply different marginal bunchers",
    subtitle = paste0(
      "Blue curves sum no-notch probability from 100 to each candidate frontier; ",
      "dashed lines are observed targets."
    ),
    x = "Marginal latent no-notch unit count",
    y = "Expected filings moved from 100+ to 99",
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "#F2F2F2", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(mass_balance_summary) != length(model_roles) ||
    any(!is.finite(mass_balance_summary$frontier_from_exact_99)) ||
    any(!is.finite(mass_balance_summary$frontier_from_missing_100_plus)) ||
    any(mass_balance_curve$expected_mass_moved_to_99 < 0) ||
    anyDuplicated(mass_balance_curve[c("model_role", "frontier_units")])
) {
  stop("Mass-balance outputs failed final QC.")
}

write_csv_if_changed(
  mass_balance_summary,
  "../output/no_notch_mass_balance_summary.csv"
)
write_csv_if_changed(
  mass_balance_curve,
  "../output/no_notch_mass_balance_curve.csv"
)
ggsave(
  "../output/no_notch_mass_balance_curve.pdf",
  mass_balance_plot,
  width = 9,
  height = 8,
  device = "pdf"
)
ggsave(
  "../output/no_notch_mass_balance_curve.png",
  mass_balance_plot,
  width = 9,
  height = 8,
  dpi = 180,
  bg = "white"
)

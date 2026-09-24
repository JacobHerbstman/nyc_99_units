# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})
source("../../../shared/code/scale_shape_helpers.R")
source("../../../shared/code/pure_notch_model.R")
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible)
analysis <- read_csv("../output/analysis_parents.csv", show_col_types = FALSE)
baseline_grid <- read_csv("../output/parameter_grid.csv", show_col_types = FALSE) |>
  filter(specification == "separate_baseline")
baseline_diagnostics <- read_csv("../output/fit_diagnostics.csv", show_col_types = FALSE)
historical <- filter(parents, sample == "historical") |>
  left_join(select(filter(analysis, sample == "historical"), parent_id, weight),
            by = "parent_id", relationship = "one-to-one")
post <- filter(parents, sample == "post_policy")
stopifnot(!anyNA(historical$weight), nrow(parents) == nrow(analysis),
          !anyDuplicated(parents[c("sample", "parent_id")]))

# First reproduce the current calibration; then add only the multi-lot moment.
current <- calibrate_historical_to_target(historical, post)
current_weight <- current$historical$calibration_weight
stopifnot(max(abs(current_weight / sum(current_weight) - historical$weight)) < 1e-10)
multilot <- calibrate_historical_to_target(historical, post,
  update(calibration_formula, ~ . + multi_lot_indicator))
multilot_weight <- multilot$historical$calibration_weight
w <- multilot_weight / sum(multilot_weight)
weight_comparison <- historical |>
  transmute(parent_id, parent_total_units, n_components, multi_lot_indicator,
            baseline_weight = weight, multilot_weight = w)

x <- historical$parent_total_units
J0 <- historical$n_components
P <- nrow(post)
J_cap <- unique(baseline_grid$J_cap)
stopifnot(length(J_cap) == 1L, all(baseline_grid$lambda == 1), all(baseline_grid$tau == 0))
observed <- notch_joint_shares(post$parent_total_units, post$n_components, rep(1 / P, P))
grid_rows <- list()
for (kappa in sort(unique(baseline_grid$kappa))) {
  choices <- notch_choices(x, kappa, lambda = 1, J_cap = J_cap, assessment = "separate")
  for (sigma in sort(unique(baseline_grid$sigma_org[baseline_grid$kappa == kappa]))) {
    prediction <- notch_predictions(choices, J0, w, sigma)
    shares <- notch_joint_shares(prediction$m, prediction$J, prediction$mass)
    grid_rows[[length(grid_rows) + 1L]] <- tibble(
      kappa = kappa, sigma_org = sigma, objective = sum((shares - observed)^2),
      objective_J1 = sum((shares[1:15] - observed[1:15])^2),
      objective_J2 = sum((shares[16:30] - observed[16:30])^2),
      objective_J3plus = sum((shares[31:45] - observed[31:45])^2),
      mean_units = sum(prediction$mass * prediction$m),
      share_99 = sum(prediction$mass[prediction$m == 99]),
      share_J2 = sum(prediction$mass[prediction$J == 2]),
      share_J3plus = sum(prediction$mass[prediction$J >= 3]),
      share_99x2 = if (kappa == 0) sum(w[historical$sorted_component_vector == "99+99"]) else
        sum(prediction$mass[prediction$m == 198 & prediction$J == 2]),
      counterfactual_units = P * sum(w * x), observed_units = sum(post$parent_total_units),
      predicted_units = P * mean_units, model_difference = counterfactual_units - predicted_units,
      direct_difference = counterfactual_units - observed_units)
  }
}
grid <- bind_rows(grid_rows) |>
  arrange(objective, kappa, sigma_org) |>
  mutate(rank = row_number(), objective_gap = objective - min(objective))
stopifnot(nrow(grid) == nrow(baseline_grid))
best <- slice_head(grid, n = 1)
baseline_best <- filter(baseline_grid, rank == 1)
baseline_prediction <- notch_predictions(
  notch_choices(x, baseline_best$kappa, J_cap = J_cap),
  J0, historical$weight, baseline_best$sigma_org)
baseline_shares <- notch_joint_shares(baseline_prediction$m, baseline_prediction$J, baseline_prediction$mass)
stopifnot(abs(sum((baseline_shares - observed)^2) - baseline_best$objective) < 1e-12)

# This table distinguishes changes in the starting distribution from fitted responses.
comparison <- bind_rows(
  baseline_diagnostics |>
    filter(series %in% c("historical", "post_policy", "separate_baseline")) |>
    select(series, mean_units, share_99, share_J2, share_J3plus, share_99x2),
  tibble(series = "multilot_historical", mean_units = sum(w * x),
         share_99 = sum(w[x == 99]), share_J2 = sum(w[J0 == 2]),
         share_J3plus = sum(w[J0 >= 3]),
         share_99x2 = sum(w[historical$sorted_component_vector == "99+99"])),
  best |> transmute(series = "multilot_fit", mean_units, share_99, share_J2, share_J3plus, share_99x2))
fit_comparison <- bind_rows(
  baseline_best |> transmute(weighting = "baseline", kappa, sigma_org, objective,
    objective_J1 = sum((baseline_shares[1:15] - observed[1:15])^2),
    objective_J2 = sum((baseline_shares[16:30] - observed[16:30])^2),
    objective_J3plus = sum((baseline_shares[31:45] - observed[31:45])^2),
    counterfactual_units, observed_units, predicted_units, model_difference, direct_difference),
  best |> transmute(weighting = "include_multilot", kappa, sigma_org, objective,
    objective_J1, objective_J2, objective_J3plus,
    counterfactual_units, observed_units, predicted_units, model_difference, direct_difference)) |>
  mutate(effective_historical_size = c(1 / sum(historical$weight^2), 1 / sum(w^2)),
         maximum_moment_error = c(current$maximum_moment_error, multilot$maximum_moment_error),
         weighted_multilot_share = c(sum(historical$weight * historical$multi_lot_indicator),
                                    sum(w * historical$multi_lot_indicator)))

SaveData(weight_comparison, "parent_id", "../output/multilot_weight_comparison.csv")
SaveData(grid, c("kappa", "sigma_org"), "../output/multilot_parameter_grid.csv")
SaveData(comparison, "series", "../output/multilot_distribution_comparison.csv")
SaveData(fit_comparison, "weighting", "../output/multilot_fit_comparison.csv")
print(comparison, width = Inf)
print(fit_comparison, width = Inf)

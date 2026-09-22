# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tidyr)
})
source("../../../shared/code/pure_notch_model.R")
source("../../../shared/code/write_data_report.R")

# Current administrative panels and already-estimated site weights. No refitting.
parents <- read_parquet("../input/parent_opportunity_panel.parquet")
filings <- read_parquet("../input/constituent_filing_panel.parquet")
weights <- read_csv("../input/calibration_weights.csv", show_col_types = FALSE)
calibration <- read_csv("../input/calibration_summary.csv", show_col_types = FALSE)
checks <- read_csv("../output/numerical_checks.csv", show_col_types = FALSE)
stopifnot(all(checks$passed), !anyDuplicated(parents[c("sample", "parent_id")]),
          !anyDuplicated(weights$parent_id), all(is.finite(weights$calibration_weight)),
          all(weights$calibration_weight > 0))

analysis <- parents |>
  filter(included_ab, parent_total_units >= 50, composition_eligible) |>
  select(sample, parent_id, cohort_date, source_end_date, parent_total_units,
         n_components, sorted_component_vector, component_addresses,
         splitting_verification_status, right_window_observed,
         lot_area_sqft, residential_far, built_far, borough, multi_lot_indicator)
historical <- filter(analysis, sample == "historical")
post <- filter(analysis, sample == "post_policy")
stopifnot(setequal(historical$parent_id, weights$parent_id),
          all(historical$cohort_date >= as.Date("2019-01-01")),
          all(historical$cohort_date <= as.Date("2022-12-31")),
          all(post$cohort_date >= as.Date("2025-01-01")),
          all(post$cohort_date <= as.Date("2026-07-08")))
historical <- historical |>
  left_join(select(weights, parent_id, weight_units = parent_total_units, calibration_weight),
            by = "parent_id", relationship = "one-to-one")
stopifnot(all(historical$parent_total_units == historical$weight_units),
          nrow(historical) == calibration$historical_parents,
          nrow(post) == calibration$post_parents)
historical <- historical |>
  mutate(weight = calibration_weight / sum(calibration_weight)) |>
  select(-weight_units, -calibration_weight)
post <- mutate(post, weight = 1 / nrow(post))
analysis <- bind_rows(historical, post)

# Reconstruct every vector from additive constituent rows before using the parents.
constituents <- filings |>
  semi_join(analysis, by = c("sample", "parent_id"))
stopifnot(!anyDuplicated(constituents[c("sample", "parent_id", "root_job_id")]),
          all(constituents$constituent_units > 0),
          all(constituents$constituent_units == floor(constituents$constituent_units)))
rebuilt <- constituents |>
  group_by(sample, parent_id) |>
  summarise(total = sum(constituent_units), J = n(),
            vector = paste(sort(constituent_units, decreasing = TRUE), collapse = "+"),
            crossers = sum(constituent_units >= 100), .groups = "drop")
validation <- analysis |>
  left_join(rebuilt, by = c("sample", "parent_id"), relationship = "one-to-one")
stopifnot(!anyNA(validation$total), all(validation$total == validation$parent_total_units),
          all(validation$J == validation$n_components),
          all(validation$vector == validation$sorted_component_vector))
double_crossers <- validation |>
  filter(sample == "post_policy", crossers >= 2) |>
  select(parent_id, parent_total_units, n_components, sorted_component_vector,
         crossers, component_addresses, splitting_verification_status)

x <- historical$parent_total_units
J0 <- historical$n_components
w <- historical$weight
P <- nrow(post)
J_cap <- max(2L, J0, post$n_components)
observed <- notch_joint_shares(post$parent_total_units, post$n_components, post$weight)
counterfactual <- notch_joint_shares(x, J0, w)
cell_definitions <- expand_grid(organization = c("1", "2", "3+"),
                                size_bin = notch_size_bins) |>
  mutate(cell = row_number())

# Equal squared errors across 45 disjoint cells, frozen before the search.
# Lambda and the common organization menu are sensitivity assumptions, not fitted.
specifications <- tibble(
  specification = c("separate_baseline", "joint_assessment", "lambda_half", "lambda_two", "menu_plus_one"),
  assessment = c("separate", "joint", "separate", "separate", "separate"),
  lambda = c(1, 1, .5, 2, 1), J_cap = c(J_cap, J_cap, J_cap, J_cap, J_cap + 1L))
# The original 56-point grid hit its upper sigma boundary; extend it visibly.
kappa_grid <- c(0, .0025, .005, .01, .02, .025, .04, .05, .075, .10, .15, .20, .30, .50, 1)
sigma_grid <- c(.0025, .005, .01, .025, .05, .10, .25, .50, 1, 2, 5, 10)
grid_rows <- list()
cell_rows <- list()
fit_id <- 0L
for (s in seq_len(nrow(specifications))) {
  spec <- specifications[s, ]
  # A local refinement surrounds the expanded-grid baseline minimum (.10, 1).
  kappas <- if (s == 1L) sort(unique(round(c(kappa_grid, seq(.07, .13, .005)), 6))) else kappa_grid
  sigmas <- if (s == 1L) sort(unique(round(c(sigma_grid, seq(.6, 1.6, .1)), 6))) else sigma_grid
  for (kappa in kappas) {
    choices <- notch_choices(x, kappa, spec$lambda, spec$J_cap, spec$assessment)
    fixed <- choices[choices$J == J0[choices$i], ]
    for (sigma in sigmas) {
      prediction <- notch_predictions(choices, J0, w, sigma)
      shares <- notch_joint_shares(prediction$m, prediction$J, prediction$mass)
      fit_id <- fit_id + 1L
      grid_rows[[fit_id]] <- spec |>
        mutate(fit_id = fit_id, kappa = kappa, tau = 0, sigma_org = sigma,
          original_grid = kappa %in% c(0, .0025, .005, .01, .02, .05, .10, .20) &
            sigma %in% c(.0025, .005, .01, .025, .05, .10, .25),
          objective = sum((shares - observed)^2),
          mean_units = sum(prediction$mass * prediction$m),
          share_99 = sum(prediction$mass[prediction$m == 99]),
          share_198 = sum(prediction$mass[prediction$m == 198]),
          share_multi = sum(prediction$mass[prediction$J >= 2]),
          counterfactual_units = P * sum(w * x), observed_units = sum(post$parent_total_units),
          predicted_units = P * sum(prediction$mass * prediction$m),
          fixed_organization_units = P * sum(w[fixed$i] * fixed$m),
          direct_difference = counterfactual_units - observed_units,
          model_difference = counterfactual_units - predicted_units,
          units_from_reorganization = predicted_units - fixed_organization_units)
      cell_rows[[fit_id]] <- cell_definitions |>
        mutate(fit_id = fit_id, observed_share = observed,
               counterfactual_share = counterfactual, predicted_share = shares)
    }
  }
  cat("Finished", spec$specification, "\n")
}
grid <- bind_rows(grid_rows) |>
  group_by(specification) |>
  arrange(objective, kappa, sigma_org, .by_group = TRUE) |>
  mutate(rank = row_number(), objective_gap = objective - min(objective)) |>
  ungroup()
stopifnot(!anyDuplicated(grid[c("specification", "kappa", "sigma_org")]))
cells <- bind_rows(cell_rows)
best <- filter(grid, rank == 1L)

# Retain the best baseline and joint-assessment contributions, including zero mass.
contribution_rows <- list()
for (s in seq_len(2L)) {
  fit <- filter(best, specification == specifications$specification[s])
  choices <- notch_choices(x, fit$kappa, fit$lambda, fit$J_cap, fit$assessment)
  prediction <- notch_predictions(choices, J0, w, fit$sigma_org)
  historical_vectors <- strsplit(historical$sorted_component_vector, "+", fixed = TRUE)
  layouts <- lapply(seq_len(nrow(prediction)), function(r) {
    a <- prediction[r, ]
    notch_partition(a$m, a$J, as.integer(historical_vectors[[a$i]]), fit$kappa, fit$assessment)
  })
  stopifnot(all(lengths(layouts) == prediction$J),
            all(vapply(layouts, sum, numeric(1)) == prediction$m),
            all(unlist(layouts) >= 1))
  if (fit$assessment == "separate" && fit$kappa > 0) {
    stopifnot(all(vapply(layouts, function(v) sum(v >= 100), integer(1)) == prediction$minimum_crossers))
  }
  contribution_rows[[s]] <- as_tibble(prediction) |>
    mutate(specification = fit$specification, kappa = fit$kappa, tau = 0,
      sigma_org = fit$sigma_org, parent_id = historical$parent_id[i],
      historical_vector = historical$sorted_component_vector[i],
      representative_vector = vapply(layouts, paste, character(1), collapse = "+"),
      layout_unique = J == 1 | m <= J + 1 |
        (fit$assessment == "separate" & fit$kappa > 0 & m <= 99 * J & m >= 99 * J - 1),
      historical_vector_preserved = representative_vector == historical_vector)
}
contributions <- bind_rows(contribution_rows)

# Parent-level diagnostics keep the full tail; layout-specific 99+99 is unique here.
diagnostics <- bind_rows(
  analysis |> transmute(series = sample, m = parent_total_units, J = n_components,
                        mass = weight, exact_99x2 = sorted_component_vector == "99+99"),
  contributions |> transmute(series = specification, m, J, mass,
                             exact_99x2 = m == 198 & J == 2 & layout_unique)) |>
  group_by(series) |>
  summarise(mean_units = sum(m * mass), share_99 = sum(mass[m == 99]),
    share_100 = sum(mass[m == 100]), share_198 = sum(mass[m == 198]),
    share_99x2 = sum(mass[exact_99x2]),
    share_J2 = sum(mass[J == 2]), share_J3plus = sum(mass[J >= 3]),
    share_301plus = sum(mass[m >= 301]),
    units_301plus_per_parent = sum(mass[m >= 301] * m[m >= 301]), .groups = "drop")

# Known-parameter recovery conditions on these weights; it is not inference for NYC.
baseline_grid <- filter(grid, specification == "separate_baseline") |> arrange(fit_id)
baseline_cells <- filter(cells, fit_id %in% baseline_grid$fit_id) |> arrange(fit_id, cell)
predicted_matrix <- matrix(baseline_cells$predicted_share, nrow = 45L)
truths <- tibble(kappa = c(.02, .10), sigma_org = c(.025, .05))
set.seed(485101)
recovery_rows <- list()
for (t in seq_len(nrow(truths))) {
  true_index <- which(baseline_grid$kappa == truths$kappa[t] &
                        baseline_grid$sigma_org == truths$sigma_org[t])
  true_shares <- predicted_matrix[, true_index]
  for (replication in 0:10) {
    target <- if (replication == 0) true_shares else as.vector(rmultinom(1, P, true_shares)) / P
    objectives <- colSums((predicted_matrix - target)^2)
    minimizers <- baseline_grid[objectives <= min(objectives) + 1e-12, ]
    if (replication == 0) stopifnot(objectives[true_index] < 1e-20)
    recovery_rows[[length(recovery_rows) + 1L]] <- tibble(
      truth = t, replication = replication, true_kappa = truths$kappa[t],
      true_sigma_org = truths$sigma_org[t], minimum_objective = min(objectives),
      true_objective = objectives[true_index], n_minimizers = nrow(minimizers),
      kappa_min = min(minimizers$kappa), kappa_max = max(minimizers$kappa),
      sigma_min = min(minimizers$sigma_org), sigma_max = max(minimizers$sigma_org))
  }
}
recovery <- bind_rows(recovery_rows)

# Delete one observed parent near the notch at a time, keeping historical weights fixed.
sensitivity_rows <- list()
nearby <- which(post$parent_total_units >= 100 & post$parent_total_units <= 119)
for (i in nearby) {
  target <- notch_joint_shares(post$parent_total_units[-i], post$n_components[-i], rep(1 / (P - 1), P - 1))
  objective <- colSums((predicted_matrix - target)^2)
  winners <- baseline_grid[objective <= min(objective) + 1e-12, ]
  sensitivity_rows[[length(sensitivity_rows) + 1L]] <- tibble(
    removed_parent = post$parent_id[i], removed_units = post$parent_total_units[i],
    removed_J = post$n_components[i], minimum_objective = min(objective),
    kappa_min = min(winners$kappa), kappa_max = max(winners$kappa),
    sigma_min = min(winners$sigma_org), sigma_max = max(winners$sigma_org))
}

provenance <- tibble(
  file = c("parent_opportunity_panel.parquet", "constituent_filing_panel.parquet",
           "calibration_weights.csv", "calibration_summary.csv"),
  md5 = unname(tools::md5sum(c("../input/parent_opportunity_panel.parquet",
    "../input/constituent_filing_panel.parquet", "../input/calibration_weights.csv",
    "../input/calibration_summary.csv"))),
  rows = c(nrow(parents), nrow(filings), nrow(weights), nrow(calibration)))
SaveData(provenance, "file", "../output/input_provenance.csv")
SaveData(analysis, c("sample", "parent_id"), "../output/analysis_parents.csv")
SaveData(double_crossers, "parent_id", "../output/observed_double_crossers.csv")
SaveData(grid, "fit_id", "../output/parameter_grid.csv")
SaveData(cells, c("fit_id", "cell"), "../output/joint_cell_predictions.csv")
SaveData(best, "specification", "../output/best_fits.csv")
SaveData(contributions, c("specification", "parent_id", "J"), "../output/best_parent_contributions.parquet")
SaveData(diagnostics, "series", "../output/fit_diagnostics.csv")
SaveData(recovery, c("truth", "replication"), "../output/synthetic_recovery.csv")
SaveData(bind_rows(sensitivity_rows), "removed_parent", "../output/near_notch_sensitivity.csv")

# Numerical text consumed by the dated logbook entry.
baseline <- filter(best, specification == "separate_baseline")
predicted <- filter(diagnostics, series == "separate_baseline")
observed_diagnostics <- filter(diagnostics, series == "post_policy")
writeLines(c(
  sprintf("\\newcommand{\\NotchKappa}{%.2f}", baseline$kappa),
  sprintf("\\newcommand{\\NotchSigma}{%.1f}", baseline$sigma_org),
  sprintf("\\newcommand{\\NotchMean}{%.1f}", predicted$mean_units),
  sprintf("\\newcommand{\\NotchObservedMean}{%.1f}", observed_diagnostics$mean_units),
  sprintf("\\newcommand{\\NotchUnitLoss}{%.0f}", baseline$model_difference),
  sprintf("\\newcommand{\\NotchDirectGap}{%.0f}", baseline$direct_difference),
  sprintf("\\newcommand{\\NotchReorganizationUnits}{%.0f}", baseline$units_from_reorganization),
  sprintf("\\newcommand{\\NotchShareNinetyNine}{%.1f}", 100 * predicted$share_99),
  sprintf("\\newcommand{\\NotchSharePairs}{%.1f}", 100 * predicted$share_J2),
  sprintf("\\newcommand{\\NotchShareThreePlus}{%.1f}", 100 * predicted$share_J3plus),
  sprintf("\\newcommand{\\NotchShareDoubleNinetyNine}{%.2f}", 100 * predicted$share_99x2)
), "../output/pilot_values.tex")
print(select(best, specification, kappa, sigma_org, objective, mean_units, share_99, share_multi), width = Inf)

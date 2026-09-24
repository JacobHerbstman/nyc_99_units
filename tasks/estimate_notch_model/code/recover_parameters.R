# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})
source("../../shared/code/write_data_report.R")

draws <- 200L

# Can the estimator tell the parameters apart? Treat the model's prediction at
# an estimate as the truth, draw recent samples of the observed size from it,
# and re-estimate each on the same grid. Only the recent sample is redrawn;
# the historical benchmark is held fixed, so this understates uncertainty.
cells <- read_parquet("../output/main_grid_cells.parquet") |> arrange(point, cell)
points <- cells |> distinct(point, kappa, tau, sigma) |> arrange(point)
predicted <- matrix(cells$share, nrow = 45)
estimates <- read_csv("../output/estimates.csv", show_col_types = FALSE)
post_parents <- estimates$post_parents[estimates$specification == "notch_and_kink"]

estimate_on_grid <- function(target) points[which.min(colSums((predicted - target)^2)), ]

# Two truths on the main grid: the main estimate, and the same jump and
# splitting cost with a kink of 0.2, to ask whether a kink would be detected.
main <- estimates |> filter(specification == "notch_and_kink")
nearest_point <- function(kappa, tau, sigma) {
  points$point[which.min(abs(points$kappa - kappa) + abs(points$tau - tau) + abs(log(points$sigma / sigma)))]
}
truths <- tibble(truth = c("main_estimate", "with_kink_0.2"),
  point = c(nearest_point(main$kappa, main$tau, main$sigma), nearest_point(main$kappa, 0.2, main$sigma))) |>
  inner_join(points, by = "point", relationship = "one-to-one")
stopifnot(abs(truths$kappa[1] - main$kappa) < 1e-9, abs(truths$sigma[1] / main$sigma - 1) < 1e-9)

set.seed(20260924)
recovery <- bind_rows(lapply(seq_len(nrow(truths)), function(k) {
  true_point <- truths[k, ]
  probabilities <- predicted[, true_point$point]
  samples <- rmultinom(draws, post_parents, probabilities) / post_parents
  bind_rows(
    estimate_on_grid(probabilities) |> mutate(draw = 0L),
    bind_rows(lapply(seq_len(draws), function(d) estimate_on_grid(samples[, d]) |> mutate(draw = d)))
  ) |>
    transmute(truth = true_point$truth, draw, true_kappa = true_point$kappa, true_tau = true_point$tau,
      true_sigma = true_point$sigma, kappa, tau, sigma)
}))

recovery_summary <- bind_rows(lapply(c("kappa", "tau", "sigma"), function(parameter) {
  recovery |>
    group_by(truth) |>
    summarise(
      parameter = parameter,
      true_value = first(.data[[paste0("true_", parameter)]]),
      exact_moments_recover = .data[[parameter]][draw == 0] == true_value,
      share_draws_at_truth = mean(.data[[parameter]][draw > 0] == true_value),
      draw_p10 = quantile(.data[[parameter]][draw > 0], 0.1, type = 1),
      draw_median = quantile(.data[[parameter]][draw > 0], 0.5, type = 1),
      draw_p90 = quantile(.data[[parameter]][draw > 0], 0.9, type = 1),
      .groups = "drop")
}))

print(recovery_summary, width = Inf)
SaveData(recovery, c("truth", "draw"), "../output/recovery.csv")
SaveData(recovery_summary, c("truth", "parameter"), "../output/recovery_summary.csv")

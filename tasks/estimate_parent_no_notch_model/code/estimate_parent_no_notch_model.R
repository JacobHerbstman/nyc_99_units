# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_parent_no_notch_model/code")
# unit_spec <- "hdb_priority"
# min_units <- 6L
# minimum_category_rows <- 30L
# counterfactual_max_units <- 400L
# plot_min_units <- 50L
# plot_max_units <- 220L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected six arguments: unit specification, minimum units, minimum ",
    "category rows, counterfactual maximum units, and plot limits."
  )
}

unit_spec <- args[1]
min_units <- as.integer(args[2])
minimum_category_rows <- as.integer(args[3])
counterfactual_max_units <- as.integer(args[4])
plot_min_units <- as.integer(args[5])
plot_max_units <- as.integer(args[6])

if (
  !(unit_spec %in% c("hdb_priority", "dob_i1_complete_case")) ||
  any(is.na(c(
    min_units, minimum_category_rows, counterfactual_max_units,
    plot_min_units, plot_max_units
  ))) ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    counterfactual_max_units < 120L ||
    plot_min_units < min_units ||
    plot_min_units >= plot_max_units ||
    plot_max_units > counterfactual_max_units
) {
  stop("Parent-model arguments are not internally consistent.")
}

prepare_train_test <- function(train_data, test_data) {
  training_year_mean <- mean(train_data$filing_year)
  train_data$filing_year_centered <-
    train_data$filing_year - training_year_mean
  test_data$filing_year_centered <-
    test_data$filing_year - training_year_mean

  train_data$residfar_missing <- is.na(train_data$residfar)
  test_data$residfar_missing <- is.na(test_data$residfar)

  for (feature_name in c("log_lotarea", "residfar", "builtfar")) {
    train_values <- train_data[[feature_name]]
    test_values <- test_data[[feature_name]]
    training_median <- median(train_values, na.rm = TRUE)

    if (!is.finite(training_median)) {
      stop("Training data have no finite values for ", feature_name, ".")
    }

    train_values[is.na(train_values)] <- training_median
    test_values[is.na(test_values)] <- training_median
    train_data[[feature_name]] <- train_values
    test_data[[feature_name]] <- test_values
  }

  for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
    train_values <- str_squish(as.character(train_data[[feature_name]]))
    test_values <- str_squish(as.character(test_data[[feature_name]]))
    train_values[is.na(train_values) | train_values == ""] <- "missing"
    test_values[is.na(test_values) | test_values == ""] <- "missing"
    training_counts <- table(train_values)
    keep_levels <- names(training_counts)[
      training_counts >= minimum_category_rows
    ]

    if (length(keep_levels) == 0L) {
      keep_levels <- names(sort(training_counts, decreasing = TRUE))[1]
    }

    train_values[!(train_values %in% keep_levels)] <- "other_rare"
    factor_levels <- sort(unique(train_values))
    fallback_level <- if ("other_rare" %in% factor_levels) {
      "other_rare"
    } else {
      names(sort(training_counts, decreasing = TRUE))[1]
    }
    test_values[!(test_values %in% keep_levels)] <- fallback_level
    train_data[[feature_name]] <- factor(
      train_values,
      levels = factor_levels
    )
    test_data[[feature_name]] <- factor(
      test_values,
      levels = factor_levels
    )
  }

  list(
    train = train_data,
    test = test_data,
    training_year_mean = training_year_mean
  )
}

# Stable evaluation of log(1 - exp(x)); this is not an outcome transform.
log_one_minus_exp <- function(log_value) {
  if (any(log_value > 0, na.rm = TRUE)) {
    stop("log_one_minus_exp received a positive log value.")
  }

  result <- numeric(length(log_value))
  use_log1p <- log_value < log(0.5)
  result[use_log1p] <- log1p(-exp(log_value[use_log1p]))
  result[!use_log1p] <- log(-expm1(log_value[!use_log1p]))
  result
}

log_normal_interval_probability <- function(lower_z, upper_z) {
  if (length(lower_z) != length(upper_z) || any(lower_z >= upper_z)) {
    stop("Normal interval bounds are not strictly ordered.")
  }

  result <- numeric(length(lower_z))
  use_upper_tail <- lower_z > 0

  if (any(!use_upper_tail)) {
    upper_log_cdf <- pnorm(upper_z[!use_upper_tail], log.p = TRUE)
    lower_log_cdf <- pnorm(lower_z[!use_upper_tail], log.p = TRUE)
    result[!use_upper_tail] <- upper_log_cdf + log_one_minus_exp(
      lower_log_cdf - upper_log_cdf
    )
  }

  if (any(use_upper_tail)) {
    lower_log_survival <- pnorm(
      lower_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    upper_log_survival <- pnorm(
      upper_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    result[use_upper_tail] <- lower_log_survival + log_one_minus_exp(
      upper_log_survival - lower_log_survival
    )
  }

  result
}

rounded_conditional_log_probability <- function(
    units, predicted_log_units, sigma, conditioning_floor) {
  lower_z <- (log(units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(conditioning_floor - 0.5) - predicted_log_units
  ) / sigma
  log_probability <- log_normal_interval_probability(lower_z, upper_z) -
    pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  log_probability[units < conditioning_floor] <- NA_real_
  log_probability
}

negative_log_likelihood <- function(
    parameters, model_matrix, units, training_floor) {
  coefficient_count <- ncol(model_matrix)
  sigma <- exp(parameters[coefficient_count + 1L])

  if (!is.finite(sigma) || sigma <= 0) {
    return(1e100)
  }

  predicted_log_units <- as.numeric(
    model_matrix %*% parameters[seq_len(coefficient_count)]
  )
  log_probability <- rounded_conditional_log_probability(
    units,
    predicted_log_units,
    sigma,
    training_floor
  )

  if (any(!is.finite(log_probability))) {
    return(1e100)
  }

  -sum(log_probability)
}

fit_rounded_mle <- function(train_raw, test_raw, training_floor, formula) {
  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test
  ols_fit <- lm(formula, data = train_data)
  train_matrix_full <- model.matrix(formula, data = train_data)
  test_matrix_full <- model.matrix(formula, data = test_data)
  ols_coefficients_full <- coef(ols_fit)
  estimable_terms <- names(ols_coefficients_full)[!is.na(ols_coefficients_full)]
  train_matrix <- train_matrix_full[, estimable_terms, drop = FALSE]
  test_matrix <- test_matrix_full[, estimable_terms, drop = FALSE]
  ols_coefficients <- ols_coefficients_full[estimable_terms]
  ols_sigma <- sqrt(mean(residuals(ols_fit)^2))

  if (
    qr(train_matrix)$rank != ncol(train_matrix) ||
      !identical(colnames(train_matrix), names(ols_coefficients)) ||
      !identical(colnames(test_matrix_full), colnames(train_matrix_full)) ||
      !identical(colnames(test_matrix), colnames(train_matrix)) ||
      any(!is.finite(ols_coefficients)) ||
      !is.finite(ols_sigma) ||
      ols_sigma <= 0
  ) {
    stop("A model matrix or OLS starting value failed QC.")
  }

  ols_parameters <- c(ols_coefficients, log(ols_sigma))
  ols_objective <- negative_log_likelihood(
    ols_parameters,
    train_matrix,
    train_data$units,
    training_floor
  )
  mle_warnings <- character()
  mle_fit <- withCallingHandlers(
    nlminb(
      start = ols_parameters,
      objective = negative_log_likelihood,
      lower = c(rep(-Inf, ncol(train_matrix)), log(0.02)),
      upper = c(rep(Inf, ncol(train_matrix)), log(10)),
      model_matrix = train_matrix,
      units = train_data$units,
      training_floor = training_floor,
      control = list(
        eval.max = 5000L,
        iter.max = 1000L,
        rel.tol = 1e-10,
        x.tol = 1e-8
      )
    ),
    warning = function(warning_condition) {
      mle_warnings <<- c(mle_warnings, conditionMessage(warning_condition))
      invokeRestart("muffleWarning")
    }
  )

  coefficient_count <- ncol(train_matrix)
  coefficients <- mle_fit$par[seq_len(coefficient_count)]
  names(coefficients) <- colnames(train_matrix)
  sigma <- exp(mle_fit$par[coefficient_count + 1L])
  mle_objective <- negative_log_likelihood(
    mle_fit$par,
    train_matrix,
    train_data$units,
    training_floor
  )

  if (
    mle_fit$convergence != 0L ||
      length(mle_warnings) > 0L ||
      any(!is.finite(mle_fit$par)) ||
      !is.finite(mle_objective) ||
      mle_objective > ols_objective + 1e-5 ||
      sigma <= 0.020001 ||
      sigma >= 9.999
  ) {
    stop("The rounded truncated MLE failed convergence or objective QC.")
  }

  list(
    coefficients = coefficients,
    sigma = sigma,
    test_mu = as.numeric(test_matrix %*% coefficients),
    objective = mle_objective,
    training_year_mean = prepared$training_year_mean
  )
}

unit_distribution <- function(predicted_log_units, sigma, upper_units) {
  unit_grid <- min_units:upper_units
  probability <- exp(rounded_conditional_log_probability(
    unit_grid,
    rep(predicted_log_units, length(unit_grid)),
    sigma,
    min_units
  ))
  distribution <- numeric(upper_units + 1L)
  distribution[unit_grid + 1L] <- probability
  distribution
}

solve_discrete_frontier <- function(target_mass, expected_distribution) {
  frontier_distribution <- expected_distribution |>
    filter(units >= 100L) |>
    arrange(units)

  if (
    !is.finite(target_mass) ||
      target_mass < 0 ||
      target_mass > sum(frontier_distribution$expected_count)
  ) {
    return(NA_real_)
  }

  if (target_mass == 0) {
    return(99.5)
  }

  cumulative_mass <- cumsum(frontier_distribution$expected_count)
  frontier_row <- which(cumulative_mass >= target_mass)[1]
  previous_mass <- if (frontier_row == 1L) 0 else {
    cumulative_mass[frontier_row - 1L]
  }
  bin_mass <- frontier_distribution$expected_count[frontier_row]
  lower_edge <- frontier_distribution$units[frontier_row] - 0.5
  lower_edge + (target_mass - previous_mass) / bin_mass
}

implied_affected_mean <- function(target_mass, expected_distribution) {
  if (!is.finite(target_mass) || target_mass <= 0) {
    return(NA_real_)
  }

  affected_distribution <- expected_distribution |>
    filter(units >= 100L) |>
    arrange(units) |>
    mutate(
      mass_before = lag(cumsum(expected_count), default = 0),
      affected_mass = pmax(
        pmin(expected_count, target_mass - mass_before),
        0
      )
    )

  sum(
    affected_distribution$units * affected_distribution$affected_mass
  ) / target_mass
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

historical_panel <- read_parquet(
  "../input/historical_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id)
) {
  stop("Enhanced-parent model inputs failed key QC.")
}

training_rows <- historical_panel |>
  filter(model_eligible, filing_year >= 2019L, date_last_filed <= as.Date("2023-12-31"))

model_eligible_post_parents <- sum(post_panel$model_eligible)

if (unit_spec == "hdb_priority") {
  score_rows <- post_panel |>
    filter(model_eligible) |>
    mutate(
      units = units_hdb_priority,
      log_units = log(units)
    )
  model_name <- "enhanced_parent_2019_2023"
  unit_label <- "HDB units (primary)"
} else {
  score_rows <- post_panel |>
    filter(
      model_eligible,
      dob_i1_complete,
      units_dob_i1 >= min_units
    ) |>
    mutate(
      units = units_dob_i1,
      log_units = log(units)
    )
  model_name <- "enhanced_parent_2019_2023_dob_i1_complete_case"
  unit_label <- "DOB initial-filing units (complete-case sensitivity)"
}

fitted_model <- fit_rounded_mle(
  training_rows,
  score_rows,
  min_units,
  model_formula
)

scores <- score_rows |>
  mutate(
    unit_definition = unit_spec,
    predicted_log_units = fitted_model$test_mu,
    probability_observed = exp(rounded_conditional_log_probability(
      units,
      predicted_log_units,
      fitted_model$sigma,
      min_units
    )),
    probability_exact_99 = exp(rounded_conditional_log_probability(
      rep(99L, n()),
      predicted_log_units,
      fitted_model$sigma,
      min_units
    )),
    probability_at_least_100 = exp(
      pnorm(
        (log(99.5) - predicted_log_units) / fitted_model$sigma,
        lower.tail = FALSE,
        log.p = TRUE
      ) - pnorm(
        (log(min_units - 0.5) - predicted_log_units) /
          fitted_model$sigma,
        lower.tail = FALSE,
        log.p = TRUE
      )
    )
  ) |>
  select(
    observation_id, unit_definition, observed_units = units,
    component_filings,
    predicted_log_units, probability_observed,
    probability_exact_99, probability_at_least_100
  ) |>
  arrange(observation_id)

expected_counts <- numeric(counterfactual_max_units + 1L)

for (score_row in seq_len(nrow(scores))) {
  expected_counts <- expected_counts + unit_distribution(
    scores$predicted_log_units[score_row],
    fitted_model$sigma,
    counterfactual_max_units
  )
}

observed_counts <- tabulate(
  scores$observed_units + 1L,
  nbins = counterfactual_max_units + 1L
)

distribution <- tibble(
  unit_definition = unit_spec,
  units = min_units:counterfactual_max_units,
  expected_count = expected_counts[
    (min_units:counterfactual_max_units) + 1L
  ],
  observed_count = observed_counts[
    (min_units:counterfactual_max_units) + 1L
  ]
)

observed_exact_99 <- sum(scores$observed_units == 99L)
expected_exact_99 <- sum(scores$probability_exact_99)
observed_100_plus <- sum(scores$observed_units >= 100L)
expected_100_plus <- sum(scores$probability_at_least_100)
excess_exact_99 <- observed_exact_99 - expected_exact_99
missing_100_plus <- expected_100_plus - observed_100_plus

counterfactual <- tibble(
  model = model_name,
  unit_definition = unit_spec,
  training_parents = nrow(training_rows),
  model_eligible_2025_parents = model_eligible_post_parents,
  scoreable_2025_parents = nrow(scores),
  excluded_2025_parents_unit_definition =
    model_eligible_post_parents - nrow(scores),
  component_filings = sum(scores$component_filings),
  observed_exact_99,
  expected_no_notch_exact_99 = expected_exact_99,
  excess_exact_99,
  observed_100_plus,
  expected_no_notch_100_plus = expected_100_plus,
  missing_100_plus,
  conservation_gap = excess_exact_99 - missing_100_plus,
  frontier_from_exact_99 = solve_discrete_frontier(
    excess_exact_99,
    distribution
  ),
  frontier_from_missing_100_plus = solve_discrete_frontier(
    missing_100_plus,
    distribution
  ),
  mean_n0_from_exact_99 = implied_affected_mean(
    excess_exact_99,
    distribution
  ),
  mean_n0_from_missing_100_plus = implied_affected_mean(
    missing_100_plus,
    distribution
  ),
  shock_sigma = fitted_model$sigma
)

parameters <- tibble(
  model = model_name,
  unit_definition = unit_spec,
  training_start_year = 2019L,
  training_end_year = 2023L,
  training_parents = nrow(training_rows),
  training_year_mean = fitted_model$training_year_mean,
  term = c(names(fitted_model$coefficients), "shock_sigma"),
  estimate = c(fitted_model$coefficients, fitted_model$sigma)
)

if (
  any(!is.finite(parameters$estimate)) ||
    any(scores$probability_observed < 0) ||
    any(scores$probability_exact_99 < 0) ||
    any(scores$probability_at_least_100 < 0) ||
    any(scores$probability_at_least_100 > 1 + 1e-10) ||
    !is.finite(counterfactual$conservation_gap)
) {
  stop("Enhanced-parent model outputs failed final QC.")
}

counterfactual_plot <- distribution |>
  filter(units >= plot_min_units, units <= plot_max_units) |>
  ggplot(aes(x = units)) +
  geom_col(
    aes(y = observed_count),
    fill = "#B8B8B8",
    width = 0.9
  ) +
  geom_line(
    aes(y = expected_count),
    color = "#1769AA",
    linewidth = 0.9
  ) +
  geom_vline(xintercept = 99.5, color = "#E6550D", linetype = "dashed") +
  scale_x_continuous(
    breaks = c(plot_min_units, 75L, 100L, 125L, 150L, 175L, 198L, plot_max_units),
    expand = expansion(mult = c(0.005, 0.01))
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Enhanced-parent filings bunch below the 100-unit threshold",
    subtitle = paste0(
      "Observed 2025 parent counts and the no-notch distribution estimated ",
      "from 2019-2023; ", unit_label
    ),
    x = "Proposed dwelling units per enhanced parent",
    y = "Parent opportunities",
    caption = paste0(
      "Gray bars are observed counts. The blue line is the fitted no-notch ",
      "distribution. Parent links combine conservative historical signals ",
      "with corroborated exact parcel adjacency."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.title.position = "plot"
  )

if (unit_spec == "hdb_priority") {
  write_csv_if_changed(
    counterfactual,
    "../output/enhanced_parent_2025_counterfactual.csv"
  )
  write_csv_if_changed(
    parameters,
    "../output/enhanced_parent_model_parameters.csv"
  )
  write_parquet_if_changed(
    scores,
    "../output/enhanced_parent_2025_scores.parquet"
  )
  write_csv_if_changed(
    distribution,
    "../output/enhanced_parent_2025_distribution.csv"
  )
  ggsave(
    "../output/enhanced_parent_2025_counterfactual.pdf",
    counterfactual_plot,
    width = 10,
    height = 6.5,
    bg = "white"
  )
} else {
  write_csv_if_changed(
    counterfactual,
    "../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.csv"
  )
  write_csv_if_changed(
    parameters,
    "../output/enhanced_parent_dob_i1_complete_case_model_parameters.csv"
  )
  write_parquet_if_changed(
    scores,
    "../output/enhanced_parent_dob_i1_complete_case_2025_scores.parquet"
  )
  write_csv_if_changed(
    distribution,
    "../output/enhanced_parent_dob_i1_complete_case_2025_distribution.csv"
  )
  ggsave(
    "../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.pdf",
    counterfactual_plot,
    width = 10,
    height = 6.5,
    bg = "white"
  )
}

cat("Wrote enhanced-parent no-notch results for ", unit_spec, " to ../output\n")

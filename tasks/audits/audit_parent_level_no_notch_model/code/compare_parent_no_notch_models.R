# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_level_no_notch_model/code")
# min_units <- 6L
# minimum_category_rows <- 30L
# counterfactual_max_units <- 400L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop(
    "Expected three arguments: minimum units, minimum category rows, and ",
    "counterfactual maximum units."
  )
}

min_units <- as.integer(args[1])
minimum_category_rows <- as.integer(args[2])
counterfactual_max_units <- as.integer(args[3])

if (
  any(is.na(c(min_units, minimum_category_rows, counterfactual_max_units))) ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    counterfactual_max_units < 120L
) {
  stop("Parent-model comparison arguments are not internally consistent.")
}

prepare_train_test <- function(train_data, test_data) {
  train_prepared <- train_data
  test_prepared <- test_data
  training_year_mean <- mean(train_prepared$filing_year)
  train_prepared$filing_year_centered <-
    train_prepared$filing_year - training_year_mean
  test_prepared$filing_year_centered <-
    test_prepared$filing_year - training_year_mean

  for (feature_name in c("log_lotarea", "residfar", "builtfar")) {
    missing_name <- paste0(feature_name, "_missing")
    train_values <- train_prepared[[feature_name]]
    test_values <- test_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    test_prepared[[missing_name]] <- is.na(test_values)
    training_median <- median(train_values, na.rm = TRUE)

    if (!is.finite(training_median)) {
      stop("Training data have no finite values for ", feature_name, ".")
    }

    train_values[is.na(train_values)] <- training_median
    test_values[is.na(test_values)] <- training_median
    train_prepared[[feature_name]] <- train_values
    test_prepared[[feature_name]] <- test_values
  }

  for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
    train_values <- str_squish(as.character(train_prepared[[feature_name]]))
    test_values <- str_squish(as.character(test_prepared[[feature_name]]))
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
    train_prepared[[feature_name]] <- factor(
      train_values,
      levels = factor_levels
    )
    test_prepared[[feature_name]] <- factor(
      test_values,
      levels = factor_levels
    )
  }

  list(
    train = train_prepared,
    test = test_prepared,
    training_year_mean = training_year_mean
  )
}

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
      !is.finite(ols_sigma) || ols_sigma <= 0
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
      sigma <= 0.020001 || sigma >= 9.999
  ) {
    stop("A rounded truncated MLE failed convergence or objective QC.")
  }

  list(
    coefficients = coefficients,
    sigma = sigma,
    test_mu = as.numeric(test_matrix %*% coefficients),
    objective = mle_objective,
    training_year_mean = prepared$training_year_mean
  )
}

component_distribution <- function(predicted_log_units, sigma, upper_units) {
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

parent_distribution <- function(predicted_log_units, sigma, upper_units) {
  if (length(predicted_log_units) == 1L) {
    return(component_distribution(
      predicted_log_units,
      sigma,
      upper_units
    ))
  }

  distribution <- c(1, rep(0, upper_units))

  for (component_mu in predicted_log_units) {
    component_probability <- component_distribution(
      component_mu,
      sigma,
      upper_units
    )
    updated_distribution <- numeric(upper_units + 1L)

    for (component_units in min_units:upper_units) {
      remaining_units <- 0:(upper_units - component_units)
      updated_distribution[remaining_units + component_units + 1L] <-
        updated_distribution[remaining_units + component_units + 1L] +
        component_probability[component_units + 1L] *
        distribution[remaining_units + 1L]
    }

    distribution <- updated_distribution
  }

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

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

historical_panel <- read_parquet(
  "../output/historical_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../output/post_policy_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

membership <- read_parquet("../output/parent_model_membership.parquet") |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel[c("definition", "observation_id")]) ||
    anyDuplicated(post_panel[c("definition", "observation_id")]) ||
    anyDuplicated(membership[c("sample", "definition", "job_number")])
) {
  stop("Parent-model comparison inputs failed key QC.")
}

historical_filing_rows <- historical_panel |>
  filter(definition == "filing") |>
  mutate(job_number = component_jobs)

post_filing_rows <- post_panel |>
  filter(definition == "filing") |>
  mutate(job_number = component_jobs)

historical_enhanced_targets <- historical_panel |>
  filter(definition == "enhanced_parent", model_eligible)

post_enhanced_targets <- post_panel |>
  filter(definition == "enhanced_parent", model_eligible)

historical_target_members <- membership |>
  filter(sample == "historical", definition == "enhanced_parent") |>
  select(target_parent_id = parent_id, job_number)

post_target_members <- membership |>
  filter(sample == "post_policy", definition == "enhanced_parent") |>
  select(target_parent_id = parent_id, job_number)

if (
  anyDuplicated(historical_filing_rows$job_number) ||
    anyDuplicated(post_filing_rows$job_number) ||
    anyDuplicated(historical_target_members$job_number) ||
    anyDuplicated(post_target_members$job_number)
) {
  stop("Filing-to-enhanced-parent keys are not unique.")
}

models <- tribble(
  ~model_id, ~model_label, ~training_definition, ~training_start_year,
  ~scoring_mode,
  "filing_2010_2023",
  "Filing model, 2010-23",
  "filing", 2010L, "filing_components",
  "filing_2019_2023",
  "Filing model, 2019-23",
  "filing", 2019L, "filing_components",
  "conservative_parent_2010_2023",
  "Conservative parent, 2010-23",
  "conservative_parent", 2010L, "parent_direct",
  "conservative_parent_2019_2023",
  "Conservative parent, 2019-23",
  "conservative_parent", 2019L, "parent_direct",
  "enhanced_parent_2019_2023",
  "Enhanced parent, 2019-23",
  "enhanced_parent", 2019L, "parent_direct"
)

validation_rows <- list()

for (model_row in seq_len(nrow(models))) {
  model_specification <- models[model_row, ]

  for (training_end_year in 2020L:2022L) {
    test_year <- training_end_year + 1L
    training_rows <- historical_panel |>
      filter(
        definition == model_specification$training_definition,
        model_eligible,
        filing_year >= model_specification$training_start_year,
        date_last_filed <= as.Date(paste0(training_end_year, "-12-31"))
      )
    validation_targets <- historical_enhanced_targets |>
      filter(filing_year == test_year, last_filing_year == test_year)

    if (model_specification$scoring_mode == "filing_components") {
      score_rows <- historical_target_members |>
        filter(target_parent_id %in% validation_targets$parent_id) |>
        left_join(
          historical_filing_rows,
          by = "job_number",
          relationship = "one-to-one"
        ) |>
        arrange(target_parent_id, date_filed, job_number)
    } else {
      score_rows <- validation_targets |>
        mutate(target_parent_id = parent_id)
    }

    if (nrow(training_rows) == 0L || nrow(score_rows) == 0L) {
      stop("A validation training or scoring sample is empty.")
    }

    fitted_model <- fit_rounded_mle(
      training_rows,
      score_rows,
      min_units,
      model_formula
    )
    scored_rows <- score_rows |>
      mutate(predicted_log_units = fitted_model$test_mu)
    parent_mu <- split(
      scored_rows$predicted_log_units,
      scored_rows$target_parent_id
    )
    parent_predictions <- vector("list", nrow(validation_targets))
    predicted_cdf_sum <- numeric(length(80L:120L))

    for (target_row in seq_len(nrow(validation_targets))) {
      target <- validation_targets[target_row, ]
      upper_units <- max(120L, target$units)
      distribution <- parent_distribution(
        parent_mu[[target$parent_id]],
        fitted_model$sigma,
        upper_units
      )
      predicted_cdf_sum <- predicted_cdf_sum + vapply(
        80L:120L,
        function(threshold) sum(distribution[seq_len(threshold + 1L)]),
        numeric(1)
      )
      parent_predictions[[target_row]] <- tibble(
        target_parent_id = target$parent_id,
        observed_units = target$units,
        probability_observed = distribution[target$units + 1L],
        probability_exact_99 = distribution[100L],
        probability_at_least_100 = 1 - sum(distribution[seq_len(100L)])
      )
    }

    parent_predictions <- bind_rows(parent_predictions)
    observed_cdf <- vapply(
      80L:120L,
      function(threshold) mean(validation_targets$units <= threshold),
      numeric(1)
    )
    predicted_cdf <- predicted_cdf_sum / nrow(validation_targets)
    observed_100_plus <- validation_targets$units >= 100L
    observed_exact_99 <- validation_targets$units == 99L
    validation_metrics <- tibble(
      metric = c(
        "rounded_negative_log_score",
        "brier_at_least_100",
        "cdf_rmse_80_120",
        "absolute_100_plus_share_error",
        "absolute_exact_99_share_error"
      ),
      value = c(
        -mean(log(pmax(parent_predictions$probability_observed, 1e-300))),
        mean((
          observed_100_plus -
            parent_predictions$probability_at_least_100
        )^2),
        sqrt(mean((predicted_cdf - observed_cdf)^2)),
        abs(
          mean(parent_predictions$probability_at_least_100) -
            mean(observed_100_plus)
        ),
        abs(
          mean(parent_predictions$probability_exact_99) -
            mean(observed_exact_99)
        )
      )
    )

    validation_rows[[length(validation_rows) + 1L]] <-
      validation_metrics |>
      mutate(
        model_id = model_specification$model_id,
        model_label = model_specification$model_label,
        training_definition = model_specification$training_definition,
        training_start_year = model_specification$training_start_year,
        training_end_year,
        test_year,
        training_rows = nrow(training_rows),
        validation_parents = nrow(validation_targets),
        shock_sigma = fitted_model$sigma,
        .before = 1L
      )
  }
}

validation_metrics <- bind_rows(validation_rows) |>
  arrange(metric, test_year, model_id)

validation_summary <- validation_metrics |>
  group_by(
    model_id, model_label, training_definition,
    training_start_year, metric
  ) |>
  summarise(
    mean_value = mean(value),
    minimum_value = min(value),
    maximum_value = max(value),
    validation_windows = n(),
    .groups = "drop"
  ) |>
  group_by(metric) |>
  mutate(rank = rank(mean_value, ties.method = "min")) |>
  ungroup() |>
  arrange(metric, rank, model_id)

final_parameter_rows <- list()
final_score_rows <- list()
final_distribution_rows <- list()
counterfactual_rows <- list()

for (model_row in seq_len(nrow(models))) {
  model_specification <- models[model_row, ]
  training_rows <- historical_panel |>
    filter(
      definition == model_specification$training_definition,
      model_eligible,
      filing_year >= model_specification$training_start_year,
      date_last_filed <= as.Date("2023-12-31")
    )

  if (model_specification$scoring_mode == "filing_components") {
    score_rows <- post_filing_rows
  } else {
    score_rows <- post_enhanced_targets |>
      mutate(target_parent_id = parent_id)
  }

  fitted_model <- fit_rounded_mle(
    training_rows,
    score_rows,
    min_units,
    model_formula
  )

  final_parameter_rows[[length(final_parameter_rows) + 1L]] <- tibble(
    model_id = model_specification$model_id,
    model_label = model_specification$model_label,
    training_definition = model_specification$training_definition,
    training_start_year = model_specification$training_start_year,
    training_end_year = 2023L,
    training_rows = nrow(training_rows),
    training_year_mean = fitted_model$training_year_mean,
    term = c(names(fitted_model$coefficients), "shock_sigma"),
    estimate = c(fitted_model$coefficients, fitted_model$sigma)
  )

  scored_rows <- score_rows |>
    mutate(predicted_log_units = fitted_model$test_mu)

  if (model_specification$scoring_mode == "filing_components") {
    scored_rows <- scored_rows |>
      select(job_number, predicted_log_units) |>
      left_join(
        post_target_members |>
          filter(target_parent_id %in% post_enhanced_targets$parent_id),
        by = "job_number",
        relationship = "one-to-one"
      ) |>
      filter(!is.na(target_parent_id))
  }

  parent_mu <- split(
    scored_rows$predicted_log_units,
    scored_rows$target_parent_id
  )
  model_scores <- vector("list", nrow(post_enhanced_targets))
  model_distribution <- numeric(counterfactual_max_units + 1L)

  for (target_row in seq_len(nrow(post_enhanced_targets))) {
    target <- post_enhanced_targets[target_row, ]
    upper_units <- max(counterfactual_max_units, target$units)
    distribution <- parent_distribution(
      parent_mu[[target$parent_id]],
      fitted_model$sigma,
      upper_units
    )
    model_distribution <- model_distribution +
      distribution[seq_len(counterfactual_max_units + 1L)]
    model_scores[[target_row]] <- tibble(
      model_id = model_specification$model_id,
      model_label = model_specification$model_label,
      evaluation_unit = "enhanced_parent",
      observation_id = target$parent_id,
      observed_units = target$units,
      component_filings = target$component_filings,
      probability_observed = distribution[target$units + 1L],
      probability_exact_99 = distribution[100L],
      probability_at_least_100 = 1 - sum(distribution[seq_len(100L)])
    )
  }

  model_scores <- bind_rows(model_scores)
  observed_distribution <- tabulate(
    post_enhanced_targets$units + 1L,
    nbins = counterfactual_max_units + 1L
  )
  model_distribution_output <- tibble(
    model_id = model_specification$model_id,
    model_label = model_specification$model_label,
    evaluation_unit = "enhanced_parent",
    units = min_units:counterfactual_max_units,
    expected_count = model_distribution[
      (min_units:counterfactual_max_units) + 1L
    ],
    observed_count = observed_distribution[
      (min_units:counterfactual_max_units) + 1L
    ]
  )
  observed_exact_99 <- sum(model_scores$observed_units == 99L)
  expected_exact_99 <- sum(model_scores$probability_exact_99)
  observed_100_plus <- sum(model_scores$observed_units >= 100L)
  expected_100_plus <- sum(model_scores$probability_at_least_100)
  excess_exact_99 <- observed_exact_99 - expected_exact_99
  missing_100_plus <- expected_100_plus - observed_100_plus

  final_score_rows[[length(final_score_rows) + 1L]] <- model_scores
  final_distribution_rows[[length(final_distribution_rows) + 1L]] <-
    model_distribution_output
  counterfactual_rows[[length(counterfactual_rows) + 1L]] <- tibble(
    model_id = model_specification$model_id,
    model_label = model_specification$model_label,
    evaluation_unit = "enhanced_parent",
    scoreable_observations = nrow(model_scores),
    component_filings = sum(model_scores$component_filings),
    observed_exact_99,
    expected_no_notch_exact_99 = expected_exact_99,
    excess_exact_99,
    observed_100_plus,
    expected_no_notch_100_plus = expected_100_plus,
    missing_100_plus,
    conservation_gap = excess_exact_99 - missing_100_plus,
    frontier_from_exact_99 = solve_discrete_frontier(
      excess_exact_99,
      model_distribution_output
    ),
    frontier_from_missing_100_plus = solve_discrete_frontier(
      missing_100_plus,
      model_distribution_output
    ),
    shock_sigma = fitted_model$sigma
  )

  if (model_specification$model_id == "filing_2010_2023") {
    individual_scores <- score_rows |>
      mutate(
        model_id = "filing_2010_2023_individual",
        model_label = "Filing model, 2010-23 (individual filings)",
        evaluation_unit = "filing",
        observation_id = observation_id,
        observed_units = units,
        component_filings = 1L,
        probability_observed = exp(rounded_conditional_log_probability(
          units,
          fitted_model$test_mu,
          fitted_model$sigma,
          min_units
        )),
        probability_exact_99 = exp(rounded_conditional_log_probability(
          rep(99L, n()),
          fitted_model$test_mu,
          fitted_model$sigma,
          min_units
        )),
        probability_at_least_100 = exp(
          pnorm(
            (log(99.5) - fitted_model$test_mu) / fitted_model$sigma,
            lower.tail = FALSE,
            log.p = TRUE
          ) - pnorm(
            (log(min_units - 0.5) - fitted_model$test_mu) /
              fitted_model$sigma,
            lower.tail = FALSE,
            log.p = TRUE
          )
        )
      ) |>
      select(
        model_id, model_label, evaluation_unit, observation_id,
        observed_units, component_filings, probability_observed,
        probability_exact_99, probability_at_least_100
      )
    individual_distribution <- numeric(counterfactual_max_units + 1L)

    for (filing_row in seq_len(nrow(score_rows))) {
      individual_distribution <- individual_distribution +
        component_distribution(
          fitted_model$test_mu[filing_row],
          fitted_model$sigma,
          counterfactual_max_units
        )
    }

    individual_observed_distribution <- tabulate(
      score_rows$units + 1L,
      nbins = counterfactual_max_units + 1L
    )
    individual_distribution_output <- tibble(
      model_id = "filing_2010_2023_individual",
      model_label = "Filing model, 2010-23 (individual filings)",
      evaluation_unit = "filing",
      units = min_units:counterfactual_max_units,
      expected_count = individual_distribution[
        (min_units:counterfactual_max_units) + 1L
      ],
      observed_count = individual_observed_distribution[
        (min_units:counterfactual_max_units) + 1L
      ]
    )
    individual_observed_exact_99 <- sum(individual_scores$observed_units == 99L)
    individual_expected_exact_99 <- sum(
      individual_scores$probability_exact_99
    )
    individual_observed_100_plus <- sum(
      individual_scores$observed_units >= 100L
    )
    individual_expected_100_plus <- sum(
      individual_scores$probability_at_least_100
    )
    individual_excess_exact_99 <-
      individual_observed_exact_99 - individual_expected_exact_99
    individual_missing_100_plus <-
      individual_expected_100_plus - individual_observed_100_plus

    final_score_rows[[length(final_score_rows) + 1L]] <- individual_scores
    final_distribution_rows[[length(final_distribution_rows) + 1L]] <-
      individual_distribution_output
    counterfactual_rows[[length(counterfactual_rows) + 1L]] <- tibble(
      model_id = "filing_2010_2023_individual",
      model_label = "Filing model, 2010-23 (individual filings)",
      evaluation_unit = "filing",
      scoreable_observations = nrow(individual_scores),
      component_filings = nrow(individual_scores),
      observed_exact_99 = individual_observed_exact_99,
      expected_no_notch_exact_99 = individual_expected_exact_99,
      excess_exact_99 = individual_excess_exact_99,
      observed_100_plus = individual_observed_100_plus,
      expected_no_notch_100_plus = individual_expected_100_plus,
      missing_100_plus = individual_missing_100_plus,
      conservation_gap =
        individual_excess_exact_99 - individual_missing_100_plus,
      frontier_from_exact_99 = solve_discrete_frontier(
        individual_excess_exact_99,
        individual_distribution_output
      ),
      frontier_from_missing_100_plus = solve_discrete_frontier(
        individual_missing_100_plus,
        individual_distribution_output
      ),
      shock_sigma = fitted_model$sigma
    )
  }
}

final_parameters <- bind_rows(final_parameter_rows) |>
  arrange(model_id, term)
final_scores <- bind_rows(final_score_rows) |>
  arrange(model_id, observation_id)
final_distribution <- bind_rows(final_distribution_rows) |>
  arrange(model_id, units)
counterfactual <- bind_rows(counterfactual_rows) |>
  arrange(evaluation_unit, model_id)

if (
  n_distinct(validation_metrics$model_id) != nrow(models) ||
    n_distinct(validation_metrics$test_year) != 3L ||
    any(!is.finite(validation_metrics$value)) ||
    n_distinct(final_parameters$model_id) != nrow(models) ||
    n_distinct(counterfactual$model_id) != nrow(models) + 1L ||
    any(final_scores$probability_observed < 0) ||
    any(final_scores$probability_exact_99 < 0) ||
    any(final_scores$probability_at_least_100 < 0) ||
    any(final_scores$probability_at_least_100 > 1 + 1e-10)
) {
  stop("Parent-model comparison outputs failed final QC.")
}

plot_rows <- bind_rows(
  validation_summary |>
    filter(metric %in% c(
      "rounded_negative_log_score",
      "brier_at_least_100",
      "cdf_rmse_80_120"
    )) |>
    transmute(
      model_label,
      panel = recode(
        metric,
        rounded_negative_log_score = "Validation: rounded log score",
        brier_at_least_100 = "Validation: Brier score at 100",
        cdf_rmse_80_120 = "Validation: CDF RMSE, 80-120"
      ),
      value = mean_value
    ),
  counterfactual |>
    transmute(
      model_label,
      panel = "2025: exact-99 excess",
      value = excess_exact_99
    ),
  counterfactual |>
    transmute(
      model_label,
      panel = "2025: missing mass at 100+",
      value = missing_100_plus
    ),
  counterfactual |>
    transmute(
      model_label,
      panel = "2025: absolute conservation gap",
      value = abs(conservation_gap)
    )
) |>
  mutate(
    model_label = factor(
      model_label,
      levels = rev(c(
        "Filing model, 2010-23 (individual filings)",
        models$model_label
      ))
    )
  )

comparison_plot <- ggplot(plot_rows, aes(x = value, y = model_label)) +
  geom_point(color = "#1769AA", size = 2.1) +
  facet_wrap(vars(panel), scales = "free_x", ncol = 2L) +
  scale_x_continuous(expand = expansion(mult = c(0.03, 0.08))) +
  labs(
    title = "Parent aggregation and parent estimation are separate changes",
    subtitle = paste0(
      "Validation uses common enhanced-parent outcomes in 2021-23; ",
      "2025 uses the common scoreable parent sample"
    ),
    x = NULL,
    y = NULL,
    caption = paste0(
      "Lower is better for validation scores and the absolute gap; the other ",
      "2025 panels report its two components. Parent links use conservative ",
      "signals plus corroborated exact adjacency, with no pre-2019 adjacency ",
      "imputation."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.title.position = "plot",
    strip.text = element_text(face = "bold"),
    axis.text.y = element_text(size = 8.5)
  )

write_csv_if_changed(
  validation_metrics,
  "../output/parent_model_validation_metrics.csv"
)
write_csv_if_changed(
  validation_summary,
  "../output/parent_model_validation_summary.csv"
)
write_csv_if_changed(
  final_parameters,
  "../output/parent_model_final_parameters.csv"
)
write_parquet_if_changed(
  final_scores,
  "../output/parent_model_2025_scores.parquet"
)
write_csv_if_changed(
  counterfactual,
  "../output/parent_model_2025_counterfactual.csv"
)
write_csv_if_changed(
  final_distribution,
  "../output/parent_model_2025_distribution.csv"
)
ggsave(
  "../output/parent_model_comparison.pdf",
  comparison_plot,
  width = 11,
  height = 10,
  bg = "white"
)
ggsave(
  "../output/parent_model_comparison.png",
  comparison_plot,
  width = 11,
  height = 10,
  dpi = 220,
  bg = "white"
)

cat("Wrote parent model validation and 2025 comparison outputs to ../output\n")

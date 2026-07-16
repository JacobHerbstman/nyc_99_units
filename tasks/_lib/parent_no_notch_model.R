prepare_train_test <- function(
    train_data, test_data, minimum_category_rows) {
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

fit_rounded_mle <- function(
    train_raw, test_raw, training_floor, minimum_category_rows, formula) {
  prepared <- prepare_train_test(
    train_raw,
    test_raw,
    minimum_category_rows
  )
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

unit_distribution <- function(
    predicted_log_units, sigma, lower_units, upper_units) {
  unit_grid <- lower_units:upper_units
  probability <- exp(rounded_conditional_log_probability(
    unit_grid,
    rep(predicted_log_units, length(unit_grid)),
    sigma,
    lower_units
  ))
  distribution <- numeric(upper_units + 1L)
  distribution[unit_grid + 1L] <- probability
  distribution
}

solve_discrete_frontier <- function(
    target_mass, expected_distribution, threshold_units) {
  frontier_distribution <- expected_distribution |>
    filter(units >= threshold_units) |>
    arrange(units)

  if (
    !is.finite(target_mass) ||
      target_mass < 0 ||
      target_mass > sum(frontier_distribution$expected_count)
  ) {
    return(NA_real_)
  }

  if (target_mass == 0) {
    return(threshold_units - 0.5)
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

implied_affected_mean <- function(
    target_mass, expected_distribution, threshold_units) {
  if (!is.finite(target_mass) || target_mass <= 0) {
    return(NA_real_)
  }

  affected_distribution <- expected_distribution |>
    filter(units >= threshold_units) |>
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

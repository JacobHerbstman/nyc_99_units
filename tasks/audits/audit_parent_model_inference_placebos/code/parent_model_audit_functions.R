expected_unit_distribution <- function(
    predicted_log_units, sigma, min_units, max_units) {
  expected_count <- numeric(max_units + 1L)

  for (row in seq_along(predicted_log_units)) {
    expected_count <- expected_count + unit_distribution(
      predicted_log_units[row],
      sigma,
      min_units,
      max_units
    )
  }

  tibble(
    units = min_units:max_units,
    expected_count = expected_count[(min_units:max_units) + 1L]
  )
}

no_notch_moments <- function(
    observed_units, predicted_log_units, sigma, expected_distribution,
    min_units, threshold_units) {
  bunch_units <- threshold_units - 1L
  expected_exact <- sum(exp(rounded_conditional_log_probability(
    rep(bunch_units, length(predicted_log_units)),
    predicted_log_units,
    sigma,
    min_units
  )))
  expected_above <- sum(exp(
    pnorm(
      (log(threshold_units - 0.5) - predicted_log_units) / sigma,
      lower.tail = FALSE,
      log.p = TRUE
    ) - pnorm(
      (log(min_units - 0.5) - predicted_log_units) / sigma,
      lower.tail = FALSE,
      log.p = TRUE
    )
  ))
  observed_exact <- sum(observed_units == bunch_units)
  observed_above <- sum(observed_units >= threshold_units)
  excess_exact <- observed_exact - expected_exact
  missing_above <- expected_above - observed_above

  tibble(
    threshold_units,
    bunch_units,
    scoreable_parents = length(observed_units),
    observed_exact_bunch_units = observed_exact,
    expected_no_notch_exact_bunch_units = expected_exact,
    excess_exact_bunch_units = excess_exact,
    observed_at_or_above_threshold = observed_above,
    expected_no_notch_at_or_above_threshold = expected_above,
    missing_at_or_above_threshold = missing_above,
    conservation_gap = excess_exact - missing_above,
    frontier_from_exact_bunch_units = solve_discrete_frontier(
      excess_exact,
      expected_distribution,
      threshold_units
    ),
    frontier_from_missing_above = solve_discrete_frontier(
      missing_above,
      expected_distribution,
      threshold_units
    ),
    mean_n0_from_exact_bunch_units = implied_affected_mean(
      excess_exact,
      expected_distribution,
      threshold_units
    ),
    mean_n0_from_missing_above = implied_affected_mean(
      missing_above,
      expected_distribution,
      threshold_units
    ),
    shock_sigma = sigma
  )
}

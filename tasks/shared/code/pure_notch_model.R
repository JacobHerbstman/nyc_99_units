# Pure-notch size/organization model, used by the pilot and numerical checks.
# Costs are normalized by ordinary-profit scale A; every constituent has >=1 unit.

ordinary_size_loss <- function(m, x, lambda = 1) {
  if (lambda == 1) return(((m - x) / 99)^2)
  ifelse(m == x, 0, (m / 99)^(1 + lambda) + lambda * (x / 99)^(1 + lambda) -
    (1 + lambda) * (x / 99)^lambda * (m / 99))
}

notch_choices <- function(x, kappa, lambda = 1, J_cap = 6L, assessment = "separate") {
  stopifnot(all(x >= 1 & x == floor(x)), kappa >= 0, lambda > 0,
            J_cap >= 1, assessment %in% c("separate", "joint"))
  choices <- expand.grid(i = seq_along(x), J = seq_len(J_cap))
  choices$x <- x[choices$i]
  capacity <- if (assessment == "separate") 99 * choices$J else 99
  # For m above capacity the burden is flat, so its best total is max(x,J).
  crossing_total <- pmax(choices$x, choices$J, capacity + 1)
  crossing_loss <- ordinary_size_loss(crossing_total, choices$x, lambda) + kappa
  exempt_total <- pmin(pmax(choices$x, choices$J), capacity)
  exempt_loss <- ordinary_size_loss(exempt_total, choices$x, lambda)
  exempt_loss[capacity < choices$J] <- Inf
  # Equal losses: retain the size closest to x; on any remaining tie take smaller m.
  exempt <- exempt_loss < crossing_loss |
    (exempt_loss == crossing_loss &
       abs(exempt_total - choices$x) <= abs(crossing_total - choices$x))
  choices$m <- ifelse(exempt, exempt_total, crossing_total)
  choices$R <- ifelse(exempt, exempt_loss, crossing_loss)
  choices$total_tie <- exempt_loss == crossing_loss
  choices$minimum_crossers <- as.integer(choices$m > capacity)
  choices
}

organization_probabilities <- function(R, J0, sigma_org) {
  stopifnot(sigma_org > 0, is.finite(R[J0]))
  p <- numeric(length(R))
  alternatives <- setdiff(which(is.finite(R)), J0)
  p[J0] <- exp(-sum(pmax(R[J0] - R[alternatives], 0)) / sigma_org)
  cuts <- sort(unique(c(R[alternatives][R[alternatives] < R[J0]], R[J0])))
  # Integrate the survival curve between successive alternative starting costs.
  # All active alternatives have the same exponential hazard, hence equal shares.
  if (length(cuts) > 1) for (h in seq_len(length(cuts) - 1)) {
    a <- cuts[h]
    b <- cuts[h + 1]
    active <- alternatives[R[alternatives] <= a]
    log_survival_a <- -sum(pmax(a - R[alternatives], 0)) / sigma_org
    interval_mass <- exp(log_survival_a) *
      (-expm1(-length(active) * (b - a) / sigma_org))
    p[active] <- p[active] + interval_mass / length(active)
  }
  stopifnot(all(is.finite(p)), all(p >= 0), abs(sum(p) - 1) < 1e-12)
  p
}

notch_predictions <- function(choices, J0, weights, sigma_org) {
  n <- length(J0)
  stopifnot(n == max(choices$i), length(weights) == n,
            all(J0 >= 1 & J0 <= max(choices$J)), all(is.finite(weights)), all(weights >= 0))
  losses <- matrix(choices$R, nrow = n)
  probabilities <- t(vapply(seq_len(n), function(i) {
    organization_probabilities(losses[i, ], J0[i], sigma_org)
  }, numeric(ncol(losses))))
  choices$J0 <- J0[choices$i]
  choices$probability <- as.vector(probabilities)
  choices$mass <- weights[choices$i] * choices$probability
  stopifnot(abs(sum(choices$mass) - sum(weights)) < 1e-12)
  choices
}

notch_size_bins <- c("under 50", "50–89", "90–94", "95–98", "99", "100–104",
                     "105–119", "120–149", "150–179", "180–197", "198", "199",
                     "200–249", "250–300", "301+")

notch_joint_shares <- function(m, J, weight) {
  size_bin <- cut(m, c(-Inf, 49, 89, 94, 98, 99, 104, 119, 149, 179, 197,
                       198, 199, 249, 300, Inf), labels = FALSE)
  cell <- size_bin + 15L * (pmin(J, 3L) - 1L)
  shares <- numeric(45L)
  totals <- rowsum(weight, cell, reorder = FALSE)
  shares[as.integer(rownames(totals))] <- totals[, 1]
  stopifnot(abs(sum(shares) - sum(weight)) < 1e-12)
  shares
}

# A representative is bookkeeping, not a prediction of layout when minimizers tie.
notch_partition <- function(m, J, historical_vector, kappa, assessment) {
  max_crossers <- if (assessment == "separate") as.integer(m > 99 * J) else J
  preserve <- length(historical_vector) == J && sum(historical_vector) == m &&
    (kappa == 0 || sum(historical_vector >= 100) == max_crossers || assessment == "joint")
  if (preserve) return(sort(historical_vector, decreasing = TRUE))
  if (kappa == 0 || assessment == "joint" || m > 99 * J) {
    return(c(m - J + 1L, rep(1L, J - 1L)))
  }
  # Fill exempt constituents up to 99, leaving at least one unit for the rest.
  units <- rep(1L, J)
  remaining <- m - J
  for (j in seq_len(J)) {
    extra <- min(98L, remaining)
    units[j] <- units[j] + extra
    remaining <- remaining - extra
  }
  units
}

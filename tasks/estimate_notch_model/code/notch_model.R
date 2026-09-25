# The developer's size and organization choice under the 485-x threshold
# (framework_writeup.tex, section 3 and appendices B-C). A historical parent
# with preferred total x and building count J0 chooses total units m and
# buildings J. Every cost is divided by the parent's ordinary cost of 99 units,
# so the parameters are ratios common to all parents:
#   size loss       l(m; x): ordinary profit given up by building m instead of x
#   policy burden   kappa + tau * [(n / 99)^(1 + lambda) - (100 / 99)^(1 + lambda)]
#                   for each separately assessed building with n >= 100 units
#   splitting cost  c * k^gamma for k buildings beyond the historical count,
#                   with c drawn for each parent from an exponential distribution
#                   with mean sigma; gamma > 1 makes each added building cost
#                   more than the last.
# Layouts within a parent are free, and each building has at least one unit.

# The loss is zero at m = x and positive elsewhere; set that zero exactly, since
# rounding would otherwise make untouched parents look affected.
size_loss <- function(m, x, lambda) {
  if (lambda == 1) return(((m - x) / 99)^2)
  loss <- (m / 99)^(1 + lambda) + lambda * (x / 99)^(1 + lambda) -
    (1 + lambda) * (x / 99)^lambda * (m / 99)
  ifelse(m == x, 0, pmax(loss, 0))
}

scaled_power <- function(n, lambda) (n / 99)^(1 + lambda)

building_burden <- function(n, kappa, tau, lambda) {
  ifelse(n >= 100, kappa + tau * (scaled_power(n, lambda) - scaled_power(100, lambda)), 0)
}

# Lowest burden of m units in J buildings, for every J and m. Above 99J units,
# k buildings cross 100: the others hold 99 each, and because the burden is
# convex the crossing buildings split the rest as evenly as possible. Under
# joint assessment the parent's total is assessed once, whatever J is.
burden_table <- function(max_units, max_buildings, kappa, tau, lambda, assessment) {
  m <- seq_len(max_units)
  if (assessment == "joint") {
    table <- matrix(building_burden(m, kappa, tau, lambda), max_buildings, max_units, byrow = TRUE)
  } else {
    table <- matrix(Inf, max_buildings, max_units)
    for (J in seq_len(max_buildings)) {
      best <- ifelse(m <= 99 * J, 0, Inf)
      for (k in seq_len(J)) {
        crossing_units <- m - 99 * (J - k)
        feasible <- m > 99 * J & crossing_units >= 100 * k
        base <- crossing_units %/% k
        larger <- crossing_units %% k
        burden <- k * kappa + tau * (larger * scaled_power(base + 1, lambda) +
          (k - larger) * scaled_power(base, lambda) - k * scaled_power(100, lambda))
        best[feasible] <- pmin(best[feasible], burden[feasible])
      }
      table[J, ] <- best
    }
  }
  table[col(table) < row(table)] <- Inf
  table
}

# Every (parent, J, m) the size choice needs. The burden never falls as m
# rises, so the best total lies between the largest burden-free total and x.
# Building counts run to ceiling(x / 99), where the burden is already zero;
# more buildings cannot help. Joint assessment gains nothing from any J.
size_candidates <- function(x, J0, lambda, assessment) {
  J_max <- if (assessment == "joint") J0 else pmax(J0, ceiling(x / 99))
  choices <- data.frame(i = rep(seq_along(x), J_max), x = rep(x, J_max), J = sequence(J_max))
  capacity <- if (assessment == "joint") 99 else 99 * choices$J
  choices$choice <- seq_len(nrow(choices))
  lower <- pmin(choices$x, capacity)
  width <- choices$x - lower + 1L
  candidates <- choices[rep(choices$choice, width), ]
  candidates$m <- rep(lower, width) + sequence(width) - 1L
  candidates$loss <- size_loss(candidates$m, candidates$x, lambda)
  candidates
}

# For each parent and J, the best total and its cost R. Ties keep the total
# closest to x.
choose_sizes <- function(candidates, burden) {
  cost <- candidates$loss + burden[cbind(candidates$J, candidates$m)]
  first <- order(candidates$choice, cost, -candidates$m)
  first <- first[!duplicated(candidates$choice[first])]
  data.frame(i = candidates$i[first], J = candidates$J[first],
             m = candidates$m[first], R = cost[first])
}

# Which J a parent chooses, as a function of its splitting cost c. Each J is a
# line R_J + c * (J - J0)^gamma in c; the parent takes the lowest line, so each J
# owns an interval of c. Fewer buildings than J0 is never chosen: it raises
# the burden and costs c, so those lines are dropped.
cost_intervals <- function(R, slope) {
  current <- which(R == min(R))
  current <- current[which.min(slope[current])]
  from <- 0
  chosen <- integer(0); lower <- numeric(0); upper <- numeric(0)
  repeat {
    if (slope[current] == 0) {
      chosen <- c(chosen, current); lower <- c(lower, from); upper <- c(upper, Inf)
      break
    }
    flatter <- which(slope < slope[current])
    crossing <- (R[flatter] - R[current]) / (slope[current] - slope[flatter])
    next_from <- min(crossing)
    successors <- flatter[crossing == next_from]
    chosen <- c(chosen, current); lower <- c(lower, from); upper <- c(upper, next_from)
    from <- next_from
    current <- successors[which.min(slope[successors])]
  }
  keep <- upper > lower
  data.frame(line = chosen[keep], lower = lower[keep], upper = upper[keep])
}

# A parent the burden does not touch keeps its historical outcome for every c.
organization_segments <- function(sizes, J0, gamma) {
  sizes <- sizes[sizes$J >= J0[sizes$i], ]
  baseline <- sizes[sizes$J == J0[sizes$i], ]
  unaffected <- baseline[baseline$R == 0, c("i", "J", "m")]
  unaffected$lower <- rep(0, nrow(unaffected))
  unaffected$upper <- rep(Inf, nrow(unaffected))
  affected <- sizes[sizes$i %in% baseline$i[baseline$R > 0], ]
  segments <- lapply(split(affected, affected$i), function(parent) {
    intervals <- cost_intervals(parent$R, (parent$J - J0[parent$i[1]])^gamma)
    cbind(parent[intervals$line, c("i", "J", "m")], intervals[c("lower", "upper")])
  })
  rbind(unaffected, do.call(rbind, segments))
}

# Probability of each segment for every splitting-cost mean in sigma.
segment_probabilities <- function(segments, sigma) {
  exp(-outer(segments$lower, 1 / sigma)) - exp(-outer(segments$upper, 1 / sigma))
}

# The parameter grid of the fit and the bootstrap.
kappa_grid <- c(0, 0.0025, 0.005, seq(0.01, 0.1, by = 0.01), seq(0.12, 0.3, by = 0.02),
  0.35, 0.4, 0.5, 0.6, 0.8, 1)
tau_grid <- c(0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 0.8, 1)
gamma_grid <- c(1, 1.25, 1.5, 1.75, 2, 2.5, 3)
sigma_grid <- exp(seq(log(0.001), log(10), length.out = 41))

# Parent-size bins and building groups (1, 2, 3+) define 45 disjoint cells.
size_bins <- c(-Inf, 49, 89, 94, 98, 99, 104, 119, 149, 179, 197, 198, 199, 249, 300, Inf)
size_bin_labels <- c("under 50", "50-89", "90-94", "95-98", "99", "100-104", "105-119",
  "120-149", "150-179", "180-197", "198", "199", "200-249", "250-300", "301+")

# Cells whose whole size bin lies at or below a maximum total.
cells_up_to <- function(maximum_units) which(rep(size_bins[-1], 3) <= maximum_units)

outcome_cell <- function(m, J) {
  cut(m, size_bins, labels = FALSE) + 15L * (pmin(J, 3L) - 1L)
}

cell_shares <- function(cell, mass) {
  shares <- matrix(0, 45, ncol(mass))
  totals <- rowsum(mass, cell)
  shares[as.integer(rownames(totals)), ] <- totals
  shares
}

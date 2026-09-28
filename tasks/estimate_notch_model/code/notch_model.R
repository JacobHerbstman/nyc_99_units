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

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(tidyr)
})

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

# The likelihood leaves a share epsilon of recorded recent outcomes unexplained,
# spread uniformly over sizes 50 to the compared maximum and 1, 2 or 3+
# buildings.
epsilon_grid <- c(0.001, 0.0025, 0.005, 0.0075, 0.01, 0.015, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2)
unexplained_shares <- function(cells) {
  width <- rep(pmax(0, size_bins[-1] - pmax(head(size_bins, -1), 49)), 3)[cells]
  width / sum(width)
}

# Burdens that differ across parents: the jump, or the whole burden at a fixed
# kink-to-jump ratio, is lognormal with a median on kappa_grid and log standard
# deviation on dispersion_grid (0 is a single burden). The distribution sits on
# kappa_grid extended to 5, where every parent of at most 300 units avoids 100:
# each value takes the probability between the midpoints to its neighbors, so a
# prediction is a weighted average of predictions at single burdens.
kappa_values <- c(kappa_grid, 1.5, 2, 3, 5)
ratio_grid <- c(0, 0.1, 0.2, 0.3, 0.5, 0.75, 1, 1.5, 2, 3, 5, 8)
dispersion_grid <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 4)
burden_distributions <- bind_rows(tibble(median = kappa_values, dispersion = 0),
  expand_grid(median = kappa_grid[kappa_grid > 0], dispersion = dispersion_grid[-1]))
burden_mass <- local({
  edges <- c(-Inf, head(kappa_values, -1) + diff(kappa_values) / 2, Inf)
  t(mapply(function(median, dispersion) {
    if (dispersion == 0) as.numeric(kappa_values == median) else diff(plnorm(edges, log(median), dispersion))
  }, burden_distributions$median, burden_distributions$dispersion))
})
stopifnot(all(abs(rowSums(burden_mass) - 1) < 1e-12))

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

# Bootstrap samples as matrices: historical weights (parents in the order of
# historical, by draws) and recent parents' cell counts (cells by draws).
bootstrap_weights <- function(samples, historical) {
  historical |>
    select(parent_id) |>
    left_join(samples |> filter(sample == "historical") |>
      pivot_wider(id_cols = parent_id, names_from = draw, values_from = weight, values_fill = 0),
      by = "parent_id", relationship = "one-to-one") |>
    select(as.character(sort(unique(samples$draw)))) |>
    as.matrix()
}
bootstrap_counts <- function(samples, post, cells) {
  samples |>
    filter(sample == "post_policy") |>
    inner_join(post |> select(parent_id, units, buildings), by = "parent_id", relationship = "many-to-one") |>
    mutate(cell = match(outcome_cell(units, buildings), cells)) |>
    filter(!is.na(cell)) |>
    count(draw, cell, wt = weight) |>
    complete(draw = sort(unique(samples$draw)), cell = seq_along(cells), fill = list(n = 0)) |>
    arrange(cell, draw) |>
    pull(n) |>
    matrix(nrow = length(cells), byrow = TRUE)
}

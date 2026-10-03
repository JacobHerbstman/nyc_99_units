# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
})
source("notch_model.R")
source("../../shared/code/write_data_report.R")

# Checks from framework_writeup.tex, appendix C: the model reproduces
# historical outcomes without the burden, matches the one-building rule,
# matches exhaustive partitions, and its menu bound never binds.
historical <- read_parquet("../output/estimation_parents.parquet") |>
  filter(variant == "all_filings", sample == "historical")
x <- historical$units
J0 <- historical$buildings
checks <- list()
record <- function(check, passed, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(check = check, passed = passed, detail = detail)
}

solve <- function(x, J0, kappa, lambda = 1, assessment = "separate") {
  candidates <- size_candidates(x, J0, lambda, assessment)
  burden <- burden_table(max(x), max(candidates$J), kappa, assessment)
  choose_sizes(candidates, burden)
}

# 1. Without the burden every parent keeps its total and building count, at
# every curvature.
zero_ok <- all(sapply(c(0.5, 1, 2), function(lambda) {
  segments <- organization_segments(solve(x, J0, 0, lambda), J0, 1)
  nrow(segments) == length(x) && all(segments$m == x[segments$i]) &&
    all(segments$J == J0[segments$i]) && all(segments$lower == 0 & is.infinite(segments$upper))
}))
record("zero burden keeps historical outcomes", zero_ok,
  paste(length(x), "historical parents; lambda = 0.5, 1, 2"))

# 2. One building, lambda = 1: shrink to 99 exactly when
# x <= 99 + 99 * sqrt(kappa); above that keep x and pay.
one_building <- 100:450
single_ok <- all(sapply(c(0.02, 0.1, 0.4), function(kappa) {
  s <- solve(one_building, rep(1L, length(one_building)), kappa)
  s <- s[s$J == 1, ]
  expected <- ifelse(one_building <= 99 + 99 * sqrt(kappa), 99, one_building)
  all(s$m == expected)
}))
record("one building matches the notch rule", single_ok, "x = 100-450, kappa = 0.02, 0.1, 0.4")

# 3. Minimum burdens match exhaustive partitions for two and three buildings.
jump <- function(n, kappa) kappa * (n >= 100)
exhaustive <- function(m, J, kappa) {
  if (J == 2) {
    n <- 1:(m - 1)
    return(min(jump(n, kappa) + jump(m - n, kappa)))
  }
  best <- Inf
  for (a in 1:(m - 2)) {
    b <- 1:(m - a - 1)
    best <- min(best, jump(a, kappa) + min(jump(b, kappa) + jump(m - a - b, kappa)))
  }
  best
}
partition_ok <- TRUE
for (kappa in c(0.02, 0.1, 0.3)) {
  table <- burden_table(500, 3, kappa, "separate")
  for (m in c(2:500)) partition_ok <- partition_ok && abs(table[2, m] - exhaustive(m, 2, kappa)) < 1e-12
  for (m in seq(3, 500, by = 7)) partition_ok <- partition_ok && abs(table[3, m] - exhaustive(m, 3, kappa)) < 1e-12
}
record("burdens match exhaustive partitions", partition_ok, "J = 2 for m = 2-500; J = 3 every 7th m")

# 4. The menu bound does not bind: at ceiling(x / 99) buildings the burden is
# zero, so no larger count can lower cost.
sizes <- solve(x, J0, 0.1)
at_bound <- sizes[sizes$J == pmax(J0, ceiling(x / 99))[sizes$i], ]
record("menu bound does not bind", nrow(at_bound) == length(x) && all(at_bound$R == 0),
  "cost is zero at the largest building count offered")

# 5. Fewer buildings than J0 never costs less before the splitting cost.
below <- merge(sizes[sizes$J < J0[sizes$i], ], sizes[sizes$J == J0[sizes$i], c("i", "R")],
  by = "i", suffixes = c("", "_baseline"))
record("consolidation never lowers the burden", all(below$R >= below$R_baseline),
  paste(nrow(below), "parent-count pairs below J0"))

# 6. Choice probabilities sum to one and match simulated cost draws.
segments <- organization_segments(sizes, J0, 1)
probabilities <- segment_probabilities(segments, c(0.02, 0.2, 2))
sums <- rowsum(probabilities, segments$i)
set.seed(20260924)
simulated_ok <- all(sapply(c(1, 1.5, 2.5), function(gamma) {
  segments <- organization_segments(sizes, J0, gamma)
  probabilities <- segment_probabilities(segments, 0.2)
  affected <- unique(segments$i[segments$lower > 0])[1:20]
  all(sapply(affected, function(parent) {
    s <- sizes[sizes$i == parent & sizes$J >= J0[parent], ]
    draws <- rexp(2e5, rate = 1 / 0.2)
    total <- outer(draws, (s$J - J0[parent])^gamma) + rep(s$R, each = length(draws))
    simulated <- tabulate(max.col(-total, ties.method = "first"), nrow(s)) / length(draws)
    analytic <- sapply(s$J, function(j) sum(probabilities[segments$i == parent & segments$J == j]))
    max(abs(simulated - analytic)) < 0.01
  }))
}))
mass_ok <- all(sapply(c(0.5, 2), function(lambda) {
  s <- organization_segments(solve(x, J0, 0.1, lambda), J0, 1)
  all(abs(rowsum(segment_probabilities(s, c(0.02, 0.2, 2)), s$i) - 1) < 1e-12)
}))
record("choice probabilities sum to one", all(abs(sums - 1) < 1e-12) && mass_ok,
  "sigma = 0.02, 0.2, 2; lambda = 0.5, 1, 2")
record("choice probabilities match simulated costs", simulated_ok,
  "20 affected parents, 200,000 draws; gamma = 1, 1.5, 2.5")

# 7. The motivating case: 220 units in one building, kappa = 0.16, c = 0.04.
# With a linear cost three buildings at full size (2c = 0.08) beat 99 + 99
# (c + (22 / 99)^2 = 0.089); with gamma = 2 three buildings cost 4c = 0.16,
# so 99 + 99 wins.
s <- solve(220L, 1L, 0.16)
linear <- s[which.min(s$R + 0.04 * (s$J - 1)), ]
steeper <- s[which.min(s$R + 0.04 * (s$J - 1)^2), ]
record("220 units: three buildings if linear, 99 + 99 if gamma = 2",
  linear$J == 3 && linear$m == 220 && steeper$J == 2 && steeper$m == 198,
  sprintf("linear J = %d, m = %d; gamma = 2 J = %d, m = %d", linear$J, linear$m, steeper$J, steeper$m))

model_checks <- do.call(rbind, checks)
print(model_checks)
stopifnot(all(model_checks$passed))
SaveData(model_checks, "check", "../output/model_checks.csv")

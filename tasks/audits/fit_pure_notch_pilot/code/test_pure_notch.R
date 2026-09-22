# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
source("../../../shared/code/pure_notch_model.R")
source("../../../shared/code/write_data_report.R")

checks <- list()
check <- function(name, error, tolerance = 1e-12) {
  stopifnot(is.finite(error), error <= tolerance)
  checks[[length(checks) + 1L]] <<- data.frame(check = name, maximum_error = error,
                                            tolerance = tolerance, passed = TRUE)
}

x <- c(50, 99, 100, 101, 175, 198, 199, 200, 220, 301, 600, 1754)
J0 <- rep(c(1L, 2L, 3L), 4)
weights <- rep(1 / length(x), length(x))
zero <- notch_predictions(notch_choices(x, 0), J0, weights, .025)
check("zero policy preserves x and J0", sum(zero$mass[zero$m != zero$x | zero$J != zero$J0]))
check("zero policy preserves exact vector", max(abs(notch_partition(220, 2, c(110,110), 0, "separate") - c(110,110))))

# Exhaustive integer size search, including small x<J and totals well above 300.
errors <- numeric()
for (assessment in c("separate", "joint")) for (lambda in c(.5, 1, 2)) {
  for (kappa in c(0, .01, .1, .2)) {
    choices <- notch_choices(c(1, 2, x), kappa, lambda, 6, assessment)
    for (r in seq_len(nrow(choices))) {
      a <- choices[r, ]
      m <- seq.int(a$J, max(a$x, 99 * a$J) + 100L)
      capacity <- if (assessment == "joint") 99 else 99 * a$J
      cost <- ordinary_size_loss(m, a$x, lambda) + kappa * (m > capacity)
      minimum <- min(cost)
      minimizers <- m[abs(cost - minimum) < 1e-13]
      errors <- c(errors, abs(a$R - minimum), min(abs(a$m - minimizers)))
    }
  }
}
check("closed form matches exhaustive integer sizes", max(errors), 1e-10)

# Independent dynamic program: sum the constituent costs, not the parent shortcut.
errors <- numeric()
for (kappa in c(0, .02, .2)) {
  dp <- matrix(Inf, nrow = 5, ncol = 451)
  dp[1, 1] <- 0
  for (J in 1:4) for (m in J:450) {
    n <- 1:(m - J + 1)
    dp[J + 1, m + 1] <- min(kappa * (n >= 100) + dp[J, m - n + 1])
    errors <- c(errors, abs(dp[J + 1, m + 1] - kappa * (m > 99 * J)))
  }
}
check("flat partition burden matches dynamic program", max(errors))

errors <- numeric()
for (R1 in c(0, .01, .1)) for (R2 in c(0, .01, .1)) for (sigma in c(.005, .025, .1)) {
  S <- R1 - R2
  p2_single <- if (S <= 0) 0 else -expm1(-S / sigma)
  p2_double <- if (S < 0) exp(S / sigma) else 1
  errors <- c(errors,
    abs(organization_probabilities(c(R1, R2), 1, sigma)[2] - p2_single),
    abs(organization_probabilities(c(R1, R2), 2, sigma)[2] - p2_double))
}
check("two-organization analytic probabilities", max(errors))

set.seed(485100)
errors <- numeric()
for (R in list(c(.1, .05, .02, 0), c(.03, .03, 0, 0), c(0, .1, .2, .3))) {
  for (toy_J0 in c(1L, 3L)) {
    costs <- matrix(rexp(400000 * 4, rate = 1 / .025), ncol = 4)
    costs[, toy_J0] <- 0
    costs <- sweep(costs, 2, R, "+")
    numerical <- tabulate(max.col(-costs, ties.method = "first"), nbins = 4) / nrow(costs)
    errors <- c(errors, abs(numerical - organization_probabilities(R, toy_J0, .025)))
  }
}
check("four-organization probabilities versus simulation", max(errors), .004)
check("infeasible alternatives have zero probability", organization_probabilities(c(.1, Inf, 0), 1, .025)[2])

separate <- notch_choices(x, .1)
p <- notch_predictions(separate, rep(1L, length(x)), weights, .025)
check("total parent mass", abs(sum(p$mass) - 1))
check("joint cells include every outcome", abs(sum(notch_joint_shares(p$m, p$J, p$mass)) - 1))
check("both crossers have no splitting saving", abs(separate$R[separate$x == 600 & separate$J == 1] - separate$R[separate$x == 600 & separate$J == 2]))
joint <- notch_predictions(notch_choices(x, .1, assessment = "joint"), J0, weights, .025)
check("joint assessment retains organization", sum(joint$mass[joint$J != joint$J0]))
check("sigma cannot change conditional choices", max(abs(p$R - notch_predictions(separate, rep(1L,length(x)), weights, .1)$R)))
check("exact 198 exempt pair has unique 99+99 layout", max(abs(notch_partition(198, 2, c(100,98), .1, "separate") - c(99,99))))

SaveData(do.call(rbind, checks), "check", "../output/numerical_checks.csv")
cat(length(checks), "numerical checks passed.\n")

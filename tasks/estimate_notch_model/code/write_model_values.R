# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# The estimates quoted in framework_writeup.tex, as LaTeX macros: the main
# model with its bootstrap intervals, the models it is compared with, the
# least-squares single burden, and the main model's fit at 99 and 99+99.
models <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE)
bootstrap <- read_csv("../output/scaled_burden_bootstrap_estimates.csv", show_col_types = FALSE)
least_squares <- read_csv("../output/estimates.csv", show_col_types = FALSE) |> filter(specification == "least_squares")
cells <- read_csv("../output/heterogeneity_cell_fit.csv", show_col_types = FALSE,
  col_types = cols(buildings = col_character())) |>
  filter(model == "scaled_burden")
main <- models |> filter(model == "scaled_burden")
stopifnot(nrow(main) == 1L, nrow(least_squares) == 1L, nrow(bootstrap) == 10L)

number <- function(x, digits = 2) formatC(x, format = "f", digits = digits)
units <- function(x) format(round(x), big.mark = ",")
interval <- function(name, digits = 2) {
  b <- bootstrap |> filter(parameter == name)
  c(number(b$bootstrap_lower, digits), number(b$bootstrap_upper, digits))
}
row_of <- function(name) models |> filter(model == name)
share <- function(rows) number(100 * sum(rows), 1)

values <- c(
  ModelHistoricalParents = least_squares$historical_parents,
  ModelPostParents = least_squares$post_parents,
  MainKappa = number(main$kappa), MainKappaLower = interval("kappa")[1], MainKappaUpper = interval("kappa")[2],
  MainTau = number(main$tau), MainTauLower = interval("tau")[1], MainTauUpper = interval("tau")[2],
  MainSpread = number(main$dispersion, 1), MainSpreadLower = interval("dispersion", 1)[1],
  MainSpreadUpper = interval("dispersion", 1)[2],
  MainGamma = number(main$gamma), MainGammaLower = interval("gamma")[1], MainGammaUpper = interval("gamma")[2],
  MainSigma = number(main$sigma), MainSigmaLower = interval("sigma")[1], MainSigmaUpper = interval("sigma")[2],
  MainEpsilon = number(main$epsilon, 3), MainEpsilonLower = interval("epsilon", 3)[1],
  MainEpsilonUpper = interval("epsilon", 3)[2],
  MainShareSmallBurden = number(100 * main$share_jump_below_0.01, 0),
  MainShareLargeBurden = number(100 * main$share_jump_above_1, 0),
  MainUnitsLost = units(main$units_lost),
  MainUnitsLostLower = units(bootstrap$bootstrap_lower[bootstrap$parameter == "units_lost"]),
  MainUnitsLostUpper = units(bootstrap$bootstrap_upper[bootstrap$parameter == "units_lost"]),
  MainUnitsLostMedian = units(bootstrap$bootstrap_median[bootstrap$parameter == "units_lost"]),
  MainLogLikelihood = number(main$log_likelihood, 1), MainAIC = number(main$aic, 1),
  SingleLogLikelihood = number(row_of("single_jump")$log_likelihood, 1),
  SingleAIC = number(row_of("single_jump")$aic, 1), SingleUnitsLost = units(row_of("single_jump")$units_lost),
  SingleKappa = number(row_of("single_jump")$kappa), SingleTau = number(row_of("single_jump")$tau),
  NonOptimizerLogLikelihood = number(row_of("non_optimizers")$log_likelihood, 1),
  NonOptimizerAIC = number(row_of("non_optimizers")$aic, 1),
  NonOptimizerUnitsLost = units(row_of("non_optimizers")$units_lost),
  NonOptimizerShare = number(100 * row_of("non_optimizers")$pi, 0),
  VaryingJumpLogLikelihood = number(row_of("heterogeneous_jump")$log_likelihood, 1),
  VaryingJumpAIC = number(row_of("heterogeneous_jump")$aic, 1),
  VaryingJumpUnitsLost = units(row_of("heterogeneous_jump")$units_lost),
  LotSplittingLogLikelihood = number(row_of("scaled_burden_lot_splitting")$log_likelihood, 1),
  LotSplittingAIC = number(row_of("scaled_burden_lot_splitting")$aic, 1),
  LotSplittingUnitsLost = units(row_of("scaled_burden_lot_splitting")$units_lost),
  LotSplittingElasticity = number(row_of("scaled_burden_lot_splitting")$lot_elasticity, 1),
  SizeSplittingLogLikelihood = number(row_of("scaled_burden_size_splitting")$log_likelihood, 1),
  SizeSplittingAIC = number(row_of("scaled_burden_size_splitting")$aic, 1),
  SizeSplittingUnitsLost = units(row_of("scaled_burden_size_splitting")$units_lost),
  SizeSplittingElasticity = number(row_of("scaled_burden_size_splitting")$size_elasticity, 1),
  LeastSquaresKappa = number(least_squares$kappa), LeastSquaresTau = number(least_squares$tau),
  LeastSquaresGamma = number(least_squares$gamma), LeastSquaresSigma = number(least_squares$sigma),
  LeastSquaresUnitsLost = units(least_squares$units_lost_model),
  ObservedShareOneAtNinetyNine = share(cells$observed[cells$buildings == "1" & cells$size_bin == "99"]),
  ModelShareOneAtNinetyNine = share(cells$fitted[cells$buildings == "1" & cells$size_bin == "99"]),
  ObservedSharePair = share(cells$observed[cells$buildings == "2" & cells$size_bin == "198"]),
  ModelSharePair = share(cells$fitted[cells$buildings == "2" & cells$size_bin == "198"]),
  ObservedShareTwoBuildings = share(cells$observed[cells$buildings == "2"]),
  ModelShareTwoBuildings = share(cells$fitted[cells$buildings == "2"])
)
writeLines(sprintf("\\newcommand{\\%s}{%s}", names(values), values), "../output/model_values.tex")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})

# The estimates quoted in framework_writeup.tex, as LaTeX macros: the main
# model with its bootstrap intervals, the models it is compared with, the
# least-squares single burden, the main model's fit at 99 and 99+99, and the
# main model on the checks of the sample.
models <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE)
bootstrap <- read_csv("../output/scaled_burden_bootstrap_estimates_all_filings.csv", show_col_types = FALSE)
specifications <- read_csv("../output/estimates.csv", show_col_types = FALSE)
least_squares <- specifications |> filter(specification == "least_squares")
cells <- read_csv("../output/heterogeneity_cell_fit.csv", show_col_types = FALSE,
  col_types = cols(buildings = col_character())) |>
  filter(model == "scaled_burden")
main <- models |> filter(model == "scaled_burden")
stopifnot(nrow(main) == 1L, nrow(least_squares) == 1L, nrow(bootstrap) == 8L)

number <- function(x, digits = 2) formatC(round(x, digits) + 0, format = "f", digits = digits)
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
  SingleKappa = number(row_of("single_jump")$kappa),
  NonOptimizerLogLikelihood = number(row_of("non_optimizers")$log_likelihood, 1),
  NonOptimizerAIC = number(row_of("non_optimizers")$aic, 1),
  NonOptimizerUnitsLost = units(row_of("non_optimizers")$units_lost),
  NonOptimizerShare = number(100 * row_of("non_optimizers")$pi, 0),
  LotSplittingLogLikelihood = number(row_of("scaled_burden_lot_splitting")$log_likelihood, 1),
  LotSplittingAIC = number(row_of("scaled_burden_lot_splitting")$aic, 1),
  LotSplittingUnitsLost = units(row_of("scaled_burden_lot_splitting")$units_lost),
  LotSplittingElasticity = number(row_of("scaled_burden_lot_splitting")$lot_elasticity, 1),
  SizeSplittingLogLikelihood = number(row_of("scaled_burden_size_splitting")$log_likelihood, 1),
  SizeSplittingAIC = number(row_of("scaled_burden_size_splitting")$aic, 1),
  SizeSplittingUnitsLost = units(row_of("scaled_burden_size_splitting")$units_lost),
  SizeSplittingElasticity = number(row_of("scaled_burden_size_splitting")$size_elasticity, 1),
  LeastSquaresKappa = number(least_squares$kappa),
  LeastSquaresGamma = number(least_squares$gamma), LeastSquaresSigma = number(least_squares$sigma),
  LeastSquaresUnitsLost = units(least_squares$units_lost_model),
  CurvatureHalfUnitsLost = units(specifications$units_lost_model[specifications$specification == "curvature_0.5"]),
  CurvatureTwoUnitsLost = units(specifications$units_lost_model[specifications$specification == "curvature_2"]),
  ObservedShareOneAtNinetyNine = share(cells$observed[cells$buildings == "1" & cells$size_bin == "99"]),
  ModelShareOneAtNinetyNine = share(cells$fitted[cells$buildings == "1" & cells$size_bin == "99"]),
  ObservedSharePair = share(cells$observed[cells$buildings == "2" & cells$size_bin == "198"]),
  ModelSharePair = share(cells$fitted[cells$buildings == "2" & cells$size_bin == "198"]),
  ObservedShareTwoBuildings = share(cells$observed[cells$buildings == "2"]),
  ModelShareTwoBuildings = share(cells$fitted[cells$buildings == "2"])
)
# The checks: the common 180-day horizon, 2025 parents only, the pre-policy
# placebo and the longer historical period, with units lost per 100 recent
# parents for comparison across samples of different size.
recent <- read_parquet("../output/estimation_parents.parquet") |>
  filter(sample == "post_policy", units <= 300) |>
  count(variant, name = "parents")
checks <- c(all_filings = "Main", horizon_180 = "Horizon", cohort_2025 = "Early", placebo = "Placebo",
  history_2014 = "Longer")
for (variant in names(checks)) {
  b <- read_csv(paste0("../output/scaled_burden_bootstrap_estimates_", variant, ".csv"), show_col_types = FALSE)
  parents <- recent$parents[recent$variant == variant]
  estimate <- function(name) b$estimate[b$parameter == name]
  bound <- function(name, side) b[[side]][b$parameter == name]
  prefix <- checks[[variant]]
  values[paste0(prefix, c("CheckParents", "CheckKappa", "CheckKappaLower", "CheckKappaUpper",
    "CheckSpread", "CheckEpsilon", "CheckUnitsLost", "CheckUnitsLostLower", "CheckUnitsLostUpper",
    "CheckUnitsPerHundred", "CheckUnitsPerHundredLower", "CheckUnitsPerHundredUpper"))] <- c(parents,
    number(estimate("kappa")), number(bound("kappa", "bootstrap_lower")), number(bound("kappa", "bootstrap_upper")),
    number(estimate("dispersion"), 1), number(estimate("epsilon"), 3),
    units(estimate("units_lost")), units(bound("units_lost", "bootstrap_lower")),
    units(bound("units_lost", "bootstrap_upper")), number(100 * estimate("units_lost") / parents, 0),
    number(100 * bound("units_lost", "bootstrap_lower") / parents, 0),
    number(100 * bound("units_lost", "bootstrap_upper") / parents, 0))
}
writeLines(sprintf("\\newcommand{\\%s}{%s}", names(values), values), "../output/model_values.tex")

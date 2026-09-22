# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/analysis_parents.csv", show_col_types = FALSE)
best <- read_csv("../output/best_fits.csv", show_col_types = FALSE) |>
  filter(specification == "separate_baseline")
predictions <- read_parquet("../output/best_parent_contributions.parquet") |>
  filter(specification == "separate_baseline")
intervals <- read_csv("../input/bootstrap_intervals.csv", show_col_types = FALSE)
bootstrap_run <- read_csv("../input/bootstrap_run_summary.csv", show_col_types = FALSE)
historical <- filter(parents, sample == "historical")
post <- filter(parents, sample == "post_policy")
n_post <- nrow(post)
stopifnot(nrow(best) == 1L, !anyDuplicated(predictions[c("parent_id", "J")]),
          abs(sum(predictions$mass) - 1) < 1e-10)

# Attribute model-implied reductions by counterfactual size x. All fitted
# parameters, simulated parents, and 45 fitting cells remain as in the pilot.
local_effects <- predictions |>
  mutate(origin_range = cut(x, c(49, 250, 300, Inf), labels = c("50-250", "251-300", "301+"))) |>
  group_by(origin_range, .drop = FALSE) |>
  summarise(parent_equivalents = n_post * sum(mass),
            counterfactual_units = n_post * sum(mass * x),
            predicted_units = n_post * sum(mass * m),
            unit_reduction = n_post * sum(mass * (x - m)),
            shrinking_parent_equivalents = n_post * sum(mass[m < x]),
            exits_from_301plus = n_post * sum(mass[x > 300 & m <= 300]),
            .groups = "drop")
stopifnot(!anyNA(local_effects$origin_range),
          abs(sum(local_effects$unit_reduction) - best$model_difference) < 1e-8,
          abs(sum(local_effects$counterfactual_units) - best$counterfactual_units) < 1e-8,
          abs(sum(local_effects$predicted_units) - best$predicted_units) < 1e-8)
SaveData(local_effects, "origin_range", "../output/local_unit_effects.csv")

# Illustrative arithmetic: assign every excess 99/198 parent a uniformly
# distributed integer origin within the fixed-organization flat-charge bound.
# At lambda=1, ((x - 99*J)/99)^2 <= kappa. This is not a fitted origin assignment;
# changing J costs money and can prevent the response, especially for pairs.
stopifnot(best$lambda == 1, best$tau == 0)
illustration <- tibble(threshold_total = c(99L, 198L),
  post_parents = c(sum(post$parent_total_units == 99), sum(post$parent_total_units == 198)),
  historical_parent_equivalents = n_post * c(
    sum(historical$weight[historical$parent_total_units == 99]),
    sum(historical$weight[historical$parent_total_units == 198]))) |>
  mutate(excess_parents = post_parents - historical_parent_equivalents,
         origin_min = threshold_total + 1L,
         continuous_origin_bound = threshold_total + 99 * sqrt(best$kappa),
         origin_max = floor(continuous_origin_bound),
         assumed_mean_reduction = (origin_min + origin_max) / 2 - threshold_total,
         illustrative_unit_reduction = excess_parents * assumed_mean_reduction)
SaveData(illustration, "threshold_total", "../output/bunching_unit_illustration.csv")

# Reuse the existing parent bootstrap, which resamples both periods and
# recalibrates site weights. The 301 bin pools all parents above 300 units.
tail <- intervals |>
  filter(statistic %in% c("parent_total_bin_301__counterfactual_share",
                         "parent_total_bin_301__observed_share", "parent_total_bin_301__difference")) |>
  mutate(series = case_when(
    statistic == "parent_total_bin_301__counterfactual_share" ~ "weighted_historical",
    statistic == "parent_total_bin_301__observed_share" ~ "observed_post",
    statistic == "parent_total_bin_301__difference" ~ "historical_minus_post"),
    # Stored differences are post minus historical; reverse their sign and bounds.
    share = if_else(series == "historical_minus_post", -point_estimate, point_estimate),
    share_lower = if_else(series == "historical_minus_post", -percentile_upper, percentile_lower),
    share_upper = if_else(series == "historical_minus_post", -percentile_lower, percentile_upper),
    parent_equivalents = n_post * share,
    parents_lower = n_post * share_lower, parents_upper = n_post * share_upper) |>
  select(series, share, share_lower, share_upper, parent_equivalents, parents_lower,
         parents_upper, successful_replications)
historical_tail_share <- sum(historical$weight[historical$parent_total_units > 300])
post_tail_share <- mean(post$parent_total_units > 300)
stopifnot(nrow(tail) == 3L,
          abs(tail$share[tail$series == "weighted_historical"] - historical_tail_share) < 1e-10,
          abs(tail$share[tail$series == "observed_post"] - post_tail_share) < 1e-10,
          abs(tail$share[tail$series == "historical_minus_post"] - historical_tail_share + post_tail_share) < 1e-10,
          all(tail$successful_replications == sum(bootstrap_run$replications[bootstrap_run$status == "successful"])))
SaveData(tail, "series", "../output/tail_count_uncertainty.csv")

# Filing-year composition is descriptive. Filing dates do not establish the
# foundation commencement dates governing 421-a eligibility.
annual_tail <- historical |> mutate(filing_year = as.integer(format(cohort_date, "%Y"))) |>
  group_by(filing_year) |>
  summarise(parents = n(), parents_301plus = sum(parent_total_units > 300),
            share_301plus = mean(parent_total_units > 300),
            mean_units = mean(parent_total_units), .groups = "drop")
SaveData(annual_tail, "filing_year", "../output/historical_tail_by_year.csv")

print(local_effects, width = Inf)
print(illustration, width = Inf)
print(tail, width = Inf)
print(bootstrap_run, width = Inf)
print(annual_tail, width = Inf)

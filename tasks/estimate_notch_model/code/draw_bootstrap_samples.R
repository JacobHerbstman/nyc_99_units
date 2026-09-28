# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
})
source("../../shared/code/scale_shape_helpers.R")
source("../../shared/code/write_data_report.R")

draws <- 500L

# Bootstrap samples shared by every bootstrap. Each draw resamples parents with
# replacement within period and borough and recalibrates the historical
# weights to the resampled recent parents; stratifying keeps Staten Island (5
# historical, 2 recent parents) in every calibration. A historical parent's
# weight is its share of the calibrated weight over its copies; a recent
# parent's weight is its number of copies. Draw 0 is the data.
parents <- read_parquet("../output/estimation_parents.parquet") |> filter(variant == "all_filings")
historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy")

resample <- function(data) data |> group_by(borough) |> slice_sample(prop = 1, replace = TRUE) |> ungroup()
set.seed(20260925)
samples <- bind_rows(lapply(0:draws, function(draw) {
  h <- if (draw == 0L) historical else resample(historical)
  p <- if (draw == 0L) post else resample(post)
  h$weight <- calibrate_historical_to_target(h, p)$historical$calibration_weight
  bind_rows(
    h |> group_by(parent_id) |> summarise(weight = sum(weight), .groups = "drop") |>
      mutate(sample = "historical", weight = weight / sum(weight)),
    p |> count(parent_id, name = "weight") |> mutate(sample = "post_policy", weight = as.numeric(weight))
  ) |>
    mutate(draw = draw, .before = 1)
})) |>
  select(draw, sample, parent_id, weight)

data <- samples |> filter(draw == 0L, sample == "historical") |>
  inner_join(historical |> select(parent_id, weight_zoning_borough), by = "parent_id", relationship = "one-to-one")
stopifnot(nrow(data) == nrow(historical), max(abs(data$weight - data$weight_zoning_borough)) < 1e-10,
  all(samples$weight[samples$draw == 0L & samples$sample == "post_policy"] == 1))

SaveData(samples, c("draw", "sample", "parent_id"), "../output/bootstrap_samples.parquet")

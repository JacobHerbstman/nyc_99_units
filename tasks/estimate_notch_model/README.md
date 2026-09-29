# Estimate the size-and-splitting model

Estimates the developer choice in `framework_writeup.tex`: how the 485-x
threshold changes a parent's total units and its number of buildings.

## Sample and weights

`prepare_estimation_sample.R` selects the comparison sample from
`build_estimation_panels`: `included_ab` rental parents with at least 50 units
and `composition_eligible`, 2019–2022 against January 1, 2025–July 8, 2026.
Historical weights are recalibrated here with the shared helper, matching
residential FAR and borough (`weight_zoning_borough`), or also log lot area
(`weight_with_lot_area`). Variant `horizon_180` counts only buildings filed
within 180 days of the parent's first filing, in both periods, and keeps
recent parents observed for at least 180 days. Variant `cohort_2025` keeps
recent parents first filed in 2025. Variant `placebo` is a pre-policy placebo
from the placebo panels: parents first filed in 2015–2018 stand in for the
historical sample and those first filed in 2019–2022, before 485-x, for the
recent one.

## Model

Each weighted historical parent supplies its preferred total `x` and building
count `J0`. Under the policy it chooses total units `m` and buildings `J` to
minimize, relative to its ordinary cost of 99 units:

- the size loss, `((m - x) / 99)^2` at curvature `lambda = 1`;
- a burden on each building with 100 or more units: a jump `kappa` plus a kink
  `tau * [(n / 99)^2 - (100 / 99)^2]`;
- a splitting cost `c * k^gamma` for `k` buildings beyond `J0`, with `c` drawn
  for each parent from an exponential distribution with mean `sigma`; `gamma`
  above 1 makes each added building cost more than the last.

Layouts are free, so above `99J` units the other buildings hold 99 each and the
crossing buildings share the rest evenly. The best total for each `J` is found
by exhaustive integer search. Because the splitting cost is linear in `c`, each
`J` is chosen on an interval of `c`, and choice probabilities are exact. A
parent never chooses fewer buildings than `J0`: that raises the burden and
costs `c`. Without the burden every parent keeps `x` and `J0`.

## Main model

The main model is the scaled burden, estimated by likelihood: each parent's
jump and kink are multiplied by one lognormal scale with median 1 and log
standard deviation `s`, as a gap between required and usual wages would scale
them, so `kappa` and `tau` describe the median parent. The likelihood treats
each recent parent of at most 300 units as a draw from the predicted cell
probabilities (1, 2 or 3+ buildings by size bin, renormalized within the
range). Every grid point gives probability zero to some observed parent, so a
share `epsilon` of recorded recent outcomes is unexplained by the model, spread
uniformly over sizes 50–300 and 1, 2 or 3+ buildings; units lost use the
model's choices only. Burden distributions are placed on the `kappa` grid,
extended to 5, where every parent of at most 300 units avoids 100, so a
prediction is a weighted average of single-burden predictions along one
kink-to-jump ratio. The grids are in `notch_model.R`.

Units lost follow the framework among historical parents whose own size is in
the compared range, scaled to the recent parents there:
`P * sum(w * (x - E[m]))`.

- `fit_heterogeneity.R` estimates the main model and the alternatives it is
  compared with, all by likelihood: a single burden; non-optimizers, a share
  `pi` of parents that keeps its 2019–2022 outcome and loses no units; a
  heterogeneous jump with a common kink; both of the last two; and the main
  model with a splitting cost that depends on lot area or on the preferred
  size, mean `sigma * (lot / median historical lot)^(-beta)` or
  `sigma * (x / 150)^(-beta)`.
- `draw_bootstrap_samples.R` draws 500 bootstrap samples of one variant:
  parents resampled with replacement within period and borough, with the
  weights recalibrated to each resampled recent sample. Draw 0 is the data.
- `bootstrap_scaled_burden.R` re-estimates the main model on the full grid in
  every sample of one variant; for `all_filings` draw 0 reproduces the estimate
  of `fit_heterogeneity.R`. The other variants are the checks: a common
  180-day horizon, 2025 parents only, and the pre-policy placebo, where a
  method free of benchmark drift should find no burden and no units lost.
- `plot_model_fit.R` draws the main model's fit.

## Least squares and robustness

`fit_notch_model.R` estimates the single burden by least squares: it minimizes
the sum of squared differences between predicted and observed cell shares
over a grid of `kappa`, `tau`, `gamma` and `sigma`. Specification
`least_squares` compares parents of at most 300 units, the distribution
within that range on both sides, renormalized, so the number of very large
projects in each period does not enter; a historical parent above 300 that
shrinks into the range still counts. Each other specification changes one
element: the cutoff (249), a linear splitting cost (`gamma = 1`), all sizes
(with and without `gamma`), lot-area weights, the 180-day horizon, curvature
0.5 and 2, and joint assessment of the whole parent. It also reports units
lost with building counts held at `J0` and the direct gap
`P * (sum(w * x) - mean(m))`.

`test_notch_model.R` runs the framework's numerical checks before fitting.

The 150-unit regime in geographic Zones A and B is not modeled, by decision
for now.

## Outputs

- `estimation_parents.parquet`: the sample and weights for each variant.
- `model_checks.csv`: numerical checks.
- `heterogeneity_estimates.csv`, `heterogeneity_profiles.csv`,
  `heterogeneity_cell_fit.csv`: estimates, likelihood comparisons, profiles of
  the added parameters and the kink, and cell fit for the main model and its
  alternatives.
- `bootstrap_samples_<variant>.parquet`: the bootstrap samples of each variant.
- `scaled_burden_bootstrap_estimates_<variant>.csv`,
  `scaled_burden_bootstrap_draws_<variant>.csv`: the main model's estimates,
  bootstrap intervals and every draw's estimate on each variant.
- `pdf/model_fit.pdf`: the main model's fit.
- `model_values.tex`: the estimates, intervals and fit shares quoted in
  `framework_writeup.tex`, written by `write_model_values.R`.
- `estimates.csv`: least-squares best point, near-optimal ranges and unit
  quantities by specification.
- `fit_moments.csv`, `cell_fit.csv`: observed, benchmark and fitted moments and
  cells by least-squares specification.
- `parameter_profiles.csv`: the best least-squares objective at each value of
  each parameter.

Run root `make estimate`; task-local `make` uses the prepared panels.

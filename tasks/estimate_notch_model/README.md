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
recent parents observed for at least 180 days.

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

## Estimation

`fit_notch_model.R` predicts the distribution of recent parents over disjoint
cells (1, 2 or 3+ buildings by size bin) and minimizes the sum of squared
differences from the observed shares over a grid of `kappa`, `tau`, `gamma`
and `sigma`. The main specification compares parents of at most 300 units:
the distribution within that range on both sides, renormalized, so the number
of very large projects in each period does not enter. A historical parent
above 300 that shrinks into the range still counts. Each other specification
changes one element: a linear splitting cost (`gamma = 1`), all sizes
(with and without `gamma`), lot-area weights, the 180-day horizon, curvature
0.5 and 2, and joint assessment of the whole parent. Unit quantities follow
the framework among historical parents whose own size is in the compared
range, scaled to the recent parents there: model units lost
`P * sum(w * (x - E[m]))`, the same with building counts held at `J0`, and the
direct gap `P * (sum(w * x) - mean(m))`.

`test_notch_model.R` runs the framework's numerical checks before fitting.
`recover_parameters.R` redraws the recent sample from the model at the
estimate, at the same point with a linear splitting cost, and with a kink of
0.2, and re-estimates each draw on the grid; the historical sample is held
fixed. `plot_model_fit.R` draws the
fit.

`bootstrap_notch_model.R` estimates the main specification by least squares
and by maximum likelihood, with bootstrap intervals for both. The likelihood
treats each recent parent as a draw from the predicted cell probabilities.
Every grid point gives probability zero to some observed parent, so a share
`epsilon` of recorded recent outcomes is unexplained by the model, spread
uniformly over sizes 50–300 and 1, 2 or 3+ buildings; `epsilon` is estimated
on a grid, and units lost use the model's choices only. Each bootstrap draw
resamples parents with replacement within period and borough, recalibrates
the weights and re-estimates on the full grid; draw 0 is the data and
reproduces the main least-squares estimate. Likelihood-ratio intervals come
from the likelihood profiles.

`fit_heterogeneity.R` adds three departures from a single burden to that
likelihood: non-optimizers, a share `pi` of parents that keeps its 2019–2022
outcome and loses no units; a heterogeneous jump, lognormal across parents
with median `kappa` and log standard deviation `s`, with a common kink; and a
scaled burden, where each parent's jump and kink are both multiplied by a
lognormal scale with median 1, as a wage gap would scale them. Each nests the
main model; non-optimizers and the heterogeneous jump are also combined.
Distributions are placed on the `kappa` grid, extended to 5, where every
parent of at most 300 units avoids 100, so a prediction is a weighted average
of single-burden predictions; the scaled burden averages along the burden
levels of one kink-to-jump ratio. The single jump
reproduces the likelihood estimate of `bootstrap_notch_model.R`.

The 150-unit regime in geographic Zones A and B is not modeled, by decision
for now.

## Outputs

- `estimation_parents.parquet`: the sample and weights for each variant.
- `model_checks.csv`: numerical checks.
- `estimates.csv`: best point, near-optimal ranges and unit quantities by specification.
- `fit_moments.csv`, `cell_fit.csv`: observed, benchmark and fitted moments and cells.
- `parameter_profiles.csv`: the best objective at each value of each parameter.
- `main_grid_cells.parquet`: main-grid predictions for recovery.
- `recovery.csv`, `recovery_summary.csv`: simulated-data recovery.
- `bootstrap_estimates.csv`, `bootstrap_draws.csv`: least-squares and likelihood
  estimates, bootstrap intervals and every draw's estimate.
- `likelihood_profiles.csv`, `likelihood_cell_fit.csv`: the likelihood profile
  of each parameter and the cell fit at the likelihood estimate.
- `heterogeneity_estimates.csv`, `heterogeneity_profiles.csv`,
  `heterogeneity_cell_fit.csv`: estimates, likelihood comparisons, profiles of
  the added parameters and the kink, and cell fit for each model.
- `pdf/model_fit.pdf`: the main fit.

Run root `make estimate`; task-local `make` uses the prepared panels.

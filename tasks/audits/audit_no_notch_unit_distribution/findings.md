# No-Notch Unit Distribution: Audit Findings

## Decision

The initial approach is sound as a building-level first stage, with three
important qualifications.

1. Estimate a full distribution of preferred units, not a binary model of
   whether a filing exceeds 99 units.
2. Use only information fixed or observable before the filing. Proposed floor
   area, apartment size, and other simultaneous design choices should remain
   outcomes or validation targets, not predictors of no-notch units.
3. Treat training-window sensitivity as a real source of uncertainty. Sampling
   error is small relative to changes in the NYC development environment across
   years.

The provisional baseline is the simple linear model with i.i.d. normal shocks
in log preferred units. The richer linear model wins two aggregate local scores
by very small margins, but the simple model has slightly better local CDF
calibration and essentially identical point accuracy. The GAM and Student-t
extensions do not improve the threshold-relevant validation enough to justify
their added complexity. The negative-binomial model is numerically unstable
and should not be used.

This is a useful audit baseline, not yet a final 2025 counterfactual. Before
assigning post-policy exposure probabilities, the project still needs a
post-policy covariate panel and a deliberate treatment of pre-existing heaping
at 99 units.

## Baseline estimand and model

For building filing (i), estimate

\[
\log n_i^* = X_i'\beta + u_i,
\qquad u_i \stackrel{i.i.d.}{\sim} N(0,s_n^2),
\]

and obtain the integer distribution of (n_i^0) by rounding
(\exp(\log n_i^*)) and conditioning on (n_i^0\geq 6). The scale (s_n)
measures residual dispersion in preferred no-notch units. It is distinct from
the dollar-scale response shock in the later bunch/cross/split model.

The simple (X_i) includes lagged lot area, residential FAR, built FAR, filing
year, borough, broad zoning category, prior site use, and explicit missingness
flags. The enriched model adds allowable and residual residential capacity,
assessed land value, existing development, floors and buildings, and community
district. All MapPLUTO features are from the latest leakage-safe release
available before the filing.

The sample contains 5,917 New Building filings from 2010 through 2023. There
are 1,024 filings from 50 through 150 units and 15 exact-99 filings. The model
is trained on all qualifying filings with at least six units; the 50--150 range
is used only for held-out diagnostics.

## Validation design

The audit uses ten forward validation windows and three additional transport
windows after the June 15, 2022 421-a deadline. Every normal-log, GAM, and
Student-t model fits all 13 windows. The negative-binomial model fits only four
and fails in nine, so it is excluded from the complete-window ranking.

Distributions are evaluated with the held-out log score, the Brier score for
(n_i^0\geq100), CDF calibration at 80, 90, 99, 100, 110, 125, and 150 units,
and prediction-interval coverage. These are proper distributional checks; RMSE
is secondary. This follows the scoring-rule logic in
[Gneiting and Raftery (2007)](https://sites.stat.washington.edu/people/raftery/Research/PDF/Gneiting2007jasa.pdf).

## Main findings

The parcel variables have meaningful predictive content. Relative to the
unconditional lognormal benchmark, the simple model lowers the average local
Brier score by 13 percent, local CDF RMSE by 47 percent, local negative log
score by 6 percent, and local log-unit RMSE by 33 percent.

The enriched model does not materially outperform the simple model near the
threshold. Across the ten main validation windows, its average local negative
log score is 5.63 versus 5.64 for the simple model, and its Brier score is 0.223
versus 0.224. The simple model has lower local CDF RMSE, 0.107 versus 0.109, and
slightly lower log-unit RMSE. These differences are too small to justify making
the richer model the baseline.

The i.i.d. normal unit shock is stable across training samples. Its fitted
scale ranges from 0.733 to 0.782. The 200-replication BBL-clustered bootstrap
produces relatively narrow intervals for this scale in every window. All 2,600
bootstrap fits succeed.

The Student-t shock estimates roughly five degrees of freedom, confirming
heavier residual tails. It nevertheless worsens central interval coverage and
does not improve local threshold scores. Nominal 80-percent intervals from the
normal model cover about 76--78 percent of held-out filings, while nominal
95-percent intervals cover about 92 percent. This modest undercoverage should
remain a robustness caveat, but it does not warrant replacing the simple normal
baseline.

The most important weakness is calendar-time transport. Recent training
windows predict aggregate 100-plus counts reasonably well: training on
2016--2020 predicts 178 such filings in the 2021--June 2022 test period, versus
183 observed; training on 2016--2021 predicts 82 in January--June 2022, versus
80 observed. By contrast, training only through 2017 predicts roughly
110--116 100-plus filings in 2018--2020, versus 214 observed. The bootstrap
intervals do not cover that gap. This is regime drift, not ordinary sampling
error, and the richer parcel models do not eliminate it.

There is also non-smooth exact-99 mass before 485-x. In the 2021--June 2022
reference test, the simple model expects about 1.7 exact-99 filings across the
full test sample and observes three. In the post-June-2022 transport sample, it
expects roughly 0.7--0.8 and observes six. A smooth continuous distribution
therefore cannot by itself define the entire no-notch 99 counterfactual.

## Implications for the structural project

The next structural stage should use draws from the full conditional unit
distribution. It should not label a filing a buncher because its predicted
mean or median exceeds 99. For a post-policy filing, the immediate empirical
counterpart is (\Pr(n_i^0\geq100\mid X_i)), plus draws of (n_i^0) for the
integrated bunch/cross/split likelihood.

The first 2025 scoring exercise should report several recent training windows,
not one pooled 2010--2023 estimate. A sensible starting set is 2016--2020,
2018--2021, and a final pre-policy fit using the recent years through 2023. The
spread across those fits should be carried into the structural simulation as a
time-transport robustness band.

Before interpreting excess 99s as 485-x responses, add one of two transparent
pre-period corrections: an exact-bin heaping adjustment learned only from the
preperiod, or a difference-in-bunching calculation that subtracts the
preperiod exact-99 residual. Both should be reported; neither should be chosen
using the 2025 spike.

If additional data are added, the highest-value predictors are pre-filing
market and feasibility measures: expected rents or sale prices, construction
costs, financing rates, tax-program regime, parcel capacity, and binding
zoning constraints. Parcel feasibility models such as
[UrbanSim](https://cloud.urbansim.com/docs/general/documentation/urbansim.html)
and official realistic-capacity guidance from
[California HCD](https://www.hcd.ca.gov/housing-element/building-blocks/sites-zoning/development-capacity)
emphasize these same objects. Parcel-level evidence also supports distinguishing
vacant or underused sites and zoning capacity; see
[Dong (2021)](https://journals.sagepub.com/doi/10.1177/0739456X21990728).
Post-policy realized unit choices must not be used as a market control because
they may themselves respond to the threshold.

Finally, this task remains building-level. Parent-opportunity aggregation and
split feasibility must be estimated symmetrically in a separate crosswalk; one
cannot sum building-level preferred-unit predictions inside a parent whose
number of buildings may itself be policy-responsive.

## Output map

- `output/no_notch_model_comparison.csv`: complete-window score comparison.
- `output/no_notch_model_window_summary.csv`: every metric by model, sample,
  and forward window.
- `output/no_notch_shock_parameters.csv`: fitted unit-distribution shock
  parameters by model and window.
- `output/no_notch_bootstrap_summary.csv`: 200-replication uncertainty bands by
  window, including the unit-distribution shock scale.
- `output/no_notch_model_status.csv` and
  `output/no_notch_bootstrap_status.csv`: explicit fit and failure records.
- `output/no_notch_histogram_validation.pdf`: held-out exact-unit distributions
  from 50 through 150 units in the reference window.

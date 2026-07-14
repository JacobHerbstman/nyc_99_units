# No-Notch Threshold-Hurdle Audit

This audit asks whether small and larger New Building filings should contribute
to the predicted probability of crossing 100 units through different equations.
It is a threshold-probability diagnostic, not a replacement for the preferred
full distribution of no-notch units.

Every model uses the same building-filing sample, leakage-safe predictors,
training-only preprocessing, and thirteen forward windows as the no-notch unit
distribution audit. Ten pre-deadline windows enter the validation summary; the
three post-June-2022 windows remain transport checks.

## Models

The current simple lognormal benchmark is

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

Its normal residual scale is estimated as `sqrt(mean(residual^2))`. The
probability of at least 100 units uses the same rounded-lognormal distribution,
conditioned on at least six units, as the existing unit-distribution audit.

The direct-logit challenger applies the same right-hand side to
`I(units >= 100)`. For each cutoff \(c\) in 11, 20, 30, and 40, the sequential
logit instead estimates

\[
q_{ic}=\Pr(n_i\geq c\mid n_i\geq6,X_i)
\]

on the full training sample and

\[
r_{ic}=\Pr(n_i\geq100\mid n_i\geq c,X_i)
\]

on the corresponding upper subset. Its threshold probability is

\[
\Pr(n_i\geq100\mid n_i\geq6,X_i)=q_{ic}r_{ic}.
\]

Both stages use numerical imputations, category pooling, factor levels, and the
filing-year center learned from the full training window. Thus differences
across models do not come from different test rows or preprocessing rules.

## Main result

The 11-unit sequential logit is the strongest binary-probability benchmark on
average, but it does not dominate in every forward window.

| Model | Mean Brier | Mean binary log score | Mean AUC | Mean absolute 100+ count error |
|---|---:|---:|---:|---:|
| Simple lognormal | 0.0973 | 0.3339 | 0.8810 | 31.9 |
| Direct 100+ logit | 0.0985 | 0.3345 | 0.8850 | 40.6 |
| Sequential logit, cutoff 11 | 0.0927 | 0.3181 | 0.8909 | 26.8 |
| Sequential logit, cutoff 20 | 0.0935 | 0.3217 | 0.8903 | 27.9 |
| Sequential logit, cutoff 30 | 0.0941 | 0.3240 | 0.8903 | 31.2 |
| Sequential logit, cutoff 40 | 0.0951 | 0.3261 | 0.8900 | 33.7 |

Across the ten validation windows, cutoff 11 has a lower Brier score than the
simple lognormal in eight, a lower binary log score in seven, and a higher AUC
in nine. It has a lower absolute 100-plus count error in six windows. Its
average expected 100-plus count is 167.2, compared with an average observed
count of 156.8; the simple lognormal averages 129.6. This improvement therefore
reflects a reduction in the baseline's average underprediction, not uniformly
better aggregate calibration in every period.

These results support taking small-building heterogeneity seriously. They do
not justify restricting the estimation sample to buildings whose realized
unit count exceeds a cutoff. Every first-stage logit continues to use all
filings with at least six units.

## Interpretation limit

The sequential logits provide only \(\Pr(n_i^0\geq100\mid X_i)\). They do not
provide probabilities for every possible unit count and cannot generate the
draws of \(n_i^0\) needed to compute bunch, cross, and split profit losses. They
also introduce separate binary response equations rather than preserving the
single i.i.d. normal preferred-size shock in the current structural sketch.

For those reasons this task is diagnostic-only. A coherent two-part unit-count
likelihood would be required before small- versus larger-building regimes could
replace the current full-distribution baseline.

## Outputs

- `output/no_notch_threshold_hurdle_window_metrics.csv` reports every model and
  metric in all thirteen windows.
- `output/no_notch_threshold_hurdle_validation_summary.csv` averages the six
  requested metrics over the ten pre-deadline validation windows.
- `output/no_notch_threshold_hurdle_status.csv` records fit status, warnings,
  and the conditional-stage sample size for every model-window pair.
- `output/no_notch_threshold_hurdle_reference_predictions.parquet` reports all
  six probabilities for the 800 filings in the 2021--June-2022 reference
  holdout.

Run from `code/` with `make`.

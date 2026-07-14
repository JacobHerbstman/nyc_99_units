# No-Notch Rounded Truncated-Likelihood Audit

This audit compares the current log-unit OLS fit with a coherent maximum-
likelihood fit of the same maintained distribution. It changes the estimator,
not the covariates, preprocessing, validation windows, risk-set definitions, or
i.i.d. normal shock.

For an observed integer unit count \(n\), latent log-unit location \(\mu=X\beta\),
shock scale \(\sigma\), and training floor \(c\), the MLE uses

\[
\frac{
  \Phi\!\left((\log(n+0.5)-\mu)/\sigma\right)-
  \Phi\!\left((\log(n-0.5)-\mu)/\sigma\right)
}{
  1-\Phi\!\left((\log(c-0.5)-\mu)/\sigma\right)
}.
\]

The numerator respects integer rounding. The denominator explicitly conditions
on the outcome-based training floor. The OLS plug-in benchmark estimates
\(\beta\) by `lm(log_units ~ X)` and \(\sigma\) by
`sqrt(mean(residual^2))`, then evaluates exactly the same rounded conditional
distribution. This separates likelihood coherence from any predictive gain.

The unchanged right-hand side is

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

Training floors 6 and 11 are the main comparison. Floor 30 is retained only as
an outcome-selected diagnostic. Every fit uses training-only numerical
imputation, category pooling, factor levels, and year centering from the
existing no-notch audit. Evaluation uses the same ten pre-policy forward
windows and the same three held-out samples:

- the complete six-plus universe;
- the outcome-selected actual 50--150-unit sample; and
- the fixed X-selected 50--150 risk set defined by the floor-6 OLS prediction.

Latent-location point metrics retain every row in each declared sample, exactly
as in the training-support audit. The audit reports two conversions from a
floor-11 or floor-30 fit into held-out probabilities:

1. **Condition at the training floor.** This divides by
   \(\Pr(n\geq c\mid X)\). It is the distribution used in estimation and is
   evaluated only where observed held-out units are at least \(c\). Both the
   declared row count and the number excluded from support are reported.
2. **Transport the underlying distribution to the common six-plus universe.**
   The fitted \(X\beta\) and \(\sigma\) still define an underlying lognormal.
   For every held-out row, this conversion instead divides integer-bin and
   100-plus probabilities by \(\Pr(n\geq6\mid X)\). It preserves the complete
   fixed held-out samples across every floor and estimator. For a higher-floor
   fit, however, predictions between 6 and the training floor are extrapolated
   from a distribution estimated only on the selected upper tail.

Both are necessary because they answer different questions. The first is the
proper score for the population on which the model was estimated. The second is
the fair common-row predictive comparison requested for the full eligible
universe, but its lower-tail transport is an extra modeling assumption. The two
conversions coincide at floor 6. Comparisons are valid between OLS and MLE at a
fixed floor and basis. Cross-floor comparisons must retain the distinction
between common-row transport and different conditional populations.

## Numerical safeguards

Normal interval probabilities are calculated in log space. Lower-tail CDFs are
used below zero and upper-tail survival functions above zero to avoid subtracting
nearly equal probabilities. Every window-floor fit must converge, improve weakly
on the OLS starting likelihood, remain away from broad sigma bounds, produce
finite held-out probabilities, and pass a distribution-normalization check.

## Results

The likelihood correction is substantively important, but it does not deliver
a uniform probability-calibration gain.

Every MLE converges without a warning and improves the exact in-sample objective
from its OLS starting value. Averaged across the ten windows, the training
log-likelihood gain per row is 0.102 at floor 6, 0.029 at floor 11, and 0.067 at
floor 30. The fitted shock scale also rises materially:

| Training floor | Mean OLS sigma | Mean truncated-MLE sigma |
|---:|---:|---:|
| 6 | 0.762 | 0.997 |
| 11 | 0.693 | 0.794 |
| 30 | 0.605 | 0.768 |

That change is not just cosmetic for a structural simulation: OLS on an
outcome-truncated sample understates the dispersion that the coherent
likelihood assigns to the underlying preferred-size distribution.

On the full fixed six-plus holdout, transporting each fit to the common
six-plus universe improves the exact rounded log score at all three floors:

| Training floor | OLS log score | MLE log score | MLE wins (of 10) |
|---:|---:|---:|---:|
| 6 | 4.570 | 4.527 | 9 |
| 11 | 4.941 | 4.714 | 10 |
| 30 | 6.060 | 4.865 | 10 |

The fixed X-selected 50--150 risk set is more demanding. Its exact rounded log
score changes from 5.734 to 5.768 at floor 6, from 5.674 to 5.657 at floor 11,
and from 5.914 to 5.716 at floor 30. Thus the floor-11 gain is small and occurs
in seven of ten windows, while floor 6 becomes slightly worse locally.

The binary 100-plus probability results are weaker. On the full common holdout,
the Brier score changes from 0.0973 to 0.1003 at floor 6, from 0.0930 to 0.0935
at floor 11, and from 0.1144 to 0.0982 at floor 30. On the fixed X-selected risk
set, the corresponding changes are 0.2314 to 0.2376, 0.1975 to 0.2000, and
0.2222 to 0.2091. Floor 30's large correction is useful evidence that naive OLS
handles severe outcome selection badly, but it is not a reason to make floor 30
the structural baseline.

Aggregate calibration tells a related but distinct story. The full validation
holdout averages 156.8 observed 100-plus filings. Floor-6 expected counts rise
from 129.6 under OLS to 149.7 under MLE, floor-11 counts move from 168.5 to
164.7, and floor-30 counts fall from 268.6 to 192.1. Yet mean absolute count
error across windows changes from 31.9 to 32.6, 16.7 to 19.2, and 111.8 to 35.3,
respectively. A closer average level can therefore coexist with worse variation
across validation periods. In the fixed X-selected risk set, which averages
75.3 observed 100-plus filings, expected counts change from 62.6 to 74.2 at
floor 6, 73.27 to 73.29 at floor 11, and 95.7 to 80.7 at floor 30. Mean absolute
count errors are 13.49 to 13.35, 7.21 to 8.28, and 20.37 to 12.15. These count
comparisons reinforce the conclusion that the likelihood correction helps some
aggregate biases but does not dominate OLS in every period or score.

The correct conclusion separates coherence from prediction. If a selected
training floor is used in the structural model, its distribution should be
estimated with the rounded truncated likelihood, not selected-sample OLS. But
MLE is not a free predictive improvement: floor-6 and floor-11 threshold
calibration is flat or slightly worse. Among the MLEs, floor 11 remains the
strongest policy-risk challenger on the common X-selected sample, with a 5.657
rounded log score versus 5.768 at floor 6 and 5.716 at floor 30. This cross-floor
comparison still relies on the explicitly labeled lower-tail transport and
does not by itself choose the structural estimation universe.

## Outputs

- `no_notch_truncated_likelihood_window_metrics.csv` contains every held-out
  metric by window, floor, model, and fixed sample.
- `no_notch_truncated_likelihood_validation_summary.csv` reports ten-window
  means, ranges, and the number of windows in which MLE beats OLS.
- `no_notch_truncated_likelihood_fit_qc.csv` records convergence, likelihood,
  sigma, rank, and normalization checks for every fit.
- `no_notch_truncated_likelihood_reference_coefficients.csv` records both sets
  of coefficients in the reference 2013--2020 training window.
- `no_notch_truncated_likelihood_reference_predictions.parquet` records both
  predictions for every reference held-out filing.
- `no_notch_truncated_likelihood_reference_fit_summary.txt` gives the reference
  likelihood and optimizer summary.

Run from `code/` with `make`.

# No-Notch Outcome-Scale Audit

This audit asks whether the preferred no-notch model performs better because it
uses log units rather than raw units. The transformation is substantive: log
OLS minimizes squared proportional errors, while raw-unit OLS minimizes squared
absolute unit errors and gives the largest projects much more influence.

The two models use exactly the same filings, forward validation windows,
training-only preprocessing, and right-hand-side variables:

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

The primary comparison treats both regressions as models of the selected sample
of filings with at least six units. Raw OLS directly predicts mean units. Its
predictions are clipped at six because values below the known sample support
are inadmissible. Log OLS predicts the center of log units. Its raw-unit mean is
recovered both under the maintained normal log shock,
`exp(X beta) * exp(sigma^2 / 2)`, and with the empirical Duan smearing factor.
Its median prediction is `exp(X beta)`.

Raw-unit RMSE and aggregate totals use predicted means. Unit MAE and log point
losses use predicted medians. Results are reported on the same scales for all
filings and the policy-relevant 50--150-unit range over every forward window.
The primary validation summary excludes the post-June-2022 transport windows.
R-squared values from regressions with different dependent variables are not
compared. AUC and hard-classification diagnostics at 100 units test ranking and
threshold separation without pretending that raw OLS supplies a probability.

This task intentionally does not turn raw OLS residuals into a normal
distribution and then condition again on six units. Because raw OLS is already
fit on the selected sample, that second conditioning would change its fitted
mean and create an unfair comparison. A full raw-normal versus lognormal
probability comparison requires estimating both models with a coherent
conditional likelihood. The existing negative-binomial alternative failed in
the reference and most recent validation windows.

## Main audit result

There is no scale-free winner. Averaged over the ten forward pre-policy
validation windows, the normal-retransformed log model has lower all-project
unit MAE (39.3 versus 46.5), log RMSE (0.838 versus 1.035), and a larger share
within a factor of two (65.7 versus 52.5 percent). Raw OLS has lower all-project
raw-unit RMSE (86.2 versus 90.0) and wins that criterion in six of ten windows.

Within the observed 50--150-unit sample, raw OLS has lower unit RMSE (60.2
versus 71.1) and log RMSE (0.762 versus 0.831). The log model has slightly lower
unit MAE (42.9 versus 45.9) and predicts aggregate units much more closely on
average: 1.038 times actual units versus 1.222 for clipped raw OLS. Raw OLS also
has slightly higher mean AUC for separating projects below and above 100, while
the log model's hard 100-unit classification is more conservative, with higher
specificity and lower sensitivity.

The reference 2013--2020 fit gives the same broad pattern. Log OLS has raw-unit
RMSE 87.4 versus 90.5 and log RMSE 0.788 versus 0.952 across all held-out
projects, but raw OLS has lower local raw-unit RMSE. The held-out actual mean is
80.1 units; predicted means are 73.6 under normal log retransformation, 77.8
under empirical smearing, and 80.5 under clipped raw OLS.

Run from `code/` with `make`.

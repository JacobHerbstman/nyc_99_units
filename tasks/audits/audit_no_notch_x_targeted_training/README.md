# Outcome-Free X-Targeted No-Notch Training Audit

This audit asks whether the no-notch model can focus on sites that look ex ante
like plausible 100-unit projects without selecting training rows using their
realized proposed units. It is an audit-only comparison. It does not replace
the broad floor-6 model or change any production dependency.

Every specification uses the current RHS and preprocessing:

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

The four models are:

- `floor6_unweighted`: the broad six-plus baseline.
- `floor11_unweighted`: the existing outcome-floor challenger. It is included
  for comparison but selects rows using their own realized units.
- `floor6_x_hard_50_150`: keeps floor-6 training rows whose leave-one-out
  X-predicted median is 50--150 units.
- `floor6_x_kernel_100`: keeps all floor-6 rows and applies a Gaussian weight
  centered at an X-predicted median of 100 units. The prespecified log bandwidth
  is `log(2)`.

The X-targeting score is the exact leave-one-out fitted value from the ordinary
floor-6 OLS within each outer training window:

```r
loo_prediction_i = log_units_i - residual_i / (1 - leverage_i)
```

Although this identity is written using row `i`'s observed outcome and full-fit
residual, algebraically it equals the prediction from refitting OLS after
removing row `i`. Thus row `i`'s weight depends on its pre-filing covariates and
other training rows, not on its own proposed units or shock. This preserves the
maintained iid-shock interpretation more cleanly than filtering on realized
units of at least 30. The score is learned anew inside each training window;
held-out outcomes never enter model fitting or targeting.

## Fixed evaluation design

The audit uses the same ten forward pre-policy validation windows as the other
no-notch audits. In each window, the ordinary floor-6 fit defines one held-out
risk set: sites whose X-predicted median is 50--150 units. That flag is computed
once using only training estimates and held-out X, then held fixed across all
four models. The full six-plus held-out universe is also reported to expose any
cost of local targeting.

The main comparison is the fixed X-risk set. Metrics cover point prediction,
aggregate units, exact rounded-lognormal probability, Brier score at 100, and
AUC. The rounded-lognormal calculations use one homoskedastic normal residual
RMS per model and condition probabilities on the maintained six-unit sample
floor. For the X-targeted models, weights depend only on cross-fitted X scores,
so estimating one weighted residual RMS remains compatible with the iid-shock
assumption. The floor-11 comparison does not have that advantage because its
sample is truncated using each row's outcome.

## Result

Neither outcome-free targeting rule improves the fixed X-risk set. Averaged
over the ten forward windows, the unweighted floor-6 model has log RMSE 0.846,
mean negative log probability 5.73, Brier score 0.231, and a predicted-to-actual
total-unit ratio of 0.912. The smooth X-kernel model worsens those quantities to
0.899, 5.78, 0.245, and 1.23. It wins only one of ten windows on log RMSE and one
on the probability score. The hard X-band model performs still worse: log RMSE
1.02, probability score 5.91, Brier score 0.280, and total-unit ratio 1.44.

The hard rule uses 159--689 training rows across windows. That loss of precision
is real, but it does not explain the kernel result: the kernel retains every
floor-6 row and has an effective sample size of 469--1,572. Its mean fitted
residual RMS is 0.899, versus 0.762 for unweighted floor 6. This suggests that
the current X-risk region contains unusually large residual variation or local
mean misspecification; simply putting more weight on those rows does not solve
either problem.

The outcome-selected floor-11 comparison remains better on this diagnostic
risk set, with log RMSE 0.792, probability score 5.67, Brier score 0.198, and a
total-unit ratio of 1.02. Those gains do not make it a coherent replacement for
the broad no-notch distribution: its own-unit floor truncates the residual and
changes the object being estimated. The audit therefore supports retaining
unweighted floor 6 as the broad baseline and floor 11 as a clearly labeled
conditional robustness specification. Neither X-targeted estimator should be
carried into the structural model.

## Interpretation guardrails

Targeted training can help only if the linear conditional-mean specification is
misspecified in a way that matters near the threshold. If the current linear
model and iid normal shock were exactly correct, unweighted floor-6 OLS would be
the efficient estimator and X-targeting should not improve systematically.
Any validation gain is therefore evidence about useful local approximation,
not evidence for a different structural shock distribution.

The leave-one-out targeting step prevents direct own-outcome selection, but it
does not make the first-stage score known without error. The ten windows also
overlap, so window win counts are robustness summaries rather than ten
independent experiments. Finally, every cutoff here is currently applied to an
individual HDB filing. The same exercise should be rerun at the legal-site or
parent-opportunity level once that crosswalk is available.

## Outputs

- `no_notch_x_targeted_window_metrics.csv` contains every model-window-sample
  metric.
- `no_notch_x_targeted_validation_summary.csv` reports ten-window means,
  ranges, and win counts.
- `no_notch_x_targeted_training_diagnostics.csv` reports actual and effective
  training sample sizes, residual RMS, weighted outcome composition, leverage,
  and held-out risk-set counts.
- `no_notch_x_targeted_reference_predictions.parquet` contains all four model
  predictions in the reference held-out window and the one fixed risk-set flag.
- `no_notch_x_targeted_reference_fit_summary.txt` records exact `summary(lm)`
  output for each reference-window fit.

Run from `code/` with `make`.

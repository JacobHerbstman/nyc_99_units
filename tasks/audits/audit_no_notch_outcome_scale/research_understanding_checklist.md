# Research Understanding Checklist

## Session goal

- [x] Determine whether the apparent predictive advantage of log units survives
  evaluation on the same raw-unit, log-unit, and threshold-probability metrics.
- [x] Separate outcome-scale choice from retransformation and point-functional
  choice.

## Analysis choices

- [x] Use identical samples, predictors, preprocessing, and forward windows.
- [x] Treat each regression as modeling the observed sample directly; do not
  condition an already selected raw-outcome regression a second time.
- [x] Use predicted means for squared raw-unit loss and aggregate totals.
- [x] Use predicted medians for absolute unit loss and current log point loss.
- [x] Use both normal retransformation and empirical smearing for log OLS.
- [x] Compare ranking and hard classification at 100 without treating either
  point prediction as a calibrated probability.
- [x] Report all-project and 50--150-unit samples separately.

## Interpretation guardrails

- [x] Do not compare R-squared across different dependent-variable scales.
- [x] Do not call `exp(X beta)` an expected raw unit count.
- [x] Treat the scale choice as substantive, not mechanical.
- [x] Record that log OLS wins typical-project and proportional losses over the
  full distribution, while raw OLS wins squared-unit loss overall and several
  local 50--150-unit losses.
- [x] Do not claim that either outcome scale uniformly predicts better.
- [x] Keep the latent preferred-size shock separate from bootstrap uncertainty
  and the later dollar-scale bunch/cross/split choice shock.
- [x] Defer probability-distribution comparison until both outcome scales have a
  coherent conditional likelihood.

Researcher restatement and quiz are `skipped_by_user` at this stage, following
the researcher's standing request. Revisit after the framework stabilizes.

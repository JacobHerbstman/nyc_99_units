# Research Understanding Checklist

## Session goal

- [x] Test whether a separate small-versus-larger-building equation improves
  held-out prediction of crossing 100 units.
- [x] Keep this binary-probability exercise separate from the structural
  distribution of preferred no-notch units.

## Data and sample

- [x] Use the same leakage-safe HDB--MapPLUTO sample beginning at six units.
- [x] Use the same ten validation and three transport windows as the main
  no-notch unit-distribution audit.
- [x] Learn numerical imputations, category pooling, factor levels, and the
  year center from each full training window only.
- [x] Use only pre-filing predictors already admitted to the simple baseline.

## Model choices

- [x] Reproduce the current simple rounded-lognormal probability of at least
  100 units.
- [x] Fit a direct 100-plus logit using the same right-hand side.
- [x] Fit sequential logits with cutoffs 11, 20, 30, and 40.
- [x] Estimate each cutoff gate on all six-plus filings and its conditional
  100-plus equation on the corresponding upper subset.
- [x] Evaluate all held-out filings rather than selecting the evaluation sample
  using realized proximity to 100.
- [x] Report Brier score, binary log score, AUC, expected and observed 100-plus
  counts, and absolute count error.

## Interpretation guardrails

- [x] Do not interpret a realized-unit cutoff as an ex-ante eligibility screen.
- [x] Do not claim that the sequential logit estimates the complete
  distribution of preferred units.
- [x] Do not use binary probabilities as exact preferred-unit draws in the
  bunch/cross/split model.
- [x] Record that cutoff 11 improves average binary validation but does not win
  every window or preserve the one-normal-shock model.
- [x] Keep the sequential logit diagnostic-only pending a coherent two-part
  unit-count likelihood.

Researcher restatement and quiz are `skipped_by_user` at this stage, following
the researcher's standing request. Revisit after the framework stabilizes.

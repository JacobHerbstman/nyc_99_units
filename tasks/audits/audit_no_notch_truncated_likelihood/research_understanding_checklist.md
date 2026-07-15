# Research Understanding Checklist

## Session goal

- [x] Replace post-selection OLS with a likelihood that explicitly conditions
  on the selected unit-count floor.
- [x] Preserve the single i.i.d. normal preferred-size shock and the existing
  rounded-lognormal distribution.
- [x] Distinguish statistical coherence from forward predictive improvement.

## Analysis choices

- [x] Hold the exact existing right-hand side and preprocessing fixed.
- [x] Use the same ten pre-policy forward-validation windows.
- [x] Compare floors 6 and 11, with floor 30 labeled diagnostic-only.
- [x] Preserve the complete, outcome-selected local, and fixed X-selected risk
  sets from the training-support audit.
- [x] Define the fixed X-selected sample with the floor-6 OLS fit in each window.
- [x] Evaluate OLS and MLE with the same rounded conditional probabilities.
- [x] Report training-floor-conditioned scores on observations inside the
  fitted floor's support and report excluded-row counts.
- [x] Also transport every fitted underlying distribution to the common
  six-plus universe and score it on the complete fixed evaluation samples.

## Numerical and interpretation guardrails

- [x] Calculate narrow normal-bin probabilities in log space using the stable
  tail on each side of zero.
- [x] Require full-rank design matrices, finite predictions, optimizer
  convergence, weak likelihood improvement, and probability normalization.
- [x] Do not interpret an MLE training-likelihood gain as held-out predictive
  improvement.
- [x] Compare estimators only within a common floor and fixed sample.
- [x] Label the higher-floor six-plus prediction as lower-tail extrapolation,
  distinct from the likelihood's training-floor conditional distribution.
- [x] Do not use floor-30 results to choose a structural sample without the
  separate substantive and selection arguments.
- [x] Keep latent-location point metrics visibly distinct from proper
  floor-conditional probability scores.

Researcher restatement and quiz are `skipped_by_user` at this stage, following
the researcher's standing request. Revisit after the framework stabilizes.

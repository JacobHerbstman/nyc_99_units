# Research Understanding Checklist

## Session goal

- [x] Test whether 6--10-unit and other small projects should determine the
  preferred-size model used near the 100-unit threshold.
- [x] Keep the model formula, preprocessing, and forward-validation windows
  fixed while varying only the training outcome floor.

## Analysis choices

- [x] Compare floors 6, 10, 11, 20, 30, 40, and 50.
- [x] Include floor 11 because it excludes the complete 6--10-unit range used
  in the statutory Small Rental Project definition.
- [x] Score every model on the same full six-plus holdout.
- [x] Label the realized 50--150-unit sample as outcome-selected.
- [x] Construct a fixed 50--150 risk set from the floor-6 model's predetermined
  covariates without using held-out units.
- [x] Use the existing ten pre-policy forward windows rather than choosing a
  floor from one train-test split.
- [x] Report normal-retransformed means separately from predicted medians.
- [x] Do not clip predictions at each candidate training floor.

## Interpretation guardrails

- [x] Do not treat lower residual RMS after outcome truncation as automatic
  evidence of better prediction or less structural heterogeneity.
- [x] Do not choose floor 30 from the outcome-selected local sample alone.
- [x] Treat floor 11 as an institutionally motivated challenger, not a
  data-mined universal replacement for floor 6.
- [x] Record that floor 11 is broader than the legal Small Rental Project
  definition because this audit does not apply all tenure, location,
  zoning-capacity, or Option C conditions.
- [x] Keep an X-selected risk set distinct from the final legal eligible-site
  and parent-opportunity crosswalk.
- [x] Do not plug a higher-floor OLS residual directly into the simulation
  without addressing conditional likelihood and possible double truncation.
- [x] Treat forward-window win counts as robustness summaries because the
  windows overlap and are not independent experiments.

Researcher restatement and quiz are `skipped_by_user` at this stage, following
the researcher's standing request. Revisit after the framework stabilizes.

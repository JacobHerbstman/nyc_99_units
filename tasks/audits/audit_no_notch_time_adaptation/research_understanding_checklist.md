# Research Understanding Checklist

## Session goal

- [x] Keep training floors 6 and 11 as fixed candidate universes.
- [x] Test two simple timing adaptations before freezing an interim model.
- [x] Rank only models that retain the static i.i.d. normal shock and a complete
  unit-count distribution.

## Analysis choices

- [x] Compare an expanding history, a trailing five-year fit, and an expanding
  fit whose intercept alone is updated on the latest two training years.
- [x] Use seven non-overlapping forward test periods from 2016 through June 15,
  2022.
- [x] Hold the right-hand side and rounded lower-truncated likelihood fixed.
- [x] Define the near-threshold risk set once per window from the expanding
  floor-6 OLS prediction and hold it fixed across all candidates.
- [x] Transport floor-11 predictions to the common six-plus universe and label
  the resulting 6--10-unit probabilities as lower-tail extrapolation.
- [x] Choose the interim model by average within-window rank across exact unit
  log score, Brier score at 100, CDF calibration from 80 to 120, and aggregate
  100-plus count error, in both the full sample and fixed risk set.

## Interpretation guardrails

- [x] Treat timing support as a robustness choice, not a dynamic developer
  model.
- [x] Do not interpret a recent-intercept update as a causal time effect.
- [x] Do not use actual held-out units to define the main risk set.
- [x] Do not promote a binary-only model that cannot simulate the full no-notch
  unit distribution.
- [x] Keep the legal-site crosswalk and vintage-specific zoning cap as future
  improvements rather than approximating them silently here.

Researcher restatement and quiz are `skipped_by_user`, following the
researcher's standing request while the framework is being stabilized.

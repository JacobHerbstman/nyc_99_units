# Research Understanding Checklist

## Question

- Why do held-out unit predictions still have large individual residuals?
- Can pre-filing covariates improve prediction without changing the economic
  object or introducing post-choice information?

## Current evidence

- [x] Separate repeated feature-lot filings from singleton filings.
- [x] Diagnose HDB-to-PLUTO address disagreement.
- [x] Restore historical `MaxAllwFAR` as a distinct pre-filing field.
- [x] Compare all candidate models over every forward validation window.
- [x] Compare building, singleton-diagnostic, and provisional site-year outcomes.
- [x] Remove rank-deficient specifications and verify all 624 fits complete cleanly.
- [x] Retain the simple local baseline; no structural extension improves the
  50--150-unit RMSE consistently enough to justify added complexity.
- [x] Export the exact preferred-model formula, preprocessing constants, factor
  levels, verbatim `summary(lm)` output, coefficient table, and held-out
  residual summary as reproducible audit outputs.

## Interpretation

- [x] Treat address disagreement as a crosswalk diagnostic, not a structural
  predictor, because the filing address can reflect the chosen configuration.
- [x] Treat historical `MaxAllwFAR` and broad capacity as useful full-support
  robustness variables; their local threshold gain is essentially zero.
- [x] Prioritize legal-site/root-job construction over additional nonlinear
  regressors: provisional site aggregation lowers mean error materially, but
  still is not the final economic observation.
- [x] Keep i.i.d. shocks at the eventual legal-site or parent-opportunity level,
  not at the level of correlated component filings.

## Guardrails

- [x] Keep shocks static and i.i.d. within each fitted model.
- [x] Do not use DOB proposed project design as a baseline predictor.
- [x] Do not use future feature-lot filing counts as a predictor.
- [x] Label site-year aggregation as provisional.
- [x] Keep all modeling choices explicit in the task Makefile.

Researcher restatement and quiz are skipped at the researcher's request for this
stage. Revisit them after the audit results stabilize.

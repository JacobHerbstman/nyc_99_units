# Research Understanding Checklist

## Session Goal
- [ ] Research question or task: understand the elastic-net prediction audit and score quintiles.
- [ ] Why this matters: the score may become an exposure/ranking device for later land-value analysis.
- [ ] What changed in this session: teaching walkthrough started; no code or model specification changed.

## Stage 1: Problem And Motivation
- [x] What problem existed? We need to distinguish candidate projects likely to be at least 100 units before studying post-policy bunching or land-value exposure.
- [x] Why did it exist? Raw proposed units after policy are potentially affected by the policy, so they cannot be treated as clean counterfactual intended size.
- [x] Why would a naive approach fail? Treating predicted scores as raw predicted units would overstate what the model identifies.
- [x] What branches or competing approaches were considered? Binary y100 score, log-unit rank score, and size-bin prediction.
- [x] Mastery status: mastered

## Stage 2: Data Provenance And Raw Inputs
- [x] What are the raw data sources? DCP Housing Database project rows and archived MapPLUTO lot files.
- [x] Which source is primary vs validation/supporting? HDB supplies filings/outcomes; MapPLUTO supplies pre-filing lot/zoning/building predictors.
- [x] What is the unit of observation? One HDB New Building filing row, joined to one selected BBL-vintage MapPLUTO lot row when available.
- [x] What is the sample window? Model audit uses train/test windows within the 2010-2023 panel; the policy cutoff is 2022-06-15 for validation/transport labels.
- [ ] What do the key columns mean? `classa_prop` is proposed permanent residential Class A units, not all possible residential/transient sleeping units.
- [ ] Which key columns are reliable, fragile, missing, or ambiguous?
- [x] Mastery status: mastered for main Class A outcome, source roles, and lagged MapPLUTO timing; all-unit sensitivity remains open

## Stage 3: Cleaning And Construction Logic
- [ ] What rows were included or excluded? HDB New Building rows in the leakage-safe panel, with valid positive integer Class A units, positive lot area, and candidate thresholds of 50+, 60+, or 70+.
- [x] What transformations were mechanical? Binary `y100`, log transforms for positive continuous fields, derived capacity fields, categorical cleanup, training-median numeric imputation plus missingness indicators.
- [ ] What decisions were subjective? Candidate thresholds trade off relevance near the 100-unit margin against sample size/power.
- [x] What edge cases were handled explicitly? Nonpositive or missing log inputs are not handled with `log1p`; positive values are logged and missing/zero status is carried through indicators.
- [x] What diagnostics check this stage? Time-holdout metrics, candidate-threshold sensitivity, score-bin reliability/capture, rank correlations, top-bin overlap, size-bin counts, and feature missingness.
- [x] Mastery status: mastered

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] What entities were joined? HDB filing rows to selected MapPLUTO lot rows by BBL plus selected source/vintage.
- [x] What makes the join safe or unsafe? It is safe only if MapPLUTO is unique by BBL/source/vintage and the join does not change HDB row count.
- [x] Were many-to-many joins avoided? Yes; code asserts `relationship = "many-to-one"` and stops if matched features have duplicate keys.
- [ ] What manual overrides or review decisions exist?
- [x] How are unresolved cases represented? They remain in the panel with explicit `exclusion_reason`, especially `no_mappluto_match`; duplicate MapPLUTO BBL cases are flagged rather than guessed.
- [ ] Mastery status: source join logic and unresolved-case representation mastered; manual review decisions not yet covered

## Stage 5: Analysis, Tables, And Plots
- [ ] What is the estimand or descriptive quantity? Score-bin enrichment among candidate filings.
- [ ] What is the denominator? Candidate new-building filings above a unit threshold, within a train/test time split.
- [ ] What comparison or aggregation is being shown? Actual 100+ shares across bins of predicted 100+ score.
- [ ] What plot/table choices affect interpretation? Quintiles emphasize ranking/exposure; raw probabilities require calibration.
- [ ] What sensitivity or robustness output should be read alongside the main result?
- [x] Mastery status: mastered for elastic-net regularization and score-bin interpretation

## Stage 6: Interpretation And Research Claims
- [ ] What can we safely claim?
- [ ] What remains only suggestive?
- [ ] What would be misleading to claim?
- [ ] What would change the conclusion?
- [ ] What belongs in the main text vs appendix/audit trail?
- [ ] Mastery status: unknown

## Open Questions
- [ ] Should the eventual production exposure score use ridge logit, elastic net, or both as main/robustness?
- [ ] Should score bins be quintiles, quartiles, or top-tail indicators in the land-value design?
- [ ] Should project-level multi-BBL features be added before freezing the production score?
- [ ] Should a Class B audit be added to document whether excluding transient/non-Class-A units ever changes near-99 project classification?

## Next Planned Stage: Local No-Notch Unit Distribution
- [ ] The existing binary score ranks 100+ exposure but is not a draw from
  (F_0(n^0\mid X)); a separate distributional audit is required.
- [ ] The initial outcome is preferred building-level Class A units. Parent
  opportunity totals require a symmetric pre/post grouping rule and remain a
  separate layer.
- [ ] The baseline should estimate a full conditional distribution of positive
  units using a simple log-unit model, not convert a binary probability into a
  unit count.
- [ ] Validation must evaluate CDF calibration and held-out histograms around
  99, not only AUC or mean prediction error.
- [ ] The 2010--2023 pool spans different market and tax-policy regimes; the
  primary estimate and recent/long-window sensitivities must be reported
  separately.
- [ ] Mastery status: implementation_not_started; quizzes_skipped_by_user.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-06-04 | Stage 1 | Restatement | Corrected: elastic net predicts y100, not unit quintiles. | Verify score-quintile interpretation. |
| 2026-06-04 | Stage 1 | Mastery check | Mastered: distinguished predicted units from predicted probability of 100+. | None. |
| 2026-06-04 | Stage 5 | Mastery check | Mastered with nuance: shrinkage stabilizes correlated/noisy predictors, not causal importance. | Explain score quintiles. |
| 2026-06-04 | Stage 5 | Mastery check | In progress: user identified sensitivity/noise; needs calibration vs ranking distinction. | Explain calibration. |
| 2026-06-04 | Stage 5 | Multiple choice | Mastered: chose ranking interpretation over raw units or literal calibrated probability. | Note quintile cutoffs are sample-specific. |
| 2026-06-04 | Stage 2 | User question | In progress: explained why Class A is the permanent housing outcome. | Verify statutory/policy denominator before final claims. |
| 2026-06-04 | Stage 2 | Edge case | Corrected: 99 Class A plus 20 Class B is included in 50+ sample but remains below 100 under the main Class A outcome. | Consider all-unit sensitivity audit. |
| 2026-06-04 | Stage 2 | Mastery check | Mostly mastered: y100 is correct; clarified that classa_prop is raw unit count, not percent. | None. |
| 2026-06-04 | Stage 2/4 | Mastery check | Mastered: lagged MapPLUTO avoids post-filing feature leakage from project/site changes. | Cover cleaning filters next. |
| 2026-06-04 | Stage 3 | Mastery check | Mastered: all buildings add irrelevant small-project contrast; 70+ loses power; 50+/60+/70+ show robustness. | Explain transformations. |
| 2026-06-04 | Stage 3 | Mastery check | Mastered: missingness may be selective, and dropping rows would waste scarce candidate-project data. | Explain edge cases/diagnostics. |
| 2026-06-04 | Stage 3 | Mastery check | Mastered: rejected `log1p`; use log-positive fields plus missing/zero handling instead. | Explain diagnostics. |
| 2026-06-04 | Stage 3 | Multiple choice | Mastered: chose time-holdout and threshold stability over in-sample AUC. | None. |
| 2026-06-04 | Stage 4 | User question | In progress: no-match rows mostly reflect BBLs not present in the selected lagged vintage, especially condo-like 7500+ lots. | Consider dedicated no-match/condo audit. |

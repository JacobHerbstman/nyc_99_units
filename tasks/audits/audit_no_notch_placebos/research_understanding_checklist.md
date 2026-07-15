# Research Understanding Checklist

## Session Goal
- [x] Research question: test whether similar excess mass appears at false years or false thresholds.
- [x] Why this matters: a model that manufactures spikes cannot support a structural response interpretation.
- [x] What changed: saved out-of-time predictions and evaluated thresholds 90, 100, 110, and 120.

## Stage 1: Problem And Motivation
- [x] Future observations must not enter placebo-year predictions.
- [x] Threshold and timing placebos address different threats.
- [x] Mastery status: skipped_by_user

## Stage 2: Data Provenance And Raw Inputs
- [x] 2016--2022 predictions come from the existing forward-validation task.
- [x] 2025 predictions come from the frozen post-policy scoring task.
- [x] 2022 is a partial year through June 15 and is flagged separately.
- [x] Mastery status: skipped_by_user

## Stage 3: Cleaning And Construction Logic
- [x] Preferred placebo models use expanding history and floor 6.
- [x] Required robustness uses rolling five-year history and floor 11.
- [x] All probabilities are conditioned on the common six-unit universe.
- [x] Mastery status: skipped_by_user

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] No joins are required beyond stacking uniquely identified prediction rows.
- [x] Period, model, and job identifiers are asserted unique.
- [x] Mastery status: skipped_by_user

## Stage 5: Analysis, Tables, And Plots
- [x] Exact-bin excess equals observed minus expected mass at threshold minus one.
- [x] Missing-above-threshold mass equals expected minus observed mass at or above the threshold.
- [x] Full-year placebo summaries exclude partial 2022 but the figure retains it.
- [x] Mastery status: skipped_by_user

## Stage 6: Interpretation And Research Claims
- [x] A unique 2025 threshold-100 spike supports a policy response interpretation.
- [x] Placebos cannot validate legal-site or parent classifications.
- [x] Calibration error in missing-above-threshold mass remains a separate diagnostic.
- [x] Mastery status: skipped_by_user

## Open Questions
- [ ] Repeat placebos after symmetric historical parent grouping is available.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-12 | All | Deferred at user request | skipped_by_user | Return later |

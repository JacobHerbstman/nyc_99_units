# Research Understanding Checklist

## Session Goal
- [x] Research question: can training emphasize the ex ante 100-unit risk set without filtering on each row's realized units?
- [x] Why this matters: an outcome floor such as 30 truncates the maintained shock, while an X-only rule need not.
- [x] What changed: added an audit-only comparison; no production model changed.

## Stage 1: Problem And Motivation
- [x] A realized-unit training floor selects observations partly by their shock.
- [x] X-targeting is useful only as a local-approximation check under misspecification.
- [x] Main versus competing approaches are explicit.
- [x] Mastery status: skipped_by_user (research quizzes are paused).

## Stage 2: Data Provenance And Raw Inputs
- [x] Primary input is the existing leakage-safe HDB--MapPLUTO training panel.
- [x] Unit of observation is an individual HDB filing, pending the legal-site crosswalk.
- [x] Ten forward pre-policy validation windows are inherited unchanged.
- [x] Mastery status: skipped_by_user.

## Stage 3: Cleaning And Construction Logic
- [x] Floor-6 eligibility and current training-only preprocessing are unchanged.
- [x] Each training row's score is an exact leave-one-out OLS prediction.
- [x] Hard and kernel targeting use that score, not the row's realized units.
- [x] Mastery status: skipped_by_user.

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] No new data join is performed.
- [x] The unresolved aggregation level is documented as a limitation.
- [x] Mastery status: skipped_by_user.

## Stage 5: Analysis, Tables, And Plots
- [x] The main denominator is one fixed held-out X-risk set per window.
- [x] All models are scored on identical held-out rows.
- [x] Full-universe metrics show the cost of targeting.
- [x] Proper probability and point-prediction metrics are both reported.
- [x] Mastery status: skipped_by_user.

## Stage 6: Interpretation And Research Claims
- [x] A gain supports a local approximation, not a new shock distribution.
- [x] Overlapping validation windows are not independent experiments.
- [x] The audit does not choose or alter the production baseline.
- [x] Mastery status: skipped_by_user.

## Open Questions
- [x] Neither X-targeted estimator improves consistently enough to justify a structural likelihood version.
- [ ] Do results survive legal-site and parent-opportunity aggregation?

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-11 | All | User requested no quiz | skipped_by_user | Revisit later |

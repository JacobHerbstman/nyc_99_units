# Research Understanding Checklist

## Session Goal
- [ ] Determine whether exact pre-filing parcel adjacency adds historical parent links.
- [ ] Keep exact adjacency separate from coordinate proximity and shared ownership.
- [ ] Measure how adjacency changes parent aggregation before model training.

## Stage 1: Problem And Motivation
- [ ] Centroid proximity does not establish that tax lots share a boundary.
- [ ] A later parcel snapshot can leak a realized subdivision or merger backward.
- [ ] Mastery status: skipped_by_user

## Stage 2: Data Provenance And Raw Inputs
- [ ] Filing pairs come from the 2019--2023 leakage-safe training sample.
- [ ] Parcel polygons come from frozen DCP MapPLUTO archives.
- [ ] The unit of the primary output is a pair of filings no more than 365 days apart.
- [ ] Mastery status: skipped_by_user

## Stage 3: Cleaning And Construction Logic
- [ ] The common snapshot is the release available before the earlier filing.
- [ ] Both filing BBLs must exist as valid, unique polygons in that snapshot.
- [ ] Exact touch is the baseline; one-meter near-touch is only a sensitivity.
- [ ] Automatic new links require exact touch plus a 30-day timing or leakage-safe owner corroboration signal.
- [ ] Mastery status: skipped_by_user

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [ ] Pair and polygon-edge keys are unique before joining.
- [ ] No many-to-many join is used.
- [ ] Missing historical BBLs remain unresolved rather than using future lot history.
- [ ] Mastery status: skipped_by_user

## Stage 5: Analysis, Tables, And Plots
- [ ] The denominator is all filing pairs in the selected years and filing-time window.
- [ ] Grouping sensitivity compares the prior conservative rule with exact adjacency.
- [ ] Mastery status: skipped_by_user

## Stage 6: Interpretation And Research Claims
- [ ] Exact adjacency is evidence of neighboring lots, not by itself common ownership.
- [ ] A parent link still requires the substantive assumption that near-simultaneous neighboring filings belong to one opportunity.
- [ ] An enhanced parent-outcome model cannot treat missing pre-2019 polygons as evidence that filings are singletons.
- [ ] A full-period conservative parent model and a 2019--2023 enhanced parent model answer related but distinct robustness questions.
- [ ] Mastery status: skipped_by_user

## Open Questions
- [ ] Whether exact adjacency alone is sufficient for automatic parent linking or should require owner, description, or lot-history corroboration.
- [ ] Whether the primary prediction specification should prioritize the 2010--2023 time span or the consistently measured 2019--2023 enhanced parent definition.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-13 | all | user-requested deferral | skipped_by_user | revisit after empirical work |

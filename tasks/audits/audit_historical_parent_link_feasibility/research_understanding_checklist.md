# Research Understanding Checklist

## Session Goal
- [ ] Determine which historical parent-link signals are observable without post-filing leakage.
- [ ] Explain why parent reconstruction changes the unit of the no-notch model.
- [ ] Keep the feasibility audit separate from a final parent crosswalk or model.

## Stage 1: Problem And Motivation
- [ ] A same-BBL rule misses adjacent-lot and multi-site development opportunities.
- [ ] A current lot-history crosswalk can inadvertently use post-filing information.
- [ ] Mastery status: skipped_by_user

## Stage 2: Data Provenance And Raw Inputs
- [ ] HDB supplies the historical filing universe, descriptions, and coordinates.
- [ ] DOB NOW supplies filing owners and descriptions only from 2021 onward.
- [ ] Frozen PLUTO releases contain tax-lot owners, coordinates, APPBBL, and APPDate.
- [ ] Archived MapPLUTO shapefiles provide exact parcel geometry from 2018 onward.
- [ ] Mastery status: skipped_by_user

## Stage 3: Cleaning And Construction Logic
- [ ] Owner matches are exact normalized-name candidates, not beneficial-ownership proof.
- [ ] Coordinate proximity does not prove adjacency.
- [ ] APPBBL signals are classified by whether their evidence was available by filing.
- [ ] Mastery status: skipped_by_user

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [ ] All source joins assert one-to-one or many-to-one cardinality.
- [ ] Duplicate raw BBLs are left unmatched rather than collapsed silently.
- [ ] Candidate pairs remain audit records; they are not automatic parents.
- [ ] Mastery status: skipped_by_user

## Stage 5: Analysis, Tables, And Plots
- [ ] Coverage is reported by filing year and signal.
- [ ] The denominator is the preferred 2010--2023 leakage-safe six-plus-unit training sample.
- [ ] Mastery status: skipped_by_user

## Stage 6: Interpretation And Research Claims
- [ ] The audit establishes feasibility and limits, not a final historical parent definition.
- [ ] Post-filing lot transitions belong in an outcome audit unless separately justified.
- [ ] Mastery status: skipped_by_user

## Open Questions
- [ ] Whether pre-2018 centroid candidates justify manual adjacency review or require another parcel-geometry archive.
- [ ] Whether tax-lot owner matches should be supplemented with beneficial-ownership records.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-12 | all | user-requested deferral | skipped_by_user | revisit after empirical work |

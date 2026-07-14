# Research Understanding Checklist

## Session Goal

- [ ] Research question: identify DOB buildings, candidate legal sites, and candidate parent development opportunities around the 99-unit bunching point and 100-unit policy threshold.
- [ ] Why this matters: incorrect grouping can turn unrelated buildings into false splits or divide one project into false independent observations.
- [ ] What changed: a new audit records pairwise evidence and provisional parent groups without making legal-site claims.

## Stage 1: Problem And Motivation

- [ ] A filing BBL is not necessarily a legal 485-x eligible site.
- [ ] A repeated 99-unit filing is not by itself evidence of a successful split.
- [ ] Mastery status: skipped_by_user.

## Stage 2: Data Provenance And Raw Inputs

- [ ] DOB NOW initial New Building filings are the primary job/building source.
- [ ] Current MapPLUTO APPBBL records are supporting lot-history evidence.
- [ ] The main output has one row per DOB root job.
- [ ] The exact-99 casebook has one row per 2025 initial 99-unit root job and
  retains later amendments separately from the initial filing.
- [ ] Mastery status: skipped_by_user.

## Stage 3: Cleaning And Construction Logic

- [ ] The audit anchors on 2025 99-unit jobs and searches 2024--2026 New Building filings with 6--1,000 integer proposed units for companions.
- [ ] Owner and applicant names are normalized only for exact string matching.
- [ ] Distance, filing window, and bunching-point definitions are explicit Make variables.
- [ ] Mastery status: skipped_by_user.

## Stage 4: Joins, Crosswalks, And Manual Decisions

- [ ] Root job and APPBBL join keys are checked for uniqueness before joining.
- [ ] Candidate pairs retain separate evidence flags rather than one opaque score.
- [ ] Public corroboration is stored as a source-linked manual input and cannot
  mechanically validate an eligible site.
- [ ] Eligible-site status remains `not_legally_validated` until official evidence exists.
- [ ] Mastery status: skipped_by_user.

## Stage 5: Analysis, Tables, And Plots

- [ ] This task produces an audit crosswalk and review queue, not a structural estimate.
- [ ] Candidate groups are anchored by at least one 99-unit job.
- [ ] The decomposition denominator is 52 distinct 2025 DOB jobs and 52 distinct initial DOB BINs proposing exactly 99 units.
- [ ] Mastery status: skipped_by_user.

## Stage 6: Interpretation And Research Claims

- [ ] Candidate groups may be described as cases for review, not confirmed legal splits.
- [ ] HPD applications or zoning-lot documents are still required for legal validation.
- [ ] Filing, amendment, permit, and completion are distinct stages; an initial
  or amended unit count is not automatically the final built outcome.
- [ ] Mastery status: skipped_by_user.

## Open Questions

- [ ] Which historical MapPLUTO vintage best represents each filing date?
- [ ] Which DOB plan documents can establish zoning-lot membership?
- [ ] What HPD fields can validate one eligible site or separate eligible sites?

## Findings From Initial Candidate Review

- [ ] Thirty-three of the 52 observed 99-unit jobs belong to a multi-job candidate group.
- [ ] Twenty-six 99-unit jobs belong to ten groups containing at least two 99-unit jobs.
- [ ] Five repeated-99 groups cross filing BBLs; five place repeated 99-unit jobs on one DOB filing BBL.
- [ ] Eleven of the 17 multi-job groups contain direct same-BBL or APPBBL lot-history evidence.
- [ ] Five additional groups have strong common-owner, common-applicant, timing, and proximity evidence without a common parcel identifier.
- [ ] Candidate 2025-007 is likely over-merged by the 250-meter rule and should remain unresolved.
- [ ] DOB and HDB BBL/BIN assignments differ in several repeated-99 groups, so neither source alone identifies the filing-date legal site.
- [ ] HPD's application form requests total project buildings and units, current and former tax lots, BINs, docket, and site-level wage compliance.
- [ ] The expanded search still assigns 33 of 52 99-unit jobs to candidate multi-building developments: 26 in repeated-99 groups and seven with non-99 companions.
- [ ] Nineteen of 52 jobs currently appear as standalone 99-unit DOB buildings.
- [ ] Only 19 anchors have a complete 365-day forward search window; 11 of those 19 are in candidate multi-building developments.
- [ ] The 100-meter main radius removes the questionable 2025-007 link; the 2024--2026 companion search adds one 46+99 candidate group.
- [ ] Two same-owner pairs between 100 and 250 meters remain review-only and do not affect the main decomposition.
- [ ] Several different-owner same-block pairs remain unresolved and could cause the standalone count to be too high if the LLCs share beneficial ownership.
- [ ] All 52 exact-99 anchors use distinct initial DOB BINs, so each histogram observation is a distinct administrative building filing.
- [ ] None of the 52 exact-99 filings is currently withdrawn.
- [ ] DOB descriptions contain four explicit companion-job cross-references and a common `MPP459` project code across the six-building Queens group.
- [ ] Contemporaneous reporting identifies 2433 Atlantic Avenue and 28 Havens Place as two 99-unit buildings on one development site and explicitly connects the design to the 485-x wage threshold.
- [ ] The four 99-unit Empire Boulevard filings sit on the site of an earlier unified 261-unit development proposal; their legal 485-x treatment remains unverified.
- [ ] The main unresolved queue contains three high-priority different-owner pairs: one adjacent 54+99 pair and two nearby 99+99 pairs.
- [ ] Twenty-nine of 52 exact-99 jobs have an observed post-approval amendment;
  all 29 continue to report 99 units and none shows an observed unit change.
- [ ] All 52 exact-99 jobs match HDB on units, while six disagree on BBL and 11
  disagree on BIN across source snapshots.
- [ ] The casebook contains 26 repeated-99 jobs, two high-priority
  different-owner 99 jobs, seven 99 jobs with non-99 companions, ten unlinked
  right-censored jobs, and seven unlinked jobs with a complete forward window.
- [ ] All ten repeated-99 candidate parents have a source-linked commercial
  real estate investigation record, including explicit distinctions between
  direct avoidance reporting, strong circumstantial evidence, and suggestive
  administrative configurations.
- [ ] Atlantic Avenue/Havens Place has direct reporting of a common development
  and 485-x wage avoidance.
- [ ] The 165th Street MPP 459 group has five 99-unit buildings and one smaller
  companion totaling 591 units on the reported zoning lot.
- [ ] The Empire Boulevard site moved from a publicly described unified
  261-unit proposal to four 99-unit filings totaling 396; interpreting this as
  485-x avoidance remains a strong inference rather than a reported fact.

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-10 | All | User requested no quizzes | skipped_by_user | Revisit after initial empirical work |

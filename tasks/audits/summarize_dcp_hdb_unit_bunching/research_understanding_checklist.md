# Research Understanding Checklist

## Session Goal
- [x] Research question or task: understand the data-cleaning and plotting pipeline behind the DCP HDB 99-unit bunching figures.
- [x] Why this matters: these plots are intended to be shown to an advisor, so the sample definition, denominator, timing variable, and unit-count variable need to be defensible.
- [x] What changed in this session: no data or figure logic changed; this note documents the existing pipeline.

## Stage 1: Problem And Motivation
- [x] What problem existed? We needed to distinguish a real 2025 filing spike at 99 units from artifacts of timing, binning, status, duplicates, or changing pre-period windows.
- [x] Why did it exist? The DCP Housing Database is an application/project file with several dates, statuses, and unit measures.
- [x] Why would a naive approach fail? Counting all rows without a stable job type, filing date, positive unit count, or pre-period denominator could manufacture or hide a spike.
- [x] What branches or competing approaches were considered? DateFiled versus DatePermit, exact counts versus 5-unit bins, full pre-period versus regime-specific pre-period cuts.
- [x] Mastery status: skipped_by_user

## Stage 2: Data Provenance And Raw Inputs
- [x] What are the raw data sources? DCP Housing Database project-level CSV ZIP, release 25Q4, fetched from the NYC Planning source metadata.
- [x] Which source is primary vs validation/supporting? DCP HDB project-level data are primary; audit CSVs are validation/supporting outputs.
- [x] What is the unit of observation? One DCP HDB project/application record.
- [x] What is the sample window? DateFiled from 2010-01-01 through 2025-12-31.
- [x] What do the key columns mean? Job type defines new-building applications; DateFiled defines timing; ClassAProp defines proposed Class A dwelling units.
- [x] Which key columns are reliable, fragile, missing, or ambiguous? DateFiled is complete for New Building rows in this release; ClassAProp is treated as the main unit-count field; DatePermit is sensitivity-only because many recent filings are not yet permitted.
- [x] Mastery status: skipped_by_user

## Stage 3: Cleaning And Construction Logic
- [x] What rows were included or excluded? Include only New Building rows, filed 2010-2025, with positive integer ClassAProp.
- [x] What transformations were mechanical? Column-name normalization, date parsing, borough/CD/council standardization, numeric casting, address concatenation.
- [x] What decisions were subjective? Using DateFiled as primary timing, ClassAProp as the outcome, excluding 2024 from the headline pre/post figure, and using 50-150 units as the display range.
- [x] What edge cases were handled explicitly? Missing dates, nonpositive or missing unit counts, noninteger unit counts, alternate date basis, application status, and duplicate 2025 99-unit site keys.
- [x] What diagnostics check this stage? Sample QC, date-basis sensitivity, status sensitivity, duplicate-site QC, exact count tables, near-threshold yearly tables.
- [x] Mastery status: skipped_by_user

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] What entities were joined? No cross-dataset joins are used in this plotting task.
- [x] What makes the join safe or unsafe? Not applicable here; the task only reads a staged DCP HDB parquet.
- [x] Were many-to-many joins avoided? Yes, no joins are used in the active plot construction.
- [x] What manual overrides or review decisions exist? None in this task.
- [x] How are unresolved cases represented? Not applicable.
- [x] Mastery status: skipped_by_user

## Stage 5: Analysis, Tables, And Plots
- [x] What is the estimand or descriptive quantity? Filed New Building applications per year by proposed Class A unit count.
- [x] What is the denominator? Pre-period totals are annualized by years in the baseline period; 2025 is a one-year count.
- [x] What comparison or aggregation is being shown? Exact-unit or 5-unit-bin distributions for pre-period baselines versus 2025.
- [x] What plot/table choices affect interpretation? Date basis, annualization, display range, bin width, free y-scales, and omission of 2024 from headline pre/post plots.
- [x] What sensitivity or robustness output should be read alongside the main result? Pre-period sensitivity, bin sensitivity, date-basis sensitivity, status sensitivity, and duplicate-site QC.
- [x] Mastery status: skipped_by_user

## Stage 6: Interpretation And Research Claims
- [x] What can we safely claim? In DCP HDB New Building filings, 2025 has a large exact 99-unit spike relative to multiple pre-period annualized baselines.
- [x] What remains only suggestive? The causal mechanism behind the spike and whether every filing corresponds to an eventual built project.
- [x] What would be misleading to claim? That these are completed buildings or permitted buildings in the headline plot; they are filed applications by DateFiled.
- [x] What would change the conclusion? A major DCP source issue in ClassAProp, a duplicate-record artifact concentrated at 99, or an alternate date basis that eliminates the spike.
- [x] What belongs in the main text vs appendix/audit trail? Main text can show the headline plot; date/status/bin/pre-period/duplicate diagnostics belong in audit or appendix.
- [x] Mastery status: skipped_by_user

## Open Questions
- [ ] Confirm whether advisor-facing language should say "filed New Building applications" rather than "new buildings" throughout.
- [ ] Decide whether the 2024 transition-year pattern belongs in main text or appendix.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-09 | all | skipped at user request | skipped_by_user | none |

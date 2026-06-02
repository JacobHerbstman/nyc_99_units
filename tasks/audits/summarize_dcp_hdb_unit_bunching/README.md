# DCP Housing Database Unit Bunching Audit

This audit checks whether proposed new-building unit counts bunch below the 485-x 100-unit threshold in the DCP Housing Database.

## Main Definition

- Unit of observation: DCP Housing Database project-level record.
- Sample: `job_type == "New Building"`, positive integer `classa_prop`, and `date_filed` from 2010-01-01 through 2025-12-31.
- Timing: `date_filed`, because the descriptive target is filing/proposal behavior.
- Size: `classa_prop`, because the descriptive target is proposed Class A units.
- Headline pre/post figure: average annual 2010-2023 distribution versus 2025 distribution.
- Figure outputs: PDF only.
- Transition marker: April 20, 2024, the statutory adoption date for RPTL 485-x.

## Interpretation

The primary figure is a descriptive audit of proposed Class A unit counts in DOB-approved new-building jobs by filing date. It is not a legal classification of 485-x eligibility or take-up.

The DCP project-level record may differ from the legal eligible site. That distinction matters for split or adjacent 99-unit filings: the project-level distribution is useful for detecting the pattern, but follow-up work must link BBLs, owners, applicants, architects, lenders, and acquisition histories before interpreting a cluster as site-level avoidance.

## Planned Sensitivities

- Replace `date_filed` with `date_permit`.
- Replace `classa_prop` with `classa_net`.
- Replace `classa_prop` with `units_co`, restricted to completed jobs.
- Collapse likely same-site/job clusters by BBL or by address/date proximity.

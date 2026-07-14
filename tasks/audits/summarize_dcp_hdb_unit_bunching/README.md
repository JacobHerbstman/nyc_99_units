# DCP Housing Database Unit Bunching Audit

This audit checks whether proposed new-building unit counts bunch below the 485-x 100-unit threshold in the DCP Housing Database.

## Main Definition

- Unit of observation: DCP Housing Database project-level DOB job/application record.
- Sample: `job_type == "New Building"`, positive integer `classa_prop`, and `date_filed` from 2010-01-01 through 2025-12-31.
- Timing: `date_filed`, because the descriptive target is filing/proposal behavior. `date_permit` is audited separately because it is the right field for approved permits.
- Size: `classa_prop`, because the descriptive target is proposed Class A units.
- Headline pre/post figure: average annual 2010-2023 distribution versus 2025 distribution.
- Figure outputs: PDF only.
- Transition marker: April 20, 2024, the statutory adoption date for RPTL 485-x.

## Interpretation

The primary figure is a descriptive audit of proposed Class A unit counts in filed New Building applications by filing date. It is not a permit-approval series, a completion series, or a legal classification of 485-x eligibility or take-up.

The DCP project-level record may differ from the legal eligible site. That distinction matters for split or adjacent 99-unit filings: the project-level distribution is useful for detecting the pattern, but follow-up work must link BBLs, owners, applicants, architects, lenders, and acquisition histories before interpreting a cluster as site-level avoidance.

## Audit Outputs

- Exact pre/post count comparisons by proposed unit count.
- Top 2025 spikes relative to the 2010-2023 annualized distribution.
- Near-threshold yearly counts from 95 through 105 proposed units.
- `date_filed` versus nonmissing `date_permit` sensitivity counts.
- Job-status composition by period.
- Pre-period robustness cuts around 421-a/Affordable New York timing.
- Pre-period regime-cut plots against the repeated 2025 comparison distribution.
- Monthly 2024-2025 timing for exact 99-unit filings.
- Row-level 2025 99-unit application list with job number, BBL/BIN, address, dates, and status.
- Geography and duplicate-site checks for the 2025 99-unit applications.

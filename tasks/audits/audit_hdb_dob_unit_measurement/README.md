# HDB-DOB unit measurement audit

This audit investigates every 2025 unit-count disagreement after the corrected
root-job join. It keeps the HDB outcome and DOB NOW filing measure separate
rather than silently choosing one during the join.

The sources measure related but different objects. DOB defines each row as a
filing: `I1` is the single initial filing, `S` is a subsequent filing, and `P`
is a post-approval amendment. Its proposed dwelling-unit field is the number
reported by the applicant for that filing, and the public dataset updates
daily. HDB is a project-level file. Its `ClassAProp` field starts from the
applicant count but is edited by DCP to count Class A units, and the local
source is the frozen 25Q4 release.

## Findings

- 588 of 619 exact root-job matches have the same unit count. The other 31
  disagree, a 5.0 percent disagreement rate.
- The median absolute disagreement is 5 units. Nine differ by one unit and
  four differ by at least 16 units. Across matched rows, HDB reports 345 fewer
  units than the current DOB I1 fields, largely because of the largest
  supportive or non-Class-A cases.
- Two disagreements are explicit DCP edits to `ClassAProp`. At 245 Clarkson
  Avenue, HDB reports 49 Class A and 86 other Class B units, which exactly
  reconciles to DOB's 135. The 148-15 Archer Avenue record also has an
  explicit Class A/Class B edit, although its two source vintages do not
  arithmetically reconcile.
- Five roots contain conflicting unit counts across DOB filings, with another
  filing reporting the HDB count. Eleven more have a changed project
  description or proposed floor count between HDB and the current DOB record.
  The remaining 13 are unresolved cross-vintage unit differences: the local
  files show the discrepancy but not when or why it arose.
- The 108-unit outlier at 172 Montrose Avenue changes from HDB's 55 units to
  DOB's 163 while the current DOB description adds nonprofit sleeping
  accommodations. This is consistent with a Class A versus other sleeping-use
  issue, but the HDB edit field does not confirm that interpretation, so the
  audit leaves it unresolved.

## Exact-99 cases

All three threshold-classification disagreements run in the same direction:

- `Q01338971`: HDB 99, I1 79, S1 99;
- `X01228107`: HDB 99, I1 97, S4 99; and
- `X01223342`: HDB 99, I1 98, S5 and S6 99.

The subsidiary filings corroborate the HDB count but do not become a new
authority rule; work-type filings can carry inconsistent project attributes.
Using HDB where an eligible HDB root match exists and DOB I1 otherwise changes
the descriptive 2025 parent-file exact-99 count from 52 to 55.

## Measurement recommendation

Use HDB `ClassAProp` as the primary unit outcome for HDB-matched projects. It
matches the outcome used to train the historical model, preserves DCP's Class
A corrections, and keeps the post outcome on the same source concept as the
pre-period outcome. Keep DOB I1 units as a named sensitivity.

For post-policy parent totals, report two versions:

1. HDB-priority: HDB units for eligible matched roots and DOB I1 units only
   for components without an eligible HDB match, with the source composition
   flagged; and
2. all-DOB sensitivity: DOB I1 units for every component.

This is a provisional measurement resolution, not a claim that HDB is
error-free. The production parent model should be changed only after the two
versions are compared explicitly.

The field definitions come from the HDB data dictionary stored with the 25Q4
raw release and the data dictionary attached to the official DOB NOW Job
Application Filings dataset:
https://data.cityofnewyork.us/d/w9ak-ipjd.

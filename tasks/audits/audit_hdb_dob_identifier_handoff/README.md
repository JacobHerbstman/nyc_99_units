# HDB-DOB identifier handoff audit

This audit separates identifier matching from the parent sample's six-unit
analysis restriction. It compares the 2025 HDB sample with the
unfiltered staged DOB NOW initial New Building filings, then checks which
exact root-job matches survive into the filtered post-policy parent
crosswalk.

The HDB data dictionary defines `Job_Number` as the DOB application number
assigned when an applicant begins an application and `DateFiled` as the
pre-filing date when that number is assigned. DCP also corrects source errors
and geocodes its records, so HDB and the original DOB NOW filing can disagree
on BBL, BIN, or address even when the application number is identical.

## Findings

- 624 of 626 eligible HDB rows match the unfiltered DOB NOW extract on the
  exact root job number. All 624 also have the same filing date.
- 619 exact matches enter the parent crosswalk. The other five are not
  identifier failures: their DOB NOW filings report 2--5 units, below the
  six-unit crosswalk minimum, while HDB reports 6--8 Class A units.
- The two HDB root jobs absent from the frozen July 10, 2026 DOB NOW pull each
  have a later New Building filing on the exact same BBL, BIN, and address
  under a different root job. The later filing occurs 64 days after the HDB
  date at 869 Linden Boulevard and 219 days after it at 1058 Burke Avenue.
  These are documented as same-site candidates, not assumed replacements.
- Among the 624 exact root matches, HDB and DOB NOW differ on 28 BBLs, 66
  BINs, and 31 normalized addresses. This is compatible with DCP's documented
  geocoding and correction work and does not overturn the exact application
  number and filing-date match.

The production handoff should therefore join HDB `job_number` to the DOB
`root_job_id`. Match coverage should be measured against the unfiltered DOB
initial-filing extract, not against a crosswalk that has already imposed the
outcome sample restriction. The two different-root same-site cases should
remain unresolved unless a separate, explicit replacement rule is justified.

The unit-count disagreements are intentionally left to a separate audit.

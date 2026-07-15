# Developer Opportunity Crosswalk Audit

This audit begins the crosswalk from DOB root jobs to candidate 485-x sites and
parent economic development opportunities. It deliberately records observable
administrative evidence without treating a filing BBL as a legally validated
485-x eligible site.

The unit of observation in the main output is one initial DOB NOW New Building
root job. The default audit anchors on 2025 jobs proposing exactly 99 units and
searches for companion New Building jobs proposing 6--1,000 units in 2024--2026.
The expanded window avoids defining a building as standalone merely because a
related building is smaller or was filed in an adjacent calendar year.

## Outputs

- `developer_opportunity_job_crosswalk.parquet` records root-job, building,
  filing-lot, MapPLUTO lot-history, owner, applicant, and candidate-parent IDs.
- `developer_opportunity_candidate_pairs.csv` is the review queue for pairs in
  which at least one job proposes 99 units and the jobs share a filing BBL, a
  MapPLUTO lot-history group, a block, or the same nearby owner.
- `developer_opportunity_unresolved_pair_review.csv` isolates pairs not linked
  by the main rule and prioritizes adjacent different-owner and repeated-99
  cases for beneficial-owner, zoning-lot, and filing-document review.
- `developer_opportunity_candidate_groups.csv` summarizes connected candidate
  parent opportunities anchored by at least one 99-unit job.
- `developer_opportunity_exact_99_casebook.csv` contains one row for each of
  the 52 exact-99 initial filings. It combines initial and amendment history,
  HDB agreement checks, physical fields, candidate-parent evidence, a review
  priority, public corroboration where available, and the next record needed.
- `developer_opportunity_bunching_decomposition.csv` reports the share of
  99-unit jobs that appear alone, with non-99 companion buildings, or in a
  candidate parent containing multiple 99-unit buildings. It reports the full
  sample and the subset with a complete 365-day forward search window.
- `developer_opportunity_crosswalk_qc.csv` reports sample counts, missingness,
  APPBBL coverage, amendment checks, HDB agreement, and candidate-group counts.

The public evidence in `input/manual_case_evidence.csv` is deliberately narrow
and source-linked. It can corroborate a common economic development context,
but it never changes `legal_485x_site_status` from `not_validated`.
`input/manual_repeated_99_parent_investigation.csv` records the commercial real
estate reporting review for all ten repeated-99 candidate parents. It separates
common-parent evidence from evidence that the configuration responds to 485-x,
and labels project-specific reporting separately from developer-level context.

## Candidate-parent rule

Two jobs receive a strong candidate-parent link when they fall within the
specified filing window and share a filing BBL, share a MapPLUTO APPBBL
lot-history group, or have the same normalized owner within the main proximity
radius. Connected strong links define candidate parent opportunities. A wider
review radius retains possible links for manual review without merging them.
These rules are audit devices, not claims that jobs share a legal zoning lot,
one 485-x application, or one economic decision-maker.

The APPBBL crosswalk comes from current MapPLUTO and can describe a lot change
dated before or after the DOB filing. The audit retains those dates explicitly.
It does not yet reconstruct the precise tax-lot state on every filing date.

The filing-history input separates initial filings from observed post-approval
amendments and subsequent filings. An unchanged 99-unit count in an amendment
is evidence that the initial count persisted at that administrative stage; it
is not a substitute for a final certificate of occupancy or an HPD benefit
application. Likewise, the HDB comparison is a source-agreement check rather
than a rule for silently replacing DOB identifiers.

Run the task from `code/` with `make`. The Makefile exposes the anchor year,
companion years and unit range, 99-unit bunching point, main and review radii,
and filing window as scalar audit choices.

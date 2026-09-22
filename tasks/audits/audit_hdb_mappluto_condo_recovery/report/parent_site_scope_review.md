# Current parent-site allocation review — September 22, 2026

After adopting the inactive-inclusive HDB 23Q4 archive for historical proposals,
the boundary and filing checks flag **152 of 905 weighting parents**. The other
753 pass the current checks. A flag identifies an unresolved question about
coverage or allocation, not a confirmed measurement error.

| Sample | Parents checked | Pass boundary/filing checks | Flagged |
| --- | ---: | ---: | ---: |
| 2019–2022 | 595 | 475 | 120 |
| January 2025–July 8, 2026 | 310 | 278 | 32 |
| Total | 905 | 753 | 152 |

The denominator is the canonical rental-opportunity sample with at least 50
units and `composition_eligible = TRUE`. Eleven historical and 17 post-period
rental parents of this size remain outside the weighting sample because of
composition eligibility.

## Reconciliation with the former 111

Of the 111 previously queued cases, 103 remain flagged in the current weighting
sample. Two old cases now form one parent, giving 102 distinct current flagged
parents. Eight leave the weighting sample; they have not been resolved. None
of the former queued cases was cleared by changing the source.

The additional 50 flagged parents comprise 29 newly entering the sample and
21 previously supported parents flagged by the revised filing information.
The two reconciliation tables follow both the old cases and current parents
through filing IDs, preserving mergers and sample exits explicitly.

## Applied decisions and evidence scope

The [five-merger and 23-case review](mergers_and_23_review.md),
[floor decisions](five_floor_decisions.md), and
[September 22 continuation](next_ten_boundaries_2026-09-22.md) preserve the
sources for applied land allocations. The
[follow-up](queued_followup_2026-09-22.md) records Wallabout's calculation and
the evidence that prompted the common historical source correction.
Production decisions belong to `parent_opportunities_manual`.

All 40 production land decisions pass their explicit filing-set checks.
Of the scope audit's 45 documentary reviews, 42 apply to the current weighting
sample. West 48th Street leaves that sample. The two Jamaica/Sutphin records
refer to separate filing sets now mechanically linked into one parent; neither
old allocation establishes the merged parent's complete boundary. Prior
research remains evidence with its original scope, rather than automatically
approving a changed parent.

The historical panel uses archived units, dates, lot and building identifiers,
status, descriptions and ownership fields. Livingston now has 144+105=249
units. Post-period outcomes and covariates are unchanged. The broader archived
filing inventory can still expose a boundary question for a post-period parent,
which explains why its flagged count can change with the same post-period data.

## Remaining inventory

Each flagged parent appears below under its first applicable reason.
Overlapping flags remain in the output. Approved floor estimates retain their
own flags separately.

| Primary question | Historical | Post-policy | Total |
| --- | ---: | ---: | ---: |
| Filing lot list differs from mapped site | 1 | 0 | 1 |
| Incomplete earlier map or area | 9 | 0 | 9 |
| Missing later parcel map | 8 | 5 | 13 |
| Other filing in transaction envelope | 1 | 2 | 3 |
| Partial earlier parcels require allocation | 37 | 10 | 47 |
| Shared earlier land or other filing | 60 | 13 | 73 |
| Source or reference-date disagreement | 4 | 2 | 6 |
| Total | 120 | 32 | 152 |

Among the 753 parents passing the boundary screen, 227 candidate areas differ
from production by more than one square foot. Passing that screen alone does
not establish the earlier building-floor and zoning allocation needed for
production. Those candidate covariate changes also require review.

## Checks and land convention

The audit searches saved HDB and DOB NOW New Building filings, including small
residential and observed nonresidential jobs. It preserves source identifiers,
expands documented condominium bases, searches filing points within earlier
parcel unions, and follows dated DOF transactions. A transaction expands the
search; it does not automatically assign its entire land to a parent. Canonical
membership distinguishes a parent's own filings from possible companions.

The current saved BIS original/zoning lists cover 17 filings and 13 parents.
GO Broome's two reference releases give identical geometric comparisons and
are counted once, with an explicit conflict check. Its original lot list
includes retained lot 1; Woodside's saved original list covers one constituent.
The source table records exact reviewed original lists. A mismatch is cleared
only if the saved list matches that documented crosswalk. Raw lot lists and
spatial disagreements remain visible.

The 45-row documentary table records source pages, reference parcels, dated
vintages, development ground, retained land, and reviewed identifiers or DOF
transactions. A common reference for a multi-filing parent must be one of its
constituents' source releases, available before the first filing, with every
named parcel area verified. Unrelated source and physical-change flags remain.

A boundary passes when complete filing ground corresponds to whole earlier
parcels or a documented allocation, without an independent source, filing, or
membership conflict. The map comparison permits at most 2% of either union
outside the other and retains continuous differences. Complete dated DOF
successor sets and reviewed original documents provide additional routes.

Count each complete earlier parcel once. For partial parcels, recorded legal
boundaries or agency plans assign the ground; an administrative successor area
can measure that same boundary. Polygons check boundaries. Ground leases
contribute their assigned ground; separate development rights, nonexclusive
easements, retained schools, and later phases do not automatically add land.
Later records reconstruct observed development ground without establishing
ownership at initial filing or legal wage-assessment treatment. Earlier floor
requires its own allocation; later vacancy does not establish prior vacancy.

## Reproduction

Run root `make dof-site-review`. The unchanged second build should run no
producer recipes. SaveData writes reports with the data:

- `output/parent_site_scope.csv`: all 905 parents, flags, evidence, candidate areas.
- `output/parent_site_other_filings.csv`: matched jobs and documentary dispositions.
- `output/parent_site_lot_envelopes.parquet`: search parcels and site evidence.
- `output/parent_site_scope_summary.csv`: counts and units by sample/status.
- `output/prepolicy_old_review_queue.csv` and `output/prepolicy_current_review_queue.csv`: dated queue reconciliation.
- `output/parent_site_document_coverage.csv`: applicability of each documentary review to the current filing set.
- `code/parent_site_document_review.csv` and `code/parent_site_membership_review.csv`: manual boundary and link evidence.

HDB does not cover every legacy nonresidential filing, and a filing point is
not a building footprint. The [unit-source diagnostic](roosevelt_hotel_unit_fallback_review.md)
continues to preserve all available HDB Class A counts, including zero; no
matched HDB record is overridden by a DOB count in that check.

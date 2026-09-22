# Build parent site characteristics

Historical unit and parcel records use 23Q4 HDB. Repeated archived building
identifiers remain visible in `duplicate_bin_rows`. A historical parent may pass
the composition screen despite that collision only when its complete additive
filing set matches a reviewed production land allocation and every constituent
has a distinct valid BIN in the saved July 2026 DOB initial records. The flag
`reviewed_distinct_buildings` identifies this corroboration. It currently applies
only to Bedford Square's four reviewed buildings; it changes no archived unit
count or proposed building count.

This task aggregates pre-existing parcel characteristics to the linked
economic-parent level. It produces one historical panel and one post-policy
panel used in the final estimation datasets and exploratory composition checks.

Historical characteristics come from each filing's leakage-safe lagged
MapPLUTO match. Post-policy characteristics use the fixed 23v3.1 MapPLUTO
snapshot. Lot area is summed across unique feature lots; FAR measures are
lot-area weighted. Proposed units are retained only as the parent outcome and
are never used to construct the site characteristics.

`site_lot_decisions.csv`, owned by `parent_opportunities_manual`, supplies reviewed
parcel allocations. Each row names earlier parcels, their source vintage, the
ground included in the development, and excluded earlier building area.
The excluded value can also record an explicitly documented archive error,
such as GO Broome’s demolished synagogue. For a flagged floor proxy it is an accounting residual;
the source reason identifies that distinction. The script replaces the complete parcel set for each reviewed
parent, checks its constituent filings and archival area, and reads the named
MapPLUTO releases directly. Existing density is included earlier building floor
area divided by included ground. `feature_methods = reviewed_parcel_allocation`
identifies these rows downstream.

Partial parcels require evidence for both ground and earlier buildings. A later
vacant site does not establish that it was vacant in the reference year. The
September 21 diligence records unresolved allocations in the audit review;
those cases retain their production values pending adjudication.

A row may combine earlier parcels only when their residential and broad FARs
are identical, which the script checks. This permits a documented total ground
area without inventing its internal division. Each earlier lot still counts
once; zoning and prior-use categories retain their combined values. Exterior
uses this rule for four source lots, excluding the neighboring building while
retaining 31,850 square feet of earlier floor area.

Recorded instruments establish the physical allocations; later records can
measure an earlier development's ground without establishing ownership at
filing. Starhill's total area uses the later administrative measurement of its
documented boundary. The source table records this distinction. Earlier zoning
is applied to the allocated portions of the earlier parcels.

Parents with incomplete lot features or repeated nonmissing BIN rows remain in
the output with an explicit eligibility flag. Approved floor estimates are
recorded explicitly in the manual table. This task
does not estimate or score an individual parcel unit-count model.

Documented historical companions with missing lagged parcel matches are retained with `missing_lagged_mappluto`. Their parents fail `feature_complete` and `composition_eligible`; units remain complete while land values are not imputed. Identifier coverage and positive observed land areas are still checked.

Building identity uses the BIN from the DOB initial filing, joined by root job number, with Housing Database fallback when DOB has no BIN. Repeated-BIN eligibility counts additive filings only. A parent is eligible when its additive filings have no repeated nonmissing BIN and all source filings have matched parcels with positive area. This rule applies to every parent. Original source rows remain available for the established prefiling site-characteristic construction.

`units` and exact-99 component counts aggregate the constructor's selected units, using Housing Database priority with DOB fallback; documentary schedules do not override them. `units_hdb_priority` and `units_dob_i1` separately retain unaltered source-based totals; the downstream panel checks selected totals against selected totals.

The producer takes one sample name (`historical` or `post_policy`) and writes
that dataset and its report. Its weighted FAR calculation uses each lot's
original area before summing the parent's land area. The September 11 review
corrected an earlier column-overwrite error that had given equal weights to
lots within a parent. Unit counts and membership do not depend on these FARs.

`built_floor_area_estimated` is TRUE when any reviewed source row for a parent
uses an explicitly approved estimate or later administrative proxy for earlier building floor.
Flatbush is the first such case: its recorded ground is 12,603 square feet;
earlier floor is allocated by old-parcel overlap under a uniform-density
assumption. The canonical parent panel carries the flag with the floor measure.
East 125th and Onderdonk use proportional allocations; St. James uses the
first post-split housing-parcel floor record. Their source reasons record
measurement assumptions and unresolved discrepancies with old totals.

Jamaica uses old shop plans and building depths to allocate frozen parcel floor.
Kingsbrook uses HCR's gross-floor schedule for four earlier pavilions plus an
estimated power-plant allocation, including cellars and a half-bay mezzanine.
Both estimates were explicitly approved on September 22 and carry the same
flag. Kingsbrook's source-table excluded amount is an accounting residual;
the adopted gross floor is not an exact reconciliation to the old PLUTO total.

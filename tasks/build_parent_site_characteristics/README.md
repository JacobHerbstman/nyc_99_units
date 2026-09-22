# Build parent site characteristics

Aggregates each linked economic parent's pre-existing parcel characteristics:
land area, residential and broad FAR, built FAR, zoning and prior use. The
producer runs once per sample and writes
`output/historical_parent_site_characteristics.parquet` and
`output/post_policy_parent_site_characteristics.parquet`, one row per parent.
Proposed units are carried only as the parent outcome; they never enter the
site characteristics.

## Parcels and reference releases

- Historical parents use each filing's lagged pre-filing MapPLUTO match from
  `build_hdb_mappluto_site_panel`, with 23Q4 Housing Database lot and building
  identifiers.
- Post-policy parents use the fixed 23v3.1 MapPLUTO release.
- Lot area sums the parent's unique lots. FAR measures are weighted by each
  lot's own area. Built FAR is earlier building floor area over included ground.

## Reviewed parcel allocations

`site_lot_decisions.csv`, owned by `parent_opportunities_manual`, replaces the
complete parcel set for each reviewed parent. Each row names the earlier parcels
and their MapPLUTO release, the ground included in the development, and earlier
building floor excluded from it (retained neighboring buildings, or a documented
archive error). The producer checks that the listed constituent filings match
the parent and that the recorded parcel areas match the named release. It reads
zoning from the earlier parcels themselves. These parents carry
`feature_methods = reviewed_parcel_allocation` (`site_feature_method` in the
canonical parent panel).

- A row may combine several earlier parcels only when their residential and
  broad FARs are identical, which the producer checks. Each lot still counts once.
- Allocating part of a parcel requires evidence for both ground and earlier
  buildings. A later vacant parcel does not establish earlier vacancy.
- `built_floor_area_estimated` is TRUE when any source row for the parent uses
  an approved estimate or later administrative proxy for earlier building
  floor. The `review_basis` column states each assumption. Where the excluded-floor
  value is an accounting residual that retains such a proxy, `review_basis` says so.

## Eligibility and units

- `feature_complete` requires a matched parcel with positive area for every
  source filing. Documented historical companions without a lagged parcel match
  are kept with the feature method `missing_lagged_mappluto`; their land is not
  imputed.
- Building identity uses the DOB initial-filing BIN, joined by root job number,
  with Housing Database fallback. `composition_eligible` also requires that
  additive filings have no repeated nonmissing BIN.
- A historical parent whose archived BINs collide may still pass when its
  complete additive filing set matches a reviewed land allocation and every
  building has a distinct valid DOB BIN. `reviewed_distinct_buildings` marks
  this; `duplicate_bin_rows` keeps the archived collision visible.
- `units` and exact-99 counts use the constructor's selected units: Housing
  Database priority with DOB fallback. `units_hdb_priority` and `units_dob_i1`
  retain the unaltered source totals.

Run `make` in `code/` against prepared inputs; use root `make data` after upstream
changes.

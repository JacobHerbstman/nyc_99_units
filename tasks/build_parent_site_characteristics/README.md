# Build parent site characteristics

Aggregates each linked economic parent's pre-existing parcel characteristics:
land area, residential FAR, built FAR, borough and community district. The producer runs once per sample and writes
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

## Lots merged within 180 days of filing

Developers often file under the one lot that will survive a merger DOF records
later, so the reference map shows only that lot. For filings whose reference is
a citywide MapPLUTO release (2018 onward), the producer adds the lots DOF
merged into a filing lot after its reference map and no more than 180 days
after the parent's first filing, using their area, FARs and existing floor from
the same reference release. DOF lot actions come from
`fetch_dof_tax_map_history`. Only lot mergers with a single surviving lot
count; splits and later mergers do not. The window is the same in both periods.

- `merged_lots_added` counts the lots added.
- `merger_window_complete` is FALSE for parents filed less than 180 days before
  the September 15, 2026 DOF snapshot, whose mergers may not all be recorded.
  They stay in the panel.
- `implausible_site` flags parents whose permitted residential floor (lot area
  times the larger of residential and broad FAR) is under 150 square feet per
  proposed unit, a sign that the recorded land is a fragment of the site.

Reviewed allocations below replace the whole parcel set, including merged lots.

## Starting lots

`starting_lots` counts the tax lots the site occupied before its own mergers
and subdivisions, for the model's splitting cost. It starts from the lots of the
parent's buildings at filing (the lagged match historically; after the policy
the DOB filing lot, which a recent subdivision may have created) and undoes,
once and newest first, each DOF lot merger or subdivision from two years before
the first filing to 180 days after it: a merger into a site lot adds the lots it
absorbed, and a subdivision replaces the lots it created with the lot they came
from. The window is the same in both periods. A reviewed parent starts on the
earlier parcels its decision names. Lots never merged or filed on, such as the
rest of a zoning lot, are not counted in either period.

## The site from its recorded zoning lot

The filing lot can be one piece of an assembled site, and a small building lot
can borrow floor area from neighbours that keep their buildings. A zoning lot
description recorded in ACRIS (`fetch_acris_zoning_lots`, document type ZONE)
lists every tax lot of a development's zoning lot. One applies when it lists a
lot of the parent's buildings (DOB filing lot or mapped lot, in both periods)
and is dated from two years before the first filing to 180 days after it; most
are recorded within months of filing. Its lots, after the same undoing of
mergers and subdivisions as `starting_lots`, are classified in the parent's
reference release: a lot is built on when it has no building floor or vacant
land use, or a DOB full demolition (`fetch_dob_demolition_filings`) was filed
on it from three years before the first filing to 180 days after it; otherwise
it lends floor area while its building remains. Condominium unit lots belong to
a remaining building.

- `site_lots` counts the starting lots and the built-on lots of the zoning lot;
  without a record it equals `starting_lots`.
- `site_lot_area_sqft`, `site_residential_far` and `site_frontage_ft` are the
  land, land-weighted residential FAR and summed street frontage of those lots
  in the reference release. Frontage sums each lot's own frontage, so it
  counts a corner lot's main frontage once.
- `air_rights_donor_lots` counts the zoning lot's lots whose buildings remain;
  `site_lots_unmapped` counts site lots absent from the reference release,
  whose land is missing from the sums.
- `zoning_lot_record` marks a record in the window; `zoning_lot_window_complete`
  is FALSE for parents first filed less than 180 days before the October 1,
  2026 ACRIS capture.

A reviewed parent's site measures are its documented parcels. These columns are
alongside the established land measures and do not replace them.

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
  building has a distinct valid DOB BIN.
- `units` uses the constructor's selected units: Housing Database priority with
  DOB fallback.

Run `make` in `code/` against prepared inputs; use root `make data` after upstream
changes.

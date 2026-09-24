# Estimation datasets

Produces the canonical panels from approved parent membership, exposure
classifications, HPD registration links and predetermined site characteristics:

- `parent_opportunity_panel.parquet`: one row per parent.
- `constituent_filing_panel.parquet`: one row per retained additive filing.

The citywide plots, borough analysis and audits all read these two files.

## Sample and sources

The comparison is 2019–2022 versus January 1, 2025–July 8, 2026. The panels
contain classified parents with at least six units; `included_ab` identifies
the adopted rental-opportunity sample. Historical linkage has a full 365-day
window. An economic parent groups development decisions; a separate legal wage
assessment needs its own evidence.

- **Historical proposals** use the inactive-inclusive **23Q4 Housing Database**:
  Class A units, filing dates, lot and building identifiers and descriptions.
  `historical_active` records membership in its active/completed file and
  `hdb_job_status` keeps the archived status. Missing historical units are not
  filled from a later release. The archive's latest DOB update is January 12,
  2024, so these are pre-adoption designs that may include amendments made
  after the original filing.
- **Post-policy counts** use **25Q4 Housing Database Class A units**, including
  recorded zeros, with DOB initial-filing units where HDB is missing.
  Zero-Class-A filings stay in upstream membership but not in the residential
  constituent panel.
- The historical linkage universe requires at least six units and a
  positive-area parcel match from an available pre-filing release, or an
  explicitly accepted manual link.
- Archived alternatives count once: earlier withdrawn applications that share a
  valid BIN, lot and exact address with one later non-withdrawn application
  within a year. Records keep the original filing date, the successor's date
  and `refiling_basis`. Other inactive proposals stay in the source.
- Historical exposure uses archived ownership and descriptions and dated
  pre-adoption Attorney General plans; HPD 485-x registrations describe
  post-policy projects only.

## Flags carried for analysis

- `composition_eligible`: complete positive-area parcel matches and distinct
  building identifiers among additive filings (a reviewed land allocation and
  distinct DOB BINs can resolve an archived BIN collision). Flagged parents stay
  in the panels; the reweighting sample selects on this flag among rental
  parents with at least 50 units.
- `exposure_status`, `confidence` and `classification_reason` come from
  `classify_parent_485x_exposure`; `included_ab_plus_d` also admits Option D
  homeownership opportunities.
- `splitting_verification_status` records whether a multi-building parent's
  constituents are verified separate 485-x registrations, share one, or sit on
  distinct filing lots.
- `site_feature_method = reviewed_parcel_allocation` marks land characteristics
  taken from `parent_opportunities_manual/output/site_lot_decisions.csv`.
- `merged_lots_added`, `merger_window_complete` and `implausible_site` come from
  the 180-day merger rule and site check in `build_parent_site_characteristics`.
  They are for sensitivity analysis and exclude no parent.
- `community_district` is the MapPLUTO community district (for example `303`,
  Brooklyn 3) of the parent's lots in the same release that supplies its land
  and zoning; `Mixed` when the lots span districts and `missing` when no lot
  has one. Marble Hill is in Manhattan but Bronx Community District 8 (`208`).
- `built_floor_area_estimated` marks parents whose earlier building floor uses
  an approved estimate. It is for sensitivity analysis and does not exclude the
  parent.

Run `make` in `code/` against prepared inputs; use root `make data` after
upstream changes.

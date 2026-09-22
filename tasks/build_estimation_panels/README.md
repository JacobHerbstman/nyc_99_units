# Estimation datasets

Produces the canonical constituent-filing and parent-opportunity panels from approved parent membership, exposure classifications, HPD registration links, and predetermined site characteristics. It preserves the existing administrative unit priority, manual membership decisions, refiling dates, and source coverage flags.

Historical proposals use the complete **23Q4 Housing Database**, including inactive records. Proposed Class A units, filing dates, lot identifiers, building identifiers, and descriptions come from that snapshot. `historical_active` records membership in its active/completed subset; `hdb_job_status` preserves the archived status. Missing historical unit counts are not filled from a later release. The archive's latest DOB update is January 12, 2024: these are pre-adoption designs, which may already incorporate amendments since the original filing.

The historical linkage universe requires at least six units and a positive-area
parcel match from an available pre-filing release, or an explicitly accepted
manual link. The source-coverage audit records proposals outside that coverage
and filings whose parent starts before 2019. Inclusion of inactive proposals
applies within these existing coverage and cohort rules.

Post-policy counts use **25Q4 Housing Database Class A units**, including recorded zeros, with DOB initial-filing units where HDB is missing. Zero-Class-A filings stay in upstream membership and do not enter the residential constituent panel.

The comparison is 2019–2022 versus January 1, 2025–July 8, 2026. The panels contain classified parents with at least six units; `included_ab` identifies the adopted rental-opportunity sample. Historical linkage has a full 365-day window. An economic parent groups development decisions; separate legal wage assessment requires its own evidence.

Archived alternatives count once when earlier withdrawn applications share a valid BIN, lot and exact address with one later nonwithdrawn application within a year. The records retain the original filing date, the successor's filing date and `refiling_basis`. The archived rule establishes alternatives at the snapshot, without inferring a withdrawal date. Other inactive proposals remain in the source. Historical exposure uses archived ownership/descriptions and dated pre-adoption AG plans; HPD 485-x registrations describe post-policy projects.

The [source-rule audit](../audits/audit_hdb_mappluto_condo_recovery/code/check_prepolicy_source_rule.R) reconciles the rebuilt panels against dated pre-change baselines, checks historical counts against 23Q4, and verifies unchanged post-policy outcomes and land covariates. `hdb_releases` records the unit source. `historical_all_active` describes additive residential constituents; `historical_all_source_active` also includes superseded and nonresidential source filings retained in membership.

Run `make` in `code/`. Outputs are `parent_opportunity_panel.parquet` (one row per parent) and `constituent_filing_panel.parquet` (one row per retained additive filing). Standard reports live in `report/`. The citywide plots, borough analysis, and relevant audits consume these same files.

`composition_eligible` identifies parents with complete positive-area parcel
matches and distinct building identifiers among additive filings. A repeated
historical BIN is also allowed when the complete constituent set has a reviewed
production land allocation and every building has a distinct valid official DOB
BIN. `reviewed_distinct_buildings` marks that corroboration; the archived BIN
collision remains in the site-characteristics output. This rule retains Bedford
Square's four documented buildings.
The site-characteristics task uses 23Q4 HDB BINs for historical buildings and
DOB initial-filing BINs with 25Q4 HDB fallback for post-policy buildings. The reweighting audit selects this flag among rental parents with at
least 50 units; the canonical panels retain flagged parents for review.

`site_feature_method` identifies how the parent land characteristics were
constructed. `reviewed_parcel_allocation` marks documentary allocations applied
from the production manual-source table. Their lot areas and earlier building
density use the development's included ground; retained neighboring buildings
are excluded. The table records the source vintage and measurement basis.

The parent field `built_floor_area_estimated` identifies adopted approximations
in earlier-building floor allocation. Flatbush uses a documented land-share
estimate approved September 21, 2026. Its 441 administrative units and filing
dates are unchanged. The flag is available for sensitivity analysis and does
not independently exclude the observation.

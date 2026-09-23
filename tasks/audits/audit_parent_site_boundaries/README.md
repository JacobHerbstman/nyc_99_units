# Parent site boundaries

Checks whether each weighting-sample parent's recorded land corresponds to its
whole development site, and keeps the calculations behind the land and floor
allocations adopted in `parent_opportunities_manual`. Nothing in production
reads this audit.

A filing's tax lot can identify only part of a development site: developers
often file under the lot that will survive a merger DOF records months later,
one old parcel can be split among developments, and zoning lots can include
retained buildings. The screen follows each parent's filing lots through DOF
tax-map transactions and archived MapPLUTO outlines and flags parents whose
site it cannot confirm.

| Script | Output |
|---|---|
| `clean_dof_history.R` | `dof_events.parquet`, `dof_condo_links.parquet`: DOF lot transactions and condominium links from `fetch_dof_tax_map_history` |
| `trace_parent_parcels.R` | `dof_parent_parcels.parquet`, `dof_parent_coverage.csv`, `dof_coverage_summary.csv`: each parent's lots traced to its reference release |
| `read_dof_geometry.R`, `compare_dof_geometry.R` | Earlier and later parcel outlines and their overlaps |
| `compare_bis_site_lots.R` | Saved DOB site fields (`parent_review_documents`) compared with the mapped lots |
| `audit_parent_site_scope.R` | `parent_site_scope.csv`: one row per weighting-sample parent, with its flags, reason and candidate earlier-parcel area |
| `measure_remaining_floors.R`, `measure_wallabout_allocation.R` | The Jamaica, Kingsbrook and Wallabout allocations adopted in the manual table |

`parent_site_document_review.csv`, `parent_site_membership_review.csv` and
`parent_site_filing_review.csv` record documentary boundary, link and filing
reviews. A review applies only while the parent's filing set and reference
release match the ones reviewed.

A parent passes when its complete filing ground corresponds to whole earlier
parcels (outlines agreeing within 2%), a complete DOF successor set, or a
documented boundary, with no conflicting filing, source or membership
question. A flag is an unresolved question, not an established error.
`candidate_area_sqft` gives the earlier-parcel area for passing parents; it is
not used in production.

The per-parent review stopped on September 22, 2026:
`audit_land_measurement_sensitivity` shows the flagged parents do not move the
reweighted comparison. Run root `make site-boundaries`.

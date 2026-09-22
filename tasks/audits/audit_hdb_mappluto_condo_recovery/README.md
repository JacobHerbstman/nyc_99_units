# Audit HDB-MapPLUTO Condo Recovery

Run `make dof-site-review` for the full weighting-sample site-allocation check.
It searches saved New Building filings, dated DOF changes, parcel maps, and
reviewed original documents. [Current counts and remaining questions](report/parent_site_scope_review.md)
come from `output/parent_site_scope.csv`.

The [supervised review](report/site_research_supervised.md) and
[ten-parent batch](report/site_research_batch10_review.md) document source
adjudications. `code/parent_site_document_review.csv` contains 45 boundary
rows keyed to current parents. Eleven pairwise decisions in
`code/parent_site_membership_review.csv` distinguish implemented links,
accepted links awaiting application, and unresolved relationships.

The September 21 [implementation](report/reviewed_parent_implementation.md)
applies Dupont's land correction and the Bedford Square and Starhill mergers
with their reviewed ground and earlier building density. Production decisions
belong to `parent_opportunities_manual`; main tasks have no audit dependency.
Other candidate allocations remain here pending their documented review and
application. The audit verifies implemented pairs against current membership.

The [remaining-three implementation](report/remaining_three_implementation.md)
applies Eagle/West at 106,018 square feet, 355 Exterior at 120,272, and
1580 Story at 203,910. Each linked evidence note records the original documents
and the distinction between surveyed and administrative area. Exterior's four
contributing earlier lots retain their common FARs without an invented internal
area split.

The [five-merger and 23-case review](report/mergers_and_23_review.md) implements
Godwin/Kimberly, GO Broome, Woodside, Motto, and Elara, plus 18 land
corrections, including the approved Flatbush floor estimate. The
[five floor estimates](report/five_floor_decisions.md) complete that batch.
The [September 22 continuation](report/next_ten_boundaries_2026-09-22.md)
applies GO Broome's documented zero earlier floor and five supported parcel
corrections from the next ten parents. Four of those ten receive complete
boundary decisions; the other six retain specific unresolved questions.
Earlier building allocation is checked separately from ground; a later vacant
parcel cannot establish its earlier floor area.

The same entry point builds `output/hdb_unit_fallback.csv`, a short diagnostic
of included DOB-unit fallbacks with an existing Housing Database record.
The [unit-source note](report/roosevelt_hotel_unit_fallback_review.md) records the
confirmed 1,000-hotel-room contamination and the general correction: available
HDB Class A counts, including zero, now take priority over DOB counts. The
regenerated diagnostic has no matched HDB rows overridden by DOB units. Panels, plots and weights use that correction. The dated pilot is archived;
a new structural fit awaits the remaining boundary work.

Run `make dof-geometry-review` to compare currently flagged weighting-sample
parents against their earlier MapPLUTO geometries. `read_dof_geometry.R` reads
the saved shoreline-clipped parcel archives for the full weighting sample; `compare_dof_geometry.R` measures
whole-parcel and partial overlaps in batches by reference vintage;
`plot_dof_geometry.R` draws the summary and a complete footprint atlas. No
manual review table or address-specific rule enters these calculations. The
audit retains missing filing parcels and source disagreements explicitly.
These outputs measure map agreement and candidate areas, not verified ownership
or final production replacements.

The corrected lookup uses a mapped filing BBL before expanding to physical
base lots; condominium billing identifiers can themselves have parcel polygons.
The [current geometry findings](report/dof_geometry_review.md) explain why this
recovers all 19 historical parents previously marked as missing later maps,
leaving 13 post-policy parents with incomplete later coverage.

The same command retains the original 32-parent physical-base diagnostic and
searches all 23 usable saved MapPLUTO releases from 2018 through 2023.
`read_dof_filing_maps.R` searches physical/base BBLs;
`match_dof_filing_maps.R` selects a single complete release closest to first
filing and flags subsequent physical DOF changes involving those identifiers.
Archive-file dates proxy for map timing. An old lot number can be reused with
a different boundary; all 19 archived matches have later transactions requiring
tracing. These are identifier-history checks, not 19 certified development sites.

`compare_bis_site_lots.R` reads a frozen capture of displayed DOB site fields
for 17 filings / 14 parents. It compares the original tax-lot lists with the
same reference releases used by production, deduplicates parcels within parents,
and flags shared zoning lists. The script preserves missing source areas.
[Filing-site findings](report/dof_filing_map_review.md) and the linked source
record explain the evidence, current-page amendment caveat, and access limits.
No DOB field or geometry candidate overrides a production area.

Run `make dof-subset-review` for the twelve-case review drawn from the original 166
flags. The saved case IDs keep that reviewed subset fixed as the sample changes. [Subset findings](report/dof_subset_review.md)
explain the ten provisional land-area comparisons and two unresolved cases.
The outputs are a parent comparison table, an average-change table, and a
twelve-page footprint PDF. `measure_dof_subset.R` calculates areas from the
existing PLUTO archives and checks their mapped boundaries against frozen DOF
geometry; `dof_subset_review.csv` records the documentary judgments. These
comparisons do not change production land characteristics or weights.

The same command produces [lot-area validation](report/dof_area_validation.md):
119 final assessment records, 16 lot checks, and a comparison of Noble/Oak's
full tax-lot and shoreline-clipped areas. `validate_dof_subset_areas.R` reads
the frozen DOF assessment response and computes the printed-dimension checks;
`dof_lot_measurement_review.csv` records the evidence and remaining questions.
Purdy, Weirfield, and Lorimer lack independent survey calculations. Sackett's
later parcel areas are measured, but its original filing footprint remains a
separate question. Noble/Oak's proposed subdivision is documented; the analysis
must distinguish full tax-lot area from physical land within the shoreline.

Run `make dof-parcel-audit` from the project root for the citywide DOF-based
parent review. [Full-sample findings](report/dof_full_sample.md) describe the
remaining cases and the [source acquisition task](../../fetch_dof_tax_map_history/README.md)
documents the frozen replication inputs. `clean_dof_history.R` constructs
transaction parcel sets and condominium links; `trace_parent_parcels.R`
applies the same chronological rules to all parents. The three final outputs
are `dof_parent_parcels.parquet`, `dof_parent_coverage.csv`, and
`dof_coverage_summary.csv`. Reports are SaveData side effects. These candidate
footprints do not yet feed production characteristics or estimation weights.

The filing-level vintage remains unchanged. A historical parent spanning two
reference releases is traced separately for each release and flagged. An explicit
documentary decision can establish a common reference that predates the first
filing; the audit validates that vintage and all named parcel areas. HDB
supplies historical BBLs; DOB supplies post-policy filing BBLs, with an explicit
comparison to HDB. DOF condominium links and fully covered transactions can
establish aliases between the two sources. Unexplained disagreements remain
visible. PLUTO 25v4 condominium numbers are linkage evidence; lot areas and FARs
come from the historical reference release.

The September 15, 2026 [DOF tax-map history review](report/dof_history_feasibility.md)
finds a public source for complete transaction-level lot actions and condominium
base-lot histories. Its two outputs are `dof_lot_changes.csv` and
`dof_applications.csv`, built by `review_dof_history.R` from frozen public-source
extracts. The DOF reconstruction remains an audit candidate; adopted parcel allocations enter production through the manual-source task.
The older APPBBL audit below documents the earlier matching experiment.

Audits whether HDB New Building rows that fail strict BBL matching can be recovered through official PLUTO/MapPLUTO apportionment fields.

This task is audit-only. It does not change the production HDB-MapPLUTO training panel and does not feed the prediction model directly.

The motivating issue is that many large HDB no-match rows have condo-like lot numbers, especially lots 7500 and above. PLUTO/MapPLUTO includes `APPBBL`, the originating BBL before a merge, split, or condominium conversion. This first-pass audit uses current official PLUTO `APPBBL` evidence to construct candidate base-lot links, then accepts only unique same-borough-block candidates that appear uniquely in the selected lagged MapPLUTO vintage and map to only one HDB row. Accepted matches are split into condo-like and non-condo-like HDB lot numbers.

Rows where several HDB jobs point to the same recovered base BBL are flagged as `duplicate_feature_bbl_across_hdb_rows`, not accepted. Those rows need deliberate aggregation or exclusion before any production modeling change.

Outputs are CSV diagnostics: unmatched-row audit, crosswalk candidates, match resolution, accepted matches, recovery summary, sample-comparison summaries, status summaries by modeling window/year/borough, duplicate recovered-base-BBL groups, and large unresolved examples.

The Flatbush follow-up is reproduced with root `make flatbush-floor-review`.
It documents the explicitly approved estimated floor allocation and its bounded
calibration sensitivity in `report/flatbush_floor_review.md`. This uses the
existing audit and acquisition tasks; main data read only the manual decision
table and archived administrative sources. At that stage, five of the original
23 land cases remained held; the September 21–22 continuation below applies all five.

Root `make five-floor-review` reproduces the five-site floor review and its
one-parent-at-a-time calibration sensitivity. All five estimates were approved
and applied with an estimate flag. `report/five_floor_decisions.md` records
their assumptions, including Jamaica’s shop allocations and Kingsbrook’s
cellar and mezzanine assumptions. The same audit contains a parcel-level Jamaica
allocation and the HCR Kingsbrook building-floor schedule. Main data read the
production-owned decision table and retain no dependency on these audit outputs.
# September 22 queued-case follow-up

The [Livingston and queued-case review](report/queued_followup_2026-09-22.md)
compares historical units across HDB releases and applies Wallabout's completed
land allocation. Root `make dof-site-review` prepares the archived source and
runs `code/queued_followup.make`. The unit comparison holds the current selection
and membership fixed. Wallabout's adopted rows live in the production manual task.

The subsequent source correction reconstructs historical panels from the
inactive-inclusive 23Q4 archive. `check_prepolicy_source_rule.R` compares them
with dated pre-change filing and parent tables, verifies the archived unit
counts, and checks unchanged post-period outcomes and land characteristics.
`prepolicy_active_comparison.csv` distinguishes active additive constituents
from activity across all source applications. It is a status comparison within
the reconstructed sample, not a separate active-only estimator.

`reconcile_prepolicy_review_queue.R` follows every old boundary case through its
source jobs to the new parents. Its two tables distinguish departures from the
review sample, newly entering parents, and current flags. Changing a parent ID
or leaving the weighting sample does not resolve its boundary. Documentary
reviews record the exact additive jobs they covered; `parent_site_document_coverage.csv`
shows which still apply to the current constituent sets and reference vintages.

The original twelve-case physical measurement exercise uses the fixed reviewed
parcel definitions in `dof_subset_parent_definitions_2026-09-22.csv`, saved before
the source correction. Its areas refer to those named footprints. Current
parent coverage and unresolved counts come from `parent_site_scope.csv` and
the queue reconciliation, rather than reinterpreting those older case studies
as measurements of newly merged parents.

## September 22 pre-policy source correction

Historical proposals use the inactive-inclusive 23Q4 archive. The rebuilt weighting sample has 595 historical and 310 post-period parents. The current site screen flags 152 (120 historical, 32 post-period); 753 pass the current checks. A flag identifies an unresolved coverage or allocation question, not an established error.

`prepolicy_old_review_queue.csv` follows the former 111 queued cases: 103 remain flagged, representing 102 current parents after one merger, and eight leave the weighting sample without being resolved. `prepolicy_current_review_queue.csv` follows the current sample. The other 50 flagged parents comprise 29 entering the sample and 21 previously supported parents flagged by the revised filing information. No former queued case was cleared by changing the source.

`parent_site_document_coverage.csv` checks each documentary review against its original additive filing set. Forty-two of 45 reviews apply. West 48th Street leaves the weighting sample, and the two Jamaica/Sutphin records require review of their merged parent. The source-rule audit records changes in units, status, coverage and parent membership against dated baseline tables in `code/`.

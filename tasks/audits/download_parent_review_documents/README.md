# Acquire primary documents for parent-link review

The [September 22 ten-parent sources](code/site_research_next10_2026-09-22/README.md)
preserve recorded deeds, zoning certificates, and public search extracts.
`code/next_ten.make` downloads nine checksum-pinned documents through root
`make dof-site-review`; the ACRIS browser exports remain unchanged source files.

The [September 15 DOF capture](code/dof_history_2026-09-15/README.md) preserves
public tax-map transactions, lot and condominium actions, historical maps,
application-tracker records, schemas, and a data dictionary. Its manifest records
50 source responses with exact queries and SHA-256 hashes. These support the
parcel-history feasibility review; ordinary audit builds reuse the frozen JSON.

This audit acquisition task preserves publicly accessible city documents used to resolve project membership and unit counts. The initial snapshot was retrieved September 9, 2026 from NYC OER's project repositories. Concrete file identifiers and destinations are recorded in `code/Makefile`; consumers inspect the retained files, not a changing portal summary. Ordinary builds reuse this snapshot. Refreshes require an explicit source change and evidence comparison.

Outputs are unchanged source PDFs. Partial downloads stay in `temp/` and never become valid outputs. Run Make from `code/`. The evidence review is maintained in `audit_estimation_parent_links/report/`. These records do not feed production estimates.

Retrieved-file SHA-256 fingerprints (September 9, 2026):

- `4121_third_fact_sheet_2026-09-04.pdf`: `556a76d63277b596d0935fdc41f5816d006fedf7e7b5b8036533ceff31dd595a`
- `4121_third_rawp_2025-10-01.pdf`: `ee3b3942eca127adc3fc2d4306b9579eb8d5b8d7e54c76a7659cbf7af1bf6652`
- `4133_third_fact_sheet_2026-09-02.pdf`: `267336d7042edc1f84325a7318f5450f157443ef5bdf62379b668b89496b17b5`
- `4133_third_rawp_2025-10-30.pdf`: `d1a06d9c925b2891bcf917645a4a45b920f1dd6754b43f7bede3f1133fb6d748`
- `4137_third_rawp_2025-07-31.pdf`: `b4796b98adcebe95e2089aa714011c3a9415502232db8e82721bb69ba43246c5`

- `1660_boone_bcp_application_2024-10-28.pdf`: `c5e405c8f21e4d912ebff55f81076645210569968c03f7434ccb1df83bf3029f`

The Boone document is a New York State DEC source. Its PDF page 62 identifies Vaja Group’s members. The September 9 refresh of the five OER files retained their recorded fingerprints.

September 10 additions are defined in `code/boundary_documents.make`, included by
the normal Makefile. GEI's December 2023 Astoria Cove geotechnical report is
published by DEC under a misleading `Phase I Report` filename. Its PDF page 9
maps the four proposed Phase 1 buildings to their blocks and lots. HDC's June
2026 authorization, PDF page 17, supplies Turnbull's apartment breakdown. The
Rockaway TEFRA notice identifies Phase IV. The Boyland source is an architect's
zoning drawing preserved by PincusCo, dated December 3, 2025. Grand Concourse's
DEC documents establish site boundaries but do not supply the needed unit
schedule. The August application explicitly states that no development plans
were then available.

Retrieved September 10 SHA-256 fingerprints:

- `astoria_cove_geotechnical_2023-12.pdf`: `ec37a6505a0e5b272e2d81b21582199a241533a441b8d6a699c3c092471726c7`
- `boyland_zoning_B01328447.pdf`: `a3ccdc1d750cf9fbcb6376903ef5ae5cab602d10b796c89166d96c295fd14d7a`
- `grand_concourse_application_2025-08.pdf`: `84bedb28d5d3883e014f9316685c7d217c37b519803899392464e214b7169236`
- `grand_concourse_citizen_plan_2025-09.pdf`: `6b2d8666733f45e4b463e161545efc886234171d8a9ceb1fe59e2e52d5e9d2a1`
- `rockaway_village_tefra_2021-11-18.pdf`: `ba36b0388a42c85b03c329a8ab594eab7d07deb419c1be7dad57a43d35ac1b51`
- `turnbull_hdc_authorization_2026-06.pdf`: `285b5f91e1956106e81c2e92cc71284d59e26de48b1f11568b6ec38b175827d3`

Unavailable sources are not represented by placeholder outputs. The city River
North technical memorandum, Queens CB1 January 12, 2026 agenda, and DOS
Greenpoint Quay package returned HTTP 403 on September 10. Browser navigation
to the DOS URL also returned the agency's unavailable-page notice. The Myrtle
link below returned HTML containing an upstream DOB Access Denied response,
not a zoning PDF; PDF validation correctly failed and no output was published.
These URLs remain research leads, not inspected local documents:

- https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/liberty-towers/tech-memo.pdf
- https://www.nyc.gov/assets/queenscb1/downloads/pdf/committee-meeting-agendas/2026/2026-Housing-Memo-Agenda-01_12.pdf
- https://dos.ny.gov/system/files/documents/2026/04/f-2025-0815_b.pdf
- https://www.pincusco.com/property-data/ZD1_Q01338971_2.pdf

If an agency restores an unavailable source, add its concrete acquisition rule
and inspect the downloaded record before using it as adjudication evidence.
The original six PDFs were also retrieved after adding the include; their
fingerprints were compared with the September 9 record and were unchanged.
# Twelve-parent DOF footprint review

`code/dof_subset_2026-09-15/` preserves the public DOF geometry extract, exact
query, dated map URLs, and source hashes used by the twelve-parent audit.
The Makefile has concrete download rules for its 25 dated maps and NYSDEC
Sackett amendment. See the [source record](code/dof_subset_2026-09-15/README.md).

The [area-validation source record](code/dof_subset_validation_2026-09-15/README.md)
preserves the DOF assessment query, count check, and schema, together with
download rules for the assessment field layout and seven further city/state
documents. `make dof-subset-review` from the root prepares those sources and
runs the lot-area checks in the existing audit.

The [manual portal review](code/dof_subset_validation_2026-09-15/manual_portal_review.md)
records the DOB and ACRIS evidence for Sackett and Noble/Oak, including the
original-document access limits and the distinction between parcel dates.

The [September 16 filing-site source record](code/filing_sites_2026-09-16/README.md)
preserves displayed DOB site fields for 17 filings and documents their capture
limits. `code/filing_sites.make` downloads the dated Flatbush tax maps and
NYCIDA's May 2020 site description. The parcel audit compares these original
lot lists with archived parcels; the source table does not override production
land areas or merge parents sharing a zoning site.

The September 16 supervised site review preserves [inspected Sullivan, Ocean Parkway, and Godwin instruments](code/site_research_supervisor_2026-09-16/README.md) and [frozen DOB/ACRIS records](code/site_research_shared_filings_2026-09-16/README.md). The instruments were exported through the public ACRIS viewer; the API records retain their query definitions and hashes. These records support the existing parcel audit's documentary review and do not alter production units or weights.

The same review preserves [Brooklyn maps and geometry](code/site_research_brooklyn_2026-09-16/README.md)
and [165th Street records and the Beach 30th City Planning plan](code/site_research_large_parents_2026-09-16/README.md).
`code/site_research.make` retrieves twelve public PDFs at their recorded URLs
and checks the saved hashes before moving them from `temp/` to `output/`.
The source folders preserve manual ACRIS images, small API captures, and
page-specific inspection limits.

The second source pass adds both Beach waterfront-certification applications'
development descriptions and site plans. The source notes distinguish the
building parcels from the wider zoning lots and preserve the status of the
earlier small-house filings. The supervisor's Ocean Parkway records establish
a 20,000-square-foot development parcel inside an earlier 57,000-square-foot
lot; the separate agreement identifies transferred floor-area rights.


The September 20 continuation preserves the [Jamaica partitions](code/site_research_followup_2026-09-20_jamaica/README.md),
[residential/school deeds](code/site_research_followup_2026-09-20_schools/README.md),
[Manhattan agency plans](code/site_research_followup_2026-09-20_four_large/README.md),
[Bronx ground-lease evidence](code/site_research_followup_2026-09-20_bronx_four/sources.csv),
and [Brooklyn development agreements](code/site_research_followup_2026-09-20_brooklyn_large/README.md).
The [Metropolitan Park application](code/site_research_followup_2026-09-20_roosevelt_hotel/README.md)
supports a separate hotel-unit finding. Source folders preserve original scans,
exact URLs, retrieval dates, and hashes. ACRIS originals were exported through
the public viewer. The [current supervised adjudications](../audit_hdb_mappluto_condo_recovery/report/site_research_supervised.md)
distinguish accepted boundaries from unresolved source and filing questions.

The next September 20 batch preserves the [Penn South and Jerome executed leases/deed](code/site_research_followup_2026-09-20_penn_jerome/README.md),
[Woodside and Sutphin site documents](code/site_research_followup_2026-09-20_woodside_sutphin/README.md),
and [Kingsbrook/Schenectady phase boundaries](code/site_research_followup_2026-09-20_atlantic_schenectady/README.md).
These documentary-review snapshots are received source records: the ACRIS originals
were exported with Save All in the public viewer. The two Sutphin applications,
Schenectady DEC application, and HCR board book have direct public download
recipes in `code/site_research.make`; source-folder symlinks point to those
outputs. Other received originals retain their exact acquisition URLs.
Their manifests and hashes allow verification
without rerunning a mutable search. They support the manually adjudicated audit
source tables and do not enter a production download dependency.

### Ten-parent sources, 20 September 2026

The three `code/site_research_batch10_2026-09-20_*` folders preserve original
evidence for the Bronx, north Brooklyn, and Flatbush review. Their source
registers record exact URLs, retrieval dates, and SHA-256 values. Mutable API
responses and web pages are frozen evidence snapshots; ACRIS scans were
exported manually through the public viewer. Four decisive direct-download
files are acquired by `code/site_research_batch10.make`, reached by root
`make dof-site-review`; source-folder symlinks point to those outputs. Recipes
verify the recorded hash before publishing the completed download. No
credentials are needed. See the [ten-parent decisions](../audit_hdb_mappluto_condo_recovery/report/site_research_batch10_review.md).

September 21 follow-up preserves the original records resolving Eagle/West,
355 Exterior, and 1580 Story in the `code/site_research_remaining3_2026-09-21_*`
folders. Each folder has a source manifest with public URL, acquisition date,
byte count, and SHA-256. ACRIS documents were exported intact from the public
viewer; Exterior's job-specific DOB PD1 and ZD1 were saved from the official
scan viewer. Derived map excerpts are identified as such. The
[implementation note](../audit_hdb_mappluto_condo_recovery/report/remaining_three_implementation.md)
links the source reviews and adopted values. The production dependency is the
small decision table owned by `parent_opportunities_manual`, not these audit
files.

The [September 21 Motto evidence](code/site_research_followup_2026-09-21_motto/README.md)
adds a prefiling DEC site plan and exact-job recorded instruments. Five direct
public documents have checksum-verified recipes in `site_research.make`; the
three ACRIS PDFs are preserved manual browser exports. The June 2019 plan
identifies ancillary lot 155 as part of the two-building development.

The [five-site floor review](code/five_floor_2026-09-21/README.md) preserves a
September 21 DOF successor extract, HCR's corrected 2018 Kingsbrook drawings
and addendum, and DEC's 2025 ESA and 2026 RAWP. Literal public URLs and pinned
SHA-256 checks are in `code/five_floor.make`, called by root
`make five-floor-review`. The audit documents manual measurements; main data
use the approved values and assumptions in the production decision table.

# Atlantic and Schenectady boundary sources, September 20, 2026

This folder preserves original public primary records gathered for the 402-unit
567 Schenectady Avenue / 818 Rutland Road case. `source_urls.csv` identifies the
exact source of every raw file and `sources.sha256` records its SHA-256 digest.
The three ACRIS PDFs were exported through the City Register viewer by the
supervising agent and copied here byte for byte. The other PDFs and JSON files
were downloaded from the listed agency URLs. Page numbers below are physical
PDF pages, including covers. The [case note](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_atlantic_schenectady.md)
also discusses 698 Atlantic using the earlier [Brooklyn source packet](../site_research_followup_2026-09-20_brooklyn_large/README.md).

| Original | Pages reviewed | Relevant content |
| --- | --- | --- |
| `schenectady_agmt_2026070900638021.pdf` | 3–4, 9, 30–33, 37–38 | Recorded agreement: developer lots 2 and 3; Parcel A/Development Land on part of lot 3 carries Phase I residential buildings; lot 2 is an open parking area; Parcel B is reserved for Phase II. Exhibit H gives 12,673, 92,709, and 23,363 sq ft for lot 2, Parcel A, and Parcel B, respectively, and separates owner lots 1 and 5. |
| `schenectady_zone_2026070900638022.pdf` | 3, 5–9 | Recorded declaration creates a combined zoning lot of lots 1, 2, 3, and 5; it distinguishes the developer-owned lots 2 and 3 from owner lots 1 and 5. A zoning lot is broader than the Phase I ground. |
| `schenectady_decl_2026070900638020.pdf` | 3–4 | Companion declaration confirms that same developer/owner split; it does not specify the parking use or Phase I allocation. |
| `schenectady_dec_bcp_application_2025.pdf` | 16, 26, 31 | NYS DEC October 2025 brownfield application: approximately 2.13-acre current cleanup/development site, Figure A-3 site outline, and the *one 402-unit* U-shaped building with greenhouse and courtyard. Its area is a rounded site description; the recorded agreement supplies exact Parcel A area. |
| `schenectady_hcr_board_2026-05-13.pdf` | 195–196, 201 | NYS HCR project summary: 818 Rutland (also 567 Schenectady) is one 402-unit building; construction includes **28 surface parking spaces**. Underwriting includes parking income. The “nearly 3-acre” acquisition concerns broader acquired land, not just Phase I. |
| `schenectady_dec_phase1_2022.pdf` | executive summary iii, printed 5 | Earlier three-building proposal on approximately 101,951 sq ft. Retained to prevent substituting an obsolete concept for the later 402-unit plan. |
| `schenectady_dof_map_2008.pdf`, `schenectady_dof_inset_2008.pdf`, `schenectady_dof_map_2026.pdf` | 1 each | Official historical and current Brooklyn block 4602 tax-map geometry; maps alone do not define the economic parent. |
| `schenectady_dof_map_library.json`, `schenectady_dof_parcels.json` | full responses | DOF map IDs and current parcel attributes. Current lot 3 `LAND_AREA` 26,249 sq ft is inconsistent with the recorded Parcel A and B areas; it was not used as the Phase I measure. |

The ACRIS instruments were signed June 30 and recorded July 22, 2026. They do
not print DOB job `B01318629-I1`; the site/address, developer, and exact 402-unit
project description in the DEC and HCR originals provide the crosswalk. The
agreement's phase and parking allocation is a documented later boundary for
the development, not a change to the filing date or administrative unit count.

The 698 Atlantic original DOB B-SCAN plan was sought through the official
B-SCAN document servlet, but the viewer returned an unsuccessful-retrieval
message and direct retrieval returned 403. Search-indexed scan references are
leads, not saved source originals; no B-SCAN scan has been included or treated
as decisive. The earlier Brooklyn source packet preserves the DOF and Empire
State Development originals used for its bounded B5 candidate.

The decisive directly downloadable PDFs are symlinked to the acquisition task's `output/` and rebuilt by literal, checksum-verified rules in `code/site_research.make`. ACRIS scans and smaller research snapshots remain received originals. Downloads use local completion timestamps so unchanged Make runs reuse the verified files.

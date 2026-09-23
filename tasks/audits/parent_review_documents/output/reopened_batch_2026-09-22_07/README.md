# Case 07 source inventory: 159-29/159-31 90th Avenue

Reviewed 2026-09-22. The working case packet is
`/private/tmp/nyc_reopened_batch_2026-09-22/case_07.json` (SHA-256
`3f8fbd4ca0e86d851416484ea69f4ac5e818579b38a76c2d961b216f7752c424`).
The packet derives the two filing rows from the archived 23Q4 Housing Database
and 25Q4/DOB sources. It is an audit input, not an original filing or site plan.

| Locally available project source | SHA-256 | Used fields |
| --- | --- | --- |
| `tasks/build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet` | `3cf1280bb60961790fd32a82f2ee3373d15205e30de8e55c775f17724e186788` | Archived 18v2Beta lot 47 and 2019 filing linkage |
| `tasks/build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet` | `5917f953e8a56e24bac91c5411b3ab7504916bb88b3546117ea1e0306d0f5344` | Archived 23v3 lot 47 and 2025 filing linkage |
| `tasks/build_estimation_panels/output/parent_opportunity_panel.parquet` | `0b48bb621554e77dc244a0ebbcfd864cf3cc3cea8dcf9622a2be373b96fb2a72` | Both proposal parent rows and analysis fields |
| `tasks/build_estimation_panels/output/constituent_filing_panel.parquet` | `ce1ef52fc8cc99aee146f8c2c69aacb10bdf41e463d887d238897db4ebd65455` | Exact job-to-parent membership and HDB units |

The following public pages were checked through web search on 2026-09-22.
The developer and architect pages were also opened. The NYC DOF and LPC
documents were visible only as search-index excerpts; neither PDF was opened
or visually checked. None was downloaded as fixed source bytes, so no checksum
is claimed:

| Publisher | URL | Evidence and limits |
| --- | --- | --- |
| Haussmann Development | <https://www.haussmanndev.com/properties/the-tabernacle> | Developer identifies its church ground-lease project at **159-29** 90th Avenue. Current marketing description has 260/265 units and 11 floors; neither count replaces HDB/DOB units. |
| GF55 Architects | <https://www.linkedin.com/posts/gf55-architects_permits-filed-for-159-31-90th-avenue-in-jamaica-activity-7366832169849090048-vGic> | The 2025 design architect identifies its 14-story 159-31 project with a new church space and explicitly says the new building replaces the church previously on the site. Its 258-unit public description is not an administrative unit override. |
| NYC Department of Finance | <https://a836-edms.nyc.gov/dctm-rest/repositories/dofedmspts/StatementSearch?bbl=4097580047&stmtDate=20250816&stmtType=SOA> | Search-index excerpt of an August 16, 2025 tax bill names First Reformed Dutch Church of Jamaica and prints **159-29 90th Ave**, BBL **4-09758-0047**. Address evidence only, not a surveyed building footprint. The PDF itself could not be opened. |
| NYC Landmarks Preservation Commission | <https://s-media.nyc.gov/agencies/lpc/arch_reports/2039.pdf> | The Jamaica Neighborhood Plan Phase IA study search excerpt lists site 58 as BBL **4097580047**. The 18 MB PDF could not be opened/downloaded in this environment; no page-level or footprint claim is based on it. |

Official exact-job queries attempted on 2026-09-22:
`https://data.cityofnewyork.us/resource/ic3t-wcy2.json?job__=420666256`
and
`https://data.cityofnewyork.us/resource/w9ak-ipjd.json?job_filing_number=Q01233524-I1`.
The shell could not resolve `data.cityofnewyork.us`; web open returned an access
error and the in-app browser reported `ERR_BLOCKED_BY_CLIENT`. There is thus no
frozen new DOB JSON, original plan, ACRIS instrument, or site-plan PDF in this
case folder. The packet's job numbers, status, filing dates, and units should
be checked against original job documents if a formal plan-to-plan footprint
comparison becomes necessary.

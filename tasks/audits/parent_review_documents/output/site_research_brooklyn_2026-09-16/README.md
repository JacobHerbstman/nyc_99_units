# Brooklyn site-research sources: September 16, 2026

This source set preserves four NYC DOF Digital Tax Map PDFs in the acquisition task's `output/` directory and the bounded API responses in this directory. `sources.csv` records exact URLs, retrieval date, byte counts, and SHA-256 hashes. Raw downloaded bytes are unchanged.

The maps were visually inspected after Poppler rendering. The GeoJSON request explicitly asks for the eleven relevant current parcel geometries in EPSG:2263. Polygon areas were measured in square feet. Current geometry is a measurement aid, not proof of the reference-date development boundary.

The ACRIS Master and Legals API results were queried live but not saved here. Their returned fields and document IDs are reported in `site_research_brooklyn.md`. ACRIS's image endpoint returned its bandwidth-policy page. No restriction was bypassed and no deed or survey image is claimed as reviewed.

Round two adds unchanged public API responses for the six exact DOB NOW initial filings and bounded ACRIS Master, Legals, and Parties queries. These responses support source gathering only. No ACRIS image was requested in round two. The ACRIS Legals response intentionally preserves all returned records for the exact predecessor/successor BBL filter; downstream reading restricts attention to 2024-2026 ACRIS document IDs.

The public PDFs listed above are saved in the acquisition task's `output/` directory.
`../site_research.make`, included by the task Makefile, retrieves their exact
URLs and checks the frozen SHA-256 before publishing each file. Run task-local
Make with the corresponding `../output/` target; ordinary unchanged builds
reuse the recorded file. Manual ACRIS images and small API captures remain
with this source record. `sources.sha256` identifies the preserved bytes.

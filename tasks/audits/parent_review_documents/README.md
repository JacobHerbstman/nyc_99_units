# Parent review documents

The documentary evidence gathered while reviewing parent links, filing roles and
land allocations: DOB site fields, DOF tax-map and assessment captures, ACRIS
legal descriptions, and the notes and checksum lists from each review batch.
The adopted decisions and their reasons live in `parent_opportunities_manual`;
the logbook summarizes the research.

- `output/<batch>/` holds the committed captures (JSON, CSV, HTML, notes) and
  `sources.sha256` lists, one folder per dated review batch. Nothing generates
  these files; restore them from version control if missing.
- The PDFs and other large documents live outside Git in
  `data_raw/parent_review_documents/<batch>/`, with earlier downloads in
  `data_raw/parent_review_documents/downloads/`. The checksum lists record their
  bytes. Keep that directory with any replication package.
- `code/Makefile` fetches the one document a build still reads, the 4121 Third
  Avenue work plan used by `audit_estimation_parent_links`, only when it is
  missing, and verifies it against `code/checksums.sha256`.

Other audits read `output/filing_sites_2026-09-16/bis_site_fields.json`
(`audit_parent_site_boundaries`) and `output/stack_parcels_2026-09-14/`
(`fit_pure_notch_pilot`).

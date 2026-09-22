# Charles Place and Broadway filing-role follow-up: September 20, 2026

This bounded source set preserves two original architect-authored zoning drawings,
one signed AI1 filing form, and two current NYC DOB Open Data API responses. The
PDFs are primary documents mirrored by third-party PincusCo; none displays a
legible DOB approval stamp. The acquisition did not alter PDF
or API-response bytes. `sources.csv` records exact retrieval URLs, date, byte
counts, and SHA-256 hashes; `sources.sha256` supports a local integrity check.

The plausible companion URL `ZD1_B01327363_1.pdf` returned bytes identical
to the preserved `_2.pdf`, rather than the Z-003 site plan mentioned inside
the drawing. The duplicate was not kept as a separate source.
Likewise, PincusCo's `ZD1_B01320823_1.pdf` is an AI1 form explicitly deferring
the ZD1, not a site drawing. Its `_2.pdf` URL returned byte-identical content.

The BIS response covers the exact legacy jobs 321590541 and 320911233. The
fresh DOB NOW query returned `[]`. A separate count query returned zero for
*all* B013-prefixed jobs in the current API response, so the empty exact-job
result is an access/data-availability limitation, not evidence that either new
filing was withdrawn. The preserved September 16 DOB NOW snapshots in sibling
source folders remain the source for new-filing fields and dates.

The page-level interpretation is in
`tasks/audits/audit_hdb_mappluto_condo_recovery/report/site_research_followup_charles.md`.

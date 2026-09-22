# 27-01 Jackson Avenue source notes (2026-09-22)

The two DOB BIS Jobs responses in `sources.csv` were retrieved with `curl -fsSL`
from the exact NYC Open Data URLs listed there. Raw responses are working copies
in `/private/tmp/reopened_08/`; their hashes describe those bytes. These mutable
responses are a September 22, 2026 observation, not a reconstruction of the
23Q4 HDB release. Repeating either request will refresh the response.

The three 2018 City Planning Commission resolutions were read from the official
PDF URLs and cited by page in the case report. The local shell received HTTP 403
for the PDF download; they were read through the web access tool, so no local
PDF checksum is asserted. The two historical PLUTO snapshots are the project's
existing pinned files and checksums in `tasks/fetch_mappluto_archive/code/`.

The interpretation is in
`tasks/audits/audit_hdb_mappluto_condo_recovery/report/reopened_batch_2026-09-22/case_08_jackson.md`.

## Supervisor preservation and application

The cited direct-download PDFs are now preserved in the acquisition task's `output/` directory under `reopened_XX_` names (replace XX with this case number). The shared `../reopened_batch_2026-09-22/sources.csv` and `sources.sha256` record their exact bytes; `../reopened_batch.make` supplies literal download recipes. Cases 08 and 10 also retain the cited mutable JSON/HTML responses in this source folder. Their temporary research paths are not required for replication. Original acquisition limitations above describe the initial research session.

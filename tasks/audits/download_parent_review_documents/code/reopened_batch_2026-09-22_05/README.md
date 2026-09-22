# 23-07 43 Avenue source snapshot, September 22, 2026

`sources.csv` records seven exact public NYC DOB, ACRIS, and Finance URLs,
along with publisher, retrieval date, size and SHA-256. The JSON and two
original Finance PDFs are unchanged responses. These targeted audit extracts
are separate from the project's pinned HDB releases. Reissuing a mutable API
query would deliberately refresh its records. The interpretation and page citations are in
[`case_05_43avenue.md`](../../../audit_hdb_mappluto_condo_recovery/report/reopened_batch_2026-09-22/case_05_43avenue.md).

The DOB BIS response has five rows, including repeat snapshots of document 03;
it is not five new buildings. The ACRIS legal response has 20 document–lot rows
and the selected master response five distinct document IDs. Both map PDFs
have one page. The Finance annual sales PDFs were inspected through the
publisher's public web copy but were not downloaded: the local HTTPS transfer
failed. Their URLs and relevant rows are cited in the report, and their bytes
are not represented as snapshotted or hashed here.

The two public map PDFs also have checksum-pinned rules in `../reopened_batch.make`; the frozen JSON responses and exact queries remain here.

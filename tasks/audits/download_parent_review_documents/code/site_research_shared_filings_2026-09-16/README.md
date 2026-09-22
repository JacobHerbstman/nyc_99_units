# Public records for four shared-filing site reviews

These files freeze public NYC Open Data API responses read on September 16,
2026. They support
`audit_hdb_mappluto_condo_recovery/report/site_research_shared_filings.md`.
They do not include the separately cited project DOF history snapshot.

- `dob_now_jobs.json`: DOB NOW Job Application Filings (`w9ak-ipjd`),
  filtered to B01320823-I1, B01327363-I1, X01201390-I1, X01202536-I1,
  X01252745-I1, X01252502-I1, and X01273665-I1.
- `dob_bis_jobs.json`: DOB BIS Job Application Filings (`ic3t-wcy2`),
  filtered to jobs 321590541 and 320911233.
- `dob_now_all_related_filings.json`: DOB NOW filing families with job numbers
  beginning B01320823, B01327363, X01201390, X01202536, or X01273665.
- `dob_bis_x01273665_related.json`: legacy DOB rows whose description contains
  X01273665; this returns the related BPP filing 240363959.
- `acris_master.json`: ACRIS Real Property Master (`bnx9-e6tj`) for
  documents 2025052300873001, 2025052900247002, 2025111201087001, 2025111201097001,
  2025111300218001, and 2025121600440001.
- `acris_legals.json`: ACRIS Real Property Legals (`8h5j-fqxa`) for the
  same document IDs.
- `acris_parties.json`: ACRIS Real Property Parties (`636b-3b5g`) for the
  same document IDs.

All requests used the public endpoint recorded in `sources.csv`. The DOB NOW
filter was `job_filing_number in (...)` for the seven IDs listed above and was
ordered by `job_filing_number`. The BIS filter was `job__ in
("321590541","320911233")`, ordered by `job__,doc__`. Each ACRIS filter was
`document_id in (...)` for the six IDs listed above; Master and Legals were
ordered by `document_id`, and Parties by `document_id,party_type`. Limits were
20 for DOB NOW and 100 otherwise. The largest first-pass response has 18 rows,
so none reached its limit. The round-2 family query used the five exact `LIKE
"<job-prefix>%"` conditions joined by `or`, ordered by `job_filing_number`,
with limit 500; it returned 60 rows. The BPP query used
`upper(job_description) like "%X01273665%"`, ordered by `job__,doc__`, with
limit 100; it returned one row. The JSON files are the original API response bytes, not
parsed or reserialized output. These are changing public datasets; the hashes
identify the bytes used in this review.

ACRIS document 2025052300873001 was also read in the public scan viewer on
September 16, 2026. It is a May 19, 2025 first modification of a zoning-lot
development and easement agreement; scan pages 3-4 identify lot 99 as the owner
parcel, lot 78 as the developer parcel, and state that a 2021 zoning-lot
declaration combined them into a single zoning lot. Page 5 begins the amended
easement provisions. The supervising researcher later exported the complete
scan to the adjacent `site_research_supervisor_2026-09-16` source folder.
Pages 11 and 13 were inspected locally; their transcription and legibility
limits are in the report. The PDF is not duplicated in this folder.

## Round 3 block-level ACRIS search

The round-3 files expand the ACRIS search from named documents to every legal
record indexed to the relevant lots. `acris_legals_block5700.json` covers Bronx
block 5700 lots 78, 79, 88, and 99; `acris_legals_block2457.json` covers
Brooklyn block 2457 lot 34; and `acris_legals_block3068.json` covers Bronx block
3068 lots 87-90. Each query was ordered by document ID and lot with a 50,000
row limit; the responses contain 93, 93, and 147 rows, respectively, so none
reached the limit.

For each block, the corresponding `acris_master_block*_since2018.json` file
contains the Master rows for non-FT document IDs dated 2018 or later that
appeared in the Legals response. The exact generated `document_id in (...)`
clause is preserved in the adjacent `*_where.txt` file. The candidate Legals
and Parties files then freeze rows for 14 potentially relevant zoning,
declaration, agreement, and easement documents. `round3_sources.csv` records
the complete encoded request URL, row count, date, and SHA-256 for every raw
response. All JSON responses are original API bytes.

The ACRIS scan viewer could not be started from this agent's browser runtime
during round 3. The supervising researcher subsequently exported the East
178th zoning instrument, the July 2026 Godwin development agreement, and the
December 2025 Broadway easement to the adjacent
`site_research_supervisor_2026-09-16` folder. I inspected those saved scans;
the report identifies the exact pages and distinguishes their text and diagrams
from the initial index findings. The PDFs are not duplicated here.

The purported Broadway zoning drawing at
`https://www.pincusco.com/property-data/ZD1_B01327363_2.pdf` is not included.
A search index exposed text from it, but direct retrieval returned HTTP 402.
The PDF was not read and the restriction was not bypassed.

# Jamaica 165th Street: September 20, 2026 source acquisition

These five PDFs are unchanged exports of NYC Department of Finance ACRIS recorded
scans. They were found through the [DOF Property Information Portal parcel page](https://propertyinformationportal.nyc.gov/parcels/parcel/4097950099)
for Queens block 9795 lot 99, then opened in ACRIS with **View Document** and
exported with the free viewer's **Save → All → OK** command. The ACRIS detail
pages below identify the documents. The files are browser exports with
export-time PDF metadata, not API responses or stable direct PDF URLs.

The declarations are dated February 26, 2026; the MTA memorandum was executed
that day and states a June 1, 2025 effective lease date. All five were recorded
September 1, 2026.
The PDFs have City Register cover sheets, so page references below count those
cover sheets. Acquisition date: September 20, 2026. `sources.sha256` records
the unchanged file hashes.

| Local file | ACRIS document ID and detail page | PDF pages | Bytes | Key inspected pages |
| --- | --- | ---: | ---: | --- |
| `zoning_confirmatory_2026051400252003.pdf` | [2026051400252003](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252003), CRFN 2026000247653 | 16 | 512,865 | 3–4: existing combined zoning lot |
| `zoning_development_2026051400252004.pdf` | [2026051400252004](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252004), CRFN 2026000247654 | 80 | 3,382,274 | 3–5: parcels and intended sale; 34–37: legal descriptions; 39/42: survey; 45: development-rights chart |
| `easement_2026051400252005.pdf` | [2026051400252005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252005), CRFN 2026000247655 | 69 | 3,952,824 | 3–4: vehicular passageway recitals; 51–53: land descriptions |
| `easement_2026051400252007.pdf` | [2026051400252007](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252007), CRFN 2026000247657 | 69 | 3,929,796 | 3–4: pedestrian passageway recitals |
| `mta_lease_memo_2026051400252009.pdf` | [2026051400252009](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252009), CRFN 2026000247659 | 9 | 323,139 | 3–4: MTA lease and effective date; 8–9: premises description |

The scans are image-only. For inspection, pages were rendered with Poppler and
read with Tesseract OCR; the decisive area chart and parcel survey were also
checked visually against the rendered original scans. OCR text and renderings
are temporary inspection artifacts, not substituted for the raw scans.

The related research note is
[`site_research_followup_jamaica.md`](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_jamaica.md).

## Bounded DOB feed recheck

The archived September 16 exact-job DOB NOW query in the prior acquisition
batch contained all six MPP 459 jobs. On September 20, a current official
[DOB NOW Job Application Filings API exact-job query](https://data.cityofnewyork.us/resource/w9ak-ipjd.json?job_filing_number=Q01243880-I1)
and a [block 9795 query](https://data.cityofnewyork.us/resource/w9ak-ipjd.json?%24where=block%3D%279795%27&%24limit=50000)
both returned `[]`; the raw responses are preserved here. The
[dataset metadata](https://data.cityofnewyork.us/api/views/w9ak-ipjd.json)
still describes a live feed. The zero result therefore cannot be treated as
evidence that the six saved jobs or any possible other job never existed.

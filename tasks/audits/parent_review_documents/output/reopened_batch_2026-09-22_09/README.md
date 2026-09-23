# Fort Washington reopened case 09: source and access record

Reviewed 2026-09-22. This is an acquisition and reproduction note for the [case report](../../../audit_hdb_mappluto_condo_recovery/report/reopened_batch_2026-09-22/case_09_fortwashington.md). The two ACRIS PDFs below are unchanged **Save → All** exports from the official public image viewer. Their SHA-256 values fingerprint received bytes. The two older official PDFs were read through the web reader because shell `curl` could not resolve `www.nyc.gov` or `www.nycourts.gov` in this sandbox; those page readings have exact URLs but no local byte fingerprint. A future acquisition should save their publisher bytes unchanged and compare the cited pages.

| Source | Exact URL or local path | Pages / fields reviewed |
| --- | --- | --- |
| NYC Manhattan Community Board 12, February 2012 resolution | https://www.nyc.gov/html/mancb12/downloads/pdf/land_use__reso_opposing_421a_application_for_29_overlook_terrace.pdf | PDF pp. 1–2: dual address, proposed tower, site condition and noncompletion |
| NY Supreme Court, *Amalgamated Bank v Fort Tryon Tower SPE LLC*, 2011 | https://www.nycourts.gov/reporter/pdfs/2011/2011_33461.pdf | PDF pp. 5–6 (printed pp. 3–4): financing, three addressed lots, construction history |
| DOB NOW public portal, exact job `M00775662-I1` | https://a810-dobnow.nyc.gov/publish/#!/ | Search Job Number `M00775662`, then BUILD: Job Filings → I1 → Zoning Information. Read lot area 42,417, old tax lots 27/62/63/64, footprint 26,132, zoning floor by use, and CRFNs 2023000152330/31. Also read property filing list for demolition `M00868056-I1`. Browser UI source, no exported bytes or hash. |
| ACRIS certificate, CRFN `2023000152330`, document ID `2023061600265001` | https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2023061600265001 | Saved `zoning_certificate_2023061600265001.pdf`, 5 physical pp.; pp. 2–4 certify exact job and draw irregular zoning lot. Recorded 2023-06-20. |
| ACRIS zoning-lot description, CRFN `2023000152331`, document ID `2023061600265002` | https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2023061600265002 | Saved `zoning_description_2023061600265002.pdf`, 5 physical pp.; pp. 2–4 give exact-job metes and bounds and diagram. Recorded 2023-06-20. |
| NYC DOF 2019 parcel map | https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=10218020190617112941 | Map ID `10218020190617112941`; prior parcel areas extracted from the project's DOF map audit, not directly read from an ACRIS image here |
| NYC DOF merger transaction | Local `dof_events.parquet`, transaction `96795` | 2022-08-18 old lots 27/62/63/64 to new lot 27; authority names CRFNs `2022000075740`, `2022000063394` |
| NYC DOF parcel geometry | Local `dof_geometry_lots.parquet`, vintages `22v1` and `23v3_1` | Union of old 27/62/63/64 and new 27 have symmetric difference 0.009 sq ft and Hausdorff distance 0.000032 ft; same mapped perimeter, computed planar area 43,531 sq ft. Old lot 27 has a 110.00-ft edge matching the ACRIS Exhibit III 110-ft survey call. |
| DCP MapPLUTO 22v1 | Local `dcp_mappluto_archive_22v1.parquet` | BBLs `1021800027`, `1021800062`, `1021800063`, `1021800064`; land, building floor, use, class |
| DCP MapPLUTO 23v3_1 | Local `dcp_mappluto_archive_23v3_1.parquet` | BBL `1021800027`; merged land and carried building floor |
| Reopened collision packet | `/private/tmp/nyc_reopened_batch_2026-09-22/case_09.json` | Filing dates, 23Q4 counts, collision, current review state |
| Fort Tryon Jewish Center, own history | https://www.ftjc.org/our-history.html | Renovation failed and property sale; identity of preexisting building |
| Ariel Property Advisors, 2019 marketing | https://arielpa.nyc/news/press-releases/ariel-property-advisors-keen-summit-hired-for-long-awaited-bankruptcy-sale-of-one-bennett-park | Assemblage and development-rights description; outside comparison |
| Ariel Property Advisors, 2022 marketing | https://arielpa.nyc/news/press-releases/ariel-property-advisors-closes-a-noteworthy-12-million-sale-at-29-overlook-terrace-one-bennett-in-hudson-heights | 42,418 site sq ft / 145,918 residential buildable sq ft, historical stall; outside comparison |

SHA-256 of locally read bytes (a fingerprint of these exact files, not a promise that mutable upstream data will remain identical):

```
1d95f4735a66c29bc4d2c8b39fef53083442599d4e17c91f55be1341ffe92d3b  /private/tmp/nyc_reopened_batch_2026-09-22/case_09.json
58f1ae0fcfd2967a9ad1d99e91d6e3697bdd43df83cba6f42a7faf00f0a98178  tasks/stage_mappluto_lots/output/dcp_mappluto_archive_22v1.parquet
648a0ebfd783500d198360d32cab7943cb5adc7e5e2ca9846cb35e929289b6d8  tasks/stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet
4256cefee9a86c6d6a82af952ed71b6ace1b30a8207dfc0e737cf7f1c3d5383a  tasks/audits/audit_hdb_mappluto_condo_recovery/output/dof_events.parquet
8adda629f5382027485faa8053b4b63a8546f56b415224c73abec5db95eee440  tasks/audits/audit_hdb_mappluto_condo_recovery/output/dof_geometry_lots.parquet
f0c42c7df1300e1bb71aee6114b03a57fcf8b4145dbeae3732d06f606ff1804c  tasks/audits/download_parent_review_documents/code/reopened_batch_2026-09-22_09/zoning_certificate_2023061600265001.pdf
32e5e210e25e7842680578917a33ec82523dd1813aa36e0999184f6ffc61ddc8  tasks/audits/download_parent_review_documents/code/reopened_batch_2026-09-22_09/zoning_description_2023061600265002.pdf
```

The older official PDF bytes and original DOB plan sheets remain unacquired. ACRIS resolves the 15-digit CRFNs shown in DOB NOW to the two **16-digit document IDs** listed above; a CRFN is not a document ID for the image-viewer URL. The recorded zoning-lot description is a 2023 exact-job boundary, not proof of the 2022 physical building footprint. Comparing its outer perimeter with the 22v1/23v3_1 DOF polygons shows the entire earlier synagogue lot within the site, supporting all 24,839 sq ft of archived prior floor. The area figures (archival reported 45,971, polygon-computed 43,531, DOB zoning 42,417 sq ft) disagree for apparently the same perimeter. No acquired document labels the archival figure erroneous, so the report recommends retaining that whole-parcel archival land area and reporting DOB's number separately.

# Crown Street reopened filing check, 2026-09-22

The two JSON files are unchanged responses from NYC Open Data's DOB Job
Application Filings dataset (`ic3t-wcy2`), downloaded on 2026-09-22. The
queries selected `job__` exactly and requested at most 100 rows:

| File | Source URL | SHA-256 |
| --- | --- | --- |
| `dob_job_321042304.json` | https://data.cityofnewyork.us/resource/ic3t-wcy2.json?$where=job__=%27321042304%27&$limit=100 | `0c2520a6945d39996001b162d57a2d87a1562c58232cc4f4f37c7e10ecf72913` |
| `dob_job_321593986.json` | https://data.cityofnewyork.us/resource/ic3t-wcy2.json?$where=job__=%27321593986%27&$limit=100 | `7947a3708a63fd33697801618b46c67f445b400a6e8d47d4996392324d0f3544` |

The data service is mutable. Each response has six records; the first has
duplicate document-04 records, so document counts are five distinct documents.
Two further NYC Department of City Planning primary PDFs were downloaded on
2026-09-22 from the official `www1.nyc.gov` host after `www.nyc.gov`
returned HTTP 403. They are preserved in `../../temp/reopened_03/`:

| File | Exact retrieval URL | Inspected page | SHA-256 |
| --- | --- | --- | --- |
| `17dcp067k_eas.pdf` | https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/eas/17dcp067k_eas.pdf | Attachment A p. A-1, physical PDF p. 25 | `57e46b4e16a98642b2455808a44eabd32d5c9a6bee756d064c87f178e49e2fd0` |
| `append2_feis.pdf` | https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/960-franklin-ave/append2-feis.pdf | printed p. 2, physical PDF p. 3 | `c1755f1ff0c3cc93b7f231e40131a0877e91f529de55e7e4317798b7b209de8a` |

The decisive pages were rendered and visually inspected. Page PNGs are in
the same temporary folder for quick verification. The EAS is dated
June 8, 2018 (PDF cover); the FEIS appendix was created January 26, 2021
according to its PDF metadata.

Previously preserved ACRIS and DOF PDFs, URLs, and SHA-256 hashes are in
`../site_research_followup_2026-09-20_brooklyn_large/`. Those files were
inspected again; they were not recopied or altered.

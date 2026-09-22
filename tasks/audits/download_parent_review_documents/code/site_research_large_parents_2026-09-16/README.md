# Large-parent primary documents inspected September 16, 2026

These files preserve the actual agency documents used in
`site_research_large_parents.md`. They are evidence for proposed research
classifications, not adopted corrections.

## 165th Street ACRIS documents

- `2022122700932001_p1.tif` through `_p6.tif`: all six image pages of the
  residential-unit contract, retrieved from ACRIS document
  `2022122700932001`. Pages 3 and 6 identify block 9795 lots 65 and 85 and
  parts of lots 30 and 89. No page contains a survey or dimensions.
- `2025082800320001_p1.tif` through `_p10.tif`: requested images for the
  ten-page condominium termination, ACRIS document `2025082800320001`.
  The agent inspected pages 3, 4, 8, and 10. The supervisor independently
  inspected the contract's page 6 and the termination's saved page 9; the latter
  is a Schedule B cover for a letter of no objection and adds no land measure.
  Other saved page responses were not all independently inspected.

Document-detail URLs:

- <https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2022122700932001>
- <https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025082800320001>

## Beach 30th Street City Planning documents

The PDF filenames in this and the following section are acquisition outputs in
`../../output/`. The JSON captures remain in this source-record directory.

- `2026Q0143_Site-Plan.pdf`: filed package attachment from the official ZAP
  API. The inspected plan states a 63,346.60-square-foot zoning lot for the
  development on block 15822 lots 44 and 48 and lists the additional lots in
  that zoning lot.
- `2026Q0143_DOB_approval.pdf`: official two-page artifact. The supervisor
  inspected both pages and confirmed that the November 25, 2025 letter
  certifies the full 17-lot scope for the two residential buildings.
- `zap_project.json`: official ZAP project metadata that supplied the file
  identifiers and attachment endpoints.
- `2026Q0143_Project-Description.pdf`: filed November 10, 2025 narrative.
  Pages 1–3 identify the two development lots, their approximate areas and
  parking counts, and describe the remainder of the zoning lot as vacant.
- `2026Q0143_Discussion-of-Findings.pdf` and `2026Q0143_Tax-Map.pdf`: filed
  supporting records inspected in the second source round. The approved-package
  site-plan URL returns bytes identical to `2026Q0143_Site-Plan.pdf`; the
  duplicate local copy was removed.
- `2026Q0143_Owner-Authorization.pdf`: three signed owner consents covering
  lots 48, 44, and all fifteen accessory parcels in the zoning lot.
- `2026Q0143_LandUse.pdf`: filed application. Its parcel table marks only lots
  44 and 48 as development sites and the other fifteen project-area lots as
  non-development-site parcels.

## Beach 29th Street companion application

- `zap_project_2025Q0444.json`: official ZAP metadata for the separate Beach
  29th Street Waterfront Certification.
- `2025Q0444_Project-Description.pdf`: November 10, 2025 narrative. Pages 1–3
  define lot 50 as the development site, list the merged zoning-lot parcels,
  call the remaining zoning-lot land vacant, and give building and parking
  quantities.
- `2025Q0444_Site-Plan.pdf`: November 9, 2025 sheet Z-001.00. It states a
  63,349.80-square-foot zoning lot and draws the proposed footprint on lot 50.
- `2025Q0444_DOB-Approval.pdf`: two-page City Planning approval artifact.
- `2025Q0444_Owner-Authorization.pdf`: two signed owner consents covering old
  development lot 46 and accessory lots 15, 16, and 38–45.
- `2025Q0444_LandUse.pdf`: filed application whose parcel table marks old lot
  46 as the development site and the accessory parcels as non-development-site
  project-area lots.

## DOB NOW and ZAP search responses

- `dob_now_beach_jobs_2026-09-16.json`: exact-job results from NYC Open Data
  dataset `w9ak-ipjd` for the three large buildings and fifteen two-family
  filings.
- `dob_now_165_jobs_2026-09-16.json`: exact-job results from the same official
  dataset for the six MPP 459 filings.
- `zap_search_165_2026-09-16.jsonl`: official ZAP API searches for `MPP 459`,
  `89-01 165 Street`, and `Ami Weinstock`; each returned zero projects.
- `acris_165_condo_documents_2026-09-16.json`: official ACRIS master-index
  response identifying the Jamaica Village declaration and recorded maps as
  documents `2024081600593001` and `2024081600593002`.

The full recorded map PDF is preserved by the supervisor at
`../site_research_supervisor_2026-09-16/jamaica_condo_maps_2024081600593002.pdf`.
All nineteen map sheets were visually inspected. PDF pages 5–6 are the key
site-plan and area-summary sheets: they show the 95,380-square-foot former-lot
assemblage, Unit 1's old commercial interiors, Unit 2's small stair/bulkhead
space, and the remaining exterior land as general common elements. The maps
do not contain the six later DOB NOW job labels or a six-building allocation.

Exact file-to-URL mapping:

| File | Official URL |
| --- | --- |
| `zap_project.json` | <https://zap-api-production.herokuapp.com/projects/2026Q0143> |
| `2026Q0143_Site-Plan.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KJZZPNN4AI5XNG26R6BG5JEW34C> |
| `2026Q0143_DOB_approval.pdf` | <https://zap-api-production.herokuapp.com/document/artifact/01QY2C5KLNUBZTDZMHVJAYY56FNNHZ4OOT> |
| `2026Q0143_Project-Description.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KMAFLSDYVPDWZAKIEQ2VFZJEE33> |
| `2026Q0143_Discussion-of-Findings.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KJOBXSXD4UICBH3WRII2LIS5P7Y> |
| `2026Q0143_Tax-Map.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KMGQPTVXWBJSJD27CRFPBWD6N7Q> |
| approved-package site plan, byte-identical to `2026Q0143_Site-Plan.pdf` | <https://zap-api-production.herokuapp.com/document/artifact/01QY2C5KKFV3P4URDB6JDKEJEZT2UQAPHH> |
| `2026Q0143_Owner-Authorization.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KJM335CQBG3MVFLHG3L3IC2JQGJ> |
| `2026Q0143_LandUse.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KKOJAHN4H3N4NHJK4HQ3CHUYYCX> |
| `zap_project_2025Q0444.json` | <https://zap-api-production.herokuapp.com/projects/2025Q0444> |
| `2025Q0444_Project-Description.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KOPLK56TKTCCJGYAAAOY6WSTSC6> |
| `2025Q0444_Site-Plan.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KPNGXSCFUBI75BKY3LC3HO6MLMW> |
| `2025Q0444_DOB-Approval.pdf` | <https://zap-api-production.herokuapp.com/document/artifact/01QY2C5KPKD3QOAGH5L5DII4EXOOQHHDOQ> |
| `2025Q0444_Owner-Authorization.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KJFQV5JHRRTIFHLANOLRYURWX5G> |
| `2025Q0444_LandUse.pdf` | <https://zap-api-production.herokuapp.com/document/package/01QY2C5KOVSJNNSW6YQFEKO3W64KPVYMKF> |

Exact raw-query URLs:

- `dob_now_beach_jobs_2026-09-16.json`: <https://data.cityofnewyork.us/resource/w9ak-ipjd.json?%24where=job_filing_number+in+%28%27Q01177691-I1%27%2C%27Q01177738-I1%27%2C%27Q01222315-I1%27%2C%27Q01211072-I1%27%2C%27Q01211084-I1%27%2C%27Q01211127-I1%27%2C%27Q01211635-I1%27%2C%27Q01211650-I1%27%2C%27Q01211674-I1%27%2C%27Q01211774-I1%27%2C%27Q01211790-I1%27%2C%27Q01211806-I1%27%2C%27Q01210838-I1%27%2C%27Q01209780-I1%27%2C%27Q01209570-I1%27%2C%27Q01209534-I1%27%2C%27Q01209550-I1%27%2C%27Q01209618-I1%27%29&%24limit=100>
- `dob_now_165_jobs_2026-09-16.json`: <https://data.cityofnewyork.us/resource/w9ak-ipjd.json?%24where=job_filing_number+in+%28%27Q01243880-I1%27%2C%27Q01243899-I1%27%2C%27Q01245408-I1%27%2C%27Q01245449-I1%27%2C%27Q01245454-I1%27%2C%27Q01245455-I1%27%29&%24limit=100>
- `zap_search_165_2026-09-16.jsonl` concatenates, in order: <https://zap-api-production.herokuapp.com/projects/?project_applicant_text=MPP+459&%24limit=100>, <https://zap-api-production.herokuapp.com/projects/?project_applicant_text=89-01+165+Street&%24limit=100>, and <https://zap-api-production.herokuapp.com/projects/?project_applicant_text=Ami+Weinstock&%24limit=100>.
- `acris_165_condo_documents_2026-09-16.json`: <https://data.cityofnewyork.us/resource/bnx9-e6tj.json?%24where=crfn+in+%28%272024000214404%27%2C%272024000214405%27%29&%24limit=20>.

## SHA-256

The full fingerprints are recorded in `sources.sha256`; public PDFs reside in
`../../output/`, and manual images and metadata remain in this directory. The
site-plan PDF hash is
`15424ec8bc9cfa96d6a8f1fb02835d2dec3fd25b149fdcebfaef31f50fabbf5e`;
the ZAP metadata hash is
`158f1db686ee04ffb297796e606b16708a0d12216e46c04e3d5f3267ceb28eac`.

The public PDFs listed above are saved in the acquisition task's `output/` directory.
`../site_research.make`, included by the task Makefile, retrieves their exact
URLs and checks the frozen SHA-256 before publishing each file. Run task-local
Make with the corresponding `../output/` target; ordinary unchanged builds
reuse the recorded file. Manual ACRIS images and small API captures remain
with this source record. `sources.sha256` identifies the preserved bytes.

## Priority Queens ACRIS index follow-up

- `acris_priority_blocks_legals_2026-09-16.json`: complete official legal-index
  response for Queens blocks 9795, 15821, and 15822. Query URL:
  <https://data.cityofnewyork.us/resource/8h5j-fqxa.json?%24where=borough%3D4%20AND%20block%20in%20%289795%2C15821%2C15822%29&%24limit=50000>.
- `acris_priority_blocks_master_2026-09-16.json`: official master rows for the
  653 distinct document IDs returned by the legal query. The file was assembled
  from nine bounded queries to dataset `bnx9-e6tj`, each using
  `$where=document_id in (...)` for at most 75 IDs and `$limit=1000`; it retains
  all returned rows rather than only selected document types.
- `acris_priority_instruments_parties_2026-09-16.json`: official party rows for
  easement `2025071800009001` and the eight related Beach declarations and
  agreements identified in the report. Query endpoint `636b-3b5g`, with
  `$where=document_id in ('2025071800009001','2026030100019001','2026030100019002','2026052200162003','2026052200162006','2026061000055006','2026061000055008','2026061000055017','2026061000055018')`
  and `$limit=1000`.

The master and legal indexes identify document types and affected parcels;
they do not reveal operative easement or declaration terms. An attempted fresh
in-app-browser retrieval of easement `2025071800009001` returned `Browser is
not available: iab`, so no page from that instrument was inspected here.

## Acquisition verification

Verified September 16, 2026 from `code/`:

- Missing-output retrieval: removed
  `../output/2026Q0143_Discussion-of-Findings.pdf` after saving a temporary
  backup, ran its concrete Make target, and compared the retrieved output to
  the backup byte for byte. The frozen-hash check printed `OK`.
- Unchanged reuse: `make -q` returned 0 for the representative target and for
  all six new targets together.
- Recipe propagation: `make -n -W site_research.make` for the representative
  target printed its download, hash-check, and move recipe.
- Failure preservation: forced the representative recipe with a temporary
  `curl` executable that exited 42. Make exited 2 before `mv`; the existing
  output's SHA-256 remained
  `1eb93992755cecc3857ac6d50c870e44f42a9af7a08c7875b0f4ce897b6b7e02`.
- All six output hashes match `sources.sha256`. `git diff --check` passed for
  the Make fragment and this source record.
- The four round-three owner-authorization and Land Use Application targets
  were retrieved through their concrete Make rules; all four frozen-hash
  checks printed `OK`.

## All-158 follow-up: GO Broome plan targets

The historical 55 Suffolk Street and 64 Norfolk Street parents are the two
buildings in City Planning application C 200061(A) ZSM. The official DEIS
Chapter 1 is
<https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/go-broome/01-deis.pdf>.
Its Figure 1-2, “Site Plan,” is PDF page 13. The official CPC decision is
<https://www.nyc.gov/assets/planning/download/pdf/about/cpc/200061a.pdf>.
PDF pages 35–36 incorporate drawing Z-103.00, “Seward Park Extension West LSRD
Site Plan (Proposed),” and drawing Z-203.00, “Parcel 2A – Zoning Lot Site Plan
(Development Site),” both revised January 17, 2020.

The searchable official text was inspected. It defines the combined
two-building development site as block 346 lots 37 and 75, 32,401 square feet,
while distinguishing existing lot 1 and the broader LSRD. Figure 1-2 itself
was not visually inspected: direct `curl -L --fail` retrieval of each NYC
Planning PDF returned HTTP 403, the web source did not return a legible plan
image, and computer use reported no browser available. No access restriction
was bypassed, and no local source bytes were added for these URLs.

## All-158 DEC site applications

- `147-35_95th_Site_A_BCP_Application.pdf` is the official DEC complete BCP
  application from
  <https://extapps.dec.ny.gov/data/DecDocs/C241263/Application.BCP.C241263.2022-04-11.Complete%20BCP%20Application.pdf>.
  PDF page 27 defines block 9999 lot 40 as a 30,067-square-foot Site A created
  by the December 2021 equal subdivision of former lot 1; the proposed
  building encompasses the site.
- `94-15_Sutphin_Site_B_BCP_Application.pdf` is the official DEC complete BCP
  application from
  <https://extapps.dec.ny.gov/data/DecDocs/C241278/Application.BCP.C241278.2023-10-18.Complete%20BCP%20Application.pdf>.
  PDF page 31 defines retained lot 1 as the 30,047-square-foot Site B created
  by that subdivision; the proposed building occupies the site.

Both PDFs are preserved as received. Their SHA-256 fingerprints are recorded
in `sources.sha256`.

# Acquire primary documents for parent-link review

This audit acquisition task preserves publicly accessible city documents used to resolve project membership and unit counts. The initial snapshot was retrieved September 9, 2026 from NYC OER's project repositories. Concrete file identifiers and destinations are recorded in `code/Makefile`; consumers inspect the retained files, not a changing portal summary. Ordinary builds reuse this snapshot. Refreshes require an explicit source change and evidence comparison.

Outputs are unchanged source PDFs. Partial downloads stay in `temp/` and never become valid outputs. Run Make from `code/`. The evidence review is maintained in `audit_estimation_parent_links/report/`. These records do not feed production estimates.

Retrieved-file SHA-256 fingerprints (September 9, 2026):

- `4121_third_fact_sheet_2026-09-04.pdf`: `556a76d63277b596d0935fdc41f5816d006fedf7e7b5b8036533ceff31dd595a`
- `4121_third_rawp_2025-10-01.pdf`: `ee3b3942eca127adc3fc2d4306b9579eb8d5b8d7e54c76a7659cbf7af1bf6652`
- `4133_third_fact_sheet_2026-09-02.pdf`: `267336d7042edc1f84325a7318f5450f157443ef5bdf62379b668b89496b17b5`
- `4133_third_rawp_2025-10-30.pdf`: `d1a06d9c925b2891bcf917645a4a45b920f1dd6754b43f7bede3f1133fb6d748`
- `4137_third_rawp_2025-07-31.pdf`: `b4796b98adcebe95e2089aa714011c3a9415502232db8e82721bb69ba43246c5`

- `1660_boone_bcp_application_2024-10-28.pdf`: `c5e405c8f21e4d912ebff55f81076645210569968c03f7434ccb1df83bf3029f`

The Boone document is a New York State DEC source. Its PDF page 62 identifies Vaja Group’s members. The September 9 refresh of the five OER files retained their recorded fingerprints.

September 10 additions are defined in `code/boundary_documents.make`, included by
the normal Makefile. GEI's December 2023 Astoria Cove geotechnical report is
published by DEC under a misleading `Phase I Report` filename. Its PDF page 9
maps the four proposed Phase 1 buildings to their blocks and lots. HDC's June
2026 authorization, PDF page 17, supplies Turnbull's apartment breakdown. The
Rockaway TEFRA notice identifies Phase IV. The Boyland source is an architect's
zoning drawing preserved by PincusCo, dated December 3, 2025. Grand Concourse's
DEC documents establish site boundaries but do not supply the needed unit
schedule. The August application explicitly states that no development plans
were then available.

Retrieved September 10 SHA-256 fingerprints:

- `astoria_cove_geotechnical_2023-12.pdf`: `ec37a6505a0e5b272e2d81b21582199a241533a441b8d6a699c3c092471726c7`
- `boyland_zoning_B01328447.pdf`: `a3ccdc1d750cf9fbcb6376903ef5ae5cab602d10b796c89166d96c295fd14d7a`
- `grand_concourse_application_2025-08.pdf`: `84bedb28d5d3883e014f9316685c7d217c37b519803899392464e214b7169236`
- `grand_concourse_citizen_plan_2025-09.pdf`: `6b2d8666733f45e4b463e161545efc886234171d8a9ceb1fe59e2e52d5e9d2a1`
- `rockaway_village_tefra_2021-11-18.pdf`: `ba36b0388a42c85b03c329a8ab594eab7d07deb419c1be7dad57a43d35ac1b51`
- `turnbull_hdc_authorization_2026-06.pdf`: `285b5f91e1956106e81c2e92cc71284d59e26de48b1f11568b6ec38b175827d3`

Unavailable sources are not represented by placeholder outputs. The city River
North technical memorandum, Queens CB1 January 12, 2026 agenda, and DOS
Greenpoint Quay package returned HTTP 403 on September 10. Browser navigation
to the DOS URL also returned the agency's unavailable-page notice. The Myrtle
link below returned HTML containing an upstream DOB Access Denied response,
not a zoning PDF; PDF validation correctly failed and no output was published.
These URLs remain research leads, not inspected local documents:

- https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/liberty-towers/tech-memo.pdf
- https://www.nyc.gov/assets/queenscb1/downloads/pdf/committee-meeting-agendas/2026/2026-Housing-Memo-Agenda-01_12.pdf
- https://dos.ny.gov/system/files/documents/2026/04/f-2025-0815_b.pdf
- https://www.pincusco.com/property-data/ZD1_Q01338971_2.pdf

If an agency restores an unavailable source, add its concrete acquisition rule
and inspect the downloaded record before using it as adjudication evidence.
The original six PDFs were also retrieved after adding the include; their
fingerprints were compared with the September 9 record and were unchanged.

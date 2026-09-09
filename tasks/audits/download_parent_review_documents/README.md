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

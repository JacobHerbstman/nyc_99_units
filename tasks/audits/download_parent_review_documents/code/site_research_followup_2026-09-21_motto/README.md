# Motto evidence snapshot — September 21, 2026

The original ACRIS zoning, development, and egress PDFs were downloaded through
the public City Register image viewer's Save → All control. `sources.csv`
records the original document URLs, retrieval date, byte counts, and SHA-256s.
These browser exports are received source files; automated replay is not
claimed. The public DEC documents and two DOF maps have concrete,
checksum-verified download rules in `../site_research.make`. For example:

```sh
make -C .. ../output/motto_dec_final_engineering_report_appendix_d.pdf
```

The complete DEC appendix preserves the June 2019 Phase I report and site plan
on PDF pages 148, 154–155 and 184. The development agreement's pages 4 and 9
and the egress agreement's page 3 identify the economic site and both exact
DOB jobs. All original bytes remain unchanged. Ordinary builds reuse their
recorded versions; a changed publisher file fails checksum validation.

The small MapPLUTO and DOF CSVs are extracts from existing frozen project
sources, explicitly labeled as extracts in the register. They are supporting
inspection copies. The proposed decision CSV is a researcher recommendation,
also labeled as derived; production consumes the adjudicated row in
`tasks/parent_opportunities_manual/output/site_lot_decisions.csv`.

The substantive review is
`tasks/audits/audit_hdb_mappluto_condo_recovery/report/site_research_motto_2026-09-21.md`.

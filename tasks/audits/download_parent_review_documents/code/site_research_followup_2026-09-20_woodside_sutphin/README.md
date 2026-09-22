# Woodside and Sutphin ground follow-up (2026-09-20)

The four original public PDFs in this directory are registered in `sources.csv`; `sources.sha256` fixes their bytes. They supplement earlier saved NYSDEC Woodside and Sutphin documents, the NYC DOF Sutphin 2022 tax map, and the frozen 18v2beta and 21v1 MapPLUTO lot areas. Source pages and the land/economic-parent distinction are in [the case note](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_woodside_sutphin_ground.md).

The 2018 and 2020 Woodside maps were visually inspected. The first displays the six predecessor lots, with other lots 1, 23, and 39 outside their union. The second displays successor lots 8 and 9. The previously saved Sutphin January 31, 2022 DOF map was also visually inspected; it displays retained lot 1 and new lot 40 as separate, adjacent parcels. The PDFs are primary map records, but the land-area figures in the case note come from recorded MapPLUTO/DOF fields, not pixel measurements.

The decisive directly downloadable PDFs are symlinked to the acquisition task's `output/` and rebuilt by literal, checksum-verified rules in `code/site_research.make`. ACRIS scans and smaller research snapshots remain received originals. Downloads use local completion timestamps so unchanged Make runs reuse the verified files.

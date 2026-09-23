# Stage DCP Housing Database

Stages the DCP Housing Database project-level file into stable fields for downstream analysis.

The staged output keeps one record per DCP project-level row and exposes filing dates, permit dates, proposed Class A units, net Class A units, certificate-of-occupancy units, geography, and source provenance.

For each release the task reads the ZIP published by `fetch_dcp_housing_database` and writes a raw table and a normalized table, each with a data report: `dcp_housing_database_project_level_raw_<release>.parquet` and `dcp_housing_database_project_level_<release>.parquet`. The 25Q4 tables are the post-policy source and the 23Q4 tables the historical source.

The 23Q4 raw and staged outputs retain every row of the archive's `HousingDB_post2010_inactive_included.csv`; `historical_active` marks jobs also present in `HousingDB_post2010.csv`. The script checks unique job numbers, active-file containment, agreement on `ClassAProp`, and the `23Q4` version. This flag records source status and does not select the study sample. The staged 23Q4 table has the same fields as 25Q4 plus `historical_active`, including the 23Q4 `job_status` and `date_updated` values. The archive's `ClassAProp` measures proposed Class A units at this release, not necessarily the original filing-date proposal.

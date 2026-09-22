# Stage DCP Housing Database

Stages the DCP Housing Database project-level file into stable fields for downstream analysis.

The staged output keeps one record per DCP project-level row and exposes filing dates, permit dates, proposed Class A units, net Class A units, certificate-of-occupancy units, geography, and source provenance.

This task now reads the recorded source ZIP directly, preserves the raw table, and constructs the normalized table. Both tables and their source metadata remain explicit outputs; acquisition remains owned by `fetch_dcp_housing_database`.

Run `make` in `code/` after the fetch task has prepared its inputs. The existing 25Q4 outputs remain the post-policy source. The 23Q4 outputs are `dcp_housing_database_project_level_raw_23q4.parquet` and `dcp_housing_database_project_level_23q4.parquet`, each with a data report. The corresponding `*_files_23q4.csv` files record the staged source path and archive member.

The 23Q4 raw and staged outputs retain every row of the archive's `HousingDB_post2010_inactive_included.csv`; `historical_active` marks jobs also present in `HousingDB_post2010.csv`. The script checks unique job numbers, active-file containment, agreement on `ClassAProp`, and the `23Q4` version. This flag records source status and does not select the study sample. The staged 23Q4 table has the same fields as 25Q4 plus `historical_active`, including the 23Q4 `job_status` and `date_updated` values. The archive's `ClassAProp` measures proposed Class A units at this release, not necessarily the original filing-date proposal.

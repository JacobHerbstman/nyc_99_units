# Broadway / West 187 reopened review source register

Review: 2026-09-22; parent `post_policy__M01393124-I1`. No remote PDF bytes were acquired in this pass. The original DOB BIS job page returned Access Denied in the browser, and the city Socrata endpoint was blocked; no purported plan was substituted. The case note is at `../../../audit_hdb_mappluto_condo_recovery/report/reopened_batch_2026-09-22/case_01_broadway.md`.

## Frozen project sources inspected

| File | SHA-256 | Relevant keys |
| --- | --- | --- |
| `tasks/stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_23q4.parquet` | `fb34edf3baa40140a90497bcac0c08ef1fdd3b4246c47b6f11bbdb7b95423f2c` | job `123766433` |
| `tasks/stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet` | `c374838aa52577e3cdcc36927156b879ca0dfbf40949a4d0c99fda87a151bc80` | absent job `123766433` |
| `tasks/stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet` | `648a0ebfd783500d198360d32cab7943cb5adc7e5e2ca9846cb35e929289b6d8` | BBLs `1021700003`, `1021700035` |
| `tasks/stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet` | `e3b1c21610d3e567001e4710196c7c11a58a395b9fe7715ddd568fb364fb95ea` | `M01393124-I1`, `M01417673-I1` |

## Web pages read without local download

- [LoopNet listing 28959093](https://www.loopnet.com/Listing/673-W-187th-St-New-York-NY/28959093/): listed from 2023-07-10, vacant 2,373-square-foot lot with 12-unit approved plan. Page text read 2026-09-22. No stable PDF page or local hash.
- [NYC Finance 2019 Manhattan annual sales PDF](https://www.nyc.gov/assets/finance/downloads/pdf/rolling_sales/annualized-sales/2019/2019_manhattan.pdf): row block 2170, lot 35, address 673 West 187 Street, 2019-03-28 sale. Search index read 2026-09-22; PDF image pages not inspected and no hash obtained.
- [2019 YIMBY article](https://newyorkyimby.com/2019/06/permits-filed-for-673-west-187th-street-in-hudson-heights-manhattan.html): original project team and proposed twelve units. Page read 2026-09-22; no local hash.
- [DOB BIS job detail requested](https://a810-bisweb.nyc.gov/bisweb/JobsQueryByNumberServlet?passjobnumber=123766433&passdocnumber=01): Access Denied; no substantive contents or hash.

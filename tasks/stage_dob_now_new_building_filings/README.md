# Stage DOB NOW initial New Building filings

This task reads the frozen DOB NOW raw extract and writes a typed, one-row-per-
initial-filing parquet file. It normalizes job numbers, dates, BBLs, unit counts,
and total construction floor area. A compact QC file records key uniqueness and
coverage checks.

`total_construction_floor_area` is the proposed project's gross construction
area reported by DOB. The source does not contain proposed residential floor
area, apartment size, bedroom count, or amenity space.

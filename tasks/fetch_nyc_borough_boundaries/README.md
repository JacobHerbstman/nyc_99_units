# NYC borough outlines

Publishes the DCP borough boundaries (water excluded) from NYC Open Data,
dataset [`gthc-hcne`](https://data.cityofnewyork.us/City-Government/Borough-Boundaries/gthc-hcne),
as extracted on September 8, 2026.

The API is mutable, so the source of record is the capture in
`data_raw/nyc_borough_boundaries/2026-09-08/`. The API is queried only when that
capture is missing, and the download must match the checksum in
`code/checksums.sha256` before it is saved. `copy_boundaries.R` checks the five
borough geometries, writes the data report, and copies the capture to `output/`.

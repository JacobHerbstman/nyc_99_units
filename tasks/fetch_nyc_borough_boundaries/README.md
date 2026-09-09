# NYC borough outlines

Downloads the NYC Department of City Planning borough boundaries (water excluded)
from NYC Open Data, dataset `gthc-hcne`. The September 8, 2026 extract is preserved
in the dated output; the API URL is mutable, so refreshing this vintage is a
deliberate source change. The analysis validates the five borough geometries.

Source: https://data.cityofnewyork.us/City-Government/Borough-Boundaries/gthc-hcne

Run `make` in `code/`. An unchanged build reuses the local snapshot. A partial
download is never published as the final output.

Snapshot SHA-256: `7aa44d9fb611f2f518a226ff994a6516a261a8ce982ccf1e7b37d663687f443c`.

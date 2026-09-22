# Stage MapPLUTO lots

Cleans each recorded PLUTO or MapPLUTO release into a lot-level table with stable fields for site linkage and predetermined characteristics. Each release has its own concrete Make target and input link. Missing files fail instead of shrinking the set of releases.

`mappluto_lot_files.csv` indexes these declared releases. It contains source metadata and paths, without build timestamps or file sizes. Downstream tasks select the documented as-of vintage. Standard reports summarize every saved release in `report/`.

Raw loading and normalization now share this task. Each recorded vintage remains a separate Make target; downstream consumers use the same raw and normalized output filenames. Source acquisition stays in `fetch_mappluto_archive`.

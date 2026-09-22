# Sources for the twelve-parent footprint review

NYC DOF, retrieved September 15, 2026. `filing_parcels.geojson` preserves the
original public ArcGIS response; `filing_parcels_url.txt` records the exact query
and `geometry.sha256` fingerprints the bytes. The query requests the selected
filing and candidate BBLs, geometry, and EPSG:2263. There are 13 returned parcels.
The service is mutable, so replication uses this saved response. Any refresh
requires a new recorded extract and a comparison of results.

`sources.csv` records the 25 dated DOF maps and the March 2026 NYSDEC Sackett
amendment, with URLs and SHA-256 hashes. The acquisition Makefile downloads these
PDFs into `output/`, validates their hashes and PDF format, then publishes them.
For a specific map, run, for example, from the project root:

```
make -C tasks/audits/download_parent_review_documents/code ../output/dof_map_30226520240625095122.pdf
```

The September 2025 Sackett map is the version covering the July 8, 2026 sample
endpoint. Its later August 2026 map documents a subsequent merger. The NYSDEC
amendment describes a site containing lots 17 and 47 together, so lot 47 alone
cannot establish the original filing's development footprint.

The consumer is `audit_hdb_mappluto_condo_recovery/code/measure_dof_subset.R`.
The manual review table there references the dated map IDs and records which
cases enter the provisional comparison. PDF review is documentary evidence;
the analysis derives numeric areas from the existing PLUTO 25v4 source archive.

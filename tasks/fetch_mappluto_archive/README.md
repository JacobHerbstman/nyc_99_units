# Fetch MapPLUTO Archive

Downloads current PLUTO/MapPLUTO release metadata and archived MapPLUTO
shapefile releases from official DCP sources. The historical geometry inventory
includes the legacy 2009--2017 borough-level MapPLUTO bundles as well as the
citywide 2018-and-later bundles.

This task only fetches raw source files and writes an inventory. It does not clean lots, choose model vintages, or define the prediction risk set.

Approximate runtime can be long because the archived MapPLUTO bundle is large.

## Recorded source vintage

`code/source_files.csv` records the exact source release used in this study. The Makefile owns each received file, checks its SHA-256, and exposes it through `output/`. Versioned public archives have direct download recipes. Mutable API responses and metadata require the original dated capture at the literal `data_raw/` prerequisite: the agency does not provide a historical query endpoint. A missing capture fails the build; it is never replaced silently with current data. Source refreshes require deliberately updating the capture, ledger, and checksum together. The original `raw_path` column remains provenance metadata; consumers read local input links.

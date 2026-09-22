# QCEW borough source files

BLS QCEW annual area CSV slices for the five NYC counties, 2019–2023. Public, no API key. Snapshot first retrieved September 8, 2026; URLs are mutable. Retain downloaded bytes on unchanged builds; deliberate refresh requires removing the relevant source and comparing reports. Source-file MD5s are in report/. Sources contain all industries and ownership categories; the consuming audit selects private construction.

Run `make` in code/. Each source has a generated data report. Failed downloads remain .part files, never final targets.

Documentation: https://www.bls.gov/cew/additional-resources/open-data/csv-data-slices.htm

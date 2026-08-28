# Fetch MapPLUTO Archive

Downloads current PLUTO/MapPLUTO release metadata and archived MapPLUTO
shapefile releases from official DCP sources. The historical geometry inventory
includes the legacy 2009--2017 borough-level MapPLUTO bundles as well as the
citywide 2018-and-later bundles.

This task only fetches raw source files and writes an inventory. It does not clean lots, choose model vintages, or define the prediction risk set.

Approximate runtime can be long because the archived MapPLUTO bundle is large.

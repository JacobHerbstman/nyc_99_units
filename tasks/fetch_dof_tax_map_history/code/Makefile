include ../../shared/code/shell_functions.make

LAYERS := 0 3 4 8 9 13 14 15

all: $(foreach layer,$(LAYERS),../output/dtm_$(layer).zip ../output/dtm_$(layer).parquet) \
	../output/applications.zip ../output/applications.parquet

include ../../shared/code/generic.make

../output/dtm_%.parquet: stage_dof.R ../output/dtm_%.zip Makefile \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< dtm_$*

../output/applications.parquet: stage_dof.R ../output/applications.zip Makefile \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< applications

../output/%.zip: ../../../data_raw/dof_tax_map/2026-09-15/%.zip checksums.sha256 | ../output
	awk '$$2 == "$*.zip" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../../../data_raw/dof_tax_map/2026-09-15/dtm_%.zip:
	mkdir -p $(@D)
	python3 download_dof.py https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/$* $@ $$(awk '$$2 == "dtm_$*.zip" {print $$1}' checksums.sha256)

../../../data_raw/dof_tax_map/2026-09-15/applications.zip:
	mkdir -p $(@D)
	python3 download_dof.py https://services3.arcgis.com/aD88pT4hjL80xq0F/arcgis/rest/services/TMU_Application_Points_Public/FeatureServer/3 $@ $$(awk '$$2 == "applications.zip" {print $$1}' checksums.sha256)

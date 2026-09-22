include ../../../shared/code/shell_functions.make

all: ../output/land_measurement_sensitivity.csv

include ../../../shared/code/generic.make

../output/land_measurement_sensitivity.csv: land_measurement_sensitivity.R Makefile \
	../../../shared/code/scale_shape_helpers.R ../../../shared/code/write_data_report.R \
	../input/parent_opportunity_panel.parquet ../input/parent_site_scope.csv \
	../input/calibration_weights.csv | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/parent_site_scope.csv: ../../audit_hdb_mappluto_condo_recovery/output/parent_site_scope.csv | ../input
	ln -sf $< $@

../input/calibration_weights.csv: ../../audit_scale_shape_splitting/output/calibration_weights.csv | ../input
	ln -sf $< $@

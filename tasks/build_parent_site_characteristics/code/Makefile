include ../../shared/code/shell_functions.make

all: ../output/historical_parent_site_characteristics.parquet \
	../output/post_policy_parent_site_characteristics.parquet

include ../../shared/code/generic.make

../output/%_parent_site_characteristics.parquet: build_parent_site_characteristics.R \
	../input/symmetric_parent_membership.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/historical_hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/site_lot_decisions.csv ../input/dcp_mappluto_archive_18v1_1.parquet \
	../input/dcp_mappluto_archive_18v2beta.parquet ../input/dcp_mappluto_archive_18v2_1.parquet \
	../input/dcp_mappluto_archive_19v1.parquet \
	../input/dcp_mappluto_archive_19v2.parquet \
	../input/dcp_mappluto_archive_20v1.parquet ../input/dcp_mappluto_archive_20v3.parquet \
	../input/dcp_mappluto_archive_20v5.parquet ../input/dcp_mappluto_archive_20v8.parquet \
	../input/dcp_mappluto_archive_21v1.parquet ../input/dcp_mappluto_archive_21v3.parquet \
	../input/dcp_mappluto_archive_22v1.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet ../../shared/code/source_pipeline_utils.R \
	../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $< $*

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/site_lot_decisions.csv: ../../parent_opportunities_manual/output/site_lot_decisions.csv | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_18v1_1.parquet ../input/dcp_mappluto_archive_18v2beta.parquet \
../input/dcp_mappluto_archive_18v2_1.parquet \
../input/dcp_mappluto_archive_19v1.parquet ../input/dcp_mappluto_archive_19v2.parquet \
../input/dcp_mappluto_archive_20v1.parquet ../input/dcp_mappluto_archive_20v3.parquet \
../input/dcp_mappluto_archive_20v5.parquet ../input/dcp_mappluto_archive_20v8.parquet \
../input/dcp_mappluto_archive_21v1.parquet ../input/dcp_mappluto_archive_21v3.parquet \
../input/dcp_mappluto_archive_22v1.parquet: \
../input/%.parquet: ../../stage_mappluto_lots/output/%.parquet | ../input
	ln -sf $< $@

../input/hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_23v3_1.parquet: \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/historical_hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

include ../../shared/code/shell_functions.make

all: ../output/historical_parent_site_characteristics.parquet ../output/post_policy_parent_site_characteristics.parquet \
	../report/historical_parent_site_characteristics.txt ../report/post_policy_parent_site_characteristics.txt

../output/%_parent_site_characteristics.parquet ../report/%_parent_site_characteristics.txt: \
	build_parent_site_characteristics.R ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_site_panel.parquet ../input/dcp_mappluto_archive_23v3_1.parquet \
	../../shared/code/source_pipeline_utils.R ../../shared/code/write_data_report.R Makefile | ../output ../report
	$(R) $< $*

../input/symmetric_parent_membership.parquet: ../../construct_parent_cohorts/output/symmetric_parent_membership.parquet \
	| ../input
	ln -sf $< $@

../input/hdb_mappluto_site_panel.parquet: ../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | \
	../input
	ln -sf $< $@

../input/dcp_mappluto_archive_23v3_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | \
	../input
	ln -sf $< $@

link-inputs: ../input/symmetric_parent_membership.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet

include ../../shared/code/generic.make

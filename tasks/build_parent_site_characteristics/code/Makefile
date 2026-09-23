include ../../shared/code/shell_functions.make

# Citywide MapPLUTO releases: reference maps for filings and merged lots.
MAPPLUTO_RELEASES := 18v1_1 18v2_1 18v2beta 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 \
	22v1 22v2 23v1 23v1_1 23v1_2 23v2 23v3 23v3_1
MAPPLUTO_INPUTS := $(foreach v,$(MAPPLUTO_RELEASES),../input/dcp_mappluto_archive_$(v).parquet)

all: ../output/historical_parent_site_characteristics.parquet \
	../output/post_policy_parent_site_characteristics.parquet

include ../../shared/code/generic.make

../output/%_parent_site_characteristics.parquet: build_parent_site_characteristics.R \
	../input/symmetric_parent_membership.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/historical_hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/site_lot_decisions.csv \
	../input/dof_transaction_headers.parquet ../input/dof_lot_actions.parquet $(MAPPLUTO_INPUTS) \
	../../shared/code/source_pipeline_utils.R ../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $< $*

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/site_lot_decisions.csv: ../../parent_opportunities_manual/output/site_lot_decisions.csv | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_%.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_%.parquet | ../input
	ln -sf $< $@

../input/hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/historical_hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/dof_transaction_headers.parquet: ../../fetch_dof_tax_map_history/output/dtm_9.parquet | ../input
	ln -sf $< $@

../input/dof_lot_actions.parquet: ../../fetch_dof_tax_map_history/output/dtm_15.parquet | ../input
	ln -sf $< $@

SHELL := bash
include ../../../shell_functions.make

all: ../output/hdb_dof_sales_feasibility_summary.csv \
	../output/hdb_dof_sales_feasibility_by_year.csv \
	../output/hdb_dof_sales_feasibility_by_match_method.csv \
	../output/hdb_dof_sales_nearest_prefiling_sales.csv \
	../output/hdb_dof_sales_price_distribution.csv

../output/hdb_dof_sales_feasibility_summary.csv: audit_hdb_dof_sales_feasibility.R ../input/hdb_mappluto_training_panel.parquet ../input/dof_annualized_sales.parquet | ../output
	$(R) $<

../output/hdb_dof_sales_feasibility_by_year.csv ../output/hdb_dof_sales_feasibility_by_match_method.csv ../output/hdb_dof_sales_nearest_prefiling_sales.csv ../output/hdb_dof_sales_price_distribution.csv: ../output/hdb_dof_sales_feasibility_summary.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

../input/dof_annualized_sales.parquet: ../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet | ../input
	@test "$$(readlink "$@")" = "../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" || ln -sf "../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/dof_annualized_sales.parquet

include ../../generic.make

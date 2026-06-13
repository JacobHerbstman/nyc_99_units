SHELL := bash
include ../../../shell_functions.make

all: ../output/acris_direct_opportunity_coverage_by_borough.csv \
	../output/acris_direct_opportunity_document_types.csv \
	../output/acris_direct_opportunity_legal_flags.csv \
	../output/acris_direct_opportunity_dof_overlap_by_year.csv \
	../output/acris_direct_opportunity_non_deed_document_counts.csv \
	../output/acris_direct_opportunity_exact_dof_building_class_mix.csv \
	../output/acris_direct_opportunity_positive_deed_property_types.csv

../output/acris_direct_opportunity_coverage_by_borough.csv: summarize_acris_direct_opportunity_coverage.R ../../../_lib/source_pipeline_utils.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/acris_direct_opportunity_legals.parquet ../input/acris_direct_opportunity_deed_bbls.parquet ../input/opportunity_sales_exact_bbl.parquet | ../output
	$(R) $<

../output/acris_direct_opportunity_document_types.csv ../output/acris_direct_opportunity_legal_flags.csv ../output/acris_direct_opportunity_dof_overlap_by_year.csv ../output/acris_direct_opportunity_non_deed_document_counts.csv ../output/acris_direct_opportunity_exact_dof_building_class_mix.csv ../output/acris_direct_opportunity_positive_deed_property_types.csv: ../output/acris_direct_opportunity_coverage_by_borough.csv
	@test -s "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_legals.parquet: ../../../stage_acris_direct_opportunity_legals/output/acris_direct_opportunity_legals.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_bbls.parquet: ../../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/opportunity_sales_exact_bbl.parquet: ../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/acris_direct_opportunity_legals.parquet ../input/acris_direct_opportunity_deed_bbls.parquet ../input/opportunity_sales_exact_bbl.parquet

include ../../generic.make

SHELL := bash
include ../../shell_functions.make

all: ../output/historical_enhanced_parent_model_panel.parquet \
	../output/post_policy_enhanced_parent_model_panel.parquet

../output/historical_enhanced_parent_model_panel.parquet: build_parent_model_panel.R \
	../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet | ../output
	$(R) $<

../output/post_policy_enhanced_parent_model_panel.parquet: ../output/historical_enhanced_parent_model_panel.parquet
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hdb_mappluto_training_panel.parquet: ../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet

include ../../generic.make

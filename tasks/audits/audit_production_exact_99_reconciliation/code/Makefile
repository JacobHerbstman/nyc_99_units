SHELL := bash
include ../../../shell_functions.make

THRESHOLD_UNITS := 100
POST_YEAR := 2025

all: ../output/production_exact_99_reconciliation.csv \
	../output/production_exact_99_reconciliation_qc.csv

../output/production_exact_99_reconciliation.csv: reconcile_production_exact_99.R \
	../../../_lib/source_pipeline_utils.R \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_model_parameters.csv \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/developer_opportunity_job_crosswalk.parquet \
	../input/developer_opportunity_exact_99_casebook.csv \
	../input/developer_opportunity_candidate_pairs.csv \
	../input/provisional_parent_universal_membership.parquet \
	../input/provisional_parent_universal_links.parquet | ../output
	$(R) $< $(THRESHOLD_UNITS) $(POST_YEAR)

../output/production_exact_99_reconciliation_qc.csv: ../output/production_exact_99_reconciliation.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_scores.parquet: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_model_parameters.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_model_parameters.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_job_crosswalk.parquet: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_job_crosswalk.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_exact_99_casebook.csv: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_exact_99_casebook.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_candidate_pairs.csv: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_candidate_pairs.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/provisional_parent_universal_membership.parquet: ../../audit_provisional_parent_no_notch/output/provisional_parent_universal_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/provisional_parent_universal_links.parquet: ../../audit_provisional_parent_no_notch/output/provisional_parent_universal_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_model_parameters.csv \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/developer_opportunity_job_crosswalk.parquet \
	../input/developer_opportunity_exact_99_casebook.csv \
	../input/developer_opportunity_candidate_pairs.csv \
	../input/provisional_parent_universal_membership.parquet \
	../input/provisional_parent_universal_links.parquet

include ../../generic.make

SHELL := bash

MINIMUM_UNITS := 50
EXACT_PLOT_MAXIMUM := 300
POOLED_TAIL_START := 301

all: ../output/parent_panel_qc.csv \
	../output/parent_190_205_audit.csv \
	../output/parent_total_reproduction_qc.csv \
	../output/near_198_placebo_totals.csv \
	../output/support_sensitivity.csv \
	../output/historical_pairwise_stability.csv \
	../output/historical_exact_shares.csv \
	../output/splitting_verification_summary.csv \
	../output/exploratory_q_theta.csv \
	../output/placebo_distributions.csv \
	../output/placebo_performance.csv \
	../output/leave_one_pre_year_out.csv \
	../output/temporal_window_sensitivity.csv \
	../output/historical_forward_placebos.pdf

../output/parent_panel_qc.csv: audit_scale_shape_panels.R \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet | ../output
	$(R) $<

../output/parent_190_205_audit.csv: ../output/parent_panel_qc.csv
	@test -s "$@"

../output/parent_total_reproduction_qc.csv: audit_scale_shape_descriptives.R \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet \
	../input/parent_total_exact_distribution_50_300.csv \
	../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv | ../output
	$(R) $< $(MINIMUM_UNITS) $(EXACT_PLOT_MAXIMUM)

../output/near_198_placebo_totals.csv \
../output/support_sensitivity.csv \
../output/historical_pairwise_stability.csv \
../output/historical_exact_shares.csv \
../output/splitting_verification_summary.csv: ../output/parent_total_reproduction_qc.csv
	@test -s "$@"

../output/exploratory_q_theta.csv: audit_shape_counterfactual.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/scale_shape_helpers.R \
	../input/parent_opportunity_panel.parquet \
	../input/reweighted_counterfactual_distributions.csv \
	../input/local_excess_deficit_moments.csv | ../output
	$(R) $< $(MINIMUM_UNITS) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START)

../output/placebo_distributions.csv \
../output/placebo_performance.csv \
../output/leave_one_pre_year_out.csv \
../output/temporal_window_sensitivity.csv \
../output/historical_forward_placebos.pdf: ../output/exploratory_q_theta.csv
	@test -s "$@"

../input/parent_opportunity_panel.parquet: ../../../analyze_485x_scale_shape_splitting/output/parent_opportunity_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_panel.parquet: ../../../analyze_485x_scale_shape_splitting/output/constituent_filing_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/reweighted_counterfactual_distributions.csv: ../../../analyze_485x_scale_shape_splitting/output/reweighted_counterfactual_distributions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/local_excess_deficit_moments.csv: ../../../analyze_485x_scale_shape_splitting/output/local_excess_deficit_moments.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_total_exact_distribution_50_300.csv: ../../../analyze_485x_scale_shape_splitting/output/parent_total_exact_distribution_50_300.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_annualized_50_300.csv: ../../../analyze_parent_unit_distribution/output/parent_unit_distribution_annualized_50_300.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_normalized_density_50_300_ab.csv: ../../../analyze_parent_unit_distribution/output/parent_unit_distribution_normalized_density_50_300_ab.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../input/reweighted_counterfactual_distributions.csv \
	../input/local_excess_deficit_moments.csv \
	../input/parent_total_exact_distribution_50_300.csv \
	../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv

include ../../generic.make

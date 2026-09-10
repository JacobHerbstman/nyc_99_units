include ../../../shared/code/shell_functions.make

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

../output/parent_panel_qc.csv: audit_scale_shape_panels.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/parent_190_205_audit.csv: ../output/parent_panel_qc.csv
	$(RECOVER) -W audit_scale_shape_panels.R all

../output/parent_total_reproduction_qc.csv: audit_scale_shape_descriptives.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/parent_opportunity_panel.parquet \
	../input/parent_total_exact_distribution_50_300.csv ../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(MINIMUM_UNITS) $(EXACT_PLOT_MAXIMUM)

../output/near_198_placebo_totals.csv \
../output/support_sensitivity.csv \
../output/historical_pairwise_stability.csv \
../output/historical_exact_shares.csv \
../output/splitting_verification_summary.csv: ../output/parent_total_reproduction_qc.csv
	$(RECOVER) -W audit_scale_shape_descriptives.R all

../output/exploratory_q_theta.csv: audit_shape_counterfactual.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../../../shared/code/scale_shape_helpers.R \
	../input/parent_opportunity_panel.parquet ../input/reweighted_counterfactual_distributions.csv \
	../input/local_excess_deficit_moments.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(MINIMUM_UNITS) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START)

../output/placebo_distributions.csv \
../output/placebo_performance.csv \
../output/leave_one_pre_year_out.csv \
../output/temporal_window_sensitivity.csv \
../output/historical_forward_placebos.pdf: ../output/exploratory_q_theta.csv
	$(RECOVER) -W audit_shape_counterfactual.R all

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/reweighted_counterfactual_distributions.csv: ../../audit_scale_shape_splitting/output/reweighted_counterfactual_distributions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/local_excess_deficit_moments.csv: ../../audit_scale_shape_splitting/output/local_excess_deficit_moments.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_total_exact_distribution_50_300.csv: ../../../plot_bunching/output/parent_total_exact_distribution_50_300.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_annualized_50_300.csv: ../../analyze_parent_unit_distribution/output/parent_unit_distribution_annualized_50_300.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_normalized_density_50_300_ab.csv: ../../analyze_parent_unit_distribution/output/parent_unit_distribution_normalized_density_50_300_ab.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../input/reweighted_counterfactual_distributions.csv \
	../input/local_excess_deficit_moments.csv \
	../input/parent_total_exact_distribution_50_300.csv \
	../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv

../../../build_estimation_panels/output/parent_opportunity_panel.parquet \
../../../build_estimation_panels/output/constituent_filing_panel.parquet: check-build_estimation_panels ;
.PHONY: check-build_estimation_panels
check-build_estimation_panels:
	$(MAKE) -C ../../../build_estimation_panels/code all

../../../plot_bunching/output/parent_total_exact_distribution_50_300.csv: check-plot_bunching ;
.PHONY: check-plot_bunching
check-plot_bunching:
	$(MAKE) -C ../../../plot_bunching/code all

../../audit_scale_shape_splitting/output/reweighted_counterfactual_distributions.csv \
../../audit_scale_shape_splitting/output/local_excess_deficit_moments.csv: check-audit_scale_shape_splitting ;
.PHONY: check-audit_scale_shape_splitting
check-audit_scale_shape_splitting:
	$(MAKE) -C ../../audit_scale_shape_splitting/code all

../../analyze_parent_unit_distribution/output/parent_unit_distribution_annualized_50_300.csv \
	../../analyze_parent_unit_distribution/output/parent_unit_distribution_normalized_density_50_300_ab.csv: check-analyze_parent_unit_distribution ;

.PHONY: check-analyze_parent_unit_distribution

check-analyze_parent_unit_distribution:
	$(MAKE) -C ../../analyze_parent_unit_distribution/code all ../output/parent_unit_distribution_annualized_50_300.csv ../output/parent_unit_distribution_normalized_density_50_300_ab.csv

include ../../../shared/code/generic.make

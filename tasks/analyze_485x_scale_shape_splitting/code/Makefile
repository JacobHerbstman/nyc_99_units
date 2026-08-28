SHELL := bash
include ../../shell_functions.make

PRE_START_DATE := 2019-01-01
PRE_END_DATE := 2022-12-31
POST_START_DATE := 2025-01-01
POST_END_DATE := 2026-07-08
MINIMUM_UNITS := 6
NEAR_99_MINIMUM := 95
EXACT_PLOT_MINIMUM := 50
EXACT_PLOT_MAXIMUM := 300
PREFERRED_MINIMUM := 50
POOLED_TAIL_START := 301
BOOTSTRAP_REPLICATIONS := 499
RANDOM_SEED := 48599

all: ../output/parent_opportunity_panel.parquet \
	../output/constituent_filing_panel.parquet \
	../output/parent_panel_qc.csv \
	../output/parent_190_205_audit.csv \
	../output/sample_exposure_summary.csv \
	../output/calibration_summary.csv \
	../output/bootstrap_intervals.csv \
	../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf \
	../output/pdf/normalized_parent_total_50_plus.pdf \
	../output/pdf/normalized_largest_constituent_50_300.pdf \
	../output/pdf/normalized_single_component_50_300.pdf \
	../output/pdf/normalized_second_constituent_50_300.pdf \
	../output/pdf/normalized_all_constituents_ordinary_50_300.pdf \
	../output/pdf/normalized_all_constituents_parent_weighted_50_300.pdf \
	../output/pdf/largest_second_constituent_heatmap.pdf \
	../output/pdf/exact_198_constituent_decomposition.pdf \
	../output/pdf/parent_response_category_shares.pdf \
	../output/pdf/constituent_count_distribution.pdf \
	../output/pdf/historical_year_normalized_parent_total.pdf \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
	../output/pdf/scale_only_parent_counts_50_300.pdf \
	../output/pdf/shape_effect_parent_counts_50_300.pdf \
	../output/pdf/observed_minus_counterfactual_shares_50_300.pdf \
	../output/pdf/cumulative_99_deficit.pdf \
	../output/pdf/historical_forward_placebos.pdf \
	../output/pdf/reweighted_constituent_count_distribution.pdf \
	../output/pdf/scale_shape_splitting_figure_guide.pdf

../output/parent_opportunity_panel.parquet: construct_scale_shape_splitting_panels.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv \
	../input/hpd_485x_registration_dob_links.csv \
	../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet | ../output
	$(R) $< $(PRE_START_DATE) $(PRE_END_DATE) $(POST_START_DATE) \
		$(POST_END_DATE) $(MINIMUM_UNITS) $(NEAR_99_MINIMUM)

../output/constituent_filing_panel.parquet \
../output/parent_panel_qc.csv \
../output/parent_190_205_audit.csv: ../output/parent_opportunity_panel.parquet
	@test -s "$@"

../output/sample_exposure_summary.csv: summarize_scale_shape_splitting.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv | ../output ../output/pdf
	$(R) $< $(EXACT_PLOT_MINIMUM) $(EXACT_PLOT_MAXIMUM) \
		$(PREFERRED_MINIMUM) $(POOLED_TAIL_START)

../output/parent_total_exact_distribution_50_300.csv \
../output/preferred_parent_distribution_50_plus.csv \
../output/parent_total_reproduction_qc.csv \
../output/outcome_distribution_50_300.csv \
../output/scale_shape_decomposition.csv \
../output/exact_threshold_shares.csv \
../output/exact_198_vector_decomposition.csv \
../output/near_198_placebo_totals.csv \
../output/parent_99xk_summary.csv \
../output/parent_response_categories.csv \
../output/support_sensitivity.csv \
../output/historical_pairwise_stability.csv \
../output/historical_exact_shares.csv \
../output/constituent_count_distribution.csv \
../output/splitting_verification_summary.csv \
../output/pdf/annualized_parent_total_50_300.pdf \
../output/pdf/normalized_parent_total_50_300_reproduction.pdf \
../output/pdf/normalized_parent_total_50_plus.pdf \
../output/pdf/normalized_largest_constituent_50_300.pdf \
../output/pdf/normalized_single_component_50_300.pdf \
../output/pdf/normalized_second_constituent_50_300.pdf \
../output/pdf/normalized_all_constituents_ordinary_50_300.pdf \
../output/pdf/normalized_all_constituents_parent_weighted_50_300.pdf \
../output/pdf/largest_second_constituent_heatmap.pdf \
../output/pdf/exact_198_constituent_decomposition.pdf \
../output/pdf/parent_response_category_shares.pdf \
../output/pdf/constituent_count_distribution.pdf \
../output/pdf/historical_year_normalized_parent_total.pdf: ../output/sample_exposure_summary.csv
	@test -s "$@"

../output/calibration_summary.csv: estimate_shape_counterfactual.R \
	scale_shape_helpers.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet | ../output ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START)

../output/calibration_weights.csv \
../output/calibration_balance.csv \
../output/reweighted_counterfactual_distributions.csv \
../output/scale_shape_count_decomposition.csv \
../output/parent_share_difference.csv \
../output/local_excess_deficit_moments.csv \
../output/reweighted_constituent_count_distribution.csv \
../output/cumulative_99_diagnostics.csv \
../output/exploratory_q_theta.csv \
../output/placebo_distributions.csv \
../output/placebo_performance.csv \
../output/leave_one_pre_year_out.csv \
../output/temporal_window_sensitivity.csv \
../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
../output/pdf/scale_only_parent_counts_50_300.pdf \
../output/pdf/shape_effect_parent_counts_50_300.pdf \
../output/pdf/observed_minus_counterfactual_shares_50_300.pdf \
../output/pdf/cumulative_99_deficit.pdf \
../output/pdf/historical_forward_placebos.pdf \
../output/pdf/reweighted_constituent_count_distribution.pdf: ../output/calibration_summary.csv
	@test -s "$@"

../output/bootstrap_intervals.csv: bootstrap_shape_counterfactual.R \
	scale_shape_helpers.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet | ../output
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START) \
		$(BOOTSTRAP_REPLICATIONS) $(RANDOM_SEED)

../output/bootstrap_draws.csv \
../output/bootstrap_run_summary.csv: ../output/bootstrap_intervals.csv
	@test -s "$@"

../temp/scale_shape_splitting_figure_guide_values.tex: build_figure_guide_values.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../output/sample_exposure_summary.csv \
	../output/local_excess_deficit_moments.csv \
	../output/bootstrap_intervals.csv \
	../output/exact_198_vector_decomposition.csv \
	../output/calibration_summary.csv \
	../output/temporal_window_sensitivity.csv \
	../output/reweighted_constituent_count_distribution.csv \
	../output/bootstrap_run_summary.csv | ../temp
	$(R) $<

../output/pdf/scale_shape_splitting_figure_guide.pdf: scale_shape_splitting_figure_guide.tex \
	../temp/scale_shape_splitting_figure_guide_values.tex \
	../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf \
	../output/pdf/normalized_parent_total_50_plus.pdf \
	../output/pdf/normalized_largest_constituent_50_300.pdf \
	../output/pdf/normalized_single_component_50_300.pdf \
	../output/pdf/normalized_second_constituent_50_300.pdf \
	../output/pdf/normalized_all_constituents_ordinary_50_300.pdf \
	../output/pdf/normalized_all_constituents_parent_weighted_50_300.pdf \
	../output/pdf/largest_second_constituent_heatmap.pdf \
	../output/pdf/exact_198_constituent_decomposition.pdf \
	../output/pdf/parent_response_category_shares.pdf \
	../output/pdf/constituent_count_distribution.pdf \
	../output/pdf/reweighted_constituent_count_distribution.pdf \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
	../output/pdf/scale_only_parent_counts_50_300.pdf \
	../output/pdf/observed_minus_counterfactual_shares_50_300.pdf \
	../output/pdf/shape_effect_parent_counts_50_300.pdf \
	../output/pdf/cumulative_99_deficit.pdf \
	../output/pdf/historical_year_normalized_parent_total.pdf \
	../output/pdf/historical_forward_placebos.pdf | ../output/pdf ../temp
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/scale_shape_splitting_figure_guide.pdf $@

../output/pdf: | ../output
	mkdir -p $@

../input/parent_opportunity_panel.parquet: ../output/parent_opportunity_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_panel.parquet: ../output/constituent_filing_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_annualized_50_300.csv: ../../analyze_parent_unit_distribution/output/parent_unit_distribution_annualized_50_300.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_unit_distribution_normalized_density_50_300_ab.csv: ../../analyze_parent_unit_distribution/output/parent_unit_distribution_normalized_density_50_300_ab.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure.csv: ../../audits/audit_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure_universe.csv: ../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_site_characteristics.parquet: ../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_parent_site_characteristics.parquet: ../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv \
	../input/hpd_485x_registration_dob_links.csv \
	../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet \
	../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../input/parent_unit_distribution_annualized_50_300.csv \
	../input/parent_unit_distribution_normalized_density_50_300_ab.csv

include ../../generic.make

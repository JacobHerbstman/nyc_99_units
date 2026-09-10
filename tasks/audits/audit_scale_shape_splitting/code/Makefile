include ../../../shared/code/shell_functions.make

PRE_START_DATE := 2019-01-01
PRE_END_DATE := 2022-12-31
POST_START_DATE := 2025-01-01
POST_END_DATE := 2026-07-08
MINIMUM_UNITS := 6
NEAR_99_MINIMUM := 95
EXACT_PLOT_MINIMUM := 50
EXACT_PLOT_MAXIMUM := 300
PREFERRED_MINIMUM := 50
FILING_PLOT_MAXIMUM := 150
POOLED_TAIL_START := 301
BOOTSTRAP_REPLICATIONS := 499
RANDOM_SEED := 48599

ifneq ($(filter command,$(origin PRE_START_DATE) $(origin PRE_END_DATE) $(origin POST_START_DATE) $(origin POST_END_DATE) $(origin MINIMUM_UNITS) $(origin NEAR_99_MINIMUM) $(origin EXACT_PLOT_MINIMUM) $(origin EXACT_PLOT_MAXIMUM) $(origin PREFERRED_MINIMUM) $(origin FILING_PLOT_MAXIMUM) $(origin POOLED_TAIL_START) $(origin BOOTSTRAP_REPLICATIONS) $(origin RANDOM_SEED)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/sample_exposure_summary.csv \
	../output/calibration_weights.csv \
	../output/calibration_summary.csv \
	../output/bootstrap_draws.csv \
	../output/bootstrap_intervals.csv \
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
	../output/pdf/reweighted_constituent_count_distribution.pdf \
	../output/pdf/scale_shape_splitting_figure_guide.pdf \
	../output/pdf/main_project_plots.pdf \
	../report/bootstrap_draws.txt \
	../report/bootstrap_intervals.txt \
	../report/bootstrap_run_summary.txt \
	../report/calibration_balance.txt \
	../report/calibration_summary.txt \
	../report/calibration_weights.txt \
	../report/constituent_count_distribution.txt \
	../report/cumulative_99_diagnostics.txt \
	../report/exact_198_vector_decomposition.txt \
	../report/exact_threshold_shares.txt \
	../report/local_excess_deficit_moments.txt \
	../report/outcome_distribution_50_300.txt \
	../report/parent_99xk_summary.txt \
	../report/parent_response_categories.txt \
	../report/parent_share_difference.txt \
	../report/reweighted_constituent_count_distribution.txt \
	../report/reweighted_counterfactual_distributions.txt \
	../report/sample_exposure_summary.txt \
	../report/scale_shape_count_decomposition.txt \
	../report/scale_shape_decomposition.txt

../output/sample_exposure_summary.csv: summarize_scale_shape_splitting.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output ../output/pdf
	$(R) $< $(EXACT_PLOT_MINIMUM) $(EXACT_PLOT_MAXIMUM) \
		$(PREFERRED_MINIMUM) $(POOLED_TAIL_START)

../output/outcome_distribution_50_300.csv \
	../output/scale_shape_decomposition.csv \
	../output/exact_threshold_shares.csv \
	../output/exact_198_vector_decomposition.csv \
	../output/parent_99xk_summary.csv \
	../output/parent_response_categories.csv \
	../output/constituent_count_distribution.csv \
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
	$(RECOVER) -W summarize_scale_shape_splitting.R all

../output/calibration_weights.csv: estimate_shape_counterfactual.R Makefile \
	../../../shared/code/scale_shape_helpers.R ../../../shared/code/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START)

../output/calibration_summary.csv \
	../output/calibration_balance.csv \
	../output/reweighted_counterfactual_distributions.csv \
	../output/scale_shape_count_decomposition.csv \
	../output/parent_share_difference.csv \
	../output/local_excess_deficit_moments.csv \
	../output/reweighted_constituent_count_distribution.csv \
	../output/cumulative_99_diagnostics.csv \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
	../output/pdf/scale_only_parent_counts_50_300.pdf \
	../output/pdf/shape_effect_parent_counts_50_300.pdf \
	../output/pdf/observed_minus_counterfactual_shares_50_300.pdf \
	../output/pdf/cumulative_99_deficit.pdf \
	../output/pdf/reweighted_constituent_count_distribution.pdf: ../output/calibration_weights.csv
	$(RECOVER) -W estimate_shape_counterfactual.R all

../output/bootstrap_draws.csv: bootstrap_shape_counterfactual.R Makefile \
	../../../shared/code/scale_shape_helpers.R ../../../shared/code/source_pipeline_utils.R \
	../input/parent_opportunity_panel.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) $(POOLED_TAIL_START) \
		$(BOOTSTRAP_REPLICATIONS) $(RANDOM_SEED)

../output/bootstrap_intervals.csv \
	../output/bootstrap_run_summary.csv: ../output/bootstrap_draws.csv
	$(RECOVER) -W bootstrap_shape_counterfactual.R all

../temp/scale_shape_splitting_figure_guide_values.tex: build_figure_guide_values.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../output/sample_exposure_summary.csv \
	../output/local_excess_deficit_moments.csv ../output/reweighted_counterfactual_distributions.csv \
	../output/bootstrap_intervals.csv ../output/exact_198_vector_decomposition.csv \
	../output/calibration_summary.csv ../output/reweighted_constituent_count_distribution.csv \
	../output/bootstrap_run_summary.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../temp
	$(R) $<

../output/pdf/scale_shape_splitting_figure_guide.pdf: scale_shape_splitting_figure_guide.tex \
	../temp/scale_shape_splitting_figure_guide_values.tex \
	../input/annualized_parent_total_50_300.pdf \
	../input/normalized_parent_total_50_300_reproduction.pdf \
	../input/normalized_parent_total_50_plus.pdf \
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
	../output/pdf/historical_year_normalized_parent_total.pdf | ../output/pdf ../temp
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/scale_shape_splitting_figure_guide.pdf $@

../output/pdf/main_project_plots.pdf: main_project_plots.tex \
	../input/annualized_constituent_filing_distribution_50_300.pdf \
	../input/normalized_constituent_filing_distribution_50_300.pdf \
	../input/normalized_constituent_filing_distribution_50_300_histogram.pdf \
	../input/constituent_filing_cdf.pdf \
	../input/constituent_filing_cdf_6_plus.pdf \
	../input/normalized_parent_total_50_plus.pdf \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
	../output/pdf/exact_198_constituent_decomposition.pdf \
	../input/parents_with_99_unit_constituents.pdf | ../output/pdf ../temp
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/main_project_plots.pdf $@

../report/bootstrap_draws.txt: report_data.R ../../../shared/code/write_data_report.R ../output/bootstrap_draws.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< bootstrap_draws

../report/bootstrap_intervals.txt: report_data.R ../../../shared/code/write_data_report.R ../output/bootstrap_intervals.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< bootstrap_intervals

../report/bootstrap_run_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/bootstrap_run_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< bootstrap_run_summary

../report/calibration_balance.txt: report_data.R ../../../shared/code/write_data_report.R ../output/calibration_balance.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< calibration_balance

../report/calibration_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/calibration_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< calibration_summary

../report/calibration_weights.txt: report_data.R ../../../shared/code/write_data_report.R ../output/calibration_weights.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< calibration_weights

../report/constituent_count_distribution.txt: report_data.R ../../../shared/code/write_data_report.R ../output/constituent_count_distribution.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< constituent_count_distribution

../report/cumulative_99_diagnostics.txt: report_data.R ../../../shared/code/write_data_report.R ../output/cumulative_99_diagnostics.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< cumulative_99_diagnostics

../report/exact_198_vector_decomposition.txt: report_data.R ../../../shared/code/write_data_report.R ../output/exact_198_vector_decomposition.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< exact_198_vector_decomposition

../report/exact_threshold_shares.txt: report_data.R ../../../shared/code/write_data_report.R ../output/exact_threshold_shares.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< exact_threshold_shares

../report/local_excess_deficit_moments.txt: report_data.R ../../../shared/code/write_data_report.R ../output/local_excess_deficit_moments.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< local_excess_deficit_moments

../report/outcome_distribution_50_300.txt: report_data.R ../../../shared/code/write_data_report.R ../output/outcome_distribution_50_300.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< outcome_distribution_50_300

../report/parent_99xk_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_99xk_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_99xk_summary

../report/parent_response_categories.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_response_categories.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_response_categories

../report/parent_share_difference.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_share_difference.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_share_difference

../report/reweighted_constituent_count_distribution.txt: report_data.R ../../../shared/code/write_data_report.R ../output/reweighted_constituent_count_distribution.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< reweighted_constituent_count_distribution

../report/reweighted_counterfactual_distributions.txt: report_data.R ../../../shared/code/write_data_report.R ../output/reweighted_counterfactual_distributions.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< reweighted_counterfactual_distributions

../report/sample_exposure_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/sample_exposure_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< sample_exposure_summary

../report/scale_shape_count_decomposition.txt: report_data.R ../../../shared/code/write_data_report.R ../output/scale_shape_count_decomposition.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< scale_shape_count_decomposition

../report/scale_shape_decomposition.txt: report_data.R ../../../shared/code/write_data_report.R ../output/scale_shape_decomposition.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< scale_shape_decomposition

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../build_estimation_panels/output/parent_opportunity_panel.parquet \
../../../build_estimation_panels/output/constituent_filing_panel.parquet: check-build_estimation_panels ;
.PHONY: check-build_estimation_panels
check-build_estimation_panels:
	$(MAKE) -C ../../../build_estimation_panels/code all

link-inputs: ../input/parent_opportunity_panel.parquet ../input/constituent_filing_panel.parquet ../input/constituent_filing_distribution_50_150.pdf ../input/annualized_constituent_filing_distribution_50_300.pdf ../input/normalized_constituent_filing_distribution_50_300.pdf ../input/normalized_constituent_filing_distribution_50_300_histogram.pdf ../input/constituent_filing_cdf.pdf ../input/constituent_filing_cdf_6_plus.pdf ../input/parents_with_99_unit_constituents.pdf ../input/annualized_parent_total_50_300.pdf ../input/normalized_parent_total_50_300_reproduction.pdf ../input/normalized_parent_total_50_plus.pdf



../input/constituent_filing_distribution_50_150.pdf: ../../../plot_bunching/output/pdf/constituent_filing_distribution_50_150.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/annualized_constituent_filing_distribution_50_300.pdf: ../../../plot_bunching/output/pdf/annualized_constituent_filing_distribution_50_300.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/normalized_constituent_filing_distribution_50_300.pdf: ../../../plot_bunching/output/pdf/normalized_constituent_filing_distribution_50_300.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/normalized_constituent_filing_distribution_50_300_histogram.pdf: ../../../plot_bunching/output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_cdf.pdf: ../../../plot_bunching/output/pdf/constituent_filing_cdf.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_cdf_6_plus.pdf: ../../../plot_bunching/output/pdf/constituent_filing_cdf_6_plus.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parents_with_99_unit_constituents.pdf: ../../../plot_bunching/output/pdf/parents_with_99_unit_constituents.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/annualized_parent_total_50_300.pdf: ../../../plot_bunching/output/pdf/annualized_parent_total_50_300.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/normalized_parent_total_50_300_reproduction.pdf: ../../../plot_bunching/output/pdf/normalized_parent_total_50_300_reproduction.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/normalized_parent_total_50_plus.pdf: ../../../plot_bunching/output/pdf/normalized_parent_total_50_plus.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../plot_bunching/output/pdf/constituent_filing_distribution_50_150.pdf \
	../../../plot_bunching/output/pdf/annualized_constituent_filing_distribution_50_300.pdf \
	../../../plot_bunching/output/pdf/normalized_constituent_filing_distribution_50_300.pdf \
	../../../plot_bunching/output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf \
	../../../plot_bunching/output/pdf/constituent_filing_cdf.pdf \
	../../../plot_bunching/output/pdf/constituent_filing_cdf_6_plus.pdf \
	../../../plot_bunching/output/pdf/parents_with_99_unit_constituents.pdf \
	../../../plot_bunching/output/pdf/annualized_parent_total_50_300.pdf \
	../../../plot_bunching/output/pdf/normalized_parent_total_50_300_reproduction.pdf \
	../../../plot_bunching/output/pdf/normalized_parent_total_50_plus.pdf: check-plot_bunching ;
.PHONY: check-plot_bunching
check-plot_bunching:
	$(MAKE) -C ../../../plot_bunching/code all

include ../../../shared/code/generic.make

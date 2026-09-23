include ../../../shared/code/shell_functions.make

SUMMARY_OUTPUTS := ../output/sample_exposure_summary.csv ../output/outcome_distribution_50_300.csv \
	../output/scale_shape_decomposition.csv ../output/exact_threshold_shares.csv \
	../output/exact_198_vector_decomposition.csv ../output/parent_99xk_summary.csv \
	../output/parent_response_categories.csv ../output/constituent_count_distribution.csv \
	../output/pdf/normalized_largest_constituent_50_300.pdf ../output/pdf/normalized_single_component_50_300.pdf \
	../output/pdf/normalized_second_constituent_50_300.pdf \
	../output/pdf/normalized_all_constituents_ordinary_50_300.pdf \
	../output/pdf/normalized_all_constituents_parent_weighted_50_300.pdf \
	../output/pdf/largest_second_constituent_heatmap.pdf ../output/pdf/exact_198_constituent_decomposition.pdf \
	../output/pdf/parent_response_category_shares.pdf ../output/pdf/constituent_count_distribution.pdf \
	../output/pdf/historical_year_normalized_parent_total.pdf
REWEIGHTING_OUTPUTS := ../output/calibration_weights.csv ../output/calibration_balance.csv \
	../output/calibration_summary.csv ../output/reweighted_counterfactual_distributions.csv \
	../output/scale_shape_count_decomposition.csv ../output/parent_share_difference.csv \
	../output/local_excess_deficit_moments.csv ../output/reweighted_constituent_count_distribution.csv \
	../output/cumulative_99_diagnostics.csv \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf ../output/pdf/scale_only_parent_counts_50_300.pdf \
	../output/pdf/shape_effect_parent_counts_50_300.pdf \
	../output/pdf/observed_minus_counterfactual_shares_50_300.pdf ../output/pdf/cumulative_99_deficit.pdf \
	../output/pdf/reweighted_constituent_count_distribution.pdf
BOOTSTRAP_OUTPUTS := ../output/bootstrap_draws.csv ../output/bootstrap_intervals.csv \
	../output/bootstrap_run_summary.csv
ANNUAL_OUTPUTS := ../output/annual_split_shares.csv ../output/annual_split_shares.png \
	../output/pdf/annual_split_shares.pdf
PLOT_BUNCHING_FIGURES := annualized_constituent_filing_distribution_50_300 normalized_constituent_filing_distribution_50_300 \
	normalized_constituent_filing_distribution_50_300_histogram constituent_filing_cdf constituent_filing_cdf_6_plus \
	parents_with_99_unit_constituents annualized_parent_total_50_300 normalized_parent_total_50_300_reproduction \
	normalized_parent_total_50_plus

all: $(ANNUAL_OUTPUTS) $(SUMMARY_OUTPUTS) $(REWEIGHTING_OUTPUTS) $(BOOTSTRAP_OUTPUTS) \
	../output/figure_guide_values.tex ../output/pdf/scale_shape_splitting_figure_guide.pdf \
	../output/pdf/meeting_packet.pdf

include ../../../shared/code/generic.make

$(ANNUAL_OUTPUTS): plot_annual_split_shares.R ../input/parent_opportunity_panel.parquet \
	../../../shared/code/write_data_report.R Makefile | $(OOPR) ../output/pdf
	$(R) $<

$(SUMMARY_OUTPUTS): summarize_scale_shape_splitting.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet ../../../shared/code/source_pipeline_utils.R \
	../../../shared/code/write_data_report.R Makefile | $(OOPR) ../output/pdf
	$(R) $<

$(REWEIGHTING_OUTPUTS): estimate_shape_counterfactual.R ../input/parent_opportunity_panel.parquet \
	../../../shared/code/source_pipeline_utils.R ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R Makefile | $(OOPR) ../output/pdf
	$(R) $<

$(BOOTSTRAP_OUTPUTS): bootstrap_shape_counterfactual.R ../input/parent_opportunity_panel.parquet \
	../../../shared/code/source_pipeline_utils.R ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

# Numbers quoted in framework_writeup.tex and the figure guide.
../output/figure_guide_values.tex: build_figure_guide_values.R ../output/sample_exposure_summary.csv \
	../output/local_excess_deficit_moments.csv ../output/reweighted_counterfactual_distributions.csv \
	../output/bootstrap_intervals.csv ../output/bootstrap_run_summary.csv \
	../output/exact_198_vector_decomposition.csv ../output/calibration_summary.csv \
	../output/reweighted_constituent_count_distribution.csv ../../../shared/code/source_pipeline_utils.R \
	Makefile | $(OOPR)
	$(R) $<

../output/pdf/scale_shape_splitting_figure_guide.pdf: scale_shape_splitting_figure_guide.tex \
	../output/figure_guide_values.tex $(filter %.pdf,$(SUMMARY_OUTPUTS) $(REWEIGHTING_OUTPUTS)) \
	../input/annualized_parent_total_50_300.pdf ../input/normalized_parent_total_50_300_reproduction.pdf \
	../input/normalized_parent_total_50_plus.pdf | $(OOPR) ../output/pdf
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/scale_shape_splitting_figure_guide.pdf $@

# Figures-only meeting packet: citywide plots plus the reweighted comparison.
../output/pdf/meeting_packet.pdf: meeting_packet.tex $(foreach f,$(PLOT_BUNCHING_FIGURES),../input/$(f).pdf) \
	../output/pdf/reweighted_parent_counterfactual_50_300.pdf \
	../output/pdf/exact_198_constituent_decomposition.pdf | $(OOPR) ../output/pdf
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/meeting_packet.pdf $@

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@

../input/%.pdf: ../../../plot_bunching/output/pdf/%.pdf | ../input
	ln -sf $< $@

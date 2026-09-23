include ../../../shared/code/shell_functions.make

all: ../output/exploratory_q_theta.csv ../output/placebo_distributions.csv ../output/placebo_performance.csv \
	../output/leave_one_pre_year_out.csv ../output/temporal_window_sensitivity.csv \
	../output/historical_forward_placebos.pdf

include ../../../shared/code/generic.make

../output/exploratory_q_theta.csv ../output/placebo_distributions.csv ../output/placebo_performance.csv \
	../output/leave_one_pre_year_out.csv ../output/temporal_window_sensitivity.csv \
	../output/historical_forward_placebos.pdf: audit_shape_counterfactual.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R ../input/parent_opportunity_panel.parquet \
	../input/reweighted_counterfactual_distributions.csv ../input/local_excess_deficit_moments.csv | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/reweighted_counterfactual_distributions.csv: ../../audit_scale_shape_splitting/output/reweighted_counterfactual_distributions.csv | ../input
	ln -sf $< $@

../input/local_excess_deficit_moments.csv: ../../audit_scale_shape_splitting/output/local_excess_deficit_moments.csv | ../input
	ln -sf $< $@

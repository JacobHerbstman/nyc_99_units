include ../../shared/code/shell_functions.make

all: ../output/estimation_parents.parquet ../output/model_checks.csv ../output/estimates.csv \
	../output/heterogeneity_estimates.csv ../output/bootstrap_samples.parquet \
	../output/scaled_burden_bootstrap_estimates.csv ../output/pdf/model_fit.pdf ../output/model_values.tex

include ../../shared/code/generic.make

../output/estimation_parents.parquet: prepare_estimation_sample.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet Makefile | $(OOPR)
	$(R) $<

../output/model_checks.csv: test_notch_model.R notch_model.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

FIT_OUTPUTS := ../output/estimates.csv ../output/fit_moments.csv ../output/cell_fit.csv \
	../output/parameter_profiles.csv

$(FIT_OUTPUTS): fit_notch_model.R notch_model.R ../output/estimation_parents.parquet \
	../output/model_checks.csv Makefile | $(OOPR)
	$(R) $<

../output/bootstrap_samples.parquet: draw_bootstrap_samples.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

HETEROGENEITY_OUTPUTS := ../output/heterogeneity_estimates.csv ../output/heterogeneity_profiles.csv \
	../output/heterogeneity_cell_fit.csv

$(HETEROGENEITY_OUTPUTS): fit_heterogeneity.R notch_model.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

SCALED_BURDEN_OUTPUTS := ../output/scaled_burden_bootstrap_draws.csv ../output/scaled_burden_bootstrap_estimates.csv

$(SCALED_BURDEN_OUTPUTS): bootstrap_scaled_burden.R notch_model.R ../output/estimation_parents.parquet \
	../output/bootstrap_samples.parquet ../output/heterogeneity_estimates.csv Makefile | $(OOPR)
	$(R) $<

../output/pdf/model_fit.pdf: plot_model_fit.R ../output/heterogeneity_cell_fit.csv ../output/heterogeneity_estimates.csv \
	../output/scaled_burden_bootstrap_estimates.csv ../output/estimates.csv Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/model_values.tex: write_model_values.R ../output/heterogeneity_estimates.csv \
	../output/heterogeneity_cell_fit.csv ../output/scaled_burden_bootstrap_estimates.csv ../output/estimates.csv \
	Makefile | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@

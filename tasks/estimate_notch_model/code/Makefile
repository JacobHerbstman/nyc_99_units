include ../../shared/code/shell_functions.make

# The main sample and its checks: a common 180-day horizon, 2025 parents only,
# a pre-policy placebo and a longer historical period.
VARIANTS := all_filings horizon_180 cohort_2025 placebo history_2014
SAMPLES := $(VARIANTS:%=../output/bootstrap_samples_%.parquet)
BOOTSTRAPS := $(VARIANTS:%=../output/scaled_burden_bootstrap_estimates_%.csv) \
	$(VARIANTS:%=../output/scaled_burden_bootstrap_draws_%.csv)

all: ../output/estimation_parents.parquet ../output/model_checks.csv ../output/estimates.csv \
	../output/heterogeneity_estimates.csv $(SAMPLES) $(BOOTSTRAPS) ../output/pdf/model_fit.pdf \
	../output/model_values.tex

include ../../shared/code/generic.make

../output/estimation_parents.parquet: prepare_estimation_sample.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet ../input/extended_parent_opportunity_panel.parquet \
	../input/extended_constituent_filing_panel.parquet Makefile | $(OOPR)
	$(R) $<

../output/model_checks.csv: test_notch_model.R notch_model.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

../output/estimates.csv: fit_notch_model.R notch_model.R ../output/estimation_parents.parquet \
	../output/model_checks.csv Makefile | $(OOPR)
	$(R) $<

$(SAMPLES): ../output/bootstrap_samples_%.parquet: draw_bootstrap_samples.R ../output/estimation_parents.parquet \
	Makefile | $(OOPR)
	$(R) $< $*

HETEROGENEITY_OUTPUTS := ../output/heterogeneity_estimates.csv ../output/heterogeneity_profiles.csv \
	../output/heterogeneity_cell_fit.csv

$(HETEROGENEITY_OUTPUTS): fit_heterogeneity.R notch_model.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

../output/scaled_burden_bootstrap_estimates_%.csv ../output/scaled_burden_bootstrap_draws_%.csv: \
	bootstrap_scaled_burden.R notch_model.R ../output/estimation_parents.parquet ../output/bootstrap_samples_%.parquet \
	../output/heterogeneity_estimates.csv Makefile | $(OOPR)
	$(R) $< $*

../output/pdf/model_fit.pdf: plot_model_fit.R $(HETEROGENEITY_OUTPUTS) \
	../output/scaled_burden_bootstrap_estimates_all_filings.csv ../output/estimates.csv Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/model_values.tex: write_model_values.R ../output/estimation_parents.parquet $(HETEROGENEITY_OUTPUTS) \
	$(VARIANTS:%=../output/scaled_burden_bootstrap_estimates_%.csv) ../output/estimates.csv Makefile | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@
../input/extended_parent_opportunity_panel.parquet: \
	../../build_estimation_panels/output/extended_parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/extended_constituent_filing_panel.parquet: \
	../../build_estimation_panels/output/extended_constituent_filing_panel.parquet | ../input
	ln -sf $< $@

include ../../shared/code/shell_functions.make

all: ../output/parent_total_exact_distribution_50_300.csv ../output/preferred_parent_distribution_50_plus.csv \
	../output/pdf/main_project_plots.pdf

include ../../shared/code/generic.make

../output/pdf/constituent_filing_distribution_50_150.pdf: plot_constituent_filing_distribution.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet | $(OOPR) ../output/pdf
	$(R) $< 50 150 normalized line

../output/pdf/annualized_constituent_filing_distribution_50_300.pdf: plot_constituent_filing_distribution.R \
	Makefile ../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet | $(OOPR) \
	../output/pdf
	$(R) $< 50 300 annualized line

../output/pdf/normalized_constituent_filing_distribution_50_300.pdf: plot_constituent_filing_distribution.R \
	Makefile ../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet | $(OOPR) \
	../output/pdf
	$(R) $< 50 300 normalized line

../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf: \
	plot_constituent_filing_distribution.R Makefile ../../shared/code/source_pipeline_utils.R \
	../input/constituent_filing_panel.parquet | $(OOPR) ../output/pdf
	$(R) $< 50 300 normalized histogram

../output/pdf/constituent_filing_cdf.pdf: plot_constituent_filing_cdf.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet | $(OOPR) ../output/pdf
	$(R) $< 50 300

../output/pdf/constituent_filing_cdf_6_plus.pdf: plot_constituent_filing_cdf.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet | $(OOPR) ../output/pdf
	$(R) $< 6 300

../output/pdf/parents_with_99_unit_constituents.pdf: plot_99_containing_parent_vectors.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/parent_opportunity_panel.parquet | $(OOPR) ../output/pdf
	$(R) $<

../output/preferred_parent_distribution_50_plus.csv ../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf ../output/pdf/normalized_parent_total_50_plus.pdf \
	../output/parent_total_exact_distribution_50_300.csv : plot_parent_distributions.R Makefile \
	../input/parent_opportunity_panel.parquet ../../shared/code/source_pipeline_utils.R \
	../../shared/code/write_data_report.R | $(OOPR) ../output/pdf
	$(R) $< 50 300 50 301

../output/pdf/main_project_plots.pdf: main_project_plots.tex \
	../output/pdf/constituent_filing_distribution_50_150.pdf \
	../output/pdf/annualized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf \
	../output/pdf/constituent_filing_cdf.pdf ../output/pdf/constituent_filing_cdf_6_plus.pdf \
	../output/pdf/parents_with_99_unit_constituents.pdf ../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf ../output/pdf/normalized_parent_total_50_plus.pdf \
	| ../temp ../output/pdf
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/main_project_plots.pdf $@

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet \
	| ../input
	ln -sf $< $@

../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet \
	| ../input
	ln -sf $< $@

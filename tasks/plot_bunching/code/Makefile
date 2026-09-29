include ../../shared/code/shell_functions.make

all: ../output/pdf/main_project_plots.pdf

include ../../shared/code/generic.make

../output/pdf/constituent_filing_distribution_50_150.pdf \
	../output/pdf/annualized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf: \
	plot_constituent_filing_distribution.R ../input/constituent_filing_panel.parquet Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/pdf/constituent_filing_cdf.pdf ../output/pdf/constituent_filing_cdf_6_plus.pdf: plot_constituent_filing_cdf.R \
	../input/constituent_filing_panel.parquet Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/pdf/parents_with_99_unit_constituents.pdf: plot_99_containing_parent_vectors.R \
	../input/parent_opportunity_panel.parquet Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/pdf/annualized_parent_total_50_300.pdf ../output/pdf/normalized_parent_total_50_300_reproduction.pdf \
	../output/pdf/normalized_parent_total_50_plus.pdf: plot_parent_distributions.R ../input/parent_opportunity_panel.parquet \
	Makefile | $(OOPR) ../output/pdf
	$(R) $<

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

include ../../shared/code/shell_functions.make

MINIMUM_UNITS := 6

PREFERRED_MINIMUM := 50

EXACT_PLOT_MINIMUM := 50

EXACT_PLOT_MAXIMUM := 300

FILING_PLOT_MAXIMUM := 150

POOLED_TAIL_START := 301

ifneq ($(filter command,$(origin MINIMUM_UNITS) $(origin PREFERRED_MINIMUM) $(origin EXACT_PLOT_MINIMUM) $(origin EXACT_PLOT_MAXIMUM) $(origin FILING_PLOT_MAXIMUM) $(origin POOLED_TAIL_START)),)

$(error These fixed-name outputs use the settings in this Makefile; edit them here so Make tracks the change)

endif

all: ../output/parent_total_exact_distribution_50_300.csv ../output/preferred_parent_distribution_50_plus.csv \
	../output/pdf/main_project_plots.pdf ../report/parent_total_exact_distribution_50_300.txt \
	../report/preferred_parent_distribution_50_plus.txt

../output/pdf/constituent_filing_distribution_50_150.pdf: plot_constituent_filing_distribution.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(FILING_PLOT_MAXIMUM) normalized line

../output/pdf/annualized_constituent_filing_distribution_50_300.pdf: plot_constituent_filing_distribution.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) annualized line

../output/pdf/normalized_constituent_filing_distribution_50_300.pdf: plot_constituent_filing_distribution.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) normalized line

../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf: \
	plot_constituent_filing_distribution.R Makefile ../../shared/code/source_pipeline_utils.R \
	../input/constituent_filing_panel.parquet ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM) normalized histogram

../output/pdf/constituent_filing_cdf.pdf: plot_constituent_filing_cdf.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(PREFERRED_MINIMUM) $(EXACT_PLOT_MAXIMUM)

../output/pdf/constituent_filing_cdf_6_plus.pdf: plot_constituent_filing_cdf.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/constituent_filing_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(MINIMUM_UNITS) $(EXACT_PLOT_MAXIMUM)

../output/pdf/parents_with_99_unit_constituents.pdf: plot_99_containing_parent_vectors.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/parent_opportunity_panel.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $<

../output/parent_total_exact_distribution_50_300.csv: plot_parent_distributions.R Makefile \
	../input/parent_opportunity_panel.parquet ../../shared/code/source_pipeline_utils.R \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output ../output/pdf
	$(R) $< $(EXACT_PLOT_MINIMUM) $(EXACT_PLOT_MAXIMUM) $(PREFERRED_MINIMUM) $(POOLED_TAIL_START)

../output/preferred_parent_distribution_50_plus.csv \
	../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf \
	../output/pdf/normalized_parent_total_50_plus.pdf: ../output/parent_total_exact_distribution_50_300.csv
	$(RECOVER) -W plot_parent_distributions.R all

../report/parent_total_exact_distribution_50_300.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/parent_total_exact_distribution_50_300.csv Makefile | ../report
	$(R) $< parent_total_exact_distribution_50_300

../report/preferred_parent_distribution_50_plus.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/preferred_parent_distribution_50_plus.csv Makefile | ../report
	$(R) $< preferred_parent_distribution_50_plus

../output/pdf/main_project_plots.pdf: main_project_plots.tex \
	../output/pdf/constituent_filing_distribution_50_150.pdf \
	../output/pdf/annualized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300.pdf \
	../output/pdf/normalized_constituent_filing_distribution_50_300_histogram.pdf \
	../output/pdf/constituent_filing_cdf.pdf ../output/pdf/constituent_filing_cdf_6_plus.pdf \
	../output/pdf/parents_with_99_unit_constituents.pdf ../output/pdf/annualized_parent_total_50_300.pdf \
	../output/pdf/normalized_parent_total_50_300_reproduction.pdf ../output/pdf/normalized_parent_total_50_plus.pdf | \
	../temp ../output/pdf
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/main_project_plots.pdf $@

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-build_estimation_panels

check-build_estimation_panels:
	$(MAKE) -C ../../build_estimation_panels/code all

../../build_estimation_panels/output/parent_opportunity_panel.parquet \
	../../build_estimation_panels/output/constituent_filing_panel.parquet: check-build_estimation_panels ;

link-inputs: ../input/parent_opportunity_panel.parquet ../input/constituent_filing_panel.parquet

include ../../shared/code/generic.make

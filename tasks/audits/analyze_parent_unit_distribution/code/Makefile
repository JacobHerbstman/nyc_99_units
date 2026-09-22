include ../../../shared/code/shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
POST_START_DATE := 2025-01-01
MIN_UNITS := 80
MAX_UNITS := 120
ZOOM_MIN_UNITS := 50
ZOOM_MAX_UNITS := 150
WIDE_MAX_UNITS := 300
FULL_BIN_WIDTH := 25
FULL_PRE_YEARS := 12
RECENT_PRE_YEARS := 4

ifneq ($(filter command,$(origin PRE_START_YEAR) $(origin PRE_END_YEAR) $(origin POST_START_DATE) $(origin MIN_UNITS) $(origin MAX_UNITS) $(origin ZOOM_MIN_UNITS) $(origin ZOOM_MAX_UNITS) $(origin WIDE_MAX_UNITS) $(origin FULL_BIN_WIDTH) $(origin FULL_PRE_YEARS) $(origin RECENT_PRE_YEARS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/parent_unit_distribution_80_120.csv \
	../output/parent_unit_distribution_sample_summary.csv \
	../output/parent_unit_distribution_total_80_120.png \
	../output/parent_unit_distribution_annualized_80_120.png \
	../output/parent_unit_distribution_exposure_80_120.csv \
	../output/parent_unit_distribution_exposure_sample_summary.csv \
	../output/parent_unit_distribution_exposure_total_80_120.png \
	../output/parent_unit_distribution_exposure_annualized_80_120.png \
	../output/parent_unit_distribution_full.csv \
	../output/parent_unit_distribution_full_histogram_bins.csv \
	../output/parent_unit_distribution_exposure_50_150.csv \
	../output/parent_unit_distribution_annualized_50_300.csv \
	../output/parent_unit_distribution_normalized_density_50_300_ab.csv \
	../output/parent_unit_distribution_full_histogram_total.png \
	../output/parent_unit_distribution_full_histogram_annualized.png \
	../output/parent_unit_distribution_full_line_total.png \
	../output/parent_unit_distribution_full_line_annualized.png \
	../output/parent_unit_distribution_exposure_histogram_total_50_150.png \
	../output/parent_unit_distribution_exposure_histogram_annualized_50_150.png \
	../output/parent_unit_distribution_exposure_line_total_50_150.png \
	../output/parent_unit_distribution_exposure_line_annualized_50_150.png \
	../output/pdf/parent_unit_distribution_annualized_50_300.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_all.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2014.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2019_2022.pdf \
	../report/parent_unit_distribution_80_120.txt \
	../report/parent_unit_distribution_annualized_50_300.txt \
	../report/parent_unit_distribution_exposure_50_150.txt \
	../report/parent_unit_distribution_exposure_80_120.txt \
	../report/parent_unit_distribution_exposure_sample_summary.txt \
	../report/parent_unit_distribution_full.txt \
	../report/parent_unit_distribution_full_histogram_bins.txt \
	../report/parent_unit_distribution_normalized_density_50_300_ab.txt \
	../report/parent_unit_distribution_sample_summary.txt

../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf: plot_parent_unit_distribution_comparisons.R Makefile \
	../../../shared/code/source_pipeline_utils.R \
	../output/parent_unit_distribution_annualized_50_300.csv \
	../output/parent_unit_distribution_normalized_density_50_300_ab.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output/pdf
	$(R) $< $(FULL_PRE_YEARS) $(RECENT_PRE_YEARS)

../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2014.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2019_2022.pdf: ../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf
	$(RECOVER) -W plot_parent_unit_distribution_comparisons.R all

../output/parent_unit_distribution_80_120.csv: plot_parent_unit_distribution.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet  \
	../input/parent_485x_exposure.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS) $(MAX_UNITS)

../output/parent_unit_distribution_sample_summary.csv  \
	../output/parent_unit_distribution_total_80_120.png \
../output/parent_unit_distribution_annualized_80_120.png \
../output/parent_unit_distribution_exposure_80_120.csv \
../output/parent_unit_distribution_exposure_sample_summary.csv \
../output/parent_unit_distribution_exposure_total_80_120.png \
../output/parent_unit_distribution_exposure_annualized_80_120.png: ../output/parent_unit_distribution_80_120.csv
	$(RECOVER) -W plot_parent_unit_distribution.R all

../output/parent_unit_distribution_full.csv: plot_parent_unit_distribution_views.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/parent_485x_exposure.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output ../output/pdf
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(ZOOM_MIN_UNITS) $(ZOOM_MAX_UNITS) $(WIDE_MAX_UNITS) \
		$(FULL_BIN_WIDTH)

../output/parent_unit_distribution_full_histogram_bins.csv \
../output/parent_unit_distribution_exposure_50_150.csv \
../output/parent_unit_distribution_annualized_50_300.csv \
../output/parent_unit_distribution_normalized_density_50_300_ab.csv \
../output/parent_unit_distribution_full_histogram_total.png \
../output/parent_unit_distribution_full_histogram_annualized.png \
../output/parent_unit_distribution_full_line_total.png \
../output/parent_unit_distribution_full_line_annualized.png \
../output/parent_unit_distribution_exposure_histogram_total_50_150.png \
../output/parent_unit_distribution_exposure_histogram_annualized_50_150.png \
../output/parent_unit_distribution_exposure_line_total_50_150.png \
../output/parent_unit_distribution_exposure_line_annualized_50_150.png \
../output/pdf/parent_unit_distribution_annualized_50_300.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_all.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_ab.pdf \
../output/pdf/parent_unit_distribution_normalized_density_50_300_ab.pdf: ../output/parent_unit_distribution_full.csv
	$(RECOVER) -W plot_parent_unit_distribution_views.R all

../report/parent_unit_distribution_80_120.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_80_120.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_80_120

../report/parent_unit_distribution_annualized_50_300.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_annualized_50_300.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_annualized_50_300

../report/parent_unit_distribution_exposure_50_150.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_exposure_50_150.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_exposure_50_150

../report/parent_unit_distribution_exposure_80_120.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_exposure_80_120.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_exposure_80_120

../report/parent_unit_distribution_exposure_sample_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_exposure_sample_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_exposure_sample_summary

../report/parent_unit_distribution_full.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_full.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_full

../report/parent_unit_distribution_full_histogram_bins.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_full_histogram_bins.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_full_histogram_bins

../report/parent_unit_distribution_normalized_density_50_300_ab.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_normalized_density_50_300_ab.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_normalized_density_50_300_ab

../report/parent_unit_distribution_sample_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_unit_distribution_sample_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_unit_distribution_sample_summary

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet  \
	../input/parent_485x_exposure.csv

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure.csv

include ../../../shared/code/generic.make

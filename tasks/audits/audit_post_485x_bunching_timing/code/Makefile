SHELL := bash
include ../../../shell_functions.make

POLICY_START_DATE := 2024-04-20
FIRST_PERIOD_END_DATE := 2024-12-31
SECOND_PERIOD_END_DATE := 2025-06-30
THIRD_PERIOD_END_DATE := 2025-12-31
SAMPLE_END_DATE := 2026-07-08
MIN_UNITS := 6
PLOT_MIN_UNITS := 50
PLOT_MAX_UNITS := 150
PARENT_PLOT_MAX_UNITS := 400
BUNCH_UNITS := 99
LOCAL_WINDOW_RADIUS := 9

all: ../output/post_485x_bunching_timing_summary.csv \
	../output/provisional_frontier_decomposition.csv \
	../output/provisional_frontier_link_signal_decomposition.csv \
	../output/post_485x_exact_99_parent_paths.csv \
	../output/post_485x_bunching_timing_qc.csv \
	../output/post_485x_filing_unit_distribution.pdf \
	../output/post_485x_filing_unit_distribution.png \
	../output/post_485x_parent_unit_distribution.pdf \
	../output/post_485x_parent_unit_distribution.png \
	../output/post_485x_bunching_timing.pdf \
	../output/post_485x_bunching_timing.png

../output/post_485x_bunching_timing_summary.csv: audit_post_485x_bunching_timing.R \
	../../../_lib/source_pipeline_utils.R \
	../input/provisional_parent_universal_membership.parquet \
	../input/provisional_parent_universal_links.parquet \
	../input/provisional_parent_membership.csv | ../output
	$(R) $< $(POLICY_START_DATE) $(FIRST_PERIOD_END_DATE) $(SECOND_PERIOD_END_DATE) $(THIRD_PERIOD_END_DATE) $(SAMPLE_END_DATE) $(MIN_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS) $(PARENT_PLOT_MAX_UNITS) $(BUNCH_UNITS) $(LOCAL_WINDOW_RADIUS)

../output/provisional_frontier_decomposition.csv \
../output/provisional_frontier_link_signal_decomposition.csv \
../output/post_485x_exact_99_parent_paths.csv \
../output/post_485x_bunching_timing_qc.csv \
../output/post_485x_filing_unit_distribution.pdf \
../output/post_485x_filing_unit_distribution.png \
../output/post_485x_parent_unit_distribution.pdf \
../output/post_485x_parent_unit_distribution.png \
../output/post_485x_bunching_timing.pdf \
../output/post_485x_bunching_timing.png: ../output/post_485x_bunching_timing_summary.csv
	@test -s "$@"

../input/provisional_parent_universal_membership.parquet: ../../audit_provisional_parent_no_notch/output/provisional_parent_universal_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/provisional_parent_membership.csv: ../../audit_provisional_parent_no_notch/output/provisional_parent_membership.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/provisional_parent_universal_links.parquet: ../../audit_provisional_parent_no_notch/output/provisional_parent_universal_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/provisional_parent_universal_membership.parquet \
	../input/provisional_parent_universal_links.parquet \
	../input/provisional_parent_membership.csv

include ../../generic.make

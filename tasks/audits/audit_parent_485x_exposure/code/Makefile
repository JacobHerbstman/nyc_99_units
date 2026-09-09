include ../../../shared/code/shell_functions.make

all: ../output/parent_485x_exposure_summary.csv \
	../output/parent_485x_exposure_by_unit.csv \
	../output/parent_485x_exposure_review_queue.csv \
	../report/parent_485x_exposure_summary.txt \
	../report/parent_485x_exposure_by_unit.txt \
	../report/parent_485x_exposure_review_queue.txt

../output/parent_485x_exposure_summary.csv: summarize_exposure.R ../../../shared/code/source_pipeline_utils.R \
	../input/parent_485x_exposure.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/parent_485x_exposure_by_unit.csv ../output/parent_485x_exposure_review_queue.csv: ../output/parent_485x_exposure_summary.csv
	$(MAKE) -W summarize_exposure.R all

../report/parent_485x_exposure_summary.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_485x_exposure_summary.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure_summary

../report/parent_485x_exposure_by_unit.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_485x_exposure_by_unit.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure_by_unit

../report/parent_485x_exposure_review_queue.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_485x_exposure_review_queue.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure_review_queue

../input/parent_485x_exposure.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure.csv

include ../../../shared/code/generic.make

all: ../output/borough_construction_pay.csv ../output/borough_construction_pay.pdf ../report/borough_construction_pay.txt

../output/borough_construction_pay.csv: build_pay.R ../input/2019_36005.csv ../input/2019_36047.csv ../input/2019_36061.csv ../input/2019_36081.csv ../input/2019_36085.csv ../input/2020_36005.csv ../input/2020_36047.csv ../input/2020_36061.csv ../input/2020_36081.csv ../input/2020_36085.csv ../input/2021_36005.csv ../input/2021_36047.csv ../input/2021_36061.csv ../input/2021_36081.csv ../input/2021_36085.csv ../input/2022_36005.csv ../input/2022_36047.csv ../input/2022_36061.csv ../input/2022_36081.csv ../input/2022_36085.csv ../input/2023_36005.csv ../input/2023_36047.csv ../input/2023_36061.csv ../input/2023_36081.csv ../input/2023_36085.csv | ../output
	$(R) $<

../output/borough_construction_pay.pdf: plot_pay.R ../output/borough_construction_pay.csv | ../output
	$(R) $<

../report/borough_construction_pay.txt: report_pay.R ../output/borough_construction_pay.csv ../../../shared/code/write_data_report.R | ../report
	$(R) $<

../report:
	mkdir -p $@

../input/2019_36005.csv: ../../fetch_qcew_construction/output/2019_36005.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2019_36047.csv: ../../fetch_qcew_construction/output/2019_36047.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2019_36061.csv: ../../fetch_qcew_construction/output/2019_36061.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2019_36081.csv: ../../fetch_qcew_construction/output/2019_36081.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2019_36085.csv: ../../fetch_qcew_construction/output/2019_36085.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2020_36005.csv: ../../fetch_qcew_construction/output/2020_36005.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2020_36047.csv: ../../fetch_qcew_construction/output/2020_36047.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2020_36061.csv: ../../fetch_qcew_construction/output/2020_36061.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2020_36081.csv: ../../fetch_qcew_construction/output/2020_36081.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2020_36085.csv: ../../fetch_qcew_construction/output/2020_36085.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2021_36005.csv: ../../fetch_qcew_construction/output/2021_36005.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2021_36047.csv: ../../fetch_qcew_construction/output/2021_36047.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2021_36061.csv: ../../fetch_qcew_construction/output/2021_36061.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2021_36081.csv: ../../fetch_qcew_construction/output/2021_36081.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2021_36085.csv: ../../fetch_qcew_construction/output/2021_36085.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2022_36005.csv: ../../fetch_qcew_construction/output/2022_36005.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2022_36047.csv: ../../fetch_qcew_construction/output/2022_36047.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2022_36061.csv: ../../fetch_qcew_construction/output/2022_36061.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2022_36081.csv: ../../fetch_qcew_construction/output/2022_36081.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2022_36085.csv: ../../fetch_qcew_construction/output/2022_36085.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2023_36005.csv: ../../fetch_qcew_construction/output/2023_36005.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2023_36047.csv: ../../fetch_qcew_construction/output/2023_36047.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2023_36061.csv: ../../fetch_qcew_construction/output/2023_36061.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2023_36081.csv: ../../fetch_qcew_construction/output/2023_36081.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/2023_36085.csv: ../../fetch_qcew_construction/output/2023_36085.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

include ../../generic.make

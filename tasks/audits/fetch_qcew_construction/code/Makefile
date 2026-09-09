include ../../../shared/code/shell_functions.make

all: ../output/2019_36005.csv \
	../output/2019_36047.csv \
	../output/2019_36061.csv \
	../output/2019_36081.csv \
	../output/2019_36085.csv \
	../output/2020_36005.csv \
	../output/2020_36047.csv \
	../output/2020_36061.csv \
	../output/2020_36081.csv \
	../output/2020_36085.csv \
	../output/2021_36005.csv \
	../output/2021_36047.csv \
	../output/2021_36061.csv \
	../output/2021_36081.csv \
	../output/2021_36085.csv \
	../output/2022_36005.csv \
	../output/2022_36047.csv \
	../output/2022_36061.csv \
	../output/2022_36081.csv \
	../output/2022_36085.csv \
	../output/2023_36005.csv \
	../output/2023_36047.csv \
	../output/2023_36061.csv \
	../output/2023_36081.csv \
	../output/2023_36085.csv \
	../report/2019_36005.txt \
	../report/2019_36047.txt \
	../report/2019_36061.txt \
	../report/2019_36081.txt \
	../report/2019_36085.txt \
	../report/2020_36005.txt \
	../report/2020_36047.txt \
	../report/2020_36061.txt \
	../report/2020_36081.txt \
	../report/2020_36085.txt \
	../report/2021_36005.txt \
	../report/2021_36047.txt \
	../report/2021_36061.txt \
	../report/2021_36081.txt \
	../report/2021_36085.txt \
	../report/2022_36005.txt \
	../report/2022_36047.txt \
	../report/2022_36061.txt \
	../report/2022_36081.txt \
	../report/2022_36085.txt \
	../report/2023_36005.txt \
	../report/2023_36047.txt \
	../report/2023_36061.txt \
	../report/2023_36081.txt \
	../report/2023_36085.txt

include download_recipes.make

../report/%.txt: report_source.R ../output/%.csv ../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< $*



include ../../../shared/code/generic.make

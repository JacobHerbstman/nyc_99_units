include ../../shared/code/shell_functions.make

all: ../output/borough_boundaries_2026-09-08.geojson ../report/borough_boundaries.txt

../output/borough_boundaries_2026-09-08.geojson: Makefile | ../output
	wget --no-use-server-timestamps --timeout=60 --tries=2 -O ../output/borough_boundaries_2026-09-08.geojson.part 'https://data.cityofnewyork.us/resource/gthc-hcne.geojson?$$limit=10'
	printf '%s  %s\n' 7aa44d9fb611f2f518a226ff994a6516a261a8ce982ccf1e7b37d663687f443c $@.part | shasum -a 256 -c -
	mv ../output/borough_boundaries_2026-09-08.geojson.part $@



../report/borough_boundaries.txt: report_data.R ../../shared/code/write_data_report.R ../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh ../output/borough_boundaries_2026-09-08.geojson Makefile | ../report
	$(R) $<

include ../../shared/code/generic.make

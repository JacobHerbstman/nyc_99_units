include ../../../shared/code/shell_functions.make

all: ../output/flatbush_deis_part2_2018.pdf ../output/flatbush_deis_part3_2018.pdf

include ../../../shared/code/generic.make

../output/flatbush_deis_part2_2018.pdf: flatbush_floor.make flatbush_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://infohub.nyced.org/docs/default-source/default-document-library/deis__ecf_80_flatbush_avenue_part2.pdf' --output ../temp/flatbush_deis_part2_2018.pdf
	cd ../temp && sed -n '/  flatbush_deis_part2_2018.pdf$$/p' ../code/flatbush_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/flatbush_deis_part2_2018.pdf $@

../output/flatbush_deis_part3_2018.pdf: flatbush_floor.make flatbush_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://infohub.nyced.org/docs/default-source/default-document-library/deis__ecf_80_flatbush_avenue_part3.pdf' --output ../temp/flatbush_deis_part3_2018.pdf
	cd ../temp && sed -n '/  flatbush_deis_part3_2018.pdf$$/p' ../code/flatbush_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/flatbush_deis_part3_2018.pdf $@

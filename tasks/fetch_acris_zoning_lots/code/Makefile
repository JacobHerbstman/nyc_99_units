include ../../shared/code/shell_functions.make

RAW := ../../../data_raw/acris_zoning_lots/2026-10-01

all: ../output/acris_zoning_lots_20261001_zoning_lot_documents.csv \
	../output/acris_zoning_lots_20261001_zoning_lot_parcels.csv

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; the capture is copied only when missing.
../output/acris_zoning_lots_20261001_zoning_lot_%.csv: $(RAW)/zoning_lot_%.csv ../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

# The Open Data API is mutable: query it only when the dated capture is missing,
# and save the capture only if its bytes match the recorded checksum. The lots
# are requested for the documents of the saved documents capture.
$(RAW)/zoning_lot_documents.csv: | ../temp
	python3 download_acris.py documents ../temp/zoning_lot_documents.csv
	awk '$$2 == "../output/acris_zoning_lots_20261001_zoning_lot_documents.csv" { print $$1 "  ../temp/zoning_lot_documents.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/zoning_lot_documents_manifest.csv $(@D)/zoning_lot_documents_manifest.csv
	mv ../temp/zoning_lot_documents.csv $@

$(RAW)/zoning_lot_parcels.csv: $(RAW)/zoning_lot_documents.csv | ../temp
	python3 download_acris.py parcels ../temp/zoning_lot_parcels.csv $<
	awk '$$2 == "../output/acris_zoning_lots_20261001_zoning_lot_parcels.csv" { print $$1 "  ../temp/zoning_lot_parcels.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mv ../temp/zoning_lot_parcels_manifest.csv $(@D)/zoning_lot_parcels_manifest.csv
	mv ../temp/zoning_lot_parcels.csv $@

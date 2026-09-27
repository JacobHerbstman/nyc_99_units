include ../../shared/code/shell_functions.make

RAW := ../../../data_raw/nyc_prevailing_wage_schedules/2026-09-27
SCHEDULES := 2018_2019 2019_2020 2020_2021 2021_2022 2022_2023 2023_2024 2024_2025 2025_2026

CAPTURES := $(SCHEDULES:%=$(RAW)/construction_worker_schedule_%.pdf)
OUTPUTS := $(SCHEDULES:%=../output/nyc_construction_prevailing_wage_schedule_%.pdf)

all: $(OUTPUTS)

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; each capture is copied only when missing.
$(OUTPUTS): ../output/nyc_construction_prevailing_wage_schedule_%.pdf: $(RAW)/construction_worker_schedule_%.pdf | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

# Download a schedule from schedule_urls.csv only when its capture is missing,
# and save it only if its bytes match the recorded checksum.
$(CAPTURES): $(RAW)/construction_worker_schedule_%.pdf: | ../temp
	curl --fail --location --silent --show-error --retry 3 --connect-timeout 30 --max-time 300 \
		--output ../temp/$(@F) "$$(awk -F, '$$1 == "$*" { print $$2 }' schedule_urls.csv)"
	awk '$$2 == "../output/nyc_construction_prevailing_wage_schedule_$*.pdf" { print $$1 "  ../temp/$(@F)" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/$(@F) $@

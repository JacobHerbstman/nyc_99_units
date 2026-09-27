include ../../shared/code/shell_functions.make

SCHEDULES := 2018_2019 2019_2020 2020_2021 2021_2022 2022_2023 2023_2024 2024_2025 2025_2026
INPUTS := $(SCHEDULES:%=../input/nyc_construction_prevailing_wage_schedule_%.pdf)

all: ../output/nyc_prevailing_wage_rates_2018_2026.csv

include ../../shared/code/generic.make

../output/nyc_prevailing_wage_rates_2018_2026.csv: stage_wage_schedules.R $(INPUTS) Makefile | $(OOPR)
	$(R) $<

../input/%.pdf: ../../fetch_nyc_prevailing_wage_schedules/output/%.pdf | ../input
	ln -sf $< $@

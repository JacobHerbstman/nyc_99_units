SHELL := bash
include ../../shell_functions.make

all: ../output/acris_site_event_manual_review_decisions.csv

../output/acris_site_event_manual_review_decisions.csv: validate_acris_site_event_manual_review_decisions.R acris_site_event_manual_review_decisions.csv | ../output
	$(R) $<

link-inputs:

include ../../generic.make

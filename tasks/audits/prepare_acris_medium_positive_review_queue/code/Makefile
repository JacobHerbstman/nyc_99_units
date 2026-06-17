SHELL := bash
include ../../../shell_functions.make

all: ../output/acris_medium_positive_review_queue.csv ../output/acris_medium_positive_review_documents.csv ../output/acris_medium_positive_review_legals.csv ../output/acris_medium_positive_review_parties.csv ../output/acris_medium_positive_review_chatgpt_prompts.csv ../output/acris_medium_positive_review_decision_template.csv

../output/acris_medium_positive_review_queue.csv: prepare_acris_medium_positive_review_queue.R ../input/acris_site_event_review_clusters.csv ../input/acris_site_event_review_documents.csv ../input/acris_site_event_review_legals.csv ../input/acris_site_event_review_parties.csv ../input/acris_site_event_review_chatgpt_prompts.csv ../input/acris_site_event_manual_review_decisions.csv | ../output
	$(R) $<

../output/acris_medium_positive_review_documents.csv: ../output/acris_medium_positive_review_queue.csv
	@test -s "$@"

../output/acris_medium_positive_review_legals.csv: ../output/acris_medium_positive_review_queue.csv
	@test -s "$@"

../output/acris_medium_positive_review_parties.csv: ../output/acris_medium_positive_review_queue.csv
	@test -s "$@"

../output/acris_medium_positive_review_chatgpt_prompts.csv: ../output/acris_medium_positive_review_queue.csv
	@test -s "$@"

../output/acris_medium_positive_review_decision_template.csv: ../output/acris_medium_positive_review_queue.csv
	@test -s "$@"

../input/acris_site_event_review_clusters.csv: ../../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_clusters.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_documents.csv: ../../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_documents.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_legals.csv: ../../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_legals.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_parties.csv: ../../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_parties.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_chatgpt_prompts.csv: ../../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_chatgpt_prompts.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_manual_review_decisions.csv: ../../../define_acris_site_event_manual_review_decisions/output/acris_site_event_manual_review_decisions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_site_event_review_clusters.csv ../input/acris_site_event_review_documents.csv ../input/acris_site_event_review_legals.csv ../input/acris_site_event_review_parties.csv ../input/acris_site_event_review_chatgpt_prompts.csv ../input/acris_site_event_manual_review_decisions.csv

include ../../generic.make

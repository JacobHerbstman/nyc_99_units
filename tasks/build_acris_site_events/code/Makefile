SHELL := bash
include ../../shell_functions.make

all: ../output/acris_site_events.parquet ../output/acris_site_event_documents.parquet ../output/acris_site_event_bbl_incidence.parquet

../output/acris_site_events.parquet: build_acris_site_events.R ../input/acris_deed_document_classified.parquet ../input/acris_site_event_review_clusters.csv ../input/acris_site_event_review_documents.csv ../input/acris_site_event_manual_review_decisions.csv | ../output
	$(R) $<

../output/acris_site_event_documents.parquet: ../output/acris_site_events.parquet
	@test -s "$@"

../output/acris_site_event_bbl_incidence.parquet: ../output/acris_site_events.parquet
	@test -s "$@"

../input/acris_deed_document_classified.parquet: ../../build_acris_market_site_sale_universe/output/acris_deed_document_classified.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_clusters.csv: ../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_clusters.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_review_documents.csv: ../../audits/prepare_acris_site_event_review_packet/output/acris_site_event_review_documents.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_event_manual_review_decisions.csv: ../../define_acris_site_event_manual_review_decisions/output/acris_site_event_manual_review_decisions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_deed_document_classified.parquet ../input/acris_site_event_review_clusters.csv ../input/acris_site_event_review_documents.csv ../input/acris_site_event_manual_review_decisions.csv

include ../../generic.make

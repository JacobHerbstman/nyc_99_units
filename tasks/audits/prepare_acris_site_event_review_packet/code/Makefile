SHELL := bash
include ../../../shell_functions.make

all: ../output/acris_site_event_review_summary.csv ../output/acris_site_event_review_clusters.csv ../output/acris_site_event_review_documents.csv ../output/acris_site_event_review_legals.csv ../output/acris_site_event_review_parties.csv ../output/acris_site_event_review_chatgpt_prompts.csv ../output/audit_same_date_site_partial_interest_superclusters.csv ../output/audit_underclustered_same_buyer_packets.csv ../output/audit_review_cluster_superset_bridge.csv

../output/acris_site_event_review_summary.csv: prepare_acris_site_event_review_packet.R ../input/acris_deed_document_classified.parquet ../input/acris_direct_deed_all_legals.parquet ../input/acris_direct_opportunity_deed_parties.parquet | ../output
	$(R) $<

../output/acris_site_event_review_clusters.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/acris_site_event_review_documents.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/acris_site_event_review_legals.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/acris_site_event_review_parties.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/acris_site_event_review_chatgpt_prompts.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/audit_same_date_site_partial_interest_superclusters.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/audit_underclustered_same_buyer_packets.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../output/audit_review_cluster_superset_bridge.csv: ../output/acris_site_event_review_summary.csv
	@test -s "$@"

../input/acris_deed_document_classified.parquet: ../../../build_acris_market_site_sale_universe/output/acris_deed_document_classified.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_deed_all_legals.parquet: ../../../stage_acris_direct_deed_all_legals/output/acris_direct_deed_all_legals.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_parties.parquet: ../../../stage_acris_direct_opportunity_deed_parties/output/acris_direct_opportunity_deed_parties.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_deed_document_classified.parquet ../input/acris_direct_deed_all_legals.parquet ../input/acris_direct_opportunity_deed_parties.parquet

include ../../generic.make

SHELL := bash
include ../../../shell_functions.make

all: ../output/dof_only_high_priority_review_queue.csv \
	../output/dof_only_high_priority_review_summary.csv \
	../output/dof_only_high_priority_review_packet.csv \
	../output/dof_only_same_date_acris_document_evidence.csv \
	../output/dof_only_review_queue_hard_checks.csv

../output/dof_only_high_priority_review_queue.csv: build_dof_only_sales_review_queue.R \
	../../../_lib/source_pipeline_utils.R \
	../input/dof_acris_best_links.parquet \
	../input/acris_direct_opportunity_deed_bbls.parquet \
	../input/acris_deed_document_classified.parquet \
	../input/acris_site_events.parquet | ../output
	$(R) $<

../output/dof_only_high_priority_review_summary.csv \
	../output/dof_only_high_priority_review_packet.csv \
	../output/dof_only_same_date_acris_document_evidence.csv \
	../output/dof_only_review_queue_hard_checks.csv: ../output/dof_only_high_priority_review_queue.csv
	@test -s "$@"

../input/dof_acris_best_links.parquet: ../../audit_recorded_sales_coverage/output/dof_acris_best_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_bbls.parquet: ../../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_deed_document_classified.parquet: ../../../build_acris_market_site_sale_universe/output/acris_deed_document_classified.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_site_events.parquet: ../../../build_acris_site_events/output/acris_site_events.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dof_acris_best_links.parquet \
	../input/acris_direct_opportunity_deed_bbls.parquet \
	../input/acris_deed_document_classified.parquet \
	../input/acris_site_events.parquet

include ../../generic.make

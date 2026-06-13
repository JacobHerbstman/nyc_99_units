SHELL := bash

all: ../output/acris_recovery_candidate_summary.csv \
	../output/acris_deed_master_fetch_summary.csv \
	../output/acris_deed_master_version_summary.csv \
	../output/acris_deed_master_version_counts.csv \
	../output/acris_recovery_candidate_coverage_by_year.csv \
	../output/acris_recovery_top_exact_key_collisions.csv \
	../output/acris_recovery_document_candidate_multiplicity.csv \
	../output/acris_opportunity_legals_summary.csv \
	../output/acris_recovered_sale_event_summary.csv \
	../output/acris_recovered_sale_events_by_year.csv \
	../output/acris_recovered_sale_events_by_seed_type.csv \
	../output/acris_recovered_sale_incidence_summary.csv \
	../output/acris_recovered_sale_incidence_by_quarter.csv \
	../output/acris_recovery_attrition_funnel.csv \
	../output/acris_recovered_sale_largest_events.csv \
	../output/acris_recovered_sale_post2024_manual_review.csv \
	../output/acris_recovered_sale_exact_vs_recovered_by_year.csv \
	../output/acris_recovered_sale_exact_vs_recovered_by_borough_exposure.csv \
	../output/acris_recovered_sale_price_outlier_review.csv \
	../output/acris_recovered_sale_same_block_mixed_review.csv \
	../output/acris_recovered_sale_repeated_timing_flags.csv \
	../output/acris_recovered_sale_multilot_allocation_sensitivity.csv \
	../output/acris_recovery_source_key_collision_review.csv

../output/acris_recovery_candidate_summary.csv: summarize_acris_recovery_layer.R ../input/acris_deed_master_files.csv ../input/acris_deed_master.parquet ../input/acris_opportunity_sale_seeds.parquet ../input/acris_dof_deed_candidate_links.parquet ../input/acris_opportunity_legals.parquet ../input/acris_recovered_sale_events.parquet ../input/acris_recovered_sale_lot_quarter_incidence.parquet ../input/opportunity_sales_exact_bbl.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../output/acris_deed_master_fetch_summary.csv ../output/acris_deed_master_version_summary.csv ../output/acris_deed_master_version_counts.csv ../output/acris_recovery_candidate_coverage_by_year.csv ../output/acris_recovery_top_exact_key_collisions.csv ../output/acris_recovery_document_candidate_multiplicity.csv ../output/acris_opportunity_legals_summary.csv ../output/acris_recovered_sale_event_summary.csv ../output/acris_recovered_sale_events_by_year.csv ../output/acris_recovered_sale_events_by_seed_type.csv ../output/acris_recovered_sale_incidence_summary.csv ../output/acris_recovered_sale_incidence_by_quarter.csv ../output/acris_recovery_attrition_funnel.csv ../output/acris_recovered_sale_largest_events.csv ../output/acris_recovered_sale_post2024_manual_review.csv ../output/acris_recovered_sale_exact_vs_recovered_by_year.csv ../output/acris_recovered_sale_exact_vs_recovered_by_borough_exposure.csv ../output/acris_recovered_sale_price_outlier_review.csv ../output/acris_recovered_sale_same_block_mixed_review.csv ../output/acris_recovered_sale_repeated_timing_flags.csv ../output/acris_recovered_sale_multilot_allocation_sensitivity.csv ../output/acris_recovery_source_key_collision_review.csv: ../output/acris_recovery_candidate_summary.csv
	@test -s "$@"

../input/acris_deed_master_files.csv: ../../../fetch_acris_deed_master/output/acris_deed_master_files.csv | ../input
	@test "$$(readlink "$@")" = "../../../fetch_acris_deed_master/output/acris_deed_master_files.csv" || ln -sf "../../../fetch_acris_deed_master/output/acris_deed_master_files.csv" "$@"

../input/acris_deed_master.parquet: ../../../stage_acris_deed_master/output/acris_deed_master.parquet | ../input
	@test "$$(readlink "$@")" = "../../../stage_acris_deed_master/output/acris_deed_master.parquet" || ln -sf "../../../stage_acris_deed_master/output/acris_deed_master.parquet" "$@"

../input/acris_opportunity_sale_seeds.parquet: ../../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet" || ln -sf "../../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet" "$@"

../input/acris_dof_deed_candidate_links.parquet: ../../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" || ln -sf "../../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" "$@"

../input/acris_opportunity_legals.parquet: ../../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet | ../input
	@test "$$(readlink "$@")" = "../../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet" || ln -sf "../../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet" "$@"

../input/acris_recovered_sale_events.parquet: ../../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet" || ln -sf "../../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet" "$@"

../input/acris_recovered_sale_lot_quarter_incidence.parquet: ../../../build_acris_recovered_lot_quarter_incidence/output/acris_recovered_sale_lot_quarter_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_acris_recovered_lot_quarter_incidence/output/acris_recovered_sale_lot_quarter_incidence.parquet" || ln -sf "../../../build_acris_recovered_lot_quarter_incidence/output/acris_recovered_sale_lot_quarter_incidence.parquet" "$@"

../input/opportunity_sales_exact_bbl.parquet: ../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" || ln -sf "../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

link-inputs: ../input/acris_deed_master_files.csv ../input/acris_deed_master.parquet ../input/acris_opportunity_sale_seeds.parquet ../input/acris_dof_deed_candidate_links.parquet ../input/acris_opportunity_legals.parquet ../input/acris_recovered_sale_events.parquet ../input/acris_recovered_sale_lot_quarter_incidence.parquet ../input/opportunity_sales_exact_bbl.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make

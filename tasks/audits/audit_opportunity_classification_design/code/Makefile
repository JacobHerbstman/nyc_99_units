SHELL := bash

all: ../output/capacity_rule_summary.csv \
	../output/frozen_opportunity_capacity_counts.csv \
	../output/hdb_capacity_threshold_confusion.csv \
	../output/hdb_capacity_bin_outcomes.csv \
	../output/hdb_capacity_tier_performance.csv \
	../output/hdb_score_tier_performance.csv \
	../output/hdb_score_tier_contrast.csv \
	../output/hdb_score_tier_examples.csv \
	../output/hdb_capacity_classification_examples.csv \
	../output/research_understanding_checklist.md

../output/capacity_rule_summary.csv: audit_opportunity_classification_design.R ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_opportunity_lots_frozen.parquet ../input/candidate_prediction_scores.csv | ../output
	$(R) $<

../output/frozen_opportunity_capacity_counts.csv ../output/hdb_capacity_threshold_confusion.csv ../output/hdb_capacity_bin_outcomes.csv ../output/hdb_capacity_tier_performance.csv ../output/hdb_score_tier_performance.csv ../output/hdb_score_tier_contrast.csv ../output/hdb_score_tier_examples.csv ../output/hdb_capacity_classification_examples.csv ../output/research_understanding_checklist.md: ../output/capacity_rule_summary.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

../input/candidate_prediction_scores.csv: ../../fit_candidate_prediction_models/output/candidate_prediction_scores.csv | ../input
	@test "$$(readlink "$@")" = "../../fit_candidate_prediction_models/output/candidate_prediction_scores.csv" || ln -sf "../../fit_candidate_prediction_models/output/candidate_prediction_scores.csv" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_opportunity_lots_frozen.parquet ../input/candidate_prediction_scores.csv

include ../../generic.make

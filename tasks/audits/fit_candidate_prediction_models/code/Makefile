SHELL := bash

all: ../output/candidate_prediction_fit_summary.csv \
	../output/candidate_prediction_deciles.csv \
	../output/candidate_prediction_rank_correlations.csv \
	../output/candidate_prediction_top_bin_overlap.csv \
	../output/candidate_prediction_sample_summary.csv \
	../output/candidate_prediction_size_bin_counts.csv \
	../output/candidate_prediction_feature_missingness.csv \
	../output/ridge_logit_enriched_main_coefficients.csv \
	../output/ridge_logit_enriched_main_diagnostics.csv \
	../output/ridge_logit_enriched_main_deciles.csv \
	../output/ridge_logit_enriched_main_cv_path.csv \
	../output/ridge_logit_enriched_main_reference_levels.csv

../output/candidate_prediction_fit_summary.csv: fit_candidate_prediction_models.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $<

../output/candidate_prediction_deciles.csv ../output/candidate_prediction_rank_correlations.csv ../output/candidate_prediction_top_bin_overlap.csv ../output/candidate_prediction_sample_summary.csv ../output/candidate_prediction_size_bin_counts.csv ../output/candidate_prediction_feature_missingness.csv: ../output/candidate_prediction_fit_summary.csv
	@test -s "$@"

../output/ridge_logit_enriched_main_coefficients.csv: summarize_ridge_logit_enriched_main.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $<

../output/ridge_logit_enriched_main_diagnostics.csv ../output/ridge_logit_enriched_main_deciles.csv ../output/ridge_logit_enriched_main_cv_path.csv ../output/ridge_logit_enriched_main_reference_levels.csv: ../output/ridge_logit_enriched_main_coefficients.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet

include ../../generic.make

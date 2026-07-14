SHELL := bash
include ../../../shell_functions.make

UNIVERSE_MIN_UNITS := 6
THRESHOLD_UNITS := 100
NEARBY_METERS := 100
MAX_FILING_DAYS := 365
SIMULATION_DRAWS := 20000
SIMULATION_SEED := 990100

all: ../output/provisional_parent_no_notch_scores.parquet \
	../output/provisional_parent_universal_membership.parquet \
	../output/provisional_parent_universal_links.parquet \
	../output/provisional_parent_membership.csv \
	../output/provisional_parent_scale_summary.csv \
	../output/provisional_parent_mass_balance.csv \
	../output/provisional_parent_structure_mass_balance.csv \
	../output/anchored_exact_99_structure_exposure.csv \
	../output/provisional_parent_score_qc.csv \
	../output/provisional_parent_predicted_vs_observed.pdf \
	../output/provisional_parent_predicted_vs_observed.png \
	../output/provisional_parent_structure_mass_balance.pdf \
	../output/provisional_parent_structure_mass_balance.png

../output/provisional_parent_no_notch_scores.parquet: audit_provisional_parent_no_notch.R ../input/developer_opportunity_job_crosswalk.parquet ../input/developer_opportunity_exact_99_casebook.csv ../input/no_notch_post_policy_exposure_scores.parquet | ../output
	$(R) $< $(UNIVERSE_MIN_UNITS) $(THRESHOLD_UNITS) $(NEARBY_METERS) $(MAX_FILING_DAYS) $(SIMULATION_DRAWS) $(SIMULATION_SEED)

../output/provisional_parent_universal_membership.parquet ../output/provisional_parent_universal_links.parquet ../output/provisional_parent_membership.csv ../output/provisional_parent_scale_summary.csv ../output/provisional_parent_mass_balance.csv ../output/provisional_parent_structure_mass_balance.csv ../output/anchored_exact_99_structure_exposure.csv ../output/provisional_parent_score_qc.csv ../output/provisional_parent_predicted_vs_observed.pdf ../output/provisional_parent_predicted_vs_observed.png ../output/provisional_parent_structure_mass_balance.pdf ../output/provisional_parent_structure_mass_balance.png: ../output/provisional_parent_no_notch_scores.parquet
	@test -s "$@"

../input/developer_opportunity_job_crosswalk.parquet: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_job_crosswalk.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_exact_99_casebook.csv: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_exact_99_casebook.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_post_policy_exposure_scores.parquet: ../../audit_no_notch_post_policy_exposure/output/no_notch_post_policy_exposure_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/developer_opportunity_job_crosswalk.parquet ../input/developer_opportunity_exact_99_casebook.csv ../input/no_notch_post_policy_exposure_scores.parquet

include ../../generic.make

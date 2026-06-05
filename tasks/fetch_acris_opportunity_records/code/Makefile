SHELL := bash
include ../../shell_functions.make

all: ../output/acris_opportunity_record_files.csv

../output/acris_opportunity_record_files.csv: fetch_acris_opportunity_records.R ../input/acris_dof_deed_candidate_links.parquet | ../output
	$(R) $<

../input/acris_dof_deed_candidate_links.parquet: ../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" || ln -sf "../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" "$@"

link-inputs: ../input/acris_dof_deed_candidate_links.parquet

include ../../generic.make

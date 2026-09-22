include ../../../shared/code/shell_functions.make

all: ../output/five_floor_sensitivity.csv ../output/jamaica_floor_allocation.csv \
	../output/kingsbrook_floor_schedule.csv ../output/remaining_floor_candidates.csv \
	../output/kingsbrook_floor_allocation.png

include ../../../shared/code/generic.make

../output/jamaica_floor_allocation.csv ../output/kingsbrook_floor_schedule.csv \
../output/remaining_floor_candidates.csv ../output/kingsbrook_floor_allocation.png: measure_remaining_floors.R kingsbrook_survey_tracing.csv \
	five_floor.make ../input/dcp_mappluto_archive_23v3_1.parquet \
	../input/kingsbrook_hcr_floor_plans_2018.pdf ../input/jamaica_condo_maps_2024081600593002.pdf \
	../input/kingsbrook_phase_I_esa_2025.pdf ../input/kingsbrook_rawp_2026.pdf \
	../input/jamaica_zoning_development_2026051400252004.pdf ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/five_floor_sensitivity.csv: five_floor_sensitivity.R five_floor.make \
	../input/parent_opportunity_panel.parquet ../input/dcp_mappluto_archive_20v1.parquet \
	../output/jamaica_floor_allocation.csv \
	../output/remaining_floor_candidates.csv \
	../output/dof_all_parent_overlaps.parquet ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_20v1.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_20v1.parquet | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_23v3_1.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	ln -sf $< $@

../input/kingsbrook_hcr_floor_plans_2018.pdf: ../../download_parent_review_documents/output/kingsbrook_hcr_floor_plans_2018.pdf | ../input
	ln -sf $< $@

../input/kingsbrook_phase_I_esa_2025.pdf: ../../download_parent_review_documents/output/kingsbrook_phase_I_esa_2025.pdf | ../input
	ln -sf $< $@

../input/kingsbrook_rawp_2026.pdf: ../../download_parent_review_documents/output/kingsbrook_rawp_2026.pdf | ../input
	ln -sf $< $@

../input/jamaica_condo_maps_2024081600593002.pdf: ../../download_parent_review_documents/code/site_research_supervisor_2026-09-16/jamaica_condo_maps_2024081600593002.pdf | ../input
	ln -sf $< $@

../input/jamaica_zoning_development_2026051400252004.pdf: ../../download_parent_review_documents/code/site_research_followup_2026-09-20_jamaica/zoning_development_2026051400252004.pdf | ../input
	ln -sf $< $@

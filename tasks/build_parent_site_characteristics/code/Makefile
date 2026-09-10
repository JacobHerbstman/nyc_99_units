include ../../shared/code/shell_functions.make

all: ../output/historical_parent_site_characteristics.parquet \
	../output/post_policy_parent_site_characteristics.parquet ../report/historical_parent_site_characteristics.txt \
	../report/post_policy_parent_site_characteristics.txt

../output/historical_parent_site_characteristics.parquet: build_parent_site_characteristics.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_site_panel.parquet ../input/dcp_mappluto_archive_23v3_1.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/post_policy_parent_site_characteristics.parquet: ../output/historical_parent_site_characteristics.parquet
	$(RECOVER) -W build_parent_site_characteristics.R all

../report/historical_parent_site_characteristics.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/historical_parent_site_characteristics.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_parent_site_characteristics

../report/post_policy_parent_site_characteristics.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/post_policy_parent_site_characteristics.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< post_policy_parent_site_characteristics

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hdb_mappluto_site_panel.parquet: ../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet \
	| ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

.PHONY: check-stage_mappluto_lots

check-stage_mappluto_lots:
	$(MAKE) -C ../../stage_mappluto_lots/code all ../output/dcp_mappluto_archive_23v3_1.parquet

../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet: check-stage_mappluto_lots ;

link-inputs: ../input/symmetric_parent_membership.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet

include ../../shared/code/generic.make

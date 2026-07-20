SHELL := bash
include ../../shell_functions.make

BUNCH_UNITS := 99
THRESHOLD_UNITS := 100

all: ../output/developer_cost_calibration_targets.csv \
	../output/affected_parent_n0_weights.csv

../output/developer_cost_calibration_targets.csv: prepare_developer_cost_calibration.R \
	../../_lib/source_pipeline_utils.R \
	../input/enhanced_parent_2025_counterfactual.csv \
	../input/enhanced_parent_2025_distribution.csv | ../output
	$(R) $< $(BUNCH_UNITS) $(THRESHOLD_UNITS)

../output/affected_parent_n0_weights.csv: ../output/developer_cost_calibration_targets.csv
	@test -s "$@"

../input/enhanced_parent_2025_counterfactual.csv: ../../estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_distribution.csv: ../../estimate_parent_no_notch_model/output/enhanced_parent_2025_distribution.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/enhanced_parent_2025_counterfactual.csv \
	../input/enhanced_parent_2025_distribution.csv

include ../../generic.make

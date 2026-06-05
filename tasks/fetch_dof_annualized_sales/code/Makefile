SHELL := bash
include ../../shell_functions.make

all: ../output/dof_annualized_sales_files.csv

../output/dof_annualized_sales_files.csv: fetch_dof_annualized_sales.R ../input/source_catalog.csv | ../output
	$(R) $<

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/source_catalog.csv

include ../../generic.make

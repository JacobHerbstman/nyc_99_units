SHELL := bash
include ../../shell_functions.make

all: ../output/dof_annualized_sales.parquet \
	../output/dof_annualized_sales_files.csv

../output/dof_annualized_sales.parquet: stage_dof_annualized_sales.R ../input/dof_annualized_sales_files.csv | ../output
	$(R) $<

../output/dof_annualized_sales_files.csv: ../output/dof_annualized_sales.parquet
	@test -s "$@"

../input/dof_annualized_sales_files.csv: ../../fetch_dof_annualized_sales/output/dof_annualized_sales_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dof_annualized_sales_files.csv

include ../../generic.make

SHELL := /bin/bash
.DELETE_ON_ERROR:

all: framework_unit_choice.pdf

framework_unit_choice.pdf: framework_unit_choice.tex Makefile
	pdflatex -interaction=nonstopmode -halt-on-error framework_unit_choice.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_unit_choice.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_unit_choice.tex

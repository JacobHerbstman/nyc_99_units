SHELL := /bin/bash
.DEFAULT_GOAL := all

.PHONY: all setup-environment source-registry paper framework-writeup empirics

all: framework-writeup empirics

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

source-registry:
	$(MAKE) -C tasks/source_registry/code

paper:
	$(MAKE) -C paper

empirics: tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf

tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf:
	$(MAKE) -C tasks/analyze_485x_scale_shape_splitting/code ../output/pdf/scale_shape_splitting_figure_guide.pdf

framework-writeup: framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex framework_writeup.bib
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex

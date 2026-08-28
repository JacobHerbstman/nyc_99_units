SHELL := /bin/bash
.DEFAULT_GOAL := all

.PHONY: all setup-environment source-registry paper framework-writeup

all: paper

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

source-registry:
	$(MAKE) -C tasks/source_registry/code

paper:
	$(MAKE) -C paper

framework-writeup: framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex

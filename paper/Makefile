.NOTPARALLEL:
.DELETE_ON_ERROR:
SHELL := /bin/bash

all: paper.pdf

paper.pdf: paper.tex Makefile sections/01_introduction.tex sections/02_data.tex sections/03_empirical_strategy.tex
	pdflatex -interaction=nonstopmode -halt-on-error paper.tex
	pdflatex -interaction=nonstopmode -halt-on-error paper.tex

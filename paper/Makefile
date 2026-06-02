SHELL := /bin/bash

all: paper.pdf

paper.pdf: paper.tex sections/01_introduction.tex sections/02_data.tex sections/03_empirical_strategy.tex
	pdflatex -interaction=nonstopmode paper.tex
	pdflatex -interaction=nonstopmode paper.tex

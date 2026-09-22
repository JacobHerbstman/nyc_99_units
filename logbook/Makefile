.DELETE_ON_ERROR:

all: logbook.pdf

# Entries are dated records. They read only the frozen figures and archived
# results committed here, never live task outputs.
logbook.pdf: logbook.tex Makefile $(wildcard entries/*.tex) $(wildcard figures/*) \
	$(wildcard archive/*/*.tex) $(wildcard archive/*/pdf/*.pdf)
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex

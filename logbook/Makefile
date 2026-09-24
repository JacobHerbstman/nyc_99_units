.DELETE_ON_ERROR:

all: logbook.pdf

# Figures from live tasks are prerequisites; figures whose producers were
# removed are archived byte copies under archive/.
logbook.pdf: logbook.tex Makefile $(wildcard entries/*.tex) $(wildcard archive/*/*.tex) \
	$(wildcard archive/*/*.pdf) $(wildcard archive/*/pdf/*.pdf) \
	../tasks/analyze_borough_bunching/output/borough_filings.pdf \
	../tasks/analyze_borough_bunching/output/borough_parents.pdf \
	../tasks/audits/audit_scale_shape_splitting/output/pdf/annual_split_shares.pdf \
	../tasks/audits/audit_estimation_parent_links/output/third_avenue_plan.png \
	../tasks/estimate_notch_model/output/pdf/model_fit.pdf
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex

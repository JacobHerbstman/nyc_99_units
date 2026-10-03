.DELETE_ON_ERROR:

all: slides.pdf

slides.pdf: slides.tex Makefile references.bib \
	sections/intro_and_motivation.tex \
	sections/literature.tex \
	sections/data.tex \
	sections/empirical_results.tex \
	sections/model.tex \
	sections/discussion_and_conclusion.tex \
	sections/appendix_data.tex \
	sections/appendix_bunching.tex \
	sections/appendix_model.tex \
	../tasks/audits/audit_scale_shape_splitting/output/figure_guide_values.tex \
	../tasks/estimate_notch_model/output/model_values.tex \
	../tasks/presentation_figures/output/pdf/parent_bunching_2019_2022.pdf \
	../tasks/presentation_figures/output/pdf/parent_bunching_both_periods.pdf \
	images/wsj_50_99_unit_buildings.png images/kostiw_99_unit_filings.png \
	images/real_deal_bistricer_99_unit_playbook.png \
	../tasks/plot_bunching/output/pdf/parents_with_99_unit_constituents.pdf \
	../tasks/plot_bunching/output/pdf/splitting_by_year.pdf \
	../tasks/estimate_notch_model/output/pdf/model_fit.pdf \
	../tasks/plot_bunching/output/pdf/normalized_constituent_filing_distribution_50_300.pdf \
	../tasks/analyze_borough_bunching/output/borough_bunching.pdf
	pdflatex -halt-on-error -interaction=nonstopmode -draftmode slides.tex
	bibtex slides
	pdflatex -halt-on-error -interaction=nonstopmode -draftmode slides.tex
	pdflatex -halt-on-error -interaction=nonstopmode slides.tex

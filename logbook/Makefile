SHELL := /bin/bash
.DELETE_ON_ERROR:
.NOTPARALLEL:

all: logbook.pdf

logbook.pdf: entries/2026-09-10-estimation-readiness.tex \
	entries/2026-09-10-administrative-unit-priority.tex \
	entries/2026-09-10-dob-unit-comparison.tex \
	../tasks/audits/audit_estimation_parent_links/output/dob_unit_filings.csv \
	../tasks/audits/audit_estimation_parent_links/output/dob_unit_parents.csv \
	../tasks/audits/audit_estimation_parent_links/report/dob_unit_filings.txt \
	../tasks/audits/audit_estimation_parent_links/report/dob_unit_parents.txt \
	entries/2026-09-10-unit-boundaries.tex \
	entries/2026-09-10-refilings.tex \
	../tasks/audits/audit_estimation_parent_links/output/refilings.csv \
	../tasks/audits/audit_estimation_parent_links/report/refilings.txt \
	entries/2026-09-09-manual-parent-decisions.tex \
	../tasks/parent_opportunities_manual/output/pair_decisions.csv \
	../tasks/parent_opportunities_manual/output/unit_decisions.csv \
	entries/2026-09-09-companion-causes.tex \
	../tasks/audits/audit_estimation_parent_links/output/companion_link_trace.csv \
	../tasks/audits/audit_estimation_parent_links/report/companion_link_trace.txt \
	../tasks/audits/audit_estimation_parent_links/output/third_avenue_plan.png \
	entries/2026-09-09-ten-case-deep-review.tex \
	../tasks/audits/audit_estimation_parent_links/report/ten_case_deep_review.md \
	entries/2026-09-09-all-parent-links.tex \
	../tasks/audits/audit_estimation_parent_links/output/parent_casebook.md \
	../tasks/audits/audit_estimation_parent_links/report/parent_constituents.txt \
	../tasks/audits/audit_estimation_parent_links/report/nearby_filings.txt \
	entries/2026-09-09-parent-link-review.tex \
	../tasks/audits/audit_symmetric_parent_cohorts/report/2026-09-09-ten-pair-followup.md \
	../tasks/audits/audit_symmetric_parent_cohorts/report/2026-09-09-five-99-pairs.md \
	entries/2026-09-09-workflow-overhaul.tex \
	entries/2026-09-08-production-review.tex \
	entries/2026-09-08-lodes.tex \
	../tasks/audits/audit_lodes_construction_wages/output/workplace_earnings_maps.pdf \
	../tasks/audits/audit_lodes_construction_wages/report/findings.md \
	entries/2026-09-08-qcew.tex \
	../tasks/audits/audit_qcew_construction_wages/output/borough_construction_pay.pdf \
	../tasks/audits/audit_qcew_construction_wages/report/borough_construction_pay.txt \
	../tasks/audits/audit_acs_construction_wages/output/community_district_99_overlay.pdf \
	entries/2026-09-08-community-earnings.tex \
	../tasks/audits/audit_acs_construction_wages/output/community_district_earnings_map.pdf \
	../tasks/audits/audit_acs_construction_wages/report/community_district_findings.md \
	entries/2026-09-08-construction-earnings.tex \
	../tasks/audits/audit_acs_construction_wages/output/construction_earnings.pdf \
	../tasks/audits/audit_acs_construction_wages/output/tract_precision.pdf \
	../tasks/audits/audit_acs_construction_wages/report/feasibility.md \
	logbook.tex \
	entries/2026-09-07-framework.tex \
	entries/2026-09-08-boroughs.tex \
	../tasks/analyze_borough_bunching/output/borough_filings.pdf \
	../tasks/analyze_borough_bunching/output/borough_parents.pdf \
	../tasks/analyze_borough_bunching/report/geographic_filings.txt \
	Makefile
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex

../tasks/analyze_borough_bunching/output/borough_filings.pdf \
../tasks/analyze_borough_bunching/output/borough_parents.pdf \
../tasks/analyze_borough_bunching/report/geographic_filings.txt: check-analyze_borough_bunching ;

.PHONY: check-analyze_borough_bunching
check-analyze_borough_bunching:
	$(MAKE) --silent -C ../tasks/analyze_borough_bunching/code all ../output/borough_filings.pdf ../output/borough_parents.pdf ../report/geographic_filings.txt

../tasks/audits/audit_acs_construction_wages/output/community_district_99_overlay.pdf \
../tasks/audits/audit_acs_construction_wages/output/community_district_earnings_map.pdf \
../tasks/audits/audit_acs_construction_wages/report/community_district_findings.md \
../tasks/audits/audit_acs_construction_wages/output/construction_earnings.pdf \
../tasks/audits/audit_acs_construction_wages/output/tract_precision.pdf \
../tasks/audits/audit_acs_construction_wages/report/feasibility.md: check-audit_acs_construction_wages ;

.PHONY: check-audit_acs_construction_wages
check-audit_acs_construction_wages:
	$(MAKE) --silent -C ../tasks/audits/audit_acs_construction_wages/code all ../output/community_district_99_overlay.pdf ../output/community_district_earnings_map.pdf ../report/community_district_findings.md ../output/construction_earnings.pdf ../output/tract_precision.pdf ../report/feasibility.md

../tasks/audits/audit_qcew_construction_wages/output/borough_construction_pay.pdf \
../tasks/audits/audit_qcew_construction_wages/report/borough_construction_pay.txt: check-audit_qcew_construction_wages ;

.PHONY: check-audit_qcew_construction_wages
check-audit_qcew_construction_wages:
	$(MAKE) --silent -C ../tasks/audits/audit_qcew_construction_wages/code all ../output/borough_construction_pay.pdf ../report/borough_construction_pay.txt

../tasks/audits/audit_lodes_construction_wages/output/workplace_earnings_maps.pdf \
../tasks/audits/audit_lodes_construction_wages/report/findings.md: check-audit_lodes_construction_wages ;

.PHONY: check-audit_lodes_construction_wages
check-audit_lodes_construction_wages:
	$(MAKE) --silent -C ../tasks/audits/audit_lodes_construction_wages/code all ../output/workplace_earnings_maps.pdf ../report/findings.md

../tasks/audits/audit_estimation_parent_links/output/companion_link_trace.csv \
../tasks/audits/audit_estimation_parent_links/report/companion_link_trace.txt \
../tasks/audits/audit_estimation_parent_links/output/third_avenue_plan.png \
../tasks/audits/audit_estimation_parent_links/output/parent_casebook.md \
../tasks/audits/audit_estimation_parent_links/report/parent_constituents.txt \
../tasks/audits/audit_estimation_parent_links/report/nearby_filings.txt: check-audit_estimation_parent_links ;

.PHONY: check-audit_estimation_parent_links
check-audit_estimation_parent_links:
	$(MAKE) --silent -C ../tasks/audits/audit_estimation_parent_links/code all

../tasks/audits/audit_estimation_parent_links/output/refilings.csv ../tasks/audits/audit_estimation_parent_links/report/refilings.txt: check-audit_estimation_parent_links ;

../tasks/audits/audit_estimation_parent_links/output/dob_unit_filings.csv ../tasks/audits/audit_estimation_parent_links/output/dob_unit_parents.csv ../tasks/audits/audit_estimation_parent_links/report/dob_unit_filings.txt ../tasks/audits/audit_estimation_parent_links/report/dob_unit_parents.txt: check-audit_estimation_parent_links ;

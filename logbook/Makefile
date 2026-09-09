SHELL := /bin/bash
.DELETE_ON_ERROR:

all: logbook.pdf

logbook.pdf: entries/2026-09-08-lodes.tex ../tasks/audits/audit_lodes_construction_wages/output/workplace_earnings_maps.pdf ../tasks/audits/audit_lodes_construction_wages/report/findings.md entries/2026-09-08-qcew.tex ../tasks/audits/audit_qcew_construction_wages/output/borough_construction_pay.pdf ../tasks/audits/audit_qcew_construction_wages/report/borough_construction_pay.txt ../tasks/audits/audit_acs_construction_wages/output/community_district_99_overlay.pdf entries/2026-09-08-community-earnings.tex ../tasks/audits/audit_acs_construction_wages/output/community_district_earnings_map.pdf ../tasks/audits/audit_acs_construction_wages/report/community_district_findings.md entries/2026-09-08-construction-earnings.tex ../tasks/audits/audit_acs_construction_wages/output/construction_earnings.pdf ../tasks/audits/audit_acs_construction_wages/output/tract_precision.pdf ../tasks/audits/audit_acs_construction_wages/report/feasibility.md logbook.tex entries/2026-09-07-framework.tex entries/2026-09-08-boroughs.tex ../tasks/analyze_borough_bunching/output/borough_filings.pdf ../tasks/analyze_borough_bunching/output/borough_parents.pdf ../tasks/analyze_borough_bunching/report/geographic_filings.txt Makefile
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex
	pdflatex -interaction=nonstopmode -halt-on-error logbook.tex

../tasks/analyze_borough_bunching/output/borough_filings.pdf ../tasks/analyze_borough_bunching/output/borough_parents.pdf ../tasks/analyze_borough_bunching/report/geographic_filings.txt: FORCE_BOROUGH_CHECK
	$(MAKE) -C ../tasks/analyze_borough_bunching/code ../$(patsubst ../tasks/analyze_borough_bunching/%,%,$@)

.PHONY: FORCE_BOROUGH_CHECK
FORCE_BOROUGH_CHECK:

../tasks/audits/audit_acs_construction_wages/output/community_district_99_overlay.pdf ../tasks/audits/audit_acs_construction_wages/output/community_district_earnings_map.pdf ../tasks/audits/audit_acs_construction_wages/report/community_district_findings.md ../tasks/audits/audit_acs_construction_wages/output/construction_earnings.pdf ../tasks/audits/audit_acs_construction_wages/output/tract_precision.pdf ../tasks/audits/audit_acs_construction_wages/report/feasibility.md: FORCE_ACS_CHECK
	$(MAKE) -C ../tasks/audits/audit_acs_construction_wages/code ../$(patsubst ../tasks/audits/audit_acs_construction_wages/%,%,$@)

.PHONY: FORCE_ACS_CHECK
FORCE_ACS_CHECK:

../tasks/audits/audit_qcew_construction_wages/output/borough_construction_pay.pdf ../tasks/audits/audit_qcew_construction_wages/report/borough_construction_pay.txt: FORCE_QCEW_CHECK
	$(MAKE) -C ../tasks/audits/audit_qcew_construction_wages/code ../$(patsubst ../tasks/audits/audit_qcew_construction_wages/%,%,$@)

.PHONY: FORCE_QCEW_CHECK
FORCE_QCEW_CHECK:

../tasks/audits/audit_lodes_construction_wages/output/workplace_earnings_maps.pdf ../tasks/audits/audit_lodes_construction_wages/report/findings.md: FORCE_LODES_CHECK
	$(MAKE) -C ../tasks/audits/audit_lodes_construction_wages/code ../$(patsubst ../tasks/audits/audit_lodes_construction_wages/%,%,$@)

.PHONY: FORCE_LODES_CHECK
FORCE_LODES_CHECK:

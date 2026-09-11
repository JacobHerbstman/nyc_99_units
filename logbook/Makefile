SHELL := /bin/bash
.DELETE_ON_ERROR:
.NOTPARALLEL:

all: logbook.pdf

logbook.pdf: entries/2026-09-11-readable-workflow.tex \
	../tasks/build_parent_site_characteristics/report/historical_parent_site_characteristics.txt \
	../tasks/build_parent_site_characteristics/report/post_policy_parent_site_characteristics.txt \
	../tasks/build_estimation_panels/report/parent_opportunity_panel.txt \
	../tasks/audits/audit_scale_shape_splitting/output/calibration_summary.csv \
	../tasks/audits/audit_scale_shape_splitting/output/local_excess_deficit_moments.csv \
	../tasks/audits/audit_scale_shape_splitting/output/bootstrap_run_summary.csv \
	entries/2026-09-10-lean-production.tex \
	entries/2026-09-10-estimation-readiness.tex \
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

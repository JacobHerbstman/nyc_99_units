# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible, n_components > 1) |>
  arrange(sample, cohort_date, parent_id)
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id))
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
members <- membership |> semi_join(parents, by = "parent_id")
stopifnot(!anyDuplicated(members[c("sample", "root_job_id")]))
hdb_historical <- read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet") |>
  select(job_number, addressnum, addressst, classaprop, datelstupd, job_desc, latitude, longitude) |>
  mutate(across(c(classaprop, latitude, longitude), as.numeric),
    datelstupd = as.Date(datelstupd), sample = "historical", source_hdb_release = "23Q4")
hdb_post <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
  select(job_number, addressnum, addressst, classaprop, datelstupd, job_desc, latitude, longitude) |>
  mutate(across(c(classaprop, latitude, longitude), as.numeric),
    datelstupd = as.Date(datelstupd), sample = "post_policy", source_hdb_release = "25Q4")
hdb <- bind_rows(hdb_historical, hdb_post)
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
history <- read_parquet("../input/dob_now_new_building_filings.parquet")
historical <- read_parquet("../input/historical_parent_filing_link_fields.parquet")
links <- read_parquet("../input/symmetric_parent_links.parquet")
# Preserve the scope of each old review when the source change adds or removes filings.
baseline <- read_csv("prepolicy_baseline_filings_2026-09-22.csv",
  show_col_types = FALSE, col_types = cols(root_job_id = col_character()))
baseline_jobs <- baseline |> group_by(parent_id) |>
  summarise(baseline_jobs = paste(sort(root_job_id), collapse = ";"), .groups = "drop")
current_jobs <- membership |> filter(additive_component) |> group_by(parent_id) |>
  summarise(current_jobs = paste(sort(root_job_id), collapse = ";"), .groups = "drop")
evidence <- read_csv("parent_evidence.csv", show_col_types = FALSE) |>
  rename(original_parent_id = parent_id) |>
  mutate(sample = sub("__.*$", "", original_parent_id),
    root_job_id = sub("-I1$", "", sub("^.*__", "", original_parent_id))) |>
  left_join(membership |> select(sample, root_job_id, parent_id),
    by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  left_join(baseline |> select(sample, root_job_id, baseline_parent_id = parent_id),
    by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  left_join(baseline_jobs, by = c("baseline_parent_id" = "parent_id"), relationship = "many-to-one") |>
  left_join(current_jobs, by = "parent_id", relationship = "many-to-one") |>
  mutate(review_scope = case_when(!parent_id %in% parents$parent_id ~ "Outside current multi-parent sample",
    is.na(baseline_jobs) ~ "No dated filing-set comparison",
    baseline_jobs != current_jobs ~ "Filing set changed; prior evidence is partial",
    TRUE ~ "Filing set unchanged since dated baseline"))
stopifnot(!anyDuplicated(evidence$original_parent_id))
SaveData(evidence, "original_parent_id", "../output/parent_review_coverage.csv")
evidence <- evidence |> semi_join(parents, by = "parent_id") |>
  arrange(original_parent_id) |> group_by(parent_id) |>
  summarise(across(c(review_scope, verdict, finding, limitation, sources),
    ~ paste(unique(.x), collapse = " | ")), .groups = "drop")
evidence <- parents |> select(parent_id) |>
  left_join(evidence, by = "parent_id", relationship = "one-to-one") |>
  mutate(review_scope = coalesce(review_scope, "No individual review in this evidence table"),
    verdict = coalesce(verdict, "Unreviewed"),
    finding = coalesce(finding, "Current membership comes from the production linking rules."),
    limitation = coalesce(limitation, "Common development and complete site boundaries require review."),
    sources = coalesce(sources, "Archived administrative records below"))
neighbors <- read_csv("../output/nearby_filings.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(hdb[c("sample", "job_number")]), !anyDuplicated(dob$job_number),
  !anyDuplicated(historical$job_number), !anyDuplicated(evidence$parent_id),
  setequal(parents$parent_id, evidence$parent_id))

filings <- members |>
  left_join(hdb |> transmute(sample, root_job_id = job_number, source_hdb_release, hdb_address = paste(addressnum, addressst),
    hdb_units = classaprop, hdb_date_updated = datelstupd, hdb_description = job_desc,
    hdb_latitude = latitude, hdb_longitude = longitude), by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  left_join(dob |> transmute(root_job_id = job_number, dob_address = address,
    dob_initial_units = proposed_dwelling_units, dob_status = filing_status,
    dob_status_date = current_status_date, dob_bin = bin, dob_floor_area = total_construction_floor_area,
    dob_owner = paste(owner_business_name, owner_first_name, owner_last_name),
    dob_applicant = paste(applicant_first_name, applicant_last_name, applicant_business_name),
    dob_description = job_description, dob_latitude = latitude, dob_longitude = longitude),
    by = "root_job_id", relationship = "many-to-one") |>
  left_join(historical |> transmute(root_job_id = job_number, historical_owner = pluto_owner_name,
    historical_description = description), by = "root_job_id", relationship = "many-to-one") |>
  mutate(address = if_else(sample == "historical", hdb_address, coalesce(dob_address, hdb_address)),
    latitude = if_else(sample == "historical", hdb_latitude, coalesce(dob_latitude, hdb_latitude)),
    longitude = if_else(sample == "historical", hdb_longitude, coalesce(dob_longitude, hdb_longitude))) |>
  arrange(parent_id, date_filed, root_job_id)
totals <- filings |> filter(additive_component) |> group_by(parent_id) |>
  summarise(total = sum(units), count = n(), .groups = "drop")
check <- left_join(parents, totals, by = "parent_id", relationship = "one-to-one")
stopifnot(all(check$total == check$parent_total_units), all(check$count == check$n_components))
SaveData(filings, c("sample", "root_job_id"), "../output/parent_constituents.csv")

lines <- c(paste0("# Current ", nrow(parents), " multi-constituent estimation parents: evidence and outstanding questions"), "",
  "Historical outcomes use HDB 23Q4; post-period outcomes use HDB 25Q4 with DOB fallback. July 2026 DOB fields are retrospective comparison evidence. Individual findings record their public-source review dates.", "",
  "A supported connection does not establish the correct decision-date unit count, complete project boundary, or common legal wage assessment. The manual source task applies the documented decisions in production. Written reviews below are mapped through filing IDs. The scope label compares additive filing sets with the dated September 22 baseline. A changed set keeps the old findings as partial evidence, and newly entering parents remain unreviewed in this table. An unchanged set alone does not establish that every boundary or unit question is settled. Updated decisions and remaining questions are documented in report/ten_case_deep_review.md.", "")
refilings <- read_csv("../output/refilings.csv", show_col_types = FALSE)
lines <- c(lines, "## Refiling corrections", "",
  paste0("The full membership file contains ", nrow(refilings),
    " replacement pairs, including documented archived alternatives. Counting only their replacement filings removes ",
    sum(refilings$original_units), " duplicate units. Original proposal dates are retained; refiling dates are recorded separately."), "",
  "Historical automatic matches require the same archived BIN, lot and exact address, with one later nonwithdrawn application within the parent window. One documented historical alternative is applied from the manual source. The archive supplies withdrawal status, not its date. Post-period automatic matches require matching building, owner and applicant and a replacement filed after the observed withdrawal date. The original review findings below predate this correction where they discuss withdrawn duplicates.", "",
  "| Address | Original filing date | Refiling date | Original units removed | Replacement units retained |",
  "|---|---|---|---:|---:|")
for (j in seq_len(nrow(refilings))) lines <- c(lines, paste0("| ", refilings$address[j],
  " | ", refilings$original_filing_date[j], " | ", refilings$refiling_date[j],
  " | ", refilings$original_units[j], " | ", refilings$replacement_units[j], " |"))
lines <- c(lines, "", "### Nearby filings", "",
  paste0("The 200-metre, 365-day screen retains same-lot filings without a distance requirement. The current screen contains ", nrow(neighbors), " parent–filing pairs; ", sum(neighbors$review_decision == "Not individually adjudicated"), " lack an individual review in the original neighbor evidence table. Accepted companions are now inside their parents and no longer appear as external neighbors. Screen counts and missing coordinates are printed by the producing script."), "",
  "Different owner labels and unsuccessful searches do not prove independence. Cases with no additional connection established remain distinct from verified rejections. Filings outside the radius, year window, source coverage or recorded vintage may still be missing.", "",
  "| Existing parent | Nearby filing | Units | Finding |",
  "|---|---|---:|---|")
priority <- neighbors |> filter(review_scope == "Current multi-parent review",
  review_decision != "No additional connection established")
for (j in seq_len(nrow(priority))) lines <- c(lines, paste0("| ", priority$anchor_address[j],
  " | ", priority$neighbor_address[j], " (", priority$neighbor_job[j], ") | ",
  priority$neighbor_units[j], " | ", priority$review_decision[j], " |"))
lines <- c(lines, "", "## Individual case files", "")
for (i in seq_len(nrow(parents))) {
  p <- parents[i, ]
  f <- filter(filings, parent_id == p$parent_id)
  e <- filter(evidence, parent_id == p$parent_id)
  l <- links |> filter(sample == p$sample, job_number_1 %in% f$job_number, job_number_2 %in% f$job_number)
  lines <- c(lines, paste0("## ", i, ". ", p$component_addresses), "",
    paste0("**", p$sorted_component_vector, " = ", p$parent_total_units, " units**; anchor ", p$cohort_date, ". `", p$parent_id, "`."), "",
    paste0("**Evidence scope: ", e$review_scope, ".**"), "",
    paste0("**Prior finding: ", e$verdict, ".** ", e$finding), "", paste0("Remaining question: ", e$limitation), "",
    paste0("Evidence sources: ", e$sources), "",
    "| Filing | Date | Address | Panel units | Period HDB | July 2026 DOB I1 | Role |",
    "|---|---|---|---:|---:|---:|---|")
  for (j in seq_len(nrow(f))) {
    lines <- c(lines, paste0("| ", paste(c(f$root_job_id[j], as.character(f$date_filed[j]),
      f$address[j], f$units[j], f$hdb_units[j], f$dob_initial_units[j], f$filing_role[j]), collapse = " | "), " |"))
  }
  lines <- c(lines, "")
  for (j in seq_len(nrow(f))) {
    lines <- c(lines, paste0("- **", f$root_job_id[j], "**. Owner: ", f$dob_owner[j],
      "; historical parcel owner: ", f$historical_owner[j], "; applicant: ", f$dob_applicant[j],
      ". Filing lot: ", f$filing_bbl[j], "; linkage lot: ", f$site_linkage_bbl[j], "."),
      paste0("  DOB status: ", f$dob_status[j], " as of ", f$dob_status_date[j], "; BIN ", f$dob_bin[j], "."),
      paste0("  Description: ", if (p$sample == "historical") f$hdb_description[j] else coalesce(f$dob_description[j], f$hdb_description[j]), "."))
  }
  lines <- c(lines, "", "Recorded internal links:", "")
  for (j in seq_len(nrow(l))) lines <- c(lines, paste0("- ", l$job_number_1[j], " / ", l$job_number_2[j],
    ": ", l$link_reason[j], "; ", l$filing_days_apart[j], " days. Manual basis: ", l$review_basis[j], "."))
  differences <- history |> filter(job_number %in% f$root_job_id) |>
    select(job_filing_number, filing_date, proposed_dwelling_units, job_description)
  if (any(f$hdb_units != f$dob_initial_units, na.rm = TRUE)) {
    lines <- c(lines, "", "DOB records for parents with a source disagreement:", "")
    for (j in seq_len(nrow(differences))) lines <- c(lines, paste0("- ", differences$job_filing_number[j],
      " (", differences$filing_date[j], "): ", differences$proposed_dwelling_units[j],
      " units; ", differences$job_description[j]))
  }
  nearby <- neighbors |> filter(parent_id == p$parent_id)
  lines <- c(lines, "", "Nearby filings outside this parent:", "")
  if (nrow(nearby) == 0) lines <- c(lines, "No candidate in the recorded spatial/time window.")
  for (j in seq_len(nrow(nearby))) lines <- c(lines,
    paste0("- **", nearby$neighbor_address[j], "** (", nearby$neighbor_job[j], "): ",
      nearby$neighbor_units[j], " units, ", nearby$distance_metres[j], " metres, ",
      nearby$days_apart[j], " days apart. **", nearby$review_decision[j], ".** ",
      nearby$review_note[j]))
  lines <- c(lines, "")
}
writeLines(lines, "../output/parent_casebook.md")

# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible, n_components > 1) |>
  arrange(sample, cohort_date, parent_id)
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id))
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
members <- membership |> semi_join(parents, by = "parent_id")
stopifnot(!anyDuplicated(members[c("sample", "root_job_id")]))
hdb <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
history <- read_parquet("../input/dob_now_new_building_filings.parquet")
historical <- read_parquet("../input/historical_parent_filing_link_fields.parquet")
links <- read_parquet("../input/symmetric_parent_links.parquet")
evidence <- read_csv("parent_evidence.csv", show_col_types = FALSE) |>
  rename(original_parent_id = parent_id) |>
  mutate(job_number = sub("^.*__", "", original_parent_id)) |>
  left_join(membership |> select(job_number, parent_id), by = "job_number", relationship = "many-to-one")
stopifnot(!anyNA(evidence$parent_id))
evidence <- evidence |> semi_join(parents, by = "parent_id")
neighbors <- read_csv("../output/nearby_filings.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(hdb$job_number), !anyDuplicated(dob$job_number),
          !anyDuplicated(historical$job_number), !anyDuplicated(evidence$parent_id),
          setequal(parents$parent_id, evidence$parent_id))

filings <- members |>
  left_join(hdb |> transmute(root_job_id = job_number, hdb_address = paste(addressnum, addressst),
    hdb_units = classaprop, hdb_date_updated = datelstupd, hdb_description = job_desc,
    hdb_latitude = latitude, hdb_longitude = longitude), by = "root_job_id", relationship = "many-to-one") |>
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
    latitude = coalesce(dob_latitude, hdb_latitude), longitude = coalesce(dob_longitude, hdb_longitude)) |>
  arrange(parent_id, date_filed, root_job_id)
totals <- filings |> filter(additive_component) |> group_by(parent_id) |>
  summarise(total = sum(units), count = n(), .groups = "drop")
check <- left_join(parents, totals, by = "parent_id", relationship = "one-to-one")
stopifnot(all(check$total == check$parent_total_units), all(check$count == check$n_components))
write_csv(filings, "../output/parent_constituents.csv", na = "")

lines <- c(paste0("# Current ", nrow(parents), " multi-constituent estimation parents: evidence and outstanding questions"), "",
  "Reviewed against saved HDB 25Q4 and DOB July 2026 records. Public-source review dated September 9, 2026.", "",
  "A supported connection does not establish the correct decision-date unit count, complete project boundary, or common legal wage assessment. The manual source task applies the September 9 decisions in production. Original written reviews below are retained and mapped through filing IDs; new decisions and remaining questions are documented in report/ten_case_deep_review.md.", "")
withdrawn <- filings |> filter(dob_status == "Filing Withdrawn")
stopifnot(nrow(withdrawn) == 6, sum(withdrawn$units) == 368,
  n_distinct(withdrawn$parent_id) == 5)
for (j in seq_len(nrow(withdrawn))) {
  w <- withdrawn[j, ]
  replacement <- filings |> filter(parent_id == w$parent_id, dob_bin == w$dob_bin,
    root_job_id != w$root_job_id, date_filed > w$dob_status_date,
    dob_status != "Filing Withdrawn")
  stopifnot(nrow(replacement) == 1,
    replacement$dob_owner == w$dob_owner,
    replacement$dob_applicant == w$dob_applicant)
}
lines <- c(lines, "## What changes our confidence", "",
  "The original 76-parent review is preserved as source evidence. This casebook follows current membership after the manual decisions; retired parent IDs are mapped through their anchor filings. Public corroboration varies, and the written findings are not independent verification of every legal project.", "",
  "Six withdrawn applications are still summed with replacement applications in five parents, adding 368 units. Four of those parents appear to represent single buildings. Production now separates East 232nd, Boone, and provisionally Wilson/Boston; evidence and remaining affiliation limits appear in report/ten_case_deep_review.md. Several additional cases have incomplete boundaries or inconsistent unit measures.", "",
  "### Withdrawn applications counted again", "",
  "These are audit recommendations. The table removes withdrawn applications from the saved total; it does not choose a new cohort date or change production data.", "",
  "| Current parent | Saved total | Withdrawn units | Remaining units |",
  "|---|---:|---:|---:|")
for (id in unique(withdrawn$parent_id)) {
  p <- filter(parents, parent_id == id)
  removed <- sum(withdrawn$units[withdrawn$parent_id == id])
  lines <- c(lines, paste0("| ", p$component_addresses, " | ", p$parent_total_units,
    " | ", removed, " | ", p$parent_total_units - removed, " |"))
}
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
    paste0("**Review: ", e$verdict, ".** ", e$finding), "", paste0("Remaining question: ", e$limitation), "",
    paste0("Evidence sources: ", e$sources), "",
    "| Filing | Date | Address | Panel units | HDB | DOB I1 | Role |",
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
      paste0("  Description: ", coalesce(f$dob_description[j], f$historical_description[j], f$hdb_description[j]), "."))
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

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_acris_dof_deed_candidates/code")
# max_key_product <- 2500

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop("Usage: Rscript build_acris_dof_deed_candidates.R <max_key_product>")
}

max_key_product <- suppressWarnings(as.integer(args[1]))

if (is.na(max_key_product) || max_key_product <= 0) {
  stop("max_key_product must be a positive integer.")
}

sale_seeds <- read_parquet("../input/acris_opportunity_sale_seeds.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(!is.na(acris_master_exact_key), !is.na(sale_price), sale_price > 0)

deed_master <- read_parquet("../input/acris_deed_master.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(!is.na(acris_master_exact_key), !is.na(document_amt), document_amt > 0)

seed_key_counts <- sale_seeds |>
  count(acris_master_exact_key, name = "seed_rows")

deed_key_counts <- deed_master |>
  count(acris_master_exact_key, name = "deed_rows")

candidate_keys <- seed_key_counts |>
  inner_join(deed_key_counts, by = "acris_master_exact_key", relationship = "one-to-one") |>
  mutate(
    key_product = seed_rows * deed_rows,
    candidate_key_status = case_when(
      seed_rows == 1L & deed_rows == 1L ~ "unique_exact_key",
      key_product <= max_key_product ~ "ambiguous_exact_key_expanded",
      TRUE ~ "ambiguous_exact_key_not_expanded"
    )
  ) |>
  arrange(acris_master_exact_key)

expanded_keys <- candidate_keys |>
  filter(key_product <= max_key_product) |>
  mutate(expanded_key_order = row_number())

sale_seeds_selected <- sale_seeds |>
  inner_join(
    expanded_keys |>
      select(
        acris_master_exact_key, expanded_key_order, seed_rows_on_exact_key = seed_rows,
        deed_rows_on_exact_key = deed_rows, exact_key_product = key_product,
        candidate_key_status
      ),
    by = "acris_master_exact_key",
    relationship = "many-to-one"
  ) |>
  select(
    sale_record_id, seed_match_type, is_primary_opportunity_bbl,
    sale_bbl, sale_borough, sale_block, sale_lot, sale_date,
    sale_price, sale_quarter, condo_or_replatted_sale_lot,
    sale_address, sale_zip_code, building_class_category,
    building_class_at_time_of_sale, sale_land_square_feet, sale_gross_square_feet,
    acris_master_exact_key, expanded_key_order, seed_rows_on_exact_key,
    deed_rows_on_exact_key, exact_key_product, candidate_key_status
  ) |>
  arrange(expanded_key_order, sale_record_id)

deed_master_selected <- deed_master |>
  inner_join(
    expanded_keys |>
      select(acris_master_exact_key, expanded_key_order),
    by = "acris_master_exact_key",
    relationship = "many-to-one"
  ) |>
  select(
    document_id, crfn, recorded_borough, doc_type, document_date,
    document_amt, recorded_datetime, percent_trans, good_through_date,
    acris_master_exact_key, expanded_key_order
  ) |>
  arrange(expanded_key_order, document_id)

if (nrow(expanded_keys) == 0) {
  candidate_links_out <- tibble(
    sale_record_id = character(),
    seed_match_type = character(),
    is_primary_opportunity_bbl = logical(),
    sale_bbl = character(),
    sale_borough = character(),
    sale_block = integer(),
    sale_lot = integer(),
    sale_date = as.Date(character()),
    sale_price = numeric(),
    sale_quarter = character(),
    condo_or_replatted_sale_lot = logical(),
    sale_address = character(),
    sale_zip_code = character(),
    building_class_category = character(),
    building_class_at_time_of_sale = character(),
    sale_land_square_feet = numeric(),
    sale_gross_square_feet = numeric(),
    acris_master_exact_key = character(),
    document_id = character(),
    crfn = character(),
    recorded_borough = character(),
    doc_type = character(),
    document_date = as.Date(character()),
    document_amt = numeric(),
    recorded_datetime = as.POSIXct(character()),
    percent_trans = numeric(),
    good_through_date = as.Date(character()),
    seed_rows_on_exact_key = integer(),
    deed_rows_on_exact_key = integer(),
    exact_key_product = integer(),
    candidate_key_status = character(),
    candidate_link_grade = character()
  )
} else {
  sale_start <- cumsum(c(1L, head(expanded_keys$seed_rows, -1L)))
  deed_start <- cumsum(c(1L, head(expanded_keys$deed_rows, -1L)))
  output_start <- cumsum(c(1L, head(expanded_keys$key_product, -1L)))

  sale_row_index <- integer(sum(expanded_keys$key_product))
  deed_row_index <- integer(sum(expanded_keys$key_product))

  for (i in seq_len(nrow(expanded_keys))) {
    sale_rows_for_key <- sale_start[i]:(sale_start[i] + expanded_keys$seed_rows[i] - 1L)
    deed_rows_for_key <- deed_start[i]:(deed_start[i] + expanded_keys$deed_rows[i] - 1L)
    output_rows_for_key <- output_start[i]:(output_start[i] + expanded_keys$key_product[i] - 1L)

    sale_row_index[output_rows_for_key] <- rep(sale_rows_for_key, each = expanded_keys$deed_rows[i])
    deed_row_index[output_rows_for_key] <- rep(deed_rows_for_key, times = expanded_keys$seed_rows[i])
  }

  candidate_links_out <- bind_cols(
    sale_seeds_selected[sale_row_index, ],
    deed_master_selected[deed_row_index, ] |>
      select(-acris_master_exact_key, -expanded_key_order)
  ) |>
    mutate(candidate_link_grade = "exact_borough_date_amount_unvalidated_legal") |>
    select(-expanded_key_order)
}

not_expanded_keys <- candidate_keys |>
  filter(key_product > max_key_product)

if (nrow(not_expanded_keys) > 0) {
  not_expanded_rows <- sale_seeds |>
    inner_join(
      not_expanded_keys,
      by = "acris_master_exact_key",
      relationship = "many-to-one"
    ) |>
    transmute(
      sale_record_id, seed_match_type, is_primary_opportunity_bbl,
      sale_bbl, sale_borough, sale_block, sale_lot, sale_date,
      sale_price, sale_quarter, condo_or_replatted_sale_lot,
      sale_address, sale_zip_code, building_class_category,
      building_class_at_time_of_sale, sale_land_square_feet, sale_gross_square_feet,
      acris_master_exact_key,
      document_id = NA_character_,
      crfn = NA_character_,
      recorded_borough = NA_character_,
      doc_type = NA_character_,
      document_date = as.Date(NA),
      document_amt = NA_real_,
      recorded_datetime = as.POSIXct(NA),
      percent_trans = NA_real_,
      good_through_date = as.Date(NA),
      seed_rows_on_exact_key = seed_rows,
      deed_rows_on_exact_key = deed_rows,
      exact_key_product = key_product,
      candidate_key_status,
      candidate_link_grade = "exact_borough_date_amount_not_expanded"
    )

  candidate_links_out <- bind_rows(candidate_links_out, not_expanded_rows)
}

candidate_links_out <- candidate_links_out |>
  arrange(sale_date, sale_record_id, document_id)

if (any(!is.na(candidate_links_out$document_id) & duplicated(paste(candidate_links_out$sale_record_id, candidate_links_out$document_id, sep = "::")))) {
  stop("Expanded ACRIS-DOF candidate links duplicate sale_record_id/document_id.")
}

write_parquet_if_changed(candidate_links_out, "../output/acris_dof_deed_candidate_links.parquet")
cat("Wrote ACRIS-DOF DEED candidate links to ../output\n")

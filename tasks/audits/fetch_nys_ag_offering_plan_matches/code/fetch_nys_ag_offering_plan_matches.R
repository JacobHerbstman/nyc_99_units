# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_nys_ag_offering_plan_matches/code")
# source_pull_date_text <- "2026-08-26"
# batch_index <- 1L
# batch_count <- 27L

suppressPackageStartupMessages({
  library(dplyr)
  library(httr)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected the source pull date, batch index, and batch count.")
}

source_pull_date_text <- args[1]
source_pull_date <- as.Date(source_pull_date_text)
batch_index <- as.integer(args[2])
batch_count <- as.integer(args[3])

if (
  is.na(source_pull_date) ||
    is.na(batch_index) ||
    is.na(batch_count) ||
    batch_index < 1L ||
    batch_index > batch_count
) {
  stop("Source pull date or batch arguments are invalid.")
}

universe <- read_csv(
  "../input/parent_485x_exposure_universe.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

queries <- universe |>
  filter(!is.na(ag_search_query), ag_search_query != "") |>
  distinct(parent_id, root_job_id, ag_search_query) |>
  arrange(parent_id, root_job_id) |>
  mutate(query_index = row_number())

batch_size <- ceiling(nrow(queries) / batch_count)
batch_first_query <- (batch_index - 1L) * batch_size + 1L
batch_last_query <- min(batch_index * batch_size, nrow(queries))

queries <- queries |>
  filter(
    query_index >= batch_first_query,
    query_index <= batch_last_query
  ) |>
  select(-query_index)

if (
  nrow(queries) == 0L ||
    anyDuplicated(queries[c("parent_id", "root_job_id")])
) {
  stop("Attorney General search universe failed identifier QC.")
}

normalize_address <- function(x) {
  x |>
    str_to_upper() |>
    str_replace_all("[^A-Z0-9 ]", " ") |>
    str_replace_all("\\bSTREET\\b", "ST") |>
    str_replace_all("\\bAVENUE\\b", "AVE") |>
    str_replace_all("\\bBOULEVARD\\b", "BLVD") |>
    str_replace_all("\\bPLACE\\b", "PL") |>
    str_replace_all("\\bROAD\\b", "RD") |>
    str_replace_all("\\bDRIVE\\b", "DR") |>
    str_replace_all("\\bTERRACE\\b", "TER") |>
    str_replace_all("\\bPARKWAY\\b", "PKWY") |>
    str_squish()
}

extract_detail <- function(document, label) {
  xpath <- paste0(
    "(//strong[normalize-space(.)='",
    label,
    ":']/parent::td/following-sibling::td[1])[1]"
  )
  node <- html_element(document, xpath = xpath)
  if (inherits(node, "xml_missing")) {
    return(NA_character_)
  }
  value <- str_squish(html_text2(node))
  if_else(value == "", NA_character_, value)
}

base_url <- "https://offeringplandatasearch.ag.ny.gov/REF/"
search_url <- paste0(base_url, "search.action")
detail_url <- paste0(base_url, "planFormServlet")
web_handle <- handle(base_url)

welcome_response <- RETRY(
  "GET",
  paste0(base_url, "welcome.jsp"),
  handle = web_handle,
  timeout(60),
  times = 5,
  pause_base = 1,
  pause_cap = 10,
  quiet = FALSE
)
stop_for_status(welcome_response)

search_audit_rows <- vector("list", nrow(queries))
plan_match_rows <- list()
plan_detail_cache <- new.env(parent = emptyenv())
plan_match_index <- 0L

for (i in seq_len(nrow(queries))) {
  query_row <- queries[i, ]
  search_response <- RETRY(
    "POST",
    search_url,
    handle = web_handle,
    body = list(
      "searchForm.searchKeyword" = query_row$ag_search_query,
      "searchForm.searchType" = "searchByPlanId",
      "search_one" = "Search"
    ),
    encode = "form",
    timeout(60),
    times = 5,
    pause_base = 1,
    pause_cap = 10,
    quiet = FALSE
  )

  search_status <- status_code(search_response)
  if (search_status != 200L) {
    stop(
      "Attorney General search failed for ",
      query_row$parent_id,
      " with HTTP status ",
      search_status,
      "."
    )
  }

  search_document <- read_html(content(search_response, as = "text"))
  result_rows <- html_elements(search_document, "table#row tbody tr")
  result_rows <- result_rows[
    lengths(html_elements(result_rows, "td.plan_id")) > 0L
  ]
  if (length(result_rows) > 0L) {
    result_plan_ids <- vapply(
      result_rows,
      function(x) str_squish(html_text2(html_element(x, "td.plan_id"))),
      character(1)
    )
    result_rows <- result_rows[!is.na(result_plan_ids) & result_plan_ids != ""]
  }

  search_audit_rows[[i]] <- tibble(
    source_pull_date,
    parent_id = query_row$parent_id,
    root_job_id = query_row$root_job_id,
    search_query = query_row$ag_search_query,
    search_http_status = search_status,
    returned_plan_count = length(result_rows),
    search_source_url = search_url
  )

  if (length(result_rows) > 0L) {
    for (result_row in result_rows) {
      cells <- html_elements(result_row, "td")
      if (length(cells) < 4L) {
        stop("Attorney General result row has fewer than four cells.")
      }

      plan_id <- str_squish(html_text2(cells[1]))
      result_name <- str_squish(html_text2(cells[2]))
      result_address <- str_squish(html_text2(cells[3]))
      result_type <- str_squish(html_text2(cells[4]))

      if (!exists(plan_id, envir = plan_detail_cache, inherits = FALSE)) {
        detail_response <- RETRY(
          "POST",
          detail_url,
          handle = web_handle,
          body = list(
            returnSearchUrl = "search.action",
            planId = plan_id,
            searchKeyword = query_row$ag_search_query,
            searchType = "searchByPlanId"
          ),
          encode = "form",
          timeout(60),
          times = 5,
          pause_base = 1,
          pause_cap = 10,
          quiet = FALSE
        )
        stop_for_status(detail_response)
        detail_document <- read_html(content(detail_response, as = "text"))

        assign(
          plan_id,
          tibble(
            plan_id,
            plan_name = extract_detail(detail_document, "Name"),
            plan_address = extract_detail(detail_document, "Address"),
            plan_borough = extract_detail(detail_document, "Boro/County"),
            plan_type = extract_detail(detail_document, "Type"),
            construction_type = extract_detail(
              detail_document,
              "Construction"
            ),
            plan_units = suppressWarnings(as.integer(str_remove_all(
              extract_detail(detail_document, "Units"),
              "[^0-9]"
            ))),
            submitted_date = suppressWarnings(as.Date(
              extract_detail(detail_document, "Submitted Date"),
              format = "%m/%d/%Y"
            )),
            accepted_date = suppressWarnings(as.Date(
              extract_detail(detail_document, "Accepted Date"),
              format = "%m/%d/%Y"
            )),
            effective_date = suppressWarnings(as.Date(
              extract_detail(detail_document, "Effective Date"),
              format = "%m/%d/%Y"
            )),
            plan_action = extract_detail(detail_document, "Action"),
            plan_source_url = paste0(
              detail_url,
              "?planId=",
              plan_id
            )
          ),
          envir = plan_detail_cache
        )
        Sys.sleep(0.05)
      }

      plan_detail <- get(plan_id, envir = plan_detail_cache, inherits = FALSE)
      plan_match_index <- plan_match_index + 1L
      plan_match_rows[[plan_match_index]] <- bind_cols(
        tibble(
          source_pull_date,
          parent_id = query_row$parent_id,
          root_job_id = query_row$root_job_id,
          search_query = query_row$ag_search_query,
          result_name,
          result_address,
          result_type
        ),
        plan_detail
      ) |>
        mutate(
          normalized_search_address = normalize_address(search_query),
          normalized_plan_address = normalize_address(plan_address),
          exact_address_phrase_match =
            !is.na(normalized_plan_address) &
            (
              str_detect(
                normalized_plan_address,
                fixed(normalized_search_address)
              ) |
                str_detect(
                  normalized_search_address,
                  fixed(normalized_plan_address)
                )
            )
        )
    }
  }

  if (i %% 25L == 0L || i == nrow(queries)) {
    cat("Queried ", i, " of ", nrow(queries), " addresses\n", sep = "")
  }
  Sys.sleep(0.05)
}

search_audit <- bind_rows(search_audit_rows) |>
  arrange(parent_id, root_job_id)

if (length(plan_match_rows) == 0L) {
  plan_matches <- tibble(
    source_pull_date = as.Date(character()),
    parent_id = character(),
    root_job_id = character(),
    search_query = character(),
    result_name = character(),
    result_address = character(),
    result_type = character(),
    plan_id = character(),
    plan_name = character(),
    plan_address = character(),
    plan_borough = character(),
    plan_type = character(),
    construction_type = character(),
    plan_units = integer(),
    submitted_date = as.Date(character()),
    accepted_date = as.Date(character()),
    effective_date = as.Date(character()),
    plan_action = character(),
    plan_source_url = character(),
    normalized_search_address = character(),
    normalized_plan_address = character(),
    exact_address_phrase_match = logical()
  )
} else {
  plan_matches <- bind_rows(plan_match_rows) |>
    distinct(parent_id, root_job_id, plan_id, .keep_all = TRUE) |>
    arrange(parent_id, root_job_id, plan_id)
}

if (
  anyDuplicated(search_audit[c("parent_id", "root_job_id")]) ||
    anyDuplicated(plan_matches[c("parent_id", "root_job_id", "plan_id")])
) {
  stop("Attorney General outputs failed identifier QC.")
}

write_csv_if_changed(
  search_audit,
  paste0(
    "../output/nys_ag_offering_plan_search_audit_batch_",
    sprintf("%02d", batch_index),
    ".csv"
  )
)
write_csv_if_changed(
  plan_matches,
  paste0(
    "../output/nys_ag_offering_plan_matches_batch_",
    sprintf("%02d", batch_index),
    ".csv"
  )
)

cat(
  "Wrote batch ",
  batch_index,
  " of ",
  batch_count,
  ": ",
  nrow(search_audit),
  " address queries and ",
  nrow(plan_matches),
  " returned plans to ../output\n",
  sep = ""
)

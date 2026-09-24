# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_nys_ag_offering_plan_matches/code")
# query_scope <- "broad"

suppressPackageStartupMessages({
  library(dplyr)
  library(httr)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source("../../../shared/code/source_pipeline_utils.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  query_scope <- args[1]
}
stopifnot(query_scope %in% c("broad", "companions"))

source_pull_date <- as.Date("2026-09-22")
if (query_scope == "broad") {
  manifest_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_manifest_2019_2022.csv"
  )
  output_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_supplement_2019_2022.csv"
  )
} else {
  manifest_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_manifest_2023_companions.csv"
  )
  output_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_supplement_2023_companions.csv"
  )
}

if (file.exists(output_path)) {
  stop("The saved historical AG supplement already exists; use a new source date for a refresh.")
}

queries <- read_csv(
  manifest_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  arrange(root_job_id, search_query)

stopifnot(
  nrow(queries) > 0L,
  all(queries$sample == "historical"),
  !anyNA(queries[c("sample", "root_job_id", "search_query", "query_scope")]),
  !anyDuplicated(queries[c("sample", "root_job_id", "search_query")])
)

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
    "(//strong[normalize-space(.)='", label,
    ":']/parent::td/following-sibling::td[1])[1]"
  )
  node <- html_element(document, xpath = xpath)
  if (inherits(node, "xml_missing")) return(NA_character_)
  value <- str_squish(html_text2(node))
  if_else(value == "", NA_character_, value)
}

base_url <- "https://offeringplandatasearch.ag.ny.gov/REF/"
search_url <- paste0(base_url, "search.action")
detail_url <- paste0(base_url, "planFormServlet")
web_handle <- handle(base_url)

welcome_response <- RETRY(
  "GET", paste0(base_url, "welcome.jsp"), handle = web_handle,
  timeout(60), times = 5, pause_base = 1, pause_cap = 10
)
stop_for_status(welcome_response)

result_rows <- vector("list", nrow(queries))
plan_detail_cache <- new.env(parent = emptyenv())
dir.create("../temp", showWarnings = FALSE)
checkpoint_path <- paste0("../temp/historical_ag_query_progress_", query_scope, ".rds")
completed <- 0L
if (file.exists(checkpoint_path)) {
  checkpoint <- readRDS(checkpoint_path)
  if (!identical(checkpoint$queries, queries)) {
    stop("The query manifest changed after the AG fetch began.")
  }
  completed <- length(checkpoint$result_rows)
  if (completed > nrow(queries)) stop("The AG checkpoint exceeds the query manifest.")
  result_rows[seq_len(completed)] <- checkpoint$result_rows
  cat("Resuming after ", completed, " completed AG searches\n", sep = "")
}

for (i in seq.int(completed + 1L, nrow(queries), length.out = nrow(queries) - completed)) {
  query <- queries[i, ]
  response <- RETRY(
    "POST", search_url, handle = web_handle,
    body = list(
      "searchForm.searchKeyword" = query$search_query,
      "searchForm.searchType" = "searchByPlanId",
      "search_one" = "Search"
    ),
    encode = "form", timeout(60), times = 5,
    pause_base = 1, pause_cap = 10
  )
  stop_for_status(response)
  document <- read_html(content(response, as = "text"))

  search_field <- html_element(document, "input#search_searchForm_searchKeyword")
  result_table <- html_element(document, "table#row")
  if (inherits(search_field, "xml_missing") ||
      html_attr(search_field, "value") != query$search_query ||
      inherits(result_table, "xml_missing")) {
    stop("AG search did not return the expected result page for ", query$root_job_id)
  }

  page_links <- html_attr(html_elements(document, "a[href]"), "href")
  if (any(str_detect(page_links, "d-[0-9]+-p="), na.rm = TRUE)) {
    stop("AG search results require pagination for ", query$root_job_id)
  }

  plans <- html_elements(result_table, "tbody tr")
  plans <- plans[lengths(html_elements(plans, "td.plan_id")) > 0L]
  plan_ids <- vapply(plans, function(row) {
    str_squish(html_text2(html_element(row, "td.plan_id")))
  }, character(1))
  plans <- plans[!is.na(plan_ids) & plan_ids != ""]
  n_plans <- length(plans)

  if (n_plans == 0L && !any(str_detect(
    html_text2(html_elements(result_table, "tbody tr.empty")),
    fixed("Your search returned no results")
  ))) {
    stop("AG search returned no plan rows without an explicit no-results message for ",
         query$root_job_id)
  }

  query_fields <- tibble(
    source_pull_date,
    sample = query$sample,
    root_job_id = query$root_job_id,
    search_query = query$search_query,
    query_scope = query$query_scope,
    search_http_status = status_code(response),
    returned_plan_count = n_plans,
    search_source_url = search_url
  )

  if (n_plans == 0L) {
    result_rows[[i]] <- query_fields |>
      mutate(
        result_name = NA_character_, result_address = NA_character_,
        result_type = NA_character_, plan_id = NA_character_,
        plan_name = NA_character_, plan_address = NA_character_,
        plan_borough = NA_character_, plan_type = NA_character_,
        construction_type = NA_character_, plan_units = NA_integer_,
        submitted_date = as.Date(NA), accepted_date = as.Date(NA),
        effective_date = as.Date(NA), plan_action = NA_character_,
        plan_source_url = NA_character_,
        normalized_search_address = NA_character_,
        normalized_plan_address = NA_character_,
        exact_address_phrase_match = NA
      )
  } else {
    plan_rows <- vector("list", n_plans)
    for (j in seq_along(plans)) {
      cells <- html_elements(plans[[j]], "td")
      if (length(cells) < 4L) stop("AG search result has fewer than four cells.")
      plan_id <- str_squish(html_text2(cells[[1]]))
      if (is.na(plan_id) || plan_id == "") stop("AG search result lacks a plan ID.")

      if (!exists(plan_id, envir = plan_detail_cache, inherits = FALSE)) {
        detail_response <- RETRY(
          "POST", detail_url, handle = web_handle,
          body = list(
            returnSearchUrl = "search.action",
            planId = plan_id,
            searchKeyword = query$search_query,
            searchType = "searchByPlanId"
          ),
          encode = "form", timeout(60), times = 5,
          pause_base = 1, pause_cap = 10
        )
        stop_for_status(detail_response)
        detail <- read_html(content(detail_response, as = "text"))
        plan_name <- extract_detail(detail, "Name")
        if (is.na(plan_name)) stop("AG plan detail lacks a name: ", plan_id)

        assign(plan_id, tibble(
          plan_id,
          plan_name,
          plan_address = extract_detail(detail, "Address"),
          plan_borough = extract_detail(detail, "Boro/County"),
          plan_type = extract_detail(detail, "Type"),
          construction_type = extract_detail(detail, "Construction"),
          plan_units = suppressWarnings(as.integer(str_remove_all(
            extract_detail(detail, "Units"), "[^0-9]"
          ))),
          submitted_date = suppressWarnings(as.Date(
            extract_detail(detail, "Submitted Date"), format = "%m/%d/%Y"
          )),
          accepted_date = suppressWarnings(as.Date(
            extract_detail(detail, "Accepted Date"), format = "%m/%d/%Y"
          )),
          effective_date = suppressWarnings(as.Date(
            extract_detail(detail, "Effective Date"), format = "%m/%d/%Y"
          )),
          plan_action = extract_detail(detail, "Action"),
          plan_source_url = paste0(detail_url, "?planId=", plan_id)
        ), envir = plan_detail_cache)
        Sys.sleep(0.05)
      }

      plan_rows[[j]] <- bind_cols(
        query_fields,
        tibble(
          result_name = str_squish(html_text2(cells[[2]])),
          result_address = str_squish(html_text2(cells[[3]])),
          result_type = str_squish(html_text2(cells[[4]]))
        ),
        get(plan_id, envir = plan_detail_cache)
      ) |>
        mutate(
          normalized_search_address = normalize_address(search_query),
          normalized_plan_address = normalize_address(plan_address),
          exact_address_phrase_match = !is.na(normalized_plan_address) &
            (str_detect(normalized_plan_address, fixed(normalized_search_address)) |
              str_detect(normalized_search_address, fixed(normalized_plan_address)))
        )
    }
    result_rows[[i]] <- bind_rows(plan_rows)
  }

  checkpoint_temp <- tempfile(tmpdir = "../temp")
  saveRDS(list(queries = queries, result_rows = result_rows[seq_len(i)]),
          checkpoint_temp)
  if (!file.rename(checkpoint_temp, checkpoint_path)) {
    stop("Could not save the AG query checkpoint.")
  }

  if (i %% 25L == 0L || i == nrow(queries)) {
    cat("Queried ", i, " of ", nrow(queries), " historical addresses\n", sep = "")
  }
  Sys.sleep(0.05)
}

supplement <- bind_rows(result_rows) |>
  arrange(root_job_id, search_query, plan_id)

stopifnot(
  n_distinct(supplement$root_job_id) == nrow(queries),
  !anyDuplicated(supplement[c("sample", "root_job_id", "search_query", "plan_id")]),
  all(supplement$search_http_status == 200L),
  all(supplement$returned_plan_count >= 0L)
)

write_csv_atomic(supplement, output_path)
unlink(checkpoint_path)
cat("Saved ", nrow(queries), " searches and ",
    sum(!is.na(supplement$plan_id)), " plan rows to ", output_path, "\n", sep = "")

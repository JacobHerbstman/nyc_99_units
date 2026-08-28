# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_150_threshold/code")
# pre_start_year <- 2011L
# pre_end_year <- 2022L
# normal_start_year <- 2017L
# normal_end_year <- 2019L
# post_start_date_text <- "2025-01-01"
# threshold_units <- 150L
# plot_min_units <- 100L
# plot_max_units <- 250L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 8L) {
  stop(
    "Expected pre start/end years, normal start/end years, post start date, ",
    "threshold units, and plot minimum/maximum units."
  )
}

pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
normal_start_year <- as.integer(args[3])
normal_end_year <- as.integer(args[4])
post_start_date_text <- args[5]
post_start_date <- as.Date(post_start_date_text)
threshold_units <- as.integer(args[6])
plot_min_units <- as.integer(args[7])
plot_max_units <- as.integer(args[8])

if (
  any(is.na(c(
    pre_start_year,
    pre_end_year,
    normal_start_year,
    normal_end_year,
    post_start_date,
    threshold_units,
    plot_min_units,
    plot_max_units
  ))) ||
    pre_start_year > normal_start_year ||
    normal_start_year > normal_end_year ||
    normal_end_year > pre_end_year ||
    plot_min_units >= threshold_units ||
    threshold_units >= plot_max_units
) {
  stop("The 150-threshold audit arguments are not internally consistent.")
}

exposure <- read_csv(
  "../input/parent_485x_exposure.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

universe <- read_csv(
  "../input/parent_485x_exposure_universe.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

hpd_links <- read_csv(
  "../input/hpd_485x_registration_dob_links.csv",
  show_col_types = FALSE,
  guess_max = Inf
)

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

dob <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  anyDuplicated(exposure[c("sample", "parent_id")]) ||
    anyDuplicated(universe[c("sample", "root_job_id")]) ||
    anyDuplicated(dob$job_number) ||
    nrow(anti_join(
      exposure,
      universe |> distinct(sample, parent_id),
      by = c("sample", "parent_id")
    )) > 0L ||
    nrow(anti_join(
      universe |> distinct(sample, parent_id),
      exposure,
      by = c("sample", "parent_id")
    )) > 0L
) {
  stop("Exposure, universe, or DOB identifiers failed pre-join QC.")
}

post_end_dates <- membership |>
  filter(sample == "post_policy") |>
  distinct(source_end_date) |>
  pull(source_end_date)

if (length(post_end_dates) != 1L || is.na(post_end_dates)) {
  stop("Post-policy source end date is missing or inconsistent.")
}

post_end_date <- post_end_dates[1]
pre_years <- pre_end_year - pre_start_year + 1L
normal_years <- normal_end_year - normal_start_year + 1L
post_years <- as.numeric(post_end_date - post_start_date + 1L) / 365.25

dob_location <- dob |>
  transmute(
    root_job_id = job_number,
    dob_nta = nta,
    dob_latitude = latitude,
    dob_longitude = longitude
  )

hpd_component <- hpd_links |>
  filter(is_latest_building_response, !is.na(matched_dob_root_job_id)) |>
  transmute(
    root_job_id = matched_dob_root_job_id,
    hpd_response_number = response_number,
    hpd_reported_units = reported_units,
    hpd_reported_option = str_to_upper(str_squish(
      reported_affordability_option
    )),
    hpd_reported_address = reported_property_address
  )

if (anyDuplicated(hpd_component$root_job_id)) {
  stop("Latest HPD registration evidence is not unique by DOB root job.")
}

zone_a_outer_ntas <- c(
  "Greenpoint",
  "Williamsburg",
  "South Williamsburg",
  "East Williamsburg",
  "Long Island City-Hunters Point"
)

zone_b_ntas <- c(
  "Brooklyn Heights",
  "Downtown Brooklyn-DUMBO-Boerum Hill",
  "Fort Greene",
  "Clinton Hill",
  "Carroll Gardens-Cobble Hill-Gowanus-Red Hook",
  "Park Slope",
  "Prospect Heights",
  "Old Astoria-Hallets Point",
  "Queensbridge-Ravenswood-Dutch Kills"
)

manhattan_north_of_96_ntas <- c(
  "East Harlem (North)",
  "East Harlem (South)",
  "Hamilton Heights-Sugar Hill",
  "Harlem (North)",
  "Harlem (South)",
  "Inwood",
  "Manhattanville-West Harlem",
  "Upper West Side-Manhattan Valley",
  "Washington Heights (North)",
  "Washington Heights (South)"
)

component_location <- universe |>
  left_join(
    dob_location,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    hpd_component,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    component_150_zone = case_when(
      borough_name == "Manhattan" &
        !is.na(dob_nta) &
        dob_nta %in% manhattan_north_of_96_ntas ~ "Outside Zones A/B",
      borough_name == "Manhattan" & !is.na(dob_nta) ~ "Zone A",
      dob_nta %in% zone_a_outer_ntas ~ "Zone A",
      dob_nta %in% zone_b_ntas ~ "Zone B",
      !is.na(dob_nta) ~ "Outside Zones A/B",
      sample == "historical" ~ "Historical NTA unavailable",
      TRUE ~ "Unresolved NTA"
    )
  )

parent_location <- component_location |>
  group_by(sample, parent_id) |>
  summarise(
    nta_2020 = paste(sort(unique(na.omit(dob_nta))), collapse = ";"),
    zone_150_categories = paste(
      sort(unique(component_150_zone)),
      collapse = ";"
    ),
    component_unit_counts = paste(sort(component_units), collapse = "+"),
    exact_99_components = sum(component_units == 99L),
    hpd_registered_components_check = sum(!is.na(hpd_response_number)),
    hpd_option_a_components = sum(hpd_reported_option == "OPTION A", na.rm = TRUE),
    hpd_option_b_components = sum(hpd_reported_option == "OPTION B", na.rm = TRUE),
    hpd_registration_components = paste(
      paste0(
        root_job_id[!is.na(hpd_response_number)],
        ":",
        hpd_reported_option[!is.na(hpd_response_number)],
        ":",
        hpd_reported_units[!is.na(hpd_response_number)]
      ),
      collapse = ";"
    ),
    .groups = "drop"
  ) |>
  mutate(
    zone_150 = case_when(
      str_detect(zone_150_categories, ";") ~ "Mixed or unresolved",
      TRUE ~ zone_150_categories
    ),
    parent_150_with_option_b_component = hpd_option_b_components > 0L
  )

parents <- exposure |>
  left_join(
    parent_location,
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    unit_band = case_when(
      parent_total_units < 100L ~ "6–99",
      parent_total_units < threshold_units ~ "100–149",
      parent_total_units < 200L ~ "150–199",
      parent_total_units < 300L ~ "200–299",
      TRUE ~ "300+"
    ),
    threshold_band = if_else(
      parent_total_units < threshold_units,
      "100–149",
      "150+"
    ),
    ownership_sector = case_when(
      government_owner ~ "Government",
      str_detect(
        str_to_upper(ownership_types),
        "NON-PROFIT|NONPROFIT"
      ) ~ "Nonprofit",
      TRUE ~ "Private or other"
    )
  )

scoped_parents <- bind_rows(
  parents |> mutate(sample_scope = "All 6+ parents"),
  parents |>
    filter(included_ab) |>
    mutate(sample_scope = "A/B rental opportunities"),
  parents |>
    filter(included_ab_plus_d) |>
    mutate(sample_scope = "A/B + Option D opportunities")
)

period_rows <- bind_rows(
  scoped_parents |>
    filter(
      sample == "historical",
      cohort_year >= pre_start_year,
      cohort_year <= pre_end_year
    ) |>
    mutate(
      period = paste0(pre_start_year, "–", pre_end_year),
      exposure_years = as.numeric(pre_years)
    ),
  scoped_parents |>
    filter(
      sample == "historical",
      cohort_year >= normal_start_year,
      cohort_year <= normal_end_year
    ) |>
    mutate(
      period = paste0(normal_start_year, "–", normal_end_year),
      exposure_years = as.numeric(normal_years)
    ),
  scoped_parents |>
    filter(
      sample == "post_policy",
      cohort_date >= post_start_date,
      cohort_date <= post_end_date
    ) |>
    mutate(
      period = paste0(
        "2025–",
        format(post_end_date, "%Y-%m-%d")
      ),
      exposure_years = post_years
    )
)

period_levels <- unique(period_rows$period)

period_summary <- period_rows |>
  filter(parent_total_units >= 100L) |>
  count(
    sample_scope,
    period,
    exposure_years,
    threshold_band,
    name = "parent_count"
  ) |>
  mutate(
    parents_per_year = parent_count / exposure_years,
    period = factor(period, levels = period_levels)
  ) |>
  arrange(sample_scope, period, threshold_band)

exact_distribution <- period_rows |>
  filter(
    period != paste0(pre_start_year, "–", pre_end_year),
    parent_total_units >= plot_min_units,
    parent_total_units <= plot_max_units
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    parent_total_units,
    name = "parent_count"
  ) |>
  complete(
    sample_scope,
    period = factor(period, levels = period_levels[-1]),
    parent_total_units = seq.int(plot_min_units, plot_max_units),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    period_rows |>
      filter(period != paste0(pre_start_year, "–", pre_end_year)) |>
      distinct(period, exposure_years),
    by = "period",
    relationship = "many-to-one",
    suffix = c("", "_period")
  ) |>
  mutate(
    exposure_years = coalesce(exposure_years, exposure_years_period),
    parents_per_year = parent_count / exposure_years
  ) |>
  select(-exposure_years_period) |>
  arrange(sample_scope, period, parent_total_units)

component_rows <- component_location |>
  left_join(
    exposure |>
      select(
        sample,
        parent_id,
        included_ab,
        included_ab_plus_d
      ),
    by = c("sample", "parent_id"),
    relationship = "many-to-one"
  )

scoped_components <- bind_rows(
  component_rows |> mutate(sample_scope = "All 6+ parents"),
  component_rows |>
    filter(included_ab) |>
    mutate(sample_scope = "A/B rental opportunities"),
  component_rows |>
    filter(included_ab_plus_d) |>
    mutate(sample_scope = "A/B + Option D opportunities")
)

component_period_rows <- bind_rows(
  scoped_components |>
    filter(
      sample == "historical",
      cohort_year >= normal_start_year,
      cohort_year <= normal_end_year
    ) |>
    mutate(
      period = paste0(normal_start_year, "–", normal_end_year),
      exposure_years = as.numeric(normal_years)
    ),
  scoped_components |>
    filter(
      sample == "post_policy",
      cohort_date >= post_start_date,
      cohort_date <= post_end_date
    ) |>
    mutate(
      period = paste0("2025–", format(post_end_date, "%Y-%m-%d")),
      exposure_years = post_years
    )
)

component_exact_distribution <- component_period_rows |>
  filter(
    component_units >= plot_min_units,
    component_units <= plot_max_units
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    component_units,
    name = "component_count"
  ) |>
  complete(
    sample_scope,
    period = factor(period, levels = period_levels[-1]),
    component_units = seq.int(plot_min_units, plot_max_units),
    fill = list(component_count = 0L)
  ) |>
  left_join(
    component_period_rows |>
      distinct(period, exposure_years),
    by = "period",
    relationship = "many-to-one",
    suffix = c("", "_period")
  ) |>
  mutate(
    exposure_years = coalesce(exposure_years, exposure_years_period),
    components_per_year = component_count / exposure_years
  ) |>
  select(-exposure_years_period) |>
  arrange(sample_scope, period, component_units)

parent_component_comparison <- bind_rows(
  period_rows |>
    filter(
      period != paste0(pre_start_year, "–", pre_end_year),
      parent_total_units >= 100L
    ) |>
    transmute(
      sample_scope,
      period,
      exposure_years,
      aggregation_level = "Linked parent",
      analysis_units = parent_total_units
    ),
  component_period_rows |>
    filter(component_units >= 100L) |>
    transmute(
      sample_scope,
      period,
      exposure_years,
      aggregation_level = "Component filing",
      analysis_units = component_units
    )
) |>
  mutate(
    threshold_band = if_else(
      analysis_units < threshold_units,
      "100–149",
      "150+"
    )
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    aggregation_level,
    threshold_band,
    name = "observation_count"
  ) |>
  mutate(observations_per_year = observation_count / exposure_years) |>
  arrange(sample_scope, aggregation_level, threshold_band, period)

post_150 <- parents |>
  filter(
    sample == "post_policy",
    cohort_date >= post_start_date,
    cohort_date <= post_end_date,
    parent_total_units >= threshold_units
  )

post_150_scoped <- bind_rows(
  post_150 |> mutate(sample_scope = "All 6+ parents"),
  post_150 |>
    filter(included_ab) |>
    mutate(sample_scope = "A/B rental opportunities"),
  post_150 |>
    filter(included_ab_plus_d) |>
    mutate(sample_scope = "A/B + Option D opportunities")
)

post_composition <- bind_rows(
  post_150_scoped |>
    transmute(sample_scope, dimension = "borough", category = boroughs),
  post_150_scoped |>
    transmute(sample_scope, dimension = "150_wage_zone", category = zone_150),
  post_150_scoped |>
    transmute(
      sample_scope,
      dimension = "exposure_status",
      category = exposure_status
    ),
  post_150_scoped |>
    transmute(sample_scope, dimension = "unit_band", category = unit_band),
  post_150_scoped |>
    transmute(
      sample_scope,
      dimension = "ownership_sector",
      category = ownership_sector
    ),
  post_150_scoped |>
    transmute(
      sample_scope,
      dimension = "cohort_year",
      category = as.character(cohort_year)
    ),
  post_150_scoped |>
    transmute(
      sample_scope,
      dimension = "linkage",
      category = if_else(
        component_filings == 1L,
        "Single filing",
        "Multiple linked filings"
      )
    )
) |>
  count(sample_scope, dimension, category, name = "parent_count") |>
  group_by(sample_scope, dimension) |>
  mutate(
    share = parent_count / sum(parent_count),
    parents_per_year = parent_count / post_years
  ) |>
  ungroup() |>
  arrange(sample_scope, dimension, desc(parent_count), category)

borough_comparison <- period_rows |>
  filter(
    period != paste0(pre_start_year, "–", pre_end_year),
    parent_total_units >= 100L
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    boroughs,
    threshold_band,
    name = "parent_count"
  ) |>
  mutate(parents_per_year = parent_count / exposure_years) |>
  arrange(sample_scope, threshold_band, boroughs, period)

ownership_comparison <- period_rows |>
  filter(
    period != paste0(pre_start_year, "–", pre_end_year),
    parent_total_units >= 100L
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    ownership_sector,
    threshold_band,
    name = "parent_count"
  ) |>
  mutate(parents_per_year = parent_count / exposure_years) |>
  arrange(sample_scope, threshold_band, ownership_sector, period)

post_parent_cases <- post_150 |>
  select(
    parent_id,
    cohort_date,
    parent_total_units,
    component_filings,
    component_unit_counts,
    exact_99_components,
    addresses,
    boroughs,
    nta_2020,
    zone_150,
    ownership_sector,
    ownership_types,
    owner_names,
    exposure_status,
    included_ab,
    included_ab_plus_d,
    confidence,
    classification_reason,
    hpd_registered_components,
    hpd_options,
    hpd_registered_components_check,
    hpd_option_a_components,
    hpd_option_b_components,
    hpd_registration_components,
    parent_150_with_option_b_component,
    ag_market_homeownership,
    ag_market_plan_ids
  ) |>
  arrange(parent_total_units, cohort_date, parent_id)

linkage_qc <- period_rows |>
  filter(parent_total_units >= 100L) |>
  mutate(
    linkage = if_else(
      component_filings == 1L,
      "Single filing",
      "Multiple linked filings"
    )
  ) |>
  count(
    sample_scope,
    period,
    exposure_years,
    threshold_band,
    linkage,
    name = "parent_count"
  ) |>
  group_by(sample_scope, period, threshold_band) |>
  mutate(
    share = parent_count / sum(parent_count),
    parents_per_year = parent_count / exposure_years
  ) |>
  ungroup() |>
  arrange(sample_scope, period, threshold_band, linkage)

hpd_registration_qc <- post_150 |>
  transmute(
    parent_id,
    parent_total_units,
    component_filings,
    hpd_registered_components,
    hpd_registered_components_check,
    hpd_option_a_components,
    hpd_option_b_components,
    hpd_registration_components,
    parent_150_with_option_b_component,
    exposure_status,
    confidence,
    addresses,
    boroughs
  ) |>
  arrange(
    desc(parent_150_with_option_b_component),
    desc(hpd_registered_components),
    parent_total_units,
    parent_id
  )

yearly_parent_rows <- membership |>
  filter(
    (
      sample == "historical" &
        cohort_year >= normal_start_year &
        cohort_year <= pre_end_year
    ) |
      (
        sample == "post_policy" &
          cohort_year > pre_end_year
      ),
    parent_observed_units >= 6L
  ) |>
  group_by(sample, parent_id) |>
  summarise(
    cohort_year = first(cohort_year),
    parent_total_units = first(parent_observed_units),
    component_filings = n(),
    contains_exact_99_component = any(units == 99L),
    all_components_below_150 = all(units < threshold_units),
    left_window_observed = first(left_window_observed),
    right_window_observed = first(right_window_observed),
    full_window_observed = first(full_window_observed),
    .groups = "drop"
  ) |>
  left_join(
    exposure |>
      select(sample, parent_id, included_ab),
    by = c("sample", "parent_id"),
    relationship = "one-to-one"
  )

scoped_yearly_parent_rows <- bind_rows(
  yearly_parent_rows |>
    mutate(sample_scope = "All 6+ parents"),
  yearly_parent_rows |>
    filter(included_ab) |>
    mutate(sample_scope = "A/B rental opportunities")
)

yearly_component_rows <- membership |>
  filter(
    (
      sample == "historical" &
        cohort_year >= normal_start_year &
        cohort_year <= pre_end_year
    ) |
      (
        sample == "post_policy" &
          cohort_year > pre_end_year
      ),
    units >= threshold_units
  ) |>
  left_join(
    exposure |>
      select(sample, parent_id, included_ab),
    by = c("sample", "parent_id"),
    relationship = "many-to-one"
  )

yearly_component_150 <- bind_rows(
  yearly_component_rows |>
    mutate(sample_scope = "All 6+ parents"),
  yearly_component_rows |>
    filter(included_ab) |>
    mutate(sample_scope = "A/B rental opportunities")
) |>
  count(
    sample_scope,
    sample,
    cohort_year,
    name = "component_filings_150_plus"
  )

yearly_linkage_diagnostic <- scoped_yearly_parent_rows |>
  group_by(sample_scope, sample, cohort_year) |>
  summarise(
    parent_count_6_plus = n(),
    multi_parent_count_6_plus = sum(component_filings > 1L),
    multi_parent_share_6_plus = mean(component_filings > 1L),
    parent_count_150_plus = sum(parent_total_units >= threshold_units),
    single_parent_count_150_plus = sum(
      parent_total_units >= threshold_units & component_filings == 1L
    ),
    multi_parent_count_150_plus = sum(
      parent_total_units >= threshold_units & component_filings > 1L
    ),
    multi_parent_share_150_plus =
      multi_parent_count_150_plus / parent_count_150_plus,
    multi_parent_150_plus_with_99 = sum(
      parent_total_units >= threshold_units &
        component_filings > 1L &
        contains_exact_99_component
    ),
    multi_parent_150_plus_all_components_below_150 = sum(
      parent_total_units >= threshold_units &
        component_filings > 1L &
        all_components_below_150
    ),
    parents_with_complete_linkage_window = sum(full_window_observed),
    all_left_windows_observed = all(left_window_observed),
    all_right_windows_observed = all(right_window_observed),
    .groups = "drop"
  ) |>
  left_join(
    yearly_component_150,
    by = c("sample_scope", "sample", "cohort_year"),
    relationship = "one-to-one"
  ) |>
  mutate(
    component_filings_150_plus = coalesce(
      component_filings_150_plus,
      0L
    ),
    source_system = if_else(
      sample == "historical",
      "DCP Housing Database",
      "DOB NOW"
    )
  ) |>
  arrange(sample_scope, cohort_year, sample)

if (
  any(!is.finite(period_summary$parents_per_year)) ||
    anyDuplicated(exact_distribution[
      c("sample_scope", "period", "parent_total_units")
    ]) ||
    any(!is.finite(exact_distribution$parents_per_year)) ||
    anyDuplicated(component_exact_distribution[
      c("sample_scope", "period", "component_units")
    ]) ||
    any(!is.finite(component_exact_distribution$components_per_year)) ||
    anyDuplicated(yearly_linkage_diagnostic[
      c("sample_scope", "sample", "cohort_year")
    ]) ||
    any(is.na(yearly_parent_rows$included_ab)) ||
    any(!is.finite(yearly_linkage_diagnostic$multi_parent_share_150_plus)) ||
    any(is.na(post_parent_cases$zone_150)) ||
    any(
      post_parent_cases$hpd_registered_components !=
        post_parent_cases$hpd_registered_components_check
    ) ||
    sum(post_parent_cases$parent_total_units < threshold_units) > 0L
) {
  stop("The 150-threshold audit failed final QC.")
}

write_csv_if_changed(
  period_summary,
  "../output/parent_150_period_summary.csv"
)
write_csv_if_changed(
  exact_distribution,
  "../output/parent_150_exact_distribution.csv"
)
write_csv_if_changed(
  component_exact_distribution,
  "../output/parent_150_component_exact_distribution.csv"
)
write_csv_if_changed(
  parent_component_comparison,
  "../output/parent_150_parent_component_comparison.csv"
)
write_csv_if_changed(
  post_composition,
  "../output/parent_150_post_composition.csv"
)
write_csv_if_changed(
  borough_comparison,
  "../output/parent_150_borough_comparison.csv"
)
write_csv_if_changed(
  ownership_comparison,
  "../output/parent_150_ownership_comparison.csv"
)
write_csv_if_changed(
  post_parent_cases,
  "../output/parent_150_post_parent_cases.csv"
)
write_csv_if_changed(
  hpd_registration_qc,
  "../output/parent_150_hpd_registration_qc.csv"
)
write_csv_if_changed(
  linkage_qc,
  "../output/parent_150_linkage_qc.csv"
)
write_csv_if_changed(
  yearly_linkage_diagnostic,
  "../output/parent_150_yearly_linkage_diagnostic.csv"
)

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels[-1]

exact_figure <- exact_distribution |>
  filter(sample_scope %in% c(
    "All 6+ parents",
    "A/B rental opportunities"
  )) |>
  ggplot(aes(
    x = parent_total_units,
    y = parents_per_year,
    color = period,
    group = period
  )) +
  geom_vline(
    xintercept = threshold_units,
    color = "grey30",
    linetype = "dashed"
  ) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 1) +
  facet_wrap(~ sample_scope, ncol = 1, scales = "free_y") +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = seq(plot_min_units, plot_max_units, by = 10L),
    minor_breaks = seq.int(plot_min_units, plot_max_units),
    limits = c(plot_min_units, plot_max_units)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Parent-development sizes around the 150-unit threshold",
    subtitle = paste0(
      "Annualized parent counts: ", normal_start_year, "–",
      normal_end_year, " versus Jan. 1, 2025–",
      format(post_end_date, "%b. %d, %Y")
    ),
    x = "Total proposed units in the parent development",
    y = "Parent developments per observed year",
    color = NULL,
    caption = paste0(
      "One-unit bins. Dashed line marks the ", threshold_units,
      "-unit Option A threshold."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
    plot.caption = element_text(hjust = 0, color = "grey35"),
    plot.title.position = "plot",
    strip.text = element_text(face = "bold", hjust = 0)
  )

temp_exact <- tempfile(fileext = ".png")
ggsave(
  temp_exact,
  exact_figure,
  width = 11,
  height = 8.5,
  dpi = 180,
  bg = "white"
)
copy_if_changed(
  temp_exact,
  "../output/parent_150_exact_distribution_annualized.png"
)

component_figure <- component_exact_distribution |>
  filter(sample_scope %in% c(
    "All 6+ parents",
    "A/B rental opportunities"
  )) |>
  ggplot(aes(
    x = component_units,
    y = components_per_year,
    color = period,
    group = period
  )) +
  geom_vline(
    xintercept = threshold_units,
    color = "grey30",
    linetype = "dashed"
  ) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 1) +
  facet_wrap(~ sample_scope, ncol = 1, scales = "free_y") +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = seq(plot_min_units, plot_max_units, by = 10L),
    minor_breaks = seq.int(plot_min_units, plot_max_units),
    limits = c(plot_min_units, plot_max_units)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Component-filing sizes around the 150-unit threshold",
    subtitle = paste0(
      "Annualized component counts: ", normal_start_year, "–",
      normal_end_year, " versus Jan. 1, 2025–",
      format(post_end_date, "%b. %d, %Y")
    ),
    x = "Proposed units in the component filing",
    y = "Component filings per observed year",
    color = NULL,
    caption = paste0(
      "One-unit bins. Components need not equal statutory eligible sites. ",
      "Dashed line marks ", threshold_units, " units."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_line(color = "grey92", linewidth = 0.25),
    plot.caption = element_text(hjust = 0, color = "grey35"),
    plot.title.position = "plot",
    strip.text = element_text(face = "bold", hjust = 0)
  )

temp_component <- tempfile(fileext = ".png")
ggsave(
  temp_component,
  component_figure,
  width = 11,
  height = 8.5,
  dpi = 180,
  bg = "white"
)
copy_if_changed(
  temp_component,
  "../output/parent_150_component_exact_distribution_annualized.png"
)

borough_figure <- borough_comparison |>
  filter(
    sample_scope == "A/B rental opportunities",
    threshold_band == "150+"
  ) |>
  ggplot(aes(
    x = reorder(boroughs, parents_per_year),
    y = parents_per_year,
    fill = period
  )) +
  geom_col(position = position_dodge(width = 0.8), width = 0.72) +
  coord_flip() +
  scale_fill_manual(values = period_colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Where did the 150-plus rental-opportunity increase occur?",
    subtitle = "Annualized linked-parent counts by borough",
    x = NULL,
    y = "A/B rental opportunities per observed year",
    fill = NULL,
    caption = paste0(
      "Historical comparison is ", normal_start_year, "–",
      normal_end_year, "; post period is Jan. 1, 2025–",
      format(post_end_date, "%b. %d, %Y"), "."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(hjust = 0, color = "grey35"),
    plot.title.position = "plot"
  )

temp_borough <- tempfile(fileext = ".png")
ggsave(
  temp_borough,
  borough_figure,
  width = 10,
  height = 6.5,
  dpi = 180,
  bg = "white"
)
copy_if_changed(
  temp_borough,
  "../output/parent_150_borough_comparison_annualized.png"
)

yearly_linkage_figure <- yearly_linkage_diagnostic |>
  select(
    sample_scope,
    cohort_year,
    `All 6+ parents` = multi_parent_share_6_plus,
    `Parents totaling 150+` = multi_parent_share_150_plus
  ) |>
  pivot_longer(
    cols = -c(sample_scope, cohort_year),
    names_to = "parent_scope",
    values_to = "multi_parent_share"
  ) |>
  ggplot(aes(
    x = cohort_year,
    y = multi_parent_share,
    color = parent_scope,
    group = parent_scope
  )) +
  geom_vline(xintercept = 2024.3, color = "grey45", linetype = "dashed") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  facet_wrap(~ sample_scope, ncol = 1) +
  scale_color_manual(values = c(
    "All 6+ parents" = "#4C78A8",
    "Parents totaling 150+" = "#E45756"
  )) +
  scale_x_continuous(breaks = seq(normal_start_year, 2026L)) +
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 1),
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "Multi-filing parents become concentrated above 150 units",
    subtitle = "Share of linked parents containing more than one filing",
    x = "Parent cohort year",
    y = "Multi-filing share",
    color = NULL,
    caption = paste0(
      "Dashed line marks the April 2024 enactment of 485-x. ",
      "Historical DCP parents through 2022; consistently linked DOB NOW ",
      "parents from 2023. The 2023 and 2024 cohorts have complete symmetric ",
      "365-day windows; 2026 is partial."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(hjust = 0, color = "grey35"),
    plot.title.position = "plot"
  )

temp_yearly_linkage <- tempfile(fileext = ".png")
ggsave(
  temp_yearly_linkage,
  yearly_linkage_figure,
  width = 10,
  height = 8.5,
  dpi = 180,
  bg = "white"
)
copy_if_changed(
  temp_yearly_linkage,
  "../output/parent_150_yearly_multi_filing_share.png"
)

cat(
  "Audited ",
  nrow(post_parent_cases),
  " post-policy parents at or above ",
  threshold_units,
  " units\n",
  sep = ""
)

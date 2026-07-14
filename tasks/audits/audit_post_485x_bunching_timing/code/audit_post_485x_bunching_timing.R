# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_post_485x_bunching_timing/code")
# policy_start_date <- as.Date("2024-04-20")
# first_period_end_date <- as.Date("2024-12-31")
# second_period_end_date <- as.Date("2025-06-30")
# third_period_end_date <- as.Date("2025-12-31")
# sample_end_date <- as.Date("2026-07-08")
# min_units <- 6L
# plot_min_units <- 50L
# plot_max_units <- 150L
# parent_plot_max_units <- 400L
# bunch_units <- 99L
# local_window_radius <- 9L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 11L) {
  stop(
    "Expected five sample dates, four unit bounds, the bunching unit, and ",
    "the local-window radius."
  )
}

policy_start_date <- as.Date(args[1])
first_period_end_date <- as.Date(args[2])
second_period_end_date <- as.Date(args[3])
third_period_end_date <- as.Date(args[4])
sample_end_date <- as.Date(args[5])
min_units <- as.integer(args[6])
plot_min_units <- as.integer(args[7])
plot_max_units <- as.integer(args[8])
parent_plot_max_units <- as.integer(args[9])
bunch_units <- as.integer(args[10])
local_window_radius <- as.integer(args[11])

if (
  any(is.na(c(
    policy_start_date, first_period_end_date, second_period_end_date,
    third_period_end_date, sample_end_date, min_units, plot_min_units,
    plot_max_units, parent_plot_max_units, bunch_units,
    local_window_radius
  ))) ||
    policy_start_date > first_period_end_date ||
    first_period_end_date >= second_period_end_date ||
    second_period_end_date >= third_period_end_date ||
    third_period_end_date >= sample_end_date ||
    min_units < 1L ||
    plot_min_units < min_units ||
    plot_max_units <= bunch_units ||
    parent_plot_max_units < 4L * bunch_units ||
    local_window_radius < 1L ||
    bunch_units - local_window_radius < min_units
) {
  stop("Post-485-x timing arguments are not internally consistent.")
}

universal_membership <- read_parquet(
  "../input/provisional_parent_universal_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

universal_links <- read_parquet(
  "../input/provisional_parent_universal_links.parquet"
) |>
  as.data.frame() |>
  as_tibble()

scoreable_membership <- read_csv(
  "../input/provisional_parent_membership.csv",
  show_col_types = FALSE
)

if (
  nrow(universal_membership) == 0L ||
    anyDuplicated(universal_membership$root_job_id) ||
    anyDuplicated(universal_links[c("root_job_id_1", "root_job_id_2")]) ||
    anyDuplicated(scoreable_membership$job_number) ||
    min(universal_membership$proposed_units) < min_units ||
    sample_end_date != max(universal_membership$filing_date)
) {
  stop("Post-485-x timing inputs failed identifier or sample-end QC.")
}

period_definitions <- tibble(
  period_order = 1L:4L,
  period_start = c(
    policy_start_date,
    first_period_end_date + 1L,
    second_period_end_date + 1L,
    third_period_end_date + 1L
  ),
  period_end = c(
    first_period_end_date,
    second_period_end_date,
    third_period_end_date,
    sample_end_date
  ),
  period_label = c(
    "Apr 20-Dec 2024",
    "Jan-Jun 2025",
    "Jul-Dec 2025",
    "Jan-Jul 8, 2026"
  )
) |>
  mutate(exposure_days = as.integer(period_end - period_start) + 1L)

jobs <- universal_membership |>
  filter(
    filing_date >= policy_start_date,
    filing_date <= sample_end_date
  ) |>
  mutate(
    period_order = case_when(
      filing_date <= first_period_end_date ~ 1L,
      filing_date <= second_period_end_date ~ 2L,
      filing_date <= third_period_end_date ~ 3L,
      TRUE ~ 4L
    )
  ) |>
  left_join(
    period_definitions,
    by = "period_order",
    relationship = "many-to-one"
  )

parents <- universal_membership |>
  distinct(
    provisional_parent_opportunity_id,
    parent_structure,
    all_dob_root_jobs,
    all_dob_proposed_units,
    all_dob_exact_99_jobs,
    all_dob_distinct_bins,
    all_dob_distinct_bbls,
    first_filing_date,
    last_filing_date,
    root_job_ids
  ) |>
  filter(
    first_filing_date >= policy_start_date,
    first_filing_date <= sample_end_date
  ) |>
  mutate(
    period_order = case_when(
      first_filing_date <= first_period_end_date ~ 1L,
      first_filing_date <= second_period_end_date ~ 2L,
      first_filing_date <= third_period_end_date ~ 3L,
      TRUE ~ 4L
    )
  ) |>
  left_join(
    period_definitions,
    by = "period_order",
    relationship = "many-to-one"
  )

if (
  nrow(jobs) == 0L ||
    nrow(parents) == 0L ||
    n_distinct(jobs$period_order) != 4L ||
    n_distinct(parents$period_order) != 4L ||
    anyDuplicated(parents$provisional_parent_opportunity_id)
) {
  stop("Post-policy job or parent cohorts failed construction QC.")
}

filing_distribution <- expand_grid(
  period_order = period_definitions$period_order,
  proposed_units = plot_min_units:plot_max_units
) |>
  left_join(
    jobs |>
      filter(
        proposed_units >= plot_min_units,
        proposed_units <= plot_max_units
      ) |>
      count(period_order, proposed_units, name = "filings"),
    by = c("period_order", "proposed_units"),
    relationship = "one-to-one"
  ) |>
  left_join(
    period_definitions,
    by = "period_order",
    relationship = "many-to-one"
  ) |>
  mutate(
    filings = coalesce(filings, 0L),
    annualized_filings = filings * 365 / exposure_days,
    exact_99 = proposed_units == bunch_units,
    period_label = factor(
      period_label,
      levels = period_definitions$period_label
    )
  )

parent_distribution <- expand_grid(
  period_order = period_definitions$period_order,
  parent_units = plot_min_units:parent_plot_max_units
) |>
  left_join(
    parents |>
      filter(
        all_dob_proposed_units >= plot_min_units,
        all_dob_proposed_units <= parent_plot_max_units
      ) |>
      count(
        period_order,
        parent_units = all_dob_proposed_units,
        name = "parents"
      ),
    by = c("period_order", "parent_units"),
    relationship = "one-to-one"
  ) |>
  left_join(
    period_definitions,
    by = "period_order",
    relationship = "many-to-one"
  ) |>
  mutate(
    parents = coalesce(parents, 0L),
    annualized_parents = parents * 365 / exposure_days,
    multiple_of_99 = parent_units %in% (bunch_units * 1L:4L),
    period_label = factor(
      period_label,
      levels = period_definitions$period_label
    )
  )

nearby_units <- c(
  (bunch_units - local_window_radius):(bunch_units - 1L),
  (bunch_units + 1L):(bunch_units + local_window_radius)
)

filing_summary <- jobs |>
  group_by(period_order) |>
  summarise(
    all_filings = n(),
    filings_50_150 = sum(
      proposed_units >= plot_min_units & proposed_units <= plot_max_units
    ),
    exact_99_filings = sum(proposed_units == bunch_units),
    nearby_filings = sum(proposed_units %in% nearby_units),
    .groups = "drop"
  ) |>
  left_join(
    period_definitions,
    by = "period_order",
    relationship = "one-to-one"
  ) |>
  mutate(
    exact_99_share_50_150 = exact_99_filings / filings_50_150,
    annualized_exact_99_filings = exact_99_filings * 365 / exposure_days,
    nearby_integer_bins = length(nearby_units),
    mean_filings_per_nearby_integer =
      nearby_filings / nearby_integer_bins,
    exact_99_to_nearby_bin_ratio =
      exact_99_filings / mean_filings_per_nearby_integer
  )

parent_summary <- parents |>
  group_by(period_order) |>
  summarise(
    parent_cohorts = n(),
    multi_job_parents = sum(all_dob_root_jobs > 1L),
    exact_99_parents = sum(all_dob_proposed_units == bunch_units),
    exact_198_parents = sum(all_dob_proposed_units == 2L * bunch_units),
    exact_297_parents = sum(all_dob_proposed_units == 3L * bunch_units),
    exact_396_parents = sum(all_dob_proposed_units == 4L * bunch_units),
    .groups = "drop"
  )

timing_summary <- filing_summary |>
  left_join(parent_summary, by = "period_order", relationship = "one-to-one") |>
  arrange(period_order)

parent_year_inventory <- universal_membership |>
  group_by(provisional_parent_opportunity_id) |>
  summarise(
    parent_member_years = paste(sort(unique(filing_year)), collapse = ";"),
    parent_member_jobs = n(),
    parent_members_outside_2025 = sum(filing_year != 2025L),
    parent_has_members_outside_2025 = any(filing_year != 2025L),
    parent_member_units = paste(
      proposed_units[order(filing_date, root_job_id)],
      collapse = ";"
    ),
    .groups = "drop"
  )

parent_link_signals <- universal_links |>
  left_join(
    universal_membership |>
      select(
        root_job_id_1 = root_job_id,
        provisional_parent_opportunity_id_1 =
          provisional_parent_opportunity_id
      ),
    by = "root_job_id_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    universal_membership |>
      select(
        root_job_id_2 = root_job_id,
        provisional_parent_opportunity_id_2 =
          provisional_parent_opportunity_id
      ),
    by = "root_job_id_2",
    relationship = "many-to-one"
  )

if (any(
  parent_link_signals$provisional_parent_opportunity_id_1 !=
    parent_link_signals$provisional_parent_opportunity_id_2
)) {
  stop("A universal link edge crosses provisional parent components.")
}

parent_link_signals <- parent_link_signals |>
  group_by(
    provisional_parent_opportunity_id =
      provisional_parent_opportunity_id_1
  ) |>
  summarise(
    parent_link_edges = n(),
    link_same_filing_bbl = any(same_filing_bbl),
    link_same_lot_history_group = any(same_lot_history_group),
    link_same_owner_nearby = any(same_owner_nearby),
    link_description_cross_reference = any(description_cross_reference),
    link_same_description_project_code = any(
      same_description_project_code
    ),
    .groups = "drop"
  )

exact_99_parent_paths <- scoreable_membership |>
  filter(observed_units == bunch_units) |>
  left_join(
    parent_year_inventory,
    by = "provisional_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    parent_link_signals,
    by = "provisional_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    parent_link_edges = coalesce(parent_link_edges, 0L),
    across(
      starts_with("link_"),
      ~ coalesce(.x, FALSE)
    ),
    survives_as_exact_99_parent = observed_parent_units == bunch_units,
    removed_from_exact_99_parent_mass = !survives_as_exact_99_parent
  ) |>
  select(
    provisional_parent_opportunity_id,
    parent_structure,
    job_number,
    date_filed,
    observed_units,
    dob_proposed_units,
    all_dob_root_jobs,
    all_dob_proposed_units,
    all_dob_exact_99_jobs,
    scoreable_parent_members,
    fixed_companion_units,
    observed_parent_units,
    parent_member_years,
    parent_member_jobs,
    parent_members_outside_2025,
    parent_has_members_outside_2025,
    parent_member_units,
    parent_link_edges,
    link_same_filing_bbl,
    link_same_lot_history_group,
    link_same_owner_nearby,
    link_description_cross_reference,
    link_same_description_project_code,
    survives_as_exact_99_parent,
    removed_from_exact_99_parent_mass
  ) |>
  arrange(parent_structure, provisional_parent_opportunity_id, job_number)

frontier_decomposition <- exact_99_parent_paths |>
  group_by(parent_structure) |>
  summarise(
    exact_99_filings = n(),
    provisional_parents = n_distinct(provisional_parent_opportunity_id),
    exact_99_filings_surviving_parent_aggregation = sum(
      survives_as_exact_99_parent
    ),
    exact_99_filings_removed_by_parent_aggregation = sum(
      removed_from_exact_99_parent_mass
    ),
    removed_filings_with_outside_2025_companions = sum(
      removed_from_exact_99_parent_mass & parent_has_members_outside_2025
    ),
    removed_filings_with_only_2025_companions = sum(
      removed_from_exact_99_parent_mass & !parent_has_members_outside_2025
    ),
    .groups = "drop"
  ) |>
  bind_rows(
    exact_99_parent_paths |>
      summarise(
        parent_structure = "all_exact_99_filings",
        exact_99_filings = n(),
        provisional_parents = n_distinct(
          provisional_parent_opportunity_id
        ),
        exact_99_filings_surviving_parent_aggregation = sum(
          survives_as_exact_99_parent
        ),
        exact_99_filings_removed_by_parent_aggregation = sum(
          removed_from_exact_99_parent_mass
        ),
        removed_filings_with_outside_2025_companions = sum(
          removed_from_exact_99_parent_mass &
            parent_has_members_outside_2025
        ),
        removed_filings_with_only_2025_companions = sum(
          removed_from_exact_99_parent_mass &
            !parent_has_members_outside_2025
        )
      )
  )

frontier_link_signal_decomposition <- exact_99_parent_paths |>
  filter(removed_from_exact_99_parent_mass) |>
  select(
    provisional_parent_opportunity_id,
    job_number,
    link_same_filing_bbl,
    link_same_lot_history_group,
    link_same_owner_nearby,
    link_description_cross_reference,
    link_same_description_project_code
  ) |>
  pivot_longer(
    cols = starts_with("link_"),
    names_to = "link_signal",
    values_to = "parent_has_signal"
  ) |>
  filter(parent_has_signal) |>
  group_by(link_signal) |>
  summarise(
    removed_exact_99_filings_in_parents_with_signal = n(),
    provisional_parents_with_signal = n_distinct(
      provisional_parent_opportunity_id
    ),
    .groups = "drop"
  ) |>
  mutate(
    link_signal_label = recode(
      link_signal,
      link_same_filing_bbl = "Same filing BBL",
      link_same_lot_history_group = "Same MapPLUTO lot-history group",
      link_same_owner_nearby = "Same owner within 100 meters",
      link_description_cross_reference = "DOB description cross-reference",
      link_same_description_project_code = "Same DOB project code"
    ),
    .before = link_signal
  ) |>
  arrange(desc(removed_exact_99_filings_in_parents_with_signal), link_signal)

timing_qc <- bind_rows(
  tibble(
    metric = c(
      "universal_jobs_2024_2026",
      "sample_jobs_policy_start_through_end",
      "sample_exact_99_jobs",
      "universal_provisional_parents",
      "policy_cohort_provisional_parents",
      "scoreable_2025_hdb_exact_99_filings",
      "scoreable_exact_99_filings_removed_at_parent_scale",
      "scoreable_exact_99_filings_surviving_at_parent_scale"
    ),
    value = c(
      nrow(universal_membership),
      nrow(jobs),
      sum(jobs$proposed_units == bunch_units),
      n_distinct(
        universal_membership$provisional_parent_opportunity_id
      ),
      nrow(parents),
      nrow(exact_99_parent_paths),
      sum(exact_99_parent_paths$removed_from_exact_99_parent_mass),
      sum(exact_99_parent_paths$survives_as_exact_99_parent)
    )
  ),
  period_definitions |>
    transmute(
      metric = paste0("period_", period_order, "_exposure_days"),
      value = exposure_days
    )
)

filing_annotations <- filing_distribution |>
  filter(proposed_units == bunch_units) |>
  transmute(
    period_label,
    proposed_units,
    annualized_filings,
    annotation = paste0("99: ", filings, " filings")
  )

filing_plot <- ggplot(
  filing_distribution,
  aes(x = proposed_units, y = annualized_filings, fill = exact_99)
) +
  geom_col(width = 0.9) +
  geom_vline(
    xintercept = bunch_units + 0.5,
    color = "#D95F02",
    linewidth = 0.55,
    linetype = "dashed"
  ) +
  geom_text(
    data = filing_annotations,
    aes(
      x = proposed_units,
      y = annualized_filings,
      label = annotation
    ),
    inherit.aes = FALSE,
    color = "#D95F02",
    hjust = -0.08,
    vjust = -0.35,
    size = 3.1
  ) +
  facet_wrap(vars(period_label), ncol = 2L) +
  scale_fill_manual(values = c(`FALSE` = "#9A9A9A", `TRUE` = "#D95F02")) +
  scale_x_continuous(
    breaks = c(plot_min_units, 75L, bunch_units, 125L, plot_max_units),
    expand = expansion(mult = c(0.01, 0.03))
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  guides(fill = "none") +
  labs(
    title = "The 99-unit filing spike is present throughout the 485-x period",
    subtitle = paste0(
      "Initial DOB NOW New Building filings; counts annualized by each ",
      "panel's exact number of calendar days"
    ),
    x = "Proposed dwelling units",
    y = "Annualized filings",
    caption = paste0(
      "Sample: April 20, 2024 through July 8, 2026; initial New Building ",
      "filings proposing 6-1,000 units. Dashed line marks the 100-unit ",
      "threshold boundary."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

parent_plot <- ggplot(
  parent_distribution,
  aes(x = parent_units, y = annualized_parents, fill = multiple_of_99)
) +
  geom_col(width = 0.9) +
  geom_vline(
    xintercept = bunch_units * 1L:4L,
    color = "#D95F02",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  facet_wrap(vars(period_label), ncol = 2L) +
  scale_fill_manual(values = c(`FALSE` = "#9A9A9A", `TRUE` = "#D95F02")) +
  scale_x_continuous(
    breaks = c(plot_min_units, bunch_units * 1L:4L),
    expand = expansion(mult = c(0.01, 0.03))
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  guides(fill = "none") +
  labs(
    title = "Provisional aggregation shifts some 99-unit filings to 198 and above",
    subtitle = paste0(
      "Parent cohorts are dated by first filing; totals include all linked ",
      "companions observed through July 8, 2026"
    ),
    x = "Observed provisional-parent dwelling units",
    y = "Annualized parent cohorts",
    caption = paste0(
      "These connected components are audit constructs, not validated legal ",
      "485-x sites. Later cohorts are more right-censored. Orange bars and ",
      "lines mark multiples of 99."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

timing_plot_rows <- bind_rows(
  timing_summary |>
    transmute(
      period_order,
      period_label,
      measure = "Exact 99 share among 50-150 unit filings",
      value = exact_99_share_50_150,
      label = percent(exact_99_share_50_150, accuracy = 0.1)
    ),
  timing_summary |>
    transmute(
      period_order,
      period_label,
      measure = "Exact 99 relative to the mean nearby integer bin",
      value = exact_99_to_nearby_bin_ratio,
      label = paste0(number(exact_99_to_nearby_bin_ratio, accuracy = 0.1), "x")
    )
) |>
  mutate(
    period_label = factor(
      period_label,
      levels = period_definitions$period_label
    )
  )

timing_plot <- ggplot(
  timing_plot_rows,
  aes(x = period_label, y = value, group = 1L)
) +
  geom_line(color = "#1769AA", linewidth = 0.75) +
  geom_point(color = "#1769AA", size = 2.4) +
  geom_text(
    aes(label = label),
    color = "#1769AA",
    vjust = -0.8,
    size = 3.2
  ) +
  facet_wrap(vars(measure), ncol = 1L, scales = "free_y") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.20))) +
  labs(
    title = "Bunching is visible before, during, and after 2025",
    subtitle = paste0(
      "The 99 share is persistent; the nearby-bin ratio is large but noisy ",
      "because most nearby integer counts are sparse"
    ),
    x = NULL,
    y = NULL,
    caption = paste0(
      "Nearby bins are ", bunch_units - local_window_radius, "-",
      bunch_units - 1L, " and ", bunch_units + 1L, "-",
      bunch_units + local_window_radius, ". The first panel is a share; ",
      "the second is a ratio and uses a separate scale."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    axis.text.x = element_text(angle = 20, hjust = 1),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(timing_summary) != 4L ||
    sum(timing_summary$all_filings) != nrow(jobs) ||
    sum(timing_summary$exact_99_filings) !=
      sum(jobs$proposed_units == bunch_units) ||
    nrow(exact_99_parent_paths) !=
      sum(scoreable_membership$observed_units == bunch_units) ||
    nrow(frontier_decomposition) !=
      n_distinct(exact_99_parent_paths$parent_structure) + 1L ||
    nrow(frontier_link_signal_decomposition) == 0L ||
    any(!is.finite(timing_summary$exact_99_to_nearby_bin_ratio)) ||
    sum(exact_99_parent_paths$survives_as_exact_99_parent) != 19L
) {
  stop("Post-485-x timing outputs failed final QC.")
}

write_csv_if_changed(
  timing_summary,
  "../output/post_485x_bunching_timing_summary.csv"
)
write_csv_if_changed(
  frontier_decomposition,
  "../output/provisional_frontier_decomposition.csv"
)
write_csv_if_changed(
  frontier_link_signal_decomposition,
  "../output/provisional_frontier_link_signal_decomposition.csv"
)
write_csv_if_changed(
  exact_99_parent_paths,
  "../output/post_485x_exact_99_parent_paths.csv"
)
write_csv_if_changed(
  timing_qc,
  "../output/post_485x_bunching_timing_qc.csv"
)
ggsave(
  "../output/post_485x_filing_unit_distribution.pdf",
  filing_plot,
  width = 11,
  height = 8.5,
  bg = "white"
)
ggsave(
  "../output/post_485x_filing_unit_distribution.png",
  filing_plot,
  width = 11,
  height = 8.5,
  dpi = 220,
  bg = "white"
)
ggsave(
  "../output/post_485x_parent_unit_distribution.pdf",
  parent_plot,
  width = 11,
  height = 8.5,
  bg = "white"
)
ggsave(
  "../output/post_485x_parent_unit_distribution.png",
  parent_plot,
  width = 11,
  height = 8.5,
  dpi = 220,
  bg = "white"
)
ggsave(
  "../output/post_485x_bunching_timing.pdf",
  timing_plot,
  width = 9,
  height = 7.5,
  bg = "white"
)
ggsave(
  "../output/post_485x_bunching_timing.png",
  timing_plot,
  width = 9,
  height = 7.5,
  dpi = 220,
  bg = "white"
)

cat("Wrote post-485-x timing audit outputs to ../output\n")

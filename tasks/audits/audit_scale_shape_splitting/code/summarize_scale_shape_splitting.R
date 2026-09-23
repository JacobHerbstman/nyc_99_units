# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_scale_shape_splitting/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(tibble)
  library(tidyr)
})

source("../../../shared/code/source_pipeline_utils.R")
source("../../../shared/code/write_data_report.R")

# Exact plots cover 50-300 units; the preferred shape sample starts at 50 with a pooled 301+ bin.
exact_plot_minimum <- 50L
exact_plot_maximum <- 300L
preferred_minimum <- 50L
pooled_tail_start <- 301L

parents <- read_parquet(
  "../input/parent_opportunity_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

constituents <- read_parquet(
  "../input/constituent_filing_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(parents) == 0L ||
    nrow(constituents) == 0L ||
    anyDuplicated(parents[c("sample", "parent_id")]) ||
    anyDuplicated(constituents[c("sample", "root_job_id")]) ||
    nrow(anti_join(
      constituents |> distinct(sample, parent_id),
      parents,
      by = c("sample", "parent_id")
    )) > 0L
) {
  stop("Descriptive parent or constituent inputs failed identifier QC.")
}

period_levels <- parents |>
  distinct(sample, period) |>
  arrange(match(sample, c("historical", "post_policy"))) |>
  pull(period)

if (length(period_levels) != 2L) {
  stop("Expected exactly one historical and one post-policy period.")
}

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

save_pdf <- function(figure, out_path, width = 11, height = 5.8) {
  ggsave(out_path, figure, width = width, height = height, bg = "white")
}

parents_ab <- parents |>
  filter(included_ab) |>
  mutate(period = factor(period, levels = period_levels))

constituents_ab <- constituents |>
  filter(included_ab) |>
  mutate(period = factor(period, levels = period_levels))

sample_exposure_summary <- bind_rows(
  parents |>
    mutate(sample_scope = "All classified 6+ parents"),
  parents_ab |>
    mutate(sample_scope = "A/B rental opportunities")
) |>
  group_by(sample_scope, period, exposure_years) |>
  summarise(
    parent_opportunities = n(),
    annualized_opportunity_rate = n() / first(exposure_years),
    total_parent_units = sum(parent_total_units),
    annualized_parent_units = sum(parent_total_units) / first(exposure_years),
    multi_component_parents = sum(multi_component),
    multi_component_share = mean(multi_component),
    exact_99x2_parents = sum(exact_99x2),
    exact_99x3_parents = sum(exact_99x3),
    right_window_observed_parents = sum(right_window_observed),
    minimum_followup_days = min(observed_followup_days),
    .groups = "drop"
  ) |>
  arrange(sample_scope, factor(period, levels = period_levels))

distribution_rows <- bind_rows(
  parents_ab |>
    transmute(
      period,
      outcome = "Parent total",
      unit_count = parent_total_units,
      observation_weight = 1
    ),
  parents_ab |>
    transmute(
      period,
      outcome = "Largest constituent",
      unit_count = max_component_units,
      observation_weight = 1
    ),
  parents_ab |>
    filter(single_component) |>
    transmute(
      period,
      outcome = "Single-component parent total",
      unit_count = parent_total_units,
      observation_weight = 1
    ),
  parents_ab |>
    filter(multi_component) |>
    transmute(
      period,
      outcome = "Second-ranked constituent",
      unit_count = second_component_units,
      observation_weight = 1
    ),
  constituents_ab |>
    transmute(
      period,
      outcome = "All constituents: ordinary count",
      unit_count = constituent_units,
      observation_weight = 1
    ),
  constituents_ab |>
    transmute(
      period,
      outcome = "All constituents: parent-normalized",
      unit_count = constituent_units,
      observation_weight = parent_constituent_weight
    )
)

outcome_distribution_50_300 <- distribution_rows |>
  filter(
    unit_count >= exact_plot_minimum,
    unit_count <= exact_plot_maximum
  ) |>
  group_by(outcome, period, unit_count) |>
  summarise(weighted_count = sum(observation_weight), .groups = "drop") |>
  complete(
    outcome,
    period = factor(period, levels = period_levels),
    unit_count = seq.int(exact_plot_minimum, exact_plot_maximum),
    fill = list(weighted_count = 0)
  ) |>
  group_by(outcome, period) |>
  mutate(normalized_share = weighted_count / sum(weighted_count)) |>
  ungroup() |>
  arrange(outcome, period, unit_count)

range_definitions <- tribble(
  ~range_label, ~range_minimum, ~range_maximum,
  "Exactly 99", 99L, 99L,
  "100-109", 100L, 109L,
  "100-122", 100L, 122L,
  "100-149", 100L, 149L,
  "Exactly 150", 150L, 150L,
  "Exactly 198", 198L, 198L,
  "199-225", 199L, 225L,
  "250-300", 250L, 300L
)

preferred_parent_rows <- parents_ab |>
  filter(parent_total_units >= preferred_minimum)

scale_shape_rows <- list()

for (range_index in seq_len(nrow(range_definitions))) {
  range_row <- range_definitions[range_index, ]
  range_counts <- preferred_parent_rows |>
    group_by(period, exposure_years) |>
    summarise(
      opportunity_count = n(),
      range_count = sum(
        parent_total_units >= range_row$range_minimum &
          parent_total_units <= range_row$range_maximum
      ),
      .groups = "drop"
    ) |>
    mutate(
      range_label = range_row$range_label,
      annualized_opportunity_rate = opportunity_count / exposure_years,
      annualized_range_count = range_count / exposure_years,
      range_share = range_count / opportunity_count
    )

  scale_shape_rows[[range_index]] <- range_counts
}

scale_shape_decomposition <- bind_rows(scale_shape_rows) |>
  select(
    range_label,
    period,
    exposure_years,
    opportunity_count,
    annualized_opportunity_rate,
    range_count,
    annualized_range_count,
    range_share
  ) |>
  pivot_wider(
    names_from = period,
    values_from = c(
      exposure_years,
      opportunity_count,
      annualized_opportunity_rate,
      range_count,
      annualized_range_count,
      range_share
    ),
    names_sep = "__"
  )

pre_suffix <- period_levels[1]
post_suffix <- period_levels[2]

scale_shape_decomposition <- scale_shape_decomposition |>
  mutate(
    annualized_count_ratio_post_pre = if_else(
      .data[[paste0("annualized_range_count__", pre_suffix)]] > 0,
      .data[[paste0("annualized_range_count__", post_suffix)]] /
        .data[[paste0("annualized_range_count__", pre_suffix)]],
      NA_real_
    ),
    market_scale_ratio_post_pre =
      .data[[paste0("annualized_opportunity_rate__", post_suffix)]] /
      .data[[paste0("annualized_opportunity_rate__", pre_suffix)]],
    shape_ratio_post_pre = if_else(
      .data[[paste0("range_share__", pre_suffix)]] > 0,
      .data[[paste0("range_share__", post_suffix)]] /
        .data[[paste0("range_share__", pre_suffix)]],
      NA_real_
    ),
    ratio_identity_error = if_else(
      !is.na(annualized_count_ratio_post_pre) &
        !is.na(shape_ratio_post_pre),
      annualized_count_ratio_post_pre -
        market_scale_ratio_post_pre * shape_ratio_post_pre,
      NA_real_
    ),
    annualized_count_difference_post_pre =
      .data[[paste0("annualized_range_count__", post_suffix)]] -
      .data[[paste0("annualized_range_count__", pre_suffix)]],
    share_difference_post_pre =
      .data[[paste0("range_share__", post_suffix)]] -
      .data[[paste0("range_share__", pre_suffix)]]
  )

if (
  any(
    abs(scale_shape_decomposition$ratio_identity_error) > 1e-10,
    na.rm = TRUE
  )
) {
  stop("The annualized-count scale-shape identity failed.")
}

exact_threshold_shares <- preferred_parent_rows |>
  filter(parent_total_units %in% c(99L, 100L, 150L, 198L, 297L)) |>
  count(period, parent_total_units, name = "parent_count") |>
  complete(
    period = factor(period, levels = period_levels),
    parent_total_units = c(99L, 100L, 150L, 198L, 297L),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    preferred_parent_rows |>
      count(period, name = "opportunity_count"),
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(normalized_share = parent_count / opportunity_count) |>
  arrange(period, parent_total_units)

exact_198_vector_decomposition <- parents_ab |>
  filter(parent_total_units == 198L) |>
  count(
    period,
    sorted_component_vector,
    splitting_verification_status,
    name = "parent_count"
  ) |>
  group_by(period) |>
  mutate(
    exact_198_parents = sum(parent_count),
    conditional_share = parent_count / exact_198_parents
  ) |>
  ungroup() |>
  arrange(period, desc(parent_count), sorted_component_vector)

parent_99xk_summary <- parents_ab |>
  mutate(
    pattern = case_when(
      single_component & parent_total_units == 99L ~ "99 x 1",
      exact_99x2 ~ "99 x 2",
      exact_99x3 ~ "99 x 3",
      TRUE ~ "Other"
    )
  ) |>
  count(period, pattern, name = "parent_count") |>
  group_by(period) |>
  mutate(share_of_all_ab_parents = parent_count / sum(parent_count)) |>
  ungroup()

parent_response_categories <- parents_ab |>
  group_by(period, exposure_years, response_category) |>
  summarise(
    parent_count = n(),
    annualized_count = n() / first(exposure_years),
    share_of_all_opportunities = n() /
      sum(parents_ab$period == first(period)),
    parents_with_total_at_least_100 = sum(parent_total_units >= 100L),
    mean_parent_total = mean(parent_total_units),
    median_parent_total = median(parent_total_units),
    mean_largest_constituent = mean(max_component_units),
    mean_lot_area_sqft = mean(lot_area_sqft, na.rm = TRUE),
    mean_residential_capacity_sqft = mean(
      residential_capacity_sqft,
      na.rm = TRUE
    ),
    mean_redevelopment_slack_sqft = mean(
      redevelopment_slack_sqft,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  left_join(
    parents_ab |>
      filter(parent_total_units >= 100L) |>
      count(period, response_category, name = "category_total_ge_100"),
    by = c("period", "response_category"),
    relationship = "one-to-one"
  ) |>
  left_join(
    parents_ab |>
      filter(parent_total_units >= 100L) |>
      count(period, name = "all_parents_total_ge_100"),
    by = "period",
    relationship = "many-to-one"
  ) |>
  mutate(
    category_total_ge_100 = coalesce(category_total_ge_100, 0L),
    share_conditional_parent_total_ge_100 =
      category_total_ge_100 / all_parents_total_ge_100
  ) |>
  arrange(period, response_category)

historical_year_distribution <- parents_ab |>
  filter(sample == "historical", parent_total_units >= preferred_minimum) |>
  count(cohort_year, parent_total_units, name = "parent_count") |>
  complete(
    cohort_year = 2019:2022,
    parent_total_units = seq.int(
      preferred_minimum,
      max(parents_ab$parent_total_units)
    ),
    fill = list(parent_count = 0L)
  ) |>
  group_by(cohort_year) |>
  mutate(
    opportunity_count = sum(parent_count),
    normalized_share = parent_count / opportunity_count,
    cumulative_share = cumsum(normalized_share)
  ) |>
  ungroup() |>
  arrange(cohort_year, parent_total_units)

make_outcome_figure <- function(outcome_name, title_text, y_text, out_path) {
  plot_rows <- outcome_distribution_50_300 |>
    filter(outcome == outcome_name)

  figure <- ggplot(
    plot_rows,
    aes(x = unit_count, y = normalized_share, color = period, group = period)
  ) +
    geom_vline(
      xintercept = c(99, 150, 198, 297),
      color = "grey72",
      linetype = "dashed",
      linewidth = 0.4
    ) +
    geom_line(linewidth = 0.9) +
    scale_color_manual(values = period_colors) +
    scale_x_continuous(
      breaks = c(50, 99, 150, 198, 250, 297),
      limits = c(exact_plot_minimum, exact_plot_maximum)
    ) +
    scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
    labs(
      title = title_text,
      subtitle = "Each period sums to 100% within the displayed 50-300 support.",
      x = "Proposed units",
      y = y_text,
      color = NULL,
      caption = "Constituents are filing/building records, not presumed eligible sites."
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top", panel.grid.minor = element_blank())

  save_pdf(figure, out_path)
}

heatmap_rows <- parents_ab |>
  filter(
    multi_component,
    max_component_units <= 200L,
    second_component_units <= 200L
  ) |>
  count(
    period,
    max_component_units,
    second_component_units,
    name = "parent_count"
  )

heatmap_figure <- ggplot(
  heatmap_rows,
  aes(
    x = second_component_units,
    y = max_component_units,
    color = parent_count,
    size = parent_count
  )
) +
  geom_point(shape = 15) +
  geom_point(
    data = heatmap_rows |>
      filter(max_component_units == 99L, second_component_units == 99L),
    shape = 21,
    size = 4,
    stroke = 1,
    fill = NA,
    color = "black"
  ) +
  facet_wrap(~period) +
  scale_color_viridis_c(option = "C") +
  scale_size_continuous(range = c(2.2, 8)) +
  coord_equal() +
  labs(
    title = "Constituent vectors within multi-component parents",
    subtitle = "The outlined cell is exactly 99 + 99.",
    x = "Second-largest constituent units",
    y = "Largest constituent units",
    color = "Parents",
    size = "Parents",
    caption = "Only constituent sizes at or below 200 are displayed."
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

exact_198_figure <- ggplot(
  exact_198_vector_decomposition,
  aes(x = period, y = parent_count, fill = splitting_verification_status)
) +
  geom_col() +
  geom_text(
    aes(label = paste0(sorted_component_vector, ": ", parent_count)),
    position = position_stack(vjust = 0.5),
    size = 3.3
  ) +
  scale_fill_manual(
    values = c(
      "suggestive_separate_components" = "#F8766D",
      "unable_to_verify" = "#00BA38",
      "verified_separate_485x_units" = "#619CFF"
    ),
    labels = c(
      "suggestive_separate_components" = "Suggestive: separate components",
      "unable_to_verify" = "Unable to verify",
      "verified_separate_485x_units" = "Verified: separate 485-x units"
    )
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Constituent decomposition of exact 198-unit parents",
    subtitle = "Every current exact-198 parent is reported by its linked filing/building vector.",
    x = NULL,
    y = "Parent opportunities",
    fill = "Verification status",
    caption = paste0(
      "A 99+99 vector is descriptive evidence of partitioning, not by itself ",
      "proof of separate 485-x eligible sites."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

category_figure <- ggplot(
  parent_response_categories |>
    mutate(
      response_category = factor(
        response_category,
        levels = rev(sort(unique(response_category)))
      )
    ),
  aes(
    x = response_category,
    y = share_of_all_opportunities,
    fill = period
  )
) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = period_colors) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "A/B parent opportunities by constituent configuration",
    x = NULL,
    y = "Share of all A/B parent opportunities",
    fill = NULL,
    caption = "F and G are mutually exclusive detailed subcategories of all-sub-100 multi-component parents."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

constituent_count_distribution <- parents_ab |>
  count(period, n_components, name = "parent_count") |>
  group_by(period) |>
  mutate(normalized_share = parent_count / sum(parent_count)) |>
  ungroup()

constituent_count_figure <- ggplot(
  constituent_count_distribution,
  aes(x = n_components, y = normalized_share, fill = period)
) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = period_colors) +
  scale_x_continuous(breaks = sort(unique(constituent_count_distribution$n_components))) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Number of constituent filings/buildings per A/B parent",
    x = "Constituents in the linked parent",
    y = "Share of A/B parent opportunities",
    fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

historical_year_figure <- historical_year_distribution |>
  filter(parent_total_units <= exact_plot_maximum) |>
  ggplot(
    aes(
      x = parent_total_units,
      y = normalized_share,
      color = factor(cohort_year),
      group = cohort_year
    )
  ) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey75",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.75) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(exact_plot_minimum, exact_plot_maximum)
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Year-specific historical A/B parent-size shares",
    subtitle = "Each year is normalized over all 50+ parent opportunities; 301+ remains in the denominator.",
    x = "Total proposed units in the linked parent",
    y = "Within-year share",
    color = "Cohort year"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

SaveData(sample_exposure_summary, c("sample_scope", "period"), "../output/sample_exposure_summary.csv")
SaveData(outcome_distribution_50_300, c("outcome", "period", "unit_count"), "../output/outcome_distribution_50_300.csv")
SaveData(scale_shape_decomposition, c("range_label"), "../output/scale_shape_decomposition.csv")
SaveData(exact_threshold_shares, c("period", "parent_total_units"), "../output/exact_threshold_shares.csv")
SaveData(exact_198_vector_decomposition, NULL, "../output/exact_198_vector_decomposition.csv")
SaveData(parent_99xk_summary, c("period", "pattern"), "../output/parent_99xk_summary.csv")
SaveData(parent_response_categories, c("period", "response_category"), "../output/parent_response_categories.csv")
SaveData(constituent_count_distribution, c("period", "n_components"), "../output/constituent_count_distribution.csv")

make_outcome_figure(
  "Largest constituent",
  "Normalized largest-constituent distribution",
  "Share of largest constituents",
  "../output/pdf/normalized_largest_constituent_50_300.pdf"
)
make_outcome_figure(
  "Single-component parent total",
  "Normalized single-component parent distribution",
  "Share of single-component parents",
  "../output/pdf/normalized_single_component_50_300.pdf"
)
make_outcome_figure(
  "Second-ranked constituent",
  "Normalized second-ranked constituent distribution",
  "Share of multi-component parents",
  "../output/pdf/normalized_second_constituent_50_300.pdf"
)
make_outcome_figure(
  "All constituents: ordinary count",
  "Normalized constituent distribution: ordinary counting",
  "Share of constituent filings/buildings",
  "../output/pdf/normalized_all_constituents_ordinary_50_300.pdf"
)
make_outcome_figure(
  "All constituents: parent-normalized",
  "Normalized constituent distribution: one total weight per parent",
  "Parent-normalized constituent share",
  "../output/pdf/normalized_all_constituents_parent_weighted_50_300.pdf"
)
save_pdf(
  heatmap_figure,
  "../output/pdf/largest_second_constituent_heatmap.pdf",
  width = 10,
  height = 5.2
)
save_pdf(
  exact_198_figure,
  "../output/pdf/exact_198_constituent_decomposition.pdf",
  width = 10,
  height = 5.8
)
save_pdf(
  category_figure,
  "../output/pdf/parent_response_category_shares.pdf",
  width = 11,
  height = 6.5
)
save_pdf(
  constituent_count_figure,
  "../output/pdf/constituent_count_distribution.pdf",
  width = 9,
  height = 5.4
)
save_pdf(
  historical_year_figure,
  "../output/pdf/historical_year_normalized_parent_total.pdf"
)

cat("Wrote descriptive scale, shape, and splitting outputs to ../output\n")

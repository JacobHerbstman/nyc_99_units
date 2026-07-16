# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/summarize_developer_responses/code")
# design_pre_start_year <- 2021L
# pre_end_year <- 2023L
# post_year <- 2025L
# min_units <- 50L
# design_max_units <- 150L
# site_plot_max_units <- 400L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(stringr)
  library(tibble)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected six arguments: design pre-period start, pre-period end, ",
    "post year, minimum units, design maximum units, and site maximum units."
  )
}

design_pre_start_year <- as.integer(args[1])
pre_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
design_max_units <- as.integer(args[5])
site_plot_max_units <- as.integer(args[6])

if (
  any(is.na(c(
    design_pre_start_year, pre_end_year, post_year, min_units,
    design_max_units, site_plot_max_units
  ))) ||
    design_pre_start_year > pre_end_year ||
    pre_end_year >= post_year ||
    min_units >= design_max_units ||
    design_max_units > site_plot_max_units
) {
  stop("Figure arguments are not internally consistent.")
}

pre_label <- paste0("Pre: ", design_pre_start_year, "-", pre_end_year)
post_label <- paste0("Post: ", post_year)

dob_filings <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    job_number = str_squish(job_number),
    filing_year = as.integer(format(filing_date, "%Y")),
    integer_proposed_units = !is.na(proposed_dwelling_units) &
      abs(proposed_dwelling_units - round(proposed_dwelling_units)) < 1e-8
  ) |>
  filter(
    job_type == "New Building",
    !is.na(filing_date),
    filing_year >= design_pre_start_year,
    filing_year <= post_year,
    !is.na(proposed_dwelling_units),
    proposed_dwelling_units > 0,
    integer_proposed_units
  ) |>
  transmute(
    job_number,
    filing_year,
    units = as.integer(round(proposed_dwelling_units)),
    bbl,
    bin,
    total_construction_floor_area,
    gross_construction_square_feet_per_unit =
      total_construction_floor_area / units
  ) |>
  arrange(filing_year, job_number)

if (
  nrow(dob_filings) == 0L ||
    anyDuplicated(dob_filings$job_number) ||
    any(is.na(dob_filings$bbl))
) {
  stop("DOB initial-filing sample failed uniqueness or BBL coverage checks.")
}

design_sample <- dob_filings |>
  mutate(
    period = case_when(
      filing_year >= design_pre_start_year & filing_year <= pre_end_year ~
        pre_label,
      filing_year == post_year ~ post_label,
      TRUE ~ NA_character_
    )
  ) |>
  filter(
    !is.na(period),
    units >= min_units,
    units <= design_max_units,
    !is.na(total_construction_floor_area),
    total_construction_floor_area > 0,
    !is.na(gross_construction_square_feet_per_unit),
    gross_construction_square_feet_per_unit > 0
  ) |>
  mutate(
    period = factor(period, levels = c(pre_label, post_label)),
    exact_99 = if_else(units == 99L, "99 units", "Other unit count")
  )

if (nrow(design_sample) == 0L) {
  stop("No DOB filings remain in the design-response sample.")
}

theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title.position = "plot",
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

area_plot_data <- design_sample |>
  transmute(
    period,
    units,
    exact_99,
    measure = factor(
      "Total construction floor area",
      levels = c(
        "Total construction floor area",
        "Proposed residential floor area"
      )
    ),
    area = total_construction_floor_area
  )

missing_residential_annotations <- tibble(
  period = factor(c(pre_label, post_label), levels = c(pre_label, post_label)),
  measure = factor(
    rep("Proposed residential floor area", 2),
    levels = c(
      "Total construction floor area",
      "Proposed residential floor area"
    )
  ),
  units = (min_units + design_max_units) / 2,
  area = median(design_sample$total_construction_floor_area),
  label = "Not reported in\nDOB NOW Open Data"
)

area_figure <- ggplot(
  area_plot_data,
  aes(x = units, y = area, color = exact_99)
) +
  geom_vline(xintercept = 99, color = "#D55E00", linewidth = 0.45) +
  geom_vline(
    xintercept = 100,
    color = "#D55E00",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  geom_point(alpha = 0.65, size = 1.5) +
  geom_text(
    data = missing_residential_annotations,
    aes(x = units, y = area, label = label),
    inherit.aes = FALSE,
    color = "#4D4D4D",
    fontface = "bold",
    lineheight = 1.1
  ) +
  facet_grid(measure ~ period) +
  scale_color_manual(
    values = c("Other unit count" = "#8C8C8C", "99 units" = "#D55E00")
  ) +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  coord_cartesian(ylim = c(20000, 500000)) +
  labs(
    title = "Proposed project area versus dwelling units",
    subtitle = paste0(
      "DOB reports total construction floor area, but not proposed ",
      "residential floor area."
    ),
    x = "Proposed dwelling units",
    y = "Square feet (log scale)",
    color = NULL,
    caption = paste0(
      "Initial DOB NOW New Building filings. Visible window: ",
      "20,000-500,000 square feet; all values remain in the source data.\n",
      "The missing panel reflects source coverage, not zero area."
    )
  )

ggsave(
  "../output/developer_response_provisional_site_construction_area_vs_units.pdf",
  area_figure,
  width = 10,
  height = 7
)

period_medians <- design_sample |>
  group_by(period) |>
  summarise(
    median_square_feet_per_unit =
      median(gross_construction_square_feet_per_unit),
    .groups = "drop"
  )

square_feet_figure <- ggplot(
  design_sample,
  aes(
    x = units,
    y = gross_construction_square_feet_per_unit,
    color = exact_99
  )
) +
  geom_vline(xintercept = 99, color = "#D55E00", linewidth = 0.45) +
  geom_vline(
    xintercept = 100,
    color = "#D55E00",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  geom_hline(
    data = period_medians,
    aes(yintercept = median_square_feet_per_unit),
    color = "#0072B2",
    linewidth = 0.55
  ) +
  geom_point(alpha = 0.65, size = 1.5) +
  facet_wrap(~period) +
  scale_color_manual(
    values = c("Other unit count" = "#8C8C8C", "99 units" = "#D55E00")
  ) +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  coord_cartesian(ylim = c(300, 3000)) +
  labs(
    title = "Total construction square feet per dwelling unit",
    subtitle =
      "The blue line is the period median. Exact 99-unit filings are highlighted.",
    x = "Proposed dwelling units",
    y = "Total construction square feet per unit (log scale)",
    color = NULL,
    caption = paste0(
      "Visible window: 300-3,000 square feet per unit; all values remain ",
      "in the source data.\nThe ratio includes common, mechanical, parking, ",
      "and nonresidential space. It is not apartment size."
    )
  )

ggsave(
  "../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf",
  square_feet_figure,
  width = 10,
  height = 5.5
)

building_application_plot_data <- dob_filings |>
  group_by(filing_year, bbl) |>
  summarise(
    application_count = n_distinct(job_number),
    building_count = n_distinct(bin),
    site_units = sum(units),
    .groups = "drop"
  ) |>
  mutate(
    period = case_when(
      filing_year >= design_pre_start_year & filing_year <= pre_end_year ~
        pre_label,
      filing_year == post_year ~ post_label,
      TRUE ~ NA_character_
    )
  ) |>
  filter(
    !is.na(period),
    site_units >= min_units,
    site_units <= site_plot_max_units
  ) |>
  count(period, application_count, building_count, name = "provisional_sites") |>
  mutate(period = factor(period, levels = c(pre_label, post_label)))

building_application_annotation <- tibble(
  period = factor(pre_label, levels = c(pre_label, post_label)),
  application_count = 3.4,
  building_count = 4.6,
  label = "One pre-period proxy has\n52 applications and 52 BINs"
)

building_application_figure <- ggplot(
  building_application_plot_data,
  aes(x = application_count, y = building_count, size = provisional_sites)
) +
  geom_point(color = "#0072B2", alpha = 0.75) +
  geom_text(
    data = building_application_annotation,
    aes(x = application_count, y = building_count, label = label),
    inherit.aes = FALSE,
    color = "#4D4D4D",
    size = 3.4,
    lineheight = 1.05
  ) +
  facet_wrap(~period) +
  scale_x_continuous(breaks = 1:5) +
  scale_y_continuous(breaks = 1:5) +
  scale_size_area(max_size = 13, breaks = pretty_breaks()) +
  coord_cartesian(xlim = c(0.75, 5.25), ylim = c(0.75, 5.25)) +
  labs(
    title = "Buildings and initial applications within provisional tax-lot sites",
    subtitle = paste0(
      "DOB BBL-year proxies with ", min_units, "-", site_plot_max_units,
      " total units; point size is the number of proxy sites."
    ),
    x = "Distinct initial New Building applications",
    y = "Distinct BINs (building proxy)",
    size = "Proxy sites",
    caption = paste0(
      "Visible window: 1-5 applications and BINs; the 52-by-52 pre-period ",
      "proxy remains in the underlying data.\nMultiple filings or BINs do ",
      "not by themselves establish a legal split under 485-x."
    )
  )

ggsave(
  "../output/developer_response_provisional_site_building_application_counts.pdf",
  building_application_figure,
  width = 9,
  height = 5.5
)

cat("Wrote developer-response figures to ../output\n")

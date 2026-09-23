# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_site_boundaries/code")
library(arrow)
library(dplyr)
library(tibble)
library(readr)
library(sf)
library(ggplot2)
source("../../../shared/code/write_data_report.R")

lots <- read_parquet("../input/dcp_mappluto_archive_23v3_1.parquet")

# Manual transcription of the 2024 ACRIS condominium drawings, physical pages
# 6, 14, 16, 18-20. The 2026 declaration, pages 34-36, puts the residential
# boundary 62 feet behind the storefronts, with a deeper 62-foot corner return.
# Ground-floor ratios approximate the almost rectangular building footprints.
# Mezzanine depths (12.5, 22, 34 feet) are scaled from drawings, not printed
# dimensions. The lower/upper columns put each small mezzanine wholly outside/
# inside. They are sensitivity cases, not bounds on all measurement error.
corner_ground_share <- (62 * 100 + (190 + 4 / 12 - 62) * 62) / ((190 + 4 / 12) * 100)
jamaica <- tribble(
  ~bbl, ~plan_ground, ~plan_other, ~included_ground_share, ~included_other_share, ~other_share_low, ~other_share_high, ~basis,
  "4097950030", 6967, 442, 62 / 70, (34 - 8) / 34, 0, 1, "2024 plan p16; rear mezzanine depth about 34 feet",
  "4097950065", 19012, 2636 + 116, corner_ground_share, 0, 0, 0, "2024 plans pp18-20; second floor and roof stair entirely behind housing boundary",
  "4097950085", 5232, 321 + 310, 62 / 70, 321 * (22 - 8) / 22 / (321 + 310), 0, 321 / (321 + 310), "2024 plan p16; rear mezzanine about 22 feet; bus office wholly outside",
  "4097950089", 3775, 3385, 0, 0, 0, 0, "2024 plan p5; Merrick building wholly outside",
  "4097950094", 5274, 5249 + 328, 0, 0, 0, 0, "2024 plan p5; Merrick building wholly outside",
  "4097950098", 6580, 0, 62 / 70, 0, 0, 0, "2023 administrative depth 70 feet; outside condo drawing coverage",
  "4097950099", 4451, 0, 62 / 80, 0, 0, 0, "2023 administrative depth 80 feet; outside condo drawing coverage",
  "4097950130", 5253, 230, 62 / 70, (12.5 - 8) / 12.5, 0, 1, "2024 plan p14; rear mezzanine depth about 12.5 feet") |>
  left_join(lots |> select(bbl, bldgarea, lotarea), by = "bbl", relationship = "one-to-one") |>
  mutate(plan_floor = plan_ground + plan_other,
    included_share = (plan_ground * included_ground_share + plan_other * included_other_share) / plan_floor,
    included_frozen_floor = bldgarea * included_share,
    mezzanine_low_floor = bldgarea * (plan_ground * included_ground_share + plan_other * other_share_low) / plan_floor,
    mezzanine_high_floor = bldgarea * (plan_ground * included_ground_share + plan_other * other_share_high) / plan_floor)
stopifnot(nrow(jamaica) == 8, sum(jamaica$bldgarea) == 69813,
  sum(jamaica$lotarea) == 111540, all(between(jamaica$included_share, 0, 1)))
SaveData(jamaica, "bbl", "../output/jamaica_floor_allocation.csv")

# HCR's corrected Attachment 4, physical p9, drawing A-200 (December 14, 2018).
# Keep the basement convention visible; this schedule excludes the power plant.
kingsbrook <- tribble(
  ~building, ~basement_floor, ~total_gross_floor,
  "Leviton", 9310, 44890,
  "Masin", 10570, 74295,
  "Blumberg", 5395, 48655,
  "LeFrak", 9970, 46440) |>
  mutate(above_basement_floor = total_gross_floor - basement_floor,
    source = "HCR corrected Attachment 4 p9, A-200, 2018-12-14")
stopifnot(sum(kingsbrook$total_gross_floor) == 214280,
  sum(kingsbrook$above_basement_floor) == 179035)
SaveData(kingsbrook, "building", "../output/kingsbrook_floor_schedule.csv")

# Manual tracing of BLD's July 2021 survey, RAWP physical p130, normalized
# to a 1711 x 1440 image. Use the printed 460-foot Rutland frontage to scale it.
# This is an approximate partition, not a new survey. The west plant bay is
# labeled "1 story & mezzanine"; the drawing does not measure the mezzanine.
trace <- read_csv("kingsbrook_survey_tracing.csv", show_col_types = FALSE)
east_corner <- trace |> filter(feature == "northeast_corner")
west_corner <- trace |> filter(feature == "northwest_corner")
pixels_per_foot <- (east_corner$x - west_corner$x) / 460
trace <- trace |> mutate(west_ft = (east_corner$x - x) / pixels_per_foot,
  south_ft = (y - east_corner$y) / pixels_per_foot)
plant <- trace |> filter(feature == "power_plant") |> select(west_ft, south_ft) |> as.matrix()
bay <- trace |> filter(feature == "mezzanine_bay") |> select(west_ft, south_ft) |> as.matrix()
plant <- st_sfc(st_polygon(list(plant)))
bay <- st_sfc(st_polygon(list(bay)))
# Recorded Parcel A legal courses, agreement pp30-31 / RAWP pp131-132.
phase <- st_sfc(st_polygon(list(rbind(c(0, 0), c(0, 248.83), c(115, 248.83),
  c(115, 211.12), c(200.5, 211.12), c(200.5, 136.5), c(315.5, 136.5),
  c(315.5, 210), c(460, 210), c(460, 0), c(0, 0)))))
inside_plant <- st_intersection(plant, phase)
inside_bay <- st_intersection(inside_plant, bay)
plant_share <- as.numeric(st_area(inside_plant) / st_area(plant))
bay_share <- as.numeric(st_area(inside_bay) / st_area(plant))
# The June 2025 ESA p10 reports an 11,600-square-foot plant footprint and a
# cellar. Use the traced shares to allocate that recorded footprint. Equal
# cellar/ground footprints and half of the mapped mezzanine bay are explicit
# assumptions. The endpoint cases omit or fill that bay, not all uncertainty.
plant_floor <- 11600 * plant_share
mezzanine_max <- 11600 * bay_share
floor_candidates <- tibble(
  case = c("Jamaica 165th", "Kingsbrook"),
  ground = c(39349.5, 105382),
  candidate_floor = c(sum(jamaica$included_frozen_floor), 214280 + 2 * plant_floor + mezzanine_max / 2),
  mezzanine_low_floor = c(sum(jamaica$mezzanine_low_floor), 214280 + 2 * plant_floor),
  mezzanine_high_floor = c(sum(jamaica$mezzanine_high_floor), 214280 + 2 * plant_floor + mezzanine_max),
  no_cellar_floor = c(NA_real_, 179035 + plant_floor + mezzanine_max / 2),
  plant_included_share = c(NA_real_, plant_share),
  plant_traced_ground = c(NA_real_, as.numeric(st_area(plant))))
stopifnot(abs(as.numeric(st_area(phase)) - 92709) < 1,
  between(plant_share, 0, 1), between(bay_share, 0, plant_share))
SaveData(floor_candidates, "case", "../output/remaining_floor_candidates.csv")

allocation_plot <- ggplot() +
  geom_sf(data = phase * -1, fill = "grey94", color = "grey45") +
  geom_sf(data = plant * -1, aes(fill = "Outside Phase I"), color = "grey25") +
  geom_sf(data = inside_plant * -1, aes(fill = "Inside Phase I"), color = "grey25") +
  geom_sf(data = inside_bay * -1, fill = NA, color = "#922C40", linewidth = 0.8) +
  scale_fill_manual(values = c("Inside Phase I" = "#5B9BB5", "Outside Phase I" = "#E5BD74"), name = NULL) +
  labs(title = "Kingsbrook: earlier power plant within the Phase I boundary",
    subtitle = "About 48% of the plant footprint is inside. Red: included part of the mezzanine bay.",
    caption = "Approximate tracing of BLD's July 2021 survey (2026 RAWP, p130). Phase I follows recorded legal courses.\nParking is separate and adds no earlier building floor. This drawing does not measure the cellar or mezzanine floor.") +
  theme_void(base_size = 11) + theme(legend.position = "bottom", plot.caption = element_text(hjust = 0))
ggsave("../output/kingsbrook_floor_allocation.png", allocation_plot, width = 9, height = 6, dpi = 180, bg = "white")

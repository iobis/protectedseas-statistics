####################### StOR - State of the Ocean Report #######################
########################### MPA biodiversity analysis ##########################
# January of 2024
# Authors: Pieter Provoost, Silas C. Principe, Ward Appeltans
# Contact: helpdesk@obis.org
#
################## Cummulative number of species and records ###################

# Load packages ----
library(tidyverse)
library(patchwork)


# Load/prepare files ----
cummulative <- readRDS("data/biodiv/cummulative.rds")

inside_mpas_cum <- cummulative$sp_inside_mpa
inside_mpas_cum_rec <- cummulative$rec_inside_mpa

outside_mpas_cum <- cummulative$sp_outside_mpa
outside_mpas_cum_rec <- cummulative$rec_outside_mpa


# Option A ----
inside_mpas_cum_tr <- inside_mpas_cum %>%
  rename(n_species = cum, year = min_year) %>% 
  mutate(n_species = n_species / max(n_species)) %>%
  mutate(group = "Covered by MPAs")

outside_mpas_cum_tr <- outside_mpas_cum %>%
  filter(min_year >= 1900) %>%
  mutate(cum = cum / max(cum)) %>%
  mutate(group = "Not covered by MPAs") %>%
  select(year = min_year, n_species = cum, group)

full_cum_tr <- bind_rows(inside_mpas_cum_tr, outside_mpas_cum_tr)


bars <- inside_mpas_cum_tr %>%
  filter(year >= 1900) %>%
  filter(year %in% c(1900, 1943, 1983, 2023)) %>%
  mutate(max_y = n_species, min_y = 0)

n_rec <- data.frame(
  year = c(2023, 1983, 1943, 1900)+c(-17, -16, 15, 16),
  n_records = paste(rev(format(inside_mpas_cum_rec$cum[
    inside_mpas_cum_rec$min_year %in% c(2023, 1983, 1943, 1900)
  ], big.mark = ",", trim = T)), "records"),
  y = rev((bars$max_y - bars$min_y)/2 + c(0, -0.05, -0.15, 0))
)

bars_b <- outside_mpas_cum_tr %>%
  filter(year >= 1900) %>%
  filter(year %in% c(1900, 1943, 1983, 2023)) %>%
  mutate(min_y = n_species, max_y = 1) %>%
  filter(year %in% c(1900, 1983))

n_rec_b <- data.frame(
  year = c(1983, 1900)+c(-19, 19),
  n_records = paste(format(rev(outside_mpas_cum_rec$cum[
    outside_mpas_cum_rec$min_year %in% c(1983, 1900)
  ]), big.mark = ",", trim = T), "records"),
  y = c(0.9, 0.7)
) 

full_cum_tr %>%
  filter(year >= 1900) %>%
  ggplot() +
  # geom_rect(data = data.frame(
  #   xmin = 2015, xmax = 2023,
  #   ymin = 0, ymax = 89000
  # ), aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
  # fill = "#34a0a4", alpha = .2) +
  # geom_segment(x = 1980, xend = 2014, y = 84000, yend = 84000,
  #              linewidth = 0.5,
  #              color = "#34a0a4",  arrow = arrow(length = unit(0.2, "cm"))) +
  # geom_label(label = "~50% of the records were \naccumulated from 2015 onwards",
  #            x = 1980, y = 84000, color = "grey20", size = 3.5,
  #            label.size = NA) +
geom_line(aes(x = year, y = n_species, color = group), linewidth = 1.5) +
  scale_color_manual(values = c("#184e77", "#D59019")) +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_linerange(data = bars, aes(x = year, ymin = min_y, ymax = max_y),
                 color = "#1a759f", alpha = .5, linetype = 2) +
  geom_linerange(data = n_rec, aes(xmin = year, xmax = year - c(-17, -16, 15, 16), y = y),
                 color = "#1a759f") +
  geom_label(data = n_rec, aes(x = year, y = y, label = n_records),
             color = "#1a759f", size = 3.5) +
  # part b
  geom_linerange(data = bars_b, aes(x = year, ymin = min_y, ymax = max_y),
                 color = "#E0AB50", alpha = .5, linetype = 2) +
  geom_linerange(data = n_rec_b, aes(xmin = year - c(0, 19), xmax = year + c(19,0), y = y),
                 color = "#E0AB50") +
  geom_label(data = n_rec_b, aes(x = year, y = y, label = n_records),
             color = "#E0AB50", size = 3.5) +
  # etc
  scale_x_continuous(breaks = seq(1900, 2023, by = 20), limits = c(1900, 2023)) +
  scale_y_continuous(expand = c(0,0,0.02,0)) +
  ylab("Fraction of total recorded species") + xlab(NULL) +
  ggtitle("Cumulative number of species") +
  theme(
    panel.background = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.2),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
    strip.text.x = element_text(size = 14, face = "bold", hjust = 0),
    strip.background = element_blank(),
    panel.spacing.y = unit(3, "lines"),
    legend.position = "bottom", 
    legend.title = element_blank(),
    legend.key = element_blank()
  )

ggsave("graphs/cumspecies_main.png", width = 9, height = 6)


# Option B ----
bars <- inside_mpas_cum_tr %>%
  filter(year >= 1900) %>%
  filter(year %in% c(1900, 1943, 1983, 2023)) %>%
  mutate(max_y = n_species, min_y = 0)

n_rec <- data.frame(
  year = c(2023, 1983, 1943, 1900)+c(-17, -16, 15, 16),
  n_records = paste(rev(format(inside_mpas_cum_rec$cum[
    inside_mpas_cum_rec$min_year %in% c(2023, 1983, 1943, 1900)
  ], big.mark = ",", trim = T)), "records"),
  y = rev((bars$max_y - bars$min_y)/2 + c(0, -0.05, -0.15, 0))
)

plot_a <- inside_mpas_cum %>%
  rename(year = min_year, n_species = cum) %>%
  filter(year >= 1900) %>%
  ggplot() +
  geom_rect(data = data.frame(
    xmin = 2015, xmax = 2023,
    ymin = 0, ymax = 89000
  ), aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
  fill = "#34a0a4", alpha = .2) +
  geom_segment(x = 1980, xend = 2014, y = 84000, yend = 84000,
               linewidth = 0.5,
               color = "#34a0a4",  arrow = arrow(length = unit(0.2, "cm"))) +
  geom_label(label = "~50% of the records were \naccumulated from 2015 onwards",
             x = 1980, y = 84000, color = "grey20", size = 3.5,
             label.size = NA) +
  geom_line(aes(x = year, y = n_species), linewidth = 1.5,
            color = "#184e77") +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_linerange(data = bars, aes(x = year, ymin = min_y, ymax = max_y),
                 color = "#1a759f", alpha = .5, linetype = 2) +
  geom_linerange(data = n_rec, aes(xmin = year, xmax = year - c(-17, -16, 15, 14), y = y),
                 color = "#1a759f") +
  geom_label(data = n_rec, aes(x = year, y = y, label = n_records),
             color = "#1a759f", size = 3.5) +
  scale_x_continuous(breaks = seq(1900, 2023, by = 20), limits = c(1900, 2023)) +
  scale_y_continuous(expand = c(0,0,0.02,0)) +
  ylab("Number of species") + xlab(NULL) +
  ggtitle("Cumulative number of species on MPAs") +
  theme(
    panel.background = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.2),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
    strip.text.x = element_text(size = 14, face = "bold", hjust = 0),
    strip.background = element_blank(),
    panel.spacing.y = unit(3, "lines"),
    legend.position = "bottom", 
    legend.title = element_blank(),
    legend.key = element_blank()
  )

plot_a


bars_b <- outside_mpas_cum %>%
  rename(year = min_year, n_species = cum) %>%
  filter(year >= 1900) %>%
  filter(year %in% c(1900, 1943, 1983, 2023)) %>%
  mutate(min_y = 0, max_y = n_species) %>%
  filter(year %in% c(1900, 1983))

n_rec_b <- data.frame(
  year = c(1983, 1900)+c(-19, 19),
  n_records = paste(format(rev(outside_mpas_cum_rec$cum[
    outside_mpas_cum_rec$min_year %in% c(1983, 1900)
  ]), big.mark = ",", trim = T), "records"),
  y = c(15000, 10000)
) 

plot_b <- outside_mpas_cum %>%
  rename(year = min_year, n_species = cum) %>%
  filter(year >= 1900) %>%
  ggplot() +
  # geom_rect(data = data.frame(
  #   xmin = 2015, xmax = 2023,
  #   ymin = 0, ymax = 89000
  # ), aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
  # fill = "#E06850", alpha = .2) +
  # geom_segment(x = 1980, xend = 2014, y = 84000, yend = 84000,
  #              linewidth = 0.5,
  #              color = "#E06850",  arrow = arrow(length = unit(0.2, "cm"))) +
  # geom_label(label = "~50% of the records were \naccumulated from 2015 onwards",
  #            x = 1980, y = 84000, color = "grey20", size = 3.5,
  #            label.size = NA) +
geom_line(aes(x = year, y = n_species), linewidth = 1.5,
          color = "#D59019") +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_linerange(data = bars_b, aes(x = year, ymin = min_y, ymax = max_y),
                 color = "#E0AB50", alpha = .5, linetype = 2) +
  geom_linerange(data = n_rec_b, aes(xmin = year - c(0, 19), xmax = year + c(19,0), y = y),
                 color = "#E0AB50") +
  geom_label(data = n_rec_b, aes(x = year, y = y, label = n_records),
             color = "#E0AB50", size = 3.5) +
  scale_x_continuous(breaks = seq(1900, 2023, by = 20), limits = c(1900, 2023)) +
  scale_y_continuous(expand = c(0,0,0.02,0)) +
  ylab(NULL) + xlab(NULL) +
  ggtitle("Cumulative number of species outside MPAs") +
  theme(
    panel.background = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.2),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
    strip.text.x = element_text(size = 14, face = "bold", hjust = 0),
    strip.background = element_blank(),
    panel.spacing.y = unit(3, "lines"),
    legend.position = "bottom", 
    legend.title = element_blank(),
    legend.key = element_blank()
  )

plot_b

plot_a + plot_b


ggsave("graphs/cumspecies.png", width = 14, height = 6)
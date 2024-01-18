####################### StOR - State of the Ocean Report #######################
########################### MPA biodiversity analysis ##########################
# January of 2024
# Authors: Pieter Provoost, Silas C. Principe, Ward Appeltans
# Contact: helpdesk@obis.org
#
############################# Summaries of species #############################
########################### All Protection level > 3 ###########################

# Load packages ----
library(storr)
library(tidyverse)


# Load files ----
species_list <- readRDS("data/biodiv/taxa.rds")
sites_list <- storr_rds("data/biodiv/sites_storr/")
red_list <- readRDS("data/biodiv/redlist.rds")
outside_list <- readRDS("data/biodiv/taxa_outside_mpa.rds")
species_summaries <- readRDS("data/biodiv/sites_summ_group.rds")
mpas_table <- read.csv("data/protectedseas/Navigator_Global_121923.csv")


# Apply the groupings and filters to the full species list ----
animal_phyla <- worrms::wm_children(2)
animal_phyla <- animal_phyla %>%
  filter(rank == "Phylum") %>%
  filter(scientificname != "Chordata")

species_list <- species_list %>%
  filter(taxonRank == "Species") %>%
  mutate(group = case_when(
    # Vertebrates
    class == "Aves" ~ "seabirds",
    class == "Mammalia"~ "mammals",
    order == "Testudines" ~ "turtle",
    class %in% c("Teleostei", "Coelacanthi",
                 "Dipneusti", "Cladistii",
                 "Chondrostei", "Holostei", 
                 "Myxini", "Petromyzonti") ~ "fishes",
    class %in% c("Elasmobranchii" , "Holocephali") ~ "sharks",
    # Invertebrates
    phylum %in% animal_phyla$scientificname ~ "invertebrates",
    .default = "others"
  ))



# Get the MPA sites ----
mpas_selected <- mpas_table %>%
  filter(lfp >= 3) #category_name == "IUCN MPA"


# Get the total number of species ----
sel_sites_dat <- sites_list$mget(mpas_selected$site_id)
names(sel_sites_dat) <- mpas_selected$site_id
mpa_data_full <- bind_rows(sel_sites_dat,
                           .id = "site_id")
rm(sel_sites_dat)

sel_total <- mpa_data_full %>%
  distinct(species) %>%
  nrow()


# Get the number of Red Lists per protection category ----
redlist_cat <- mpa_data_full %>%
  left_join(mpas_table[,c("site_id", "site_name", "marine_area", "lfp")]) %>%
  mutate(category = ifelse(is.na(category), "Not RL", category)) %>%
  mutate(category = ifelse(category %in% c("VU", "EN", "CR"),
                           "RL", "Not RL")) %>% # Constrained to meaningful categories
  group_by(lfp, category) %>%
  distinct(species) %>%
  count() %>%
  group_by(lfp) %>%
  mutate(perc_n = (n * 100)/sum(n))

redlist_cat

redlist_cat %>% group_by(lfp) %>% summarise(n = sum(n))

clipr::write_clip(redlist_cat, object = "table")

# Number of Red List species in general
species_list %>%
  left_join(red_list) %>%
  filter(!is.na(category)) %>%
  filter(category %in% c("VU", "EN", "CR")) %>% # Constrained to meaningful categories
  distinct(species) %>%
  nrow() %>% cat(., "total red list species \n")

# Number of Red List species on MPAs
mpa_data_full %>%
  filter(!is.na(category)) %>%
  filter(category %in% c("VU", "EN", "CR")) %>%  # Constrained to meaningful categories
  distinct(species) %>%
  nrow() %>% cat(., "red list species on MPAs \n")


# Get summaries ----

# Rename for better plotting/display
sel_data <- species_summaries %>%
  filter(site_id %in% mpas_selected$site_id) %>%
  mutate(renamed_group = case_when(
    group == "seabirds" ~ "Seabirds",
    group == "mammals" ~ "Mammals",
    group == "turtle" ~ "Turtles",
    group == "fishes" ~ "Fishes (others)",
    group == "sharks" ~ "Fishes (sharks/rays)",
    group == "invertebrates" ~ "Invertebrates",
    group == "others" ~ "Other groups"
  ))

## Statistics general ----
sel_summaries_general <- sel_data %>%
  group_by(site_id) %>%
  summarise(
    total_species = sum(n)
  ) %>%
  ungroup()

sel_summaries_general %>% summary()

sel_summaries_general %>%
  filter(total_species >= 2000) %>%
  nrow()

sel_summaries_general %>%
  filter(total_species >= 2000) %>%
  left_join(mpas_table[,c("site_id", "site_name")])

quantile(sel_summaries_general$total_species, .9)

## Statistics by group ----
sel_summaries <- sel_data %>%
  group_by(renamed_group, site_id) %>%
  summarise(n = sum(n)) %>%
  summarise(
    mean_species = mean(n),
    sd_species = sd(n),
    median_species = median(n),
    q0_25 = quantile(n, 0.25),
    q0_75 = quantile(n, 0.75)
  )

clipr::write_clip(sel_summaries[order(sel_summaries$total_species),], object = "table")

total_sp_groups <- mpa_data_full %>%
  mutate(renamed_group = case_when(
    # Vertebrates
    class == "Aves" ~ "Seabirds",
    class == "Mammalia"~ "Mammals",
    order == "Testudines" ~ "Turtles",
    class %in% c("Teleostei", "Coelacanthi",
                 "Dipneusti", "Cladistii",
                 "Chondrostei", "Holostei", 
                 "Myxini", "Petromyzonti") ~ "Fishes (others)",
    class %in% c("Elasmobranchii" , "Holocephali") ~ "Fishes (sharks/rays)",
    # Invertebrates
    phylum %in% animal_phyla$scientificname ~ "Invertebrates",
    .default = "Other groups"
  )) %>%
  group_by(renamed_group) %>%
  distinct(species) %>%
  summarise(total = n())

clipr::write_clip(total_sp_groups[order(total_sp_groups$total),], object = "table")

sel_summaries %>% 
  left_join(total_sp_groups) %>%
  arrange(total_species) %>%
  clipr::write_clip(object = "table")

## Statistics by group / protected category ----
sel_summaries_bylfp <- mpa_data_full %>%
  mutate(renamed_group = case_when(
    # Vertebrates
    class == "Aves" ~ "Seabirds",
    class == "Mammalia"~ "Mammals",
    order == "Testudines" ~ "Turtles",
    class %in% c("Teleostei", "Coelacanthi",
                 "Dipneusti", "Cladistii",
                 "Chondrostei", "Holostei", 
                 "Myxini", "Petromyzonti") ~ "Fishes (others)",
    class %in% c("Elasmobranchii" , "Holocephali") ~ "Fishes (sharks/rays)",
    # Invertebrates
    phylum %in% animal_phyla$scientificname ~ "Invertebrates",
    .default = "Other groups"
  )) %>%
  left_join(mpas_table[,c("site_id", "site_name", "marine_area", "lfp")]) %>%
  group_by(renamed_group, lfp) %>%
  distinct(species) %>%
  summarise(total = n()) %>%
  pivot_wider(names_from = lfp, values_from = total)

clipr::write_clip(sel_summaries_bylfp, object = "table")


## Statistics by size of protected area ----
round(quantile(na.omit(mpas_table$marine_area)), 2)

mpas_area_q <- mpas_selected[,c("site_id", "site_name", "marine_area", "lfp")] %>%
  mutate(size = ntile(marine_area, 4)) %>%
  mutate(size = case_when(
    size == 1 ~ "Q1",
    size == 2 ~ "Q2",
    size == 3 ~ "Q3",
    size == 4 ~ "Q4"
  ))

sel_summaries_size <- mpa_data_full %>%
  left_join(mpas_area_q) %>%
  mutate(category = ifelse(is.na(category), "Not RL", category)) %>%
  mutate(category = ifelse(!category %in% c("VU", "EN", "CR"),
                           "Not RL", category))

sel_summaries_size_nsp <- sel_summaries_size %>%
  group_by(size) %>%
  distinct(species) %>%
  count()

sel_summaries_size_rl <- sel_summaries_size %>%
  group_by(size, category) %>%
  distinct(species) %>%
  summarise(total = n()) %>%
  group_by(size) %>%
  mutate(perc = (total * 100)/sum(total))

clipr::write_clip(sel_summaries_size_rl, object = "table")


# Get number of species per size of area ----
large_area <- 150000

mpas_table_class <- mpas_selected %>%
  mutate(area_class = ifelse(is.na(marine_area), "Not available",
                             ifelse(marine_area >= large_area, "Large area", "Small area")))

sp_size_sites <- mpa_data_full %>%
  left_join(mpas_table_class[,c("site_id", "area_class", "marine_area")]) 
  
sp_size_sites %>%
  group_by(area_class) %>%
  distinct(species) %>%
  count()

sp_size <- mpa_data_full %>%
  group_by(site_id) %>%
  distinct(species) %>%
  count() %>%
  left_join(mpas_table_class[,c("site_id", "area_class", "marine_area")])

sp_size %>%
  ggplot() +
  geom_point(aes(x = marine_area, y = n), alpha = .2) +
  scale_x_continuous(labels = scales::comma) +
  theme_light() + 
  theme(plot.margin = margin(r = 14)) +
  facet_wrap(~factor(area_class, levels = c("Small area", "Large area")), scales = "free_x") +
  xlab("MPA area (km2)") + ylab("Number of species")

ggsave("graphs/scatter_size.png", width = 8, height = 5)



# Plot (A) - Make plot number of species per group ----
sel_plot_a <- sel_data %>%
  group_by(group, renamed_group, site_id) %>%
  summarise(total = sum(n)) %>%
  filter(!is.na(group))

sel_plot_a <- left_join(sel_plot_a, mpas_table_class[,c("site_id", "area_class")])


sel_plot_a_summs <- sel_plot_a %>%
  group_by(group, renamed_group) %>%
  summarise(median = median(total),
            q25 = quantile(total, .25),
            q75 = quantile(total, .75),
            max = max(total)) %>%
  mutate(subgroup = ifelse(max >= 1000, "high_species", "low_species")) %>%
  mutate(subgroup = factor(subgroup, levels = c("low_species", "high_species")))

sel_plot_a_dat <- sel_plot_a %>% # To be solved
  mutate(renamed_group = factor(renamed_group, levels = sel_plot_a_summs %>% 
                          arrange(desc(max)) %>%
                          ungroup() %>%
                          select(renamed_group) %>%
                          as.vector() %>% unlist() %>% unname())) %>%
  group_by(renamed_group) %>%
  mutate(max = max(total)) %>%
  mutate(subgroup = ifelse(max >= 1000, "high_species", "low_species")) %>%
  mutate(subgroup = factor(subgroup, levels = c("low_species", "high_species")))

iqr <- function(z, lower = 0.25, upper = 0.75) {
  data.frame(
    y = median(z),
    ymin = quantile(z, lower),
    ymax = quantile(z, upper)
  )
}

ggplot(sel_plot_a_dat) +
  geom_jitter(aes(y = total, x = renamed_group, color = area_class), alpha = .3,
              position = position_jitterdodge(jitter.width = .3, dodge.width = 0.5)) +
  scale_color_manual(values = c("#1f90bf", "#75c275")) +
  stat_summary(aes(x = renamed_group, y = total, shape = "IQR"), fun.data = iqr, size = 0.4) +
  coord_flip() +
  #scale_shape_manual("fraction", values = 21) +
  facet_wrap(~subgroup, nrow = 2, scales = "free") +
  ylab(NULL) + xlab("Number of species") +
  ggtitle("Number of species in MPAs according to area") +
  theme(
    panel.background = element_blank(),
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.2),
    panel.grid.major.x = element_blank(),
    axis.line.x = element_line(colour = "grey80", linewidth = 0.2),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    strip.text = element_blank(),
    #strip.text.x = element_text(size = 14, face = "bold", hjust = 0),
    strip.background = element_blank(),
    #panel.spacing.y = unit(3, "lines"),
    #legend.position = "none", 
    legend.title = element_blank(),
    legend.key = element_blank()
  )

ggsave("graphs/nspecies_by_group.png", height = 8, width = 13)

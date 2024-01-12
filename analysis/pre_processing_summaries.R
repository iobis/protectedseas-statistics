####################### StOR - State of the Ocean Report #######################
########################### MPA biodiversity analysis ##########################
# January of 2024
# Authors: Pieter Provoost, Silas C. Principe, Ward Appeltans
# Contact: helpdesk@obis.org
#
######################### Add groups to species list ###########################

# Load packages ----
library(storr)
library(tidyverse)

# Load files ----
species_list <- readRDS("data/biodiv/taxa.rds")
sites_list <- storr_rds("data/biodiv/sites_storr/")
outside_list <- readRDS("data/biodiv/taxa_outside_mpa.rds")

# Apply groupings and filters ----
animal_phyla <- worrms::wm_children(2)
animal_phyla <- animal_phyla %>%
  filter(rank == "Phylum") %>%
  filter(scientificname != "Chordata")

# Get the summaries list by group ----
sites_dat <- sites_list$mget(sites_list$list())
names(sites_dat) <- sites_list$list()
sites_dat <- bind_rows(sites_dat, .id = "site_id")

sites_data <- sites_dat %>%
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

grouped_sum <- sites_data %>%
  group_by(group, category, site_id) %>%
  count()

saveRDS(grouped_sum, "data/biodiv/sites_summ_group.rds")

### END
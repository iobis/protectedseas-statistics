####################### StOR - State of the Ocean Report #######################
########################### MPA biodiversity analysis ##########################
# January of 2024
# Authors: Pieter Provoost, Silas C. Principe, Ward Appeltans
# Contact: helpdesk@obis.org
#
######################### Get cumulative information ###########################

# Load packages ----
library(DBI)
library(tidyverse)
library(glue)


# Load/prepare files ----
database_path <- "data/biodiv/database.sqlite"
con <- dbConnect(RSQLite::SQLite(), database_path)

site_cells_table <- "site_cells"
gbif_occurrence_table <- "gbif_occurrence"
obis_occurrence_table <- "obis_occurrence"

taxa <- readRDS("data/biodiv/taxa.rds")
obis_taxa <- taxa %>% filter(source == "obis")
gbif_taxa <- taxa %>% filter(source == "gbif")

mpas_table <- read.csv("data/protectedseas/Navigator_Global_121923.csv")
mpas_selected <- mpas_table %>%
  filter(lfp >= 3)


# MPAs - Cumulative number of species and records ----

# Get string of site ids 
sites_qr <- paste0("'", mpas_selected$site_id, "'", collapse = ",")

# Prepare query for OBIS
obis_query <- glue('
      select species, min(max_year) as min_year, sum(records) as records
      from {site_cells_table}
      inner join {obis_occurrence_table} on {site_cells_table}.h3 = {obis_occurrence_table}.h3
      where site_id in ({sites_qr}) and max_year >= 1073
      group by species
    ')

# Get results
obis_res <- dbSendQuery(con, obis_query)
obis_records <- dbFetch(obis_res)

# Prepare query for GBIF
gbif_query <- glue('
      select species, min(max_year) as min_year, sum(records) as records
      from {site_cells_table}
      inner join {gbif_occurrence_table} on {site_cells_table}.h3 = {gbif_occurrence_table}.h3
      where site_id in ({sites_qr}) and max_year >= 1073
      group by species
    ')

# Get results
gbif_res <- dbSendQuery(con, gbif_query)
gbif_records <- dbFetch(gbif_res) 

# Bind
gbif_records <- gbif_records %>% 
  select(input = species, min_year, records) %>%
  left_join(gbif_taxa, by = "input",
            multiple = "first") %>% # TODO: To be corrected for species count (possible separate in two pieces, one for records and other for count)
  filter(is.na(species)) %>%
  select(species, min_year, records)

all_records <- bind_rows(obis_records, gbif_records)

inside_mpas_cum <- all_records %>%
  group_by(species) %>%
  summarise(min_year = min(min_year)) %>%
  group_by(min_year) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  arrange(min_year) %>%
  mutate(cum = cumsum(n))

inside_mpas_cum_rec <- all_records %>%
  group_by(min_year) %>%
  summarise(n = sum(records)) %>%
  ungroup() %>%
  arrange(min_year) %>%
  mutate(cum = cumsum(n))

rm(all_records, obis_records, gbif_records)
gc()


# Outside MPAs - Cumulative number of species and records ----

# Prepare query for OBIS
obis_query <- glue('
      select species, min(max_year) as min_year, sum(records) as records
      from {site_cells_table}
      inner join {obis_occurrence_table} on {site_cells_table}.h3 = {obis_occurrence_table}.h3
      where site_id not in ({sites_qr}) and max_year >= 1073
      group by species
    ')

# Get results
obis_res <- dbSendQuery(con, obis_query)
obis_records <- dbFetch(obis_res)

# Prepare query for GBIF
gbif_query <- glue('
      select species, min(max_year) as min_year, sum(records) as records
      from {site_cells_table}
      inner join {gbif_occurrence_table} on {site_cells_table}.h3 = {gbif_occurrence_table}.h3
      where site_id not in ({sites_qr}) and max_year >= 1073
      group by species
    ')

# Get results
gbif_res <- dbSendQuery(con, gbif_query)
gbif_records <- dbFetch(gbif_res)

gbif_records <- gbif_records %>% 
  select(input = species, min_year, records) %>%
  left_join(gbif_taxa, by = "input",
            multiple = "first") %>% # TODO: To be corrected for species count (possible separate in two pieces, one for records and other for count)
  filter(is.na(species)) %>%
  select(species, min_year, records)


# Bind
all_records <- bind_rows(obis_records, gbif_records)

outside_mpas_cum <- all_records %>%
  group_by(species) %>%
  summarise(min_year = min(min_year)) %>%
  group_by(min_year) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  arrange(min_year) %>%
  mutate(cum = cumsum(n))

outside_mpas_cum_rec <- all_records %>%
  group_by(min_year) %>%
  summarise(n = sum(records)) %>%
  ungroup() %>%
  arrange(min_year) %>%
  mutate(cum = cumsum(n))


# Save objects ----

saveRDS(list(sp_inside_mpa = inside_mpas_cum,
             rec_inside_mpa = inside_mpas_cum_rec,
             sp_outside_mpa = outside_mpas_cum,
             rec_outside_mpa = outside_mpas_cum_rec),
        file = "data/biodiv/cummulative.rds")

DBI::dbDisconnect(con)

### END
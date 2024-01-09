library(sf)
library(dplyr)
library(h3jsr)
library(purrr)
library(glue)
library(DBI)
source("common.R")

info <- read.csv("../protectedseas/shapes/Navigator_Global_121923.csv") # %>% filter(category_name == "IUCN MPA")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)
st <- storr::storr_rds(sites_storr)
redlist <- readRDS("redlist.rds")
taxa <- readRDS("taxa.rds")

walk(info$site_id, function(site_id) {
  if (!st$exists(site_id)) {

    obis_query <- glue("
      select site_id, species
      from {site_cells_table}
      inner join {obis_occurrence_table} on {site_cells_table}.h3 = {obis_occurrence_table}.h3
      where site_id = '{site_id}'
      group by site_id, species
    ")
    obis_res <- dbSendQuery(con, obis_query)
    obis_species <- dbFetch(obis_res)
    gbif_query <- glue("
      select site_id, species
      from {site_cells_table}
      inner join {gbif_occurrence_table} on {site_cells_table}.h3 = {gbif_occurrence_table}.h3
      where site_id = '{site_id}'
      group by site_id, species
    ")
    gbif_res <- dbSendQuery(con, gbif_query)
    gbif_species <- dbFetch(gbif_res)
    
    species <- bind_rows(obis_species, gbif_species) %>%
      distinct() %>%
      left_join(taxa, by = "species") %>%
      left_join(redlist, by = "species")
    
    st$set(site_id, species)    
  }

}, .progress = TRUE)

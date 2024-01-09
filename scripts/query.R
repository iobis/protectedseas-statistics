source("scripts/requirements.R")
source("scripts/common.R")

info <- read.csv("../protectedseas/shapes/Navigator_Global_121923.csv") # %>% filter(category_name == "IUCN MPA")
redlist <- readRDS("redlist.rds")
taxa <- readRDS("taxa.rds")

# get species lists by site and store in a storr

con <- dbConnect(RSQLite::SQLite(), sqlite_file)
st <- storr::storr_rds(sites_storr)

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


# get species list outside a specific subset of sites

info %>%
  select(site_id, category_name) %>%
  dbWriteTable(con, sites_table, ., overwrite = TRUE)

dbSendQuery(con, glue("create index {sites_table}_site_id on {sites_table}(site_id)"))
dbSendQuery(con, glue("create index {sites_table}_category_name on {sites_table}(category_name)"))

obis_query <- glue("
  with mpas as (
  select * from sites
  where sites.category_name = 'IUCN MPA'
  )
  select distinct(species) as species from obis_occurrence
  left join site_cells on obis_occurrence.h3 = site_cells.h3
  left join mpas on mpas.site_id = site_cells.site_id
  where mpas.category_name is null
")
obis_res <- dbSendQuery(con, obis_query)
obis_species <- dbFetch(obis_res)

gbif_query <- glue("
  with mpas as (
  select * from sites
  where sites.category_name = 'IUCN MPA'
  )
  select distinct(species) as species from gbif_occurrence
  left join site_cells on gbif_occurrence.h3 = site_cells.h3
  left join mpas on mpas.site_id = site_cells.site_id
  where mpas.category_name is null
")
gbif_res <- dbSendQuery(con, gbif_query)
gbif_species <- dbFetch(gbif_res)

species <- bind_rows(obis_species, gbif_species) %>%
  distinct() %>%
  left_join(taxa, by = "species") %>%
  left_join(redlist, by = "species")

saveRDS(species, "taxa_outside_mpa.rds")

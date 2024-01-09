# library(dplyr)
# library(DBI)
# library(rgbif)
# library(purrr)
# library(worrms)
# library(tidyr)
# library(glue)
# library(furrr)
# source("common.R")
# 
# con <- dbConnect(RSQLite::SQLite(), sqlite_file)
# 
# dbSendQuery(con, glue("alter table {gbif_occurrence_table} add AphiaID int"))
# 
# dbSendQuery(con, glue("create index {gbif_occurrence_table}_species on {gbif_occurrence_table}(species)"))
# dbSendQuery(con, glue("create index {gbif_taxa_table}_input on {gbif_taxa_table}(input)"))
# 
# dbSendQuery(con, glue("update {gbif_occurrence_table} set AphiaID = {gbif_taxa_table}.AphiaID from {gbif_occurrence_table} t inner join {gbif_taxa_table} on t.species = {gbif_taxa_table}.input"))

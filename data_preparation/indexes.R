source("requirements.R")
source("common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

drop_indexes <- function() {
}

create_indexes <- function() {
  dbSendQuery(con, glue("create index gbif_occurrence_h3 on {gbif_occurrence_table}(h3)"))
  # dbSendQuery(con, glue("create index gbif_occurrence_species on {gbif_occurrence_table}(species)"))
  dbSendQuery(con, glue("create index obis_occurrence_h3 on {obis_occurrence_table}(h3)"))
  # dbSendQuery(con, glue("create index obis_occurrence_species on {obis_occurrence_table}(species)"))
  dbSendQuery(con, glue("create index {site_cells_table}_site_id on {site_cells_table}(site_id)"))
  dbSendQuery(con, glue("create index {site_cells_table}_h3 on {site_cells_table}(h3)"))
}

create_indexes()

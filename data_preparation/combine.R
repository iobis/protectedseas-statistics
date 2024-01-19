source("data_preparation/requirements.R")
source("data_preparation/common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

dbSendQuery(con, glue("create table occurrence_temp as select h3, species, records, min_year, max_year from {obis_occurrence_table}"))
dbSendQuery(con, glue("insert into occurrence_temp select h3, species, records, min_year, max_year from {gbif_occurrence_table}"))
dbSendQuery(con, glue("create index occurrence_temp_h3 on occurrence_temp(h3)"))
dbSendQuery(con, glue("create index occurrence_temp_species on occurrence_temp(species)"))

dbSendQuery(con, glue("drop table if exists {occurrence_table}"))

dbSendQuery(con, glue("
  create table {occurrence_table} as
  select species, h3, sum(records) as records, min(min_year) as min_year, max(max_year) as max_year
  from occurrence_temp
  group by species, h3
"))

dbSendQuery(con, glue("drop table if exists occurrence_temp"))
dbSendQuery(con, glue("drop table if exists {obis_occurrence_table}"))
dbSendQuery(con, glue("drop table if exists {gbif_occurrence_table}"))

dbSendQuery(con, glue("create index occurrence_h3 on {occurrence_table}(h3)"))
dbSendQuery(con, glue("create index occurrence_species on {occurrence_table}(species)"))

dbSendQuery(con, "vacuum")

source("data_preparation/requirements.R")
source("data_preparation/common.R")

st <- storr::storr_rds(obis_storr_path)
con <- dbConnect(RSQLite::SQLite(), sqlite_file)

dbSendQuery(con, glue("drop table if exists {obis_occurrence_table}_temp"))
dbSendQuery(con, glue("drop table if exists {obis_occurrence_table}"))

f <- 4
grid <- st_make_grid(cellsize = c(10 / f, 10 / f), offset = c(-180, -90), n = c(36 * f, 18 * f), crs = st_crs(4326))

purrr::walk(seq_along(grid), function(i) {
  if (st$exists(as.character(i))) {
    st$get(as.character(i)) %>%
      filter(!is.na(species)) %>%
      dbWriteTable(con, glue("{obis_occurrence_table}_temp"), ., append = TRUE)
  }
}, .progress = TRUE)

dbSendQuery(con, glue("
  create table {obis_occurrence_table} as
  select h3, species, sum(records) as records, min(min_year) as min_year, max(max_year) as max_year
  from {obis_occurrence_table}_temp
  group by h3, species
"))

dbSendQuery(con, glue("drop table if exists {obis_occurrence_table}_temp"))

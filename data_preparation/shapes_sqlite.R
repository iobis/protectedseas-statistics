source("data_preparation/requirements.R")
source("data_preparation/common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

# indexed shapes to sqlite

st <- storr::storr_rds(shapes_storr_path)

site_ids <- read_sf(shapefile_path) %>%
  pull(SITE_ID)

dbSendQuery(con, glue("drop table if exists {site_cells_table}"))

walk(site_ids, function(site_id) {
  message(site_id)
  if (st$exists(site_id)) {
    cells <- st$get(site_id)
    data.frame(site_id = site_id, h3 = cells) %>%
      dbWriteTable(con, site_cells_table, ., append = TRUE)
  }
})#, .progress = TRUE)

# site info to sqlite

info <- read.csv(info_file)

info %>%
  select(site_id, category_name, lfp) %>%
  dbWriteTable(con, sites_table, ., overwrite = TRUE)

# indexes

dbSendQuery(con, glue("create index {sites_table}_site_id on {sites_table}(site_id)"))
dbSendQuery(con, glue("create index {sites_table}_lfp on {sites_table}(lfp)"))

dbSendQuery(con, glue("create index {site_cells_table}_h3 on {site_cells_table}(h3)"))
dbSendQuery(con, glue("create index {site_cells_table}_site_id on {site_cells_table}(site_id)"))

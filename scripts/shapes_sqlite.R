source("requirements.R")
source("common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)
st <- storr::storr_rds(shapes_storr_path)

site_ids <- read_sf(shapefile_path) %>%
  pull(SITE_ID)

dbSendQuery(con, glue("drop table if exists {site_cells_table}"))

walk(site_ids, function(site_id) {
  if (st$exists(site_id)) {
    cells <- st$get(site_id)
    data.frame(site_id = site_id, h3 = cells) %>%
      dbWriteTable(con, site_cells_table, ., append = TRUE)
  }
}, .progress = TRUE)

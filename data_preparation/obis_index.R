source("requirements.R")
source("common.R")

st <- storr::storr_rds(obis_storr_path)

# index occurrences to h3 and create occurrence table

f <- 4
grid <- st_make_grid(cellsize = c(10 / f, 10 / f), offset = c(-180, -90), n = c(36 * f, 18 * f), crs = st_crs(4326))

purrr::walk(seq_along(grid), function(i) {
  bbox <- st_bbox(grid[i])
  df <- open_dataset(obis_snapshot_path) %>%
    select(decimalLongitude, decimalLatitude, species, AphiaID, date_year) %>%
    filter(decimalLongitude >= bbox$xmin & decimalLongitude <= bbox$xmax & decimalLatitude >= bbox$ymin & decimalLatitude <= bbox$ymax) %>%
    collect()
  if (nrow(df) > 0) {
    suppressMessages({
      df %>%
        mutate(h3 = point_to_cell(.[,c("decimalLongitude", "decimalLatitude")], h3_res)) %>%
        group_by(h3, species, AphiaID) %>%
        summarize(records = n(), max_year = max(date_year, na.rm = TRUE)) %>%
        mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
        st$set(i, .)
    })
  }
}, .progress = TRUE)

# to sqlite

con <- dbConnect(RSQLite::SQLite(), sqlite_file)
dbSendQuery(con, glue("drop table if exists {obis_occurrence_table}"))

purrr::walk(seq_along(grid), function(i) {
  if (st$exists(as.character(i))) {
    st$get(as.character(i)) %>%
      filter(!is.na(species)) %>%
      dbWriteTable(con, obis_occurrence_table, ., append = TRUE)
  }
}, .progress = TRUE)

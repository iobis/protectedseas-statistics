source("data_preparation/requirements.R")
source("data_preparation/common.R")

st <- storr::storr_rds(obis_storr_path)

f <- 4
grid <- st_make_grid(cellsize = c(10 / f, 10 / f), offset = c(-180, -90), n = c(36 * f, 18 * f), crs = st_crs(4326))

walk(seq_along(grid), function(i) {
  if (!st$exists(as.character(i))) {
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
          summarize(records = n(), min_year = min(date_year, na.rm = TRUE), max_year = max(date_year, na.rm = TRUE)) %>%
          mutate(min_year = ifelse(is.infinite(min_year), NA, min_year)) %>%
          mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
          st$set(i, .)
      })
    }
  }
}, .progress = TRUE)

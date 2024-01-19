source("data_preparation/requirements.R")
source("data_preparation/common.R")

library(nngeo)
library(stringi)

sf_use_s2(FALSE)
shapefile <- "https://github.com/iobis/mwhs-shapes/raw/master/output/marine_world_heritage.gpkg"

shapes <- read_sf(shapefile) %>%
  mutate(name_simplified = gsub("_+", "_", gsub("[^[:alnum:]]", "_", tolower(stri_trans_general(name, "latin-ascii"))))) %>%
  group_by(name_simplified) %>%
  summarize() %>%
  st_remove_holes()

# to storr

st <- storr::storr_rds("mwhs_storr")

polygon_to_cells_possibly = possibly(.f = h3jsr::polygon_to_cells, otherwise = NULL)

for (i in 1:nrow(shapes)) {
  site_id <- shapes$name_simplified[i]
  message(glue("{site_id} | {i}/{nrow(shapes)}"))
  error_file <- glue("shapes_errors/{site_id}.txt")

  if (!st$exists(site_id) & !file.exists(error_file)) {
    suppressMessages({
      result <- polygon_to_cells_possibly(shapes$geometry[i], h3_res)      
    })
    if (!is.null(result)) {
      cells <- result[[1]]
      st$set(site_id, cells)
    } else {
      file.create(error_file)
    }
  }
}

# to sqlite

dbSendQuery(con, glue("drop table if exists mwhs_cells"))

walk(shapes$name_simplified, function(site_id) {
  if (st$exists(site_id)) {
    cells <- st$get(site_id)
    data.frame(site_id = site_id, h3 = cells) %>%
      dbWriteTable(con, "mwhs_cells", ., append = TRUE)
  }
}, .progress = TRUE)

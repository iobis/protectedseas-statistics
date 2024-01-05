library(sf)
library(dplyr)
library(h3jsr)
library(purrr)

h3_res <- 7
shapes <- read_sf("shapes/Navigator_Global_121923/Navigator_Global_121923.shp")

st <- storr::storr_rds("shapes_storr")

polygon_to_cells_possibly = possibly(.f = h3jsr::polygon_to_cells, otherwise = NULL)

# TODO: check errors!

walk(seq_along(shapes$SITE_ID), function(i) {
  site_id <- shapes$SITE_ID[i]
  if (!st$exists(site_id)) {
    suppressMessages({
      result <- polygon_to_cells_possibly(shapes$geometry[i], h3_res)      
    })
    if (!is.null(result)) {
      cells <- result[[1]]
      st$set(site_id, cells)
    } else {
      file.create(glue::glue("shapes_errors/{site_id}.txt"))
    }
  }
}, .progress = TRUE)

# st_remove_holes()

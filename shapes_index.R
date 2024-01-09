library(sf)
library(dplyr)
library(h3jsr)
library(purrr)
library(glue)
source("common.R")

shapes <- read_sf(shapefile_path)

st <- storr::storr_rds(shapes_storr_path)

polygon_to_cells_possibly = possibly(.f = h3jsr::polygon_to_cells, otherwise = NULL)

for (i in 1:nrow(shapes)) {
  site_id <- shapes$SITE_ID[i]
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

# st_remove_holes()

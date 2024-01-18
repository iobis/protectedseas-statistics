suppressMessages(suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(h3jsr)
  library(DBI)
  library(data.table)
  source("data_preparation/common.R")
  
  args <- commandArgs(trailingOnly = TRUE)
  parquet_file <- args[1]
  st <- storr::storr_rds(gbif_storr_path)
  
  if (!st$exists(parquet_file)) {
    
    row_to_geo <- function(row) {
      point_to_cell(c(row$decimallongitude, row$decimallatitude), h3_res)
    }
    
    df <- open_dataset(paste0(gbif_snapshot_path, parquet_file)) %>%
      filter(decimallongitude >= -180 & decimallongitude <= 180 & decimallatitude >= -90 & decimallatitude <= 90 & !is.na(species)) %>%
      group_by(species, decimallongitude, decimallatitude, year) %>%
      summarize(records = n()) %>%
      ungroup() %>%
      collect() %>%
      mutate(h3 = point_to_cell(.[,c("decimallongitude", "decimallatitude")], h3_res))
    
    setDT(df)[, .(records = sum(records), min_year = min(year, na.rm = TRUE), max_year = max(year, na.rm = TRUE)), by = .(h3, species)] %>%
      as.data.frame() %>%
      mutate(min_year = ifelse(is.infinite(min_year), NA, min_year)) %>%
      mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
      st$set(parquet_file, .)
    
  }
  
})))

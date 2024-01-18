suppressMessages(suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(DBI)
  source("data_preparation/common.R")

  args <- commandArgs(trailingOnly = TRUE)
  parquet_file <- args[1]

  gbif_species <- readRDS(gbif_marine_species_file) %>%
    # temporary fix for duplicate inputs
    group_by(input) %>%
    filter(row_number() == 1) %>%
    select(input, species)
  
  st <- storr::storr_rds("gbif_storr")
  con <- dbConnect(RSQLite::SQLite(), sqlite_file)

  test <- st$get(parquet_file) %>%
    filter(!is.na(species)) %>%
    rename("input" = "species") %>%
    inner_join(gbif_species, by = "input", keep = FALSE) %>%
    select(-input) %>%
    dbWriteTable(con, gbif_occurrence_table, ., append = TRUE)

})))

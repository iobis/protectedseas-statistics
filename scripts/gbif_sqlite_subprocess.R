suppressMessages(suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(DBI)
  source("common.R")

  args <- commandArgs(trailingOnly = TRUE)
  parquet_file <- args[1]

  gbif_marine_taxa <- readRDS(gbif_marine_taxa_file) %>%
    select(input, AphiaID) %>%
    distinct()
    
  st <- storr::storr_rds("gbif_storr")
  con <- dbConnect(RSQLite::SQLite(), sqlite_file)

  st$get(parquet_file) %>%
    filter(!is.na(species)) %>%
    inner_join(gbif_marine_taxa, by = c("species" = "input")) %>%
    dbWriteTable(con, gbif_occurrence_table, ., append = TRUE)

})))

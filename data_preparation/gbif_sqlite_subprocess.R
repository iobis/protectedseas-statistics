suppressMessages(suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(DBI)
  source("common.R")

  args <- commandArgs(trailingOnly = TRUE)
  parquet_file <- args[1]

  st <- storr::storr_rds("gbif_storr")
  con <- dbConnect(RSQLite::SQLite(), sqlite_file)

  st$get(parquet_file) %>%
    filter(!is.na(species)) %>%
    dbWriteTable(con, gbif_occurrence_table, ., append = TRUE)

})))

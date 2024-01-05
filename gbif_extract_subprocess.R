suppressMessages(suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(h3jsr)
  library(DBI)
  library(purrr)
  library(tidyr)
  library(glue)

  args <- commandArgs(trailingOnly = TRUE)
  parquet_file <- args[1]
  
  h3_res <- 7
  gbif_snapshot_path <- "/Volumes/LaCie/gbif/occurrence.parquet/"
  sqlite_file <- "database.sqlite"
  occurrence_table <- "gbif_occurrence"
  con <- dbConnect(RSQLite::SQLite(), sqlite_file)
  
  row_to_geo <- function(row) {
    point_to_cell(c(row$decimallongitude, row$decimallatitude), h3_res)
  }
  
  open_dataset(paste0(gbif_snapshot_path, parquet_file)) %>%
    select(decimallongitude, decimallatitude, species, year) %>%
    filter(decimallongitude >= -180 & decimallongitude <= 180 & decimallatitude >= -90 & decimallatitude <= 90) %>%
    collect() %>%
    mutate(h3 = point_to_cell(.[,c("decimallongitude", "decimallatitude")], h3_res)) %>%
    group_by(h3, species) %>%
    summarize(records = n(), max_year = max(year, na.rm = TRUE)) %>%
    mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
    dbWriteTable(con, occurrence_table, ., append = TRUE)
  
})))

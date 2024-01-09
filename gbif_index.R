library(dplyr)
library(DBI)
library(rgbif)
library(purrr)
library(worrms)
library(tidyr)
library(glue)
source("common.R")

parquet_files <- list.files(gbif_snapshot_path)

for (parquet_file in parquet_files) {
  command <- glue("Rscript gbif_index_subprocess.R {parquet_file}")
  message(command)
  suppressMessages({
    system(command)
  })
}

source("data_preparation/requirements.R")
source("data_preparation/common.R")

st <- storr::storr_rds("gbif_storr")
parquet_files <- list.files(gbif_snapshot_path)
con <- dbConnect(RSQLite::SQLite(), sqlite_file)

dbSendQuery(con, glue("drop table if exists {gbif_occurrence_table}"))

for (parquet_file in parquet_files) {
  command <- glue("Rscript data_preparation/gbif_sqlite_subprocess.R {parquet_file}")
  message(command)
  suppressMessages({
    system(command)
  })
}

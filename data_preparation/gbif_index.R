source("data_preparation/requirements.R")
source("data_preparation/common.R")

parquet_files <- list.files(gbif_snapshot_path)

for (parquet_file in parquet_files) {
  command <- glue("Rscript data_preparation/gbif_index_subprocess.R {parquet_file}")
  message(command)
  suppressMessages({
    system(command)
  })
}

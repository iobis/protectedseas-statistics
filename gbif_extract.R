library(dplyr)
library(arrow)
library(h3jsr)
library(DBI)
library(rgbif)
library(purrr)
library(furrr)
library(worrms)
library(tidyr)

h3_res <- 7
gbif_snapshot_path <- "~/Desktop/temp/occurrence.parquet/"
sqlite_file <- "gbif.db"

parquet_files <- list.files(gbif_snapshot_path)

row_to_geo <- function(row) {
  point_to_cell(c(row$decimallatitude, row$decimallongitude), h3_res)
}

if (file.exists(sqlite_file)) {
  file.remove(sqlite_file)
}
con <- dbConnect(RSQLite::SQLite(), sqlite_file)

for (parquet_file in parquet_files) {
  message(parquet_file)
  open_dataset(paste0(gbif_snapshot_path, parquet_file)) %>%
    select(decimallongitude, decimallatitude, species, year) %>%
    filter(decimallongitude >= -180 & decimallongitude <= 180 & decimallatitude >= -90 & decimallatitude <= 90) %>%
    collect() %>%
    mutate(h3 = row_to_geo(.)) %>%
    group_by(h3, species) %>%
    summarize(records = n(), max_year = max(year, na.rm = TRUE)) %>%
    mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
    dbWriteTable(con, "occurrence", ., append = TRUE)
}

# match names

worms_for_names <- possibly(function(x) {
  worrms::wm_records_names(x, marine_only = FALSE) %>%
    setNames(x) %>%
    bind_rows(.id = "input")
}, otherwise = NULL)

res <- dbSendQuery(con, "select species from occurrence group by species")
species_names <- dbFetch(res) %>%
  pull(species) %>%
  unique() %>%
  na.omit()

name_batches <- split(species_names, as.integer((seq_along(species_names) - 1) / 50))
plan(multisession, workers = 10)
matches <- future_map(name_batches, worms_for_names, .progress = TRUE) %>%
  bind_rows()

# resolve to accepted names

aphiaids <- matches %>%
  filter(AphiaID != valid_AphiaID) %>%
  pull(valid_AphiaID) %>%
  unique()

aphiaid_batches <- split(aphiaids, as.integer((seq_along(aphiaids) - 1) / 50))
plan(multisession, workers = 10)
replacement_taxa <- future_map(aphiaid_batches, wm_record, .progress = TRUE) %>%
  bind_rows() %>%
  select(valid_AphiaID = AphiaID, AphiaID = AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

valid_taxa <- matches %>%
  filter(AphiaID == valid_AphiaID) %>%
  select(input, AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

invalid_taxa <- matches %>%
  filter(AphiaID != valid_AphiaID) %>%
  select(input, valid_AphiaID) %>%
  left_join(replacement_taxa, by = "valid_AphiaID") %>%
  select(-valid_AphiaID)

taxa <- bind_rows(valid_taxa, invalid_taxa) %>%
  mutate_at(c("isMarine", "isBrackish"), ~replace_na(., 0)) %>%
  mutate(in_scope = isMarine + isBrackish > 0)

dbWriteTable(con, "taxa", taxa, overwrite = TRUE)

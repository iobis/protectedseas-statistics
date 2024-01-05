library(dplyr)
library(arrow)
library(h3jsr)
library(DBI)
library(rgbif)
library(purrr)
library(furrr)
library(worrms)
library(tidyr)
library(sf)
library(glue)

h3_res <- 7
obis_snapshot_path <- "~/Desktop/temp/obis_20231025.parquet"
sqlite_file <- "database.sqlite"
occurrence_table <- "obis_occurrence"
taxa_table <- "obis_taxa"

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

# index occurrences to h3 and create occurrence table

dbSendQuery(con, "drop table obis_occurrence")

f <- 4
grid <- st_make_grid(cellsize = c(10 / f, 10 / f), offset = c(-180, -90), n = c(36 * f, 18 * f), crs = st_crs(4326))

purrr::walk(seq_along(grid), function(i) {
  bbox <- st_bbox(grid[i])
  df <- open_dataset(obis_snapshot_path) %>%
    select(decimalLongitude, decimalLatitude, species, AphiaID, date_year) %>%
    filter(decimalLongitude >= bbox$xmin & decimalLongitude <= bbox$xmax & decimalLatitude >= bbox$ymin & decimalLatitude <= bbox$ymax) %>%
    collect()
  if (nrow(df) > 0) {
    suppressMessages({
      df %>%
        mutate(h3 = point_to_cell(.[,c("decimalLongitude", "decimalLatitude")], h3_res)) %>%
        group_by(h3, species, AphiaID) %>%
        summarize(records = n(), max_year = max(date_year, na.rm = TRUE)) %>%
        mutate(max_year = ifelse(is.infinite(max_year), NA, max_year)) %>%
        dbWriteTable(con, "obis_occurrence", ., append = TRUE)
    })
  }
}, .progress = TRUE)

# match names and create taxa table

# worms_for_names <- possibly(function(x) {
#   worrms::wm_records_names(x, marine_only = FALSE) %>%
#     setNames(x) %>%
#     bind_rows(.id = "input")
# }, otherwise = NULL)
# 
# res <- dbSendQuery(con, "select species from occurrence group by species")
# species_names <- dbFetch(res) %>%
#   pull(species) %>%
#   unique() %>%
#   na.omit()
# 
# name_batches <- split(species_names, as.integer((seq_along(species_names) - 1) / 50))
# plan(multisession, workers = 10)
# matches <- future_map(name_batches, worms_for_names, .progress = TRUE) %>%
#   bind_rows()

# resolve to accepted names

# aphiaids <- matches %>%
#   filter(AphiaID != valid_AphiaID) %>%
#   pull(valid_AphiaID) %>%
#   unique()
# 
# aphiaid_batches <- split(aphiaids, as.integer((seq_along(aphiaids) - 1) / 50))
# plan(multisession, workers = 10)
# replacement_taxa <- future_map(aphiaid_batches, wm_record, .progress = TRUE) %>%
#   bind_rows() %>%
#   select(valid_AphiaID = AphiaID, AphiaID = AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)
# 
# valid_taxa <- matches %>%
#   filter(AphiaID == valid_AphiaID) %>%
#   select(input, AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)
# 
# invalid_taxa <- matches %>%
#   filter(AphiaID != valid_AphiaID) %>%
#   select(input, valid_AphiaID) %>%
#   left_join(replacement_taxa, by = "valid_AphiaID") %>%
#   select(-valid_AphiaID)
# 
# taxa <- bind_rows(valid_taxa, invalid_taxa) %>%
#   mutate_at(c("isMarine", "isBrackish"), ~replace_na(., 0)) %>%
#   mutate(in_scope = isMarine + isBrackish > 0)
# 
# dbWriteTable(con, "gbif_taxa", taxa, overwrite = TRUE)

# add indexes

# dbSendQuery(con, "create index gbif_occurrence_h3 on gbif_occurrence(h3)")
# dbSendQuery(con, "create index gbif_occurrence_species on gbif_occurrence(species)")
# 
# dbSendQuery(con, "create index gbif_taxa_input on gbif_taxa(input)")
# dbSendQuery(con, "create index gbif_taxa_inscope on gbif_taxa(in_scope)")

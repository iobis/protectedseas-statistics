source("requirements.R")
source("common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

res <- dbSendQuery(con, glue("select distinct(AphiaID) from {obis_occurrence_table}"))
aphiaids <- dbFetch(res)[,1]
  
aphiaid_batches <- split(aphiaids, as.integer((seq_along(aphiaids) - 1) / 50))

plan(multisession, workers = 10)
records <- future_map(aphiaid_batches, worrms::wm_record, .progress = TRUE) %>%
  bind_rows()

taxa <- records %>%
  select(AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, genus, isMarine, isBrackish, isFreshwater, isTerrestrial) %>%
  mutate_at(c("isMarine", "isBrackish"), ~replace_na(., 0)) %>%
  mutate(in_scope = isMarine + isBrackish > 0)

dbWriteTable(con, obis_taxa_table, taxa, overwrite = TRUE)

source("data_preparation/requirements.R")
source("data_preparation/common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

res <- dbSendQuery(con, glue("select distinct(species) from {occurrence_table}"))
species_names <- dbFetch(res)$species

worms_for_names <- possibly(function(x) {
  worrms::wm_records_names(x, marine_only = FALSE)
}, otherwise = NULL)

name_batches <- split(species_names, as.integer((seq_along(species_names) - 1) / 50))
plan(multisession, workers = 10)
matches <- future_map(name_batches, worms_for_names, .progress = TRUE) %>%
  bind_rows()

taxa <- matches %>%
  arrange(scientificname, status) %>% # accepted first
  group_by(scientificname) %>%
  filter(row_number() == 1) %>%
  ungroup()

# TODO: check why this doesn't have all names

dbWriteTable(con, taxa_table, taxa, overwrite = TRUE)
dbSendQuery(con, glue("create index taxa_scientificname on {taxa_table}(scientificname)"))

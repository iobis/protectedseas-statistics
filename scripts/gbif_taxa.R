source("scripts/requirements.R")
source("scripts/common.R")

species_names <- open_dataset(gbif_snapshot_path) %>%
  filter(!is.na(species)) %>%
  distinct(species) %>%
  collect()

# match names and create taxa table

worms_for_names <- possibly(function(x) {
  worrms::wm_records_names(x, marine_only = FALSE) %>%
    setNames(x) %>%
    bind_rows(.id = "input")
}, otherwise = NULL)

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
  select(valid_AphiaID = AphiaID, AphiaID = AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, family, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

valid_taxa <- matches %>%
  filter(AphiaID == valid_AphiaID) %>%
  select(input, AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, family, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

invalid_taxa <- matches %>%
  filter(AphiaID != valid_AphiaID) %>%
  select(input, valid_AphiaID) %>%
  left_join(replacement_taxa, by = "valid_AphiaID") %>%
  select(-valid_AphiaID)

taxa <- bind_rows(valid_taxa, invalid_taxa) %>%
  mutate_at(c("isMarine", "isBrackish"), ~replace_na(., 0)) %>%
  mutate(in_scope = isMarine + isBrackish > 0)

marine_taxa <- taxa %>%
  filter(in_scope) %>%
  select(input, AphiaID, scientificName, taxonRank, phylum, class, order, family, genus) %>%
  mutate(species = ifelse(taxonRank =="Species", scientificName, NA_character_))

saveRDS(marine_taxa, gbif_marine_taxa_file)

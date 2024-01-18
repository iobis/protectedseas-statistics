source("scripts/requirements.R")
source("scripts/common.R")

species_names <- open_dataset(gbif_snapshot_path) %>%
  filter(!is.na(species)) %>%
  distinct(species) %>%
  collect()

# match names and create table with input and matched taxon

worms_for_names <- possibly(function(x) {
  worrms::wm_records_names(x, marine_only = FALSE) %>%
    setNames(x) %>%
    bind_rows(.id = "input")
}, otherwise = NULL)

name_batches <- split(species_names, as.integer((seq_along(species_names) - 1) / 50))
plan(multisession, workers = 10)
matches <- future_map(name_batches, worms_for_names, .progress = TRUE) %>%
  bind_rows()

# resolve matches to accepted names

accepted_aphiaids <- matches %>%
  filter(AphiaID != valid_AphiaID) %>%
  pull(valid_AphiaID) %>%
  unique()

aphiaid_batches <- split(accepted_aphiaids, as.integer((seq_along(accepted_aphiaids) - 1) / 50))
plan(multisession, workers = 10)
accepted_taxa <- future_map(aphiaid_batches, wm_record, .progress = TRUE) %>%
  bind_rows() %>%
  select(valid_AphiaID = AphiaID, AphiaID = AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, family, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

taxa_ok <- matches %>%
  filter(AphiaID == valid_AphiaID) %>%
  select(input, AphiaID, scientificName = scientificname, taxonRank = rank, kingdom, phylum, class, order, family, genus, isMarine, isBrackish, isFreshwater, isTerrestrial)

taxa_fixed <- matches %>%
  filter(AphiaID != valid_AphiaID) %>%
  select(input, valid_AphiaID) %>%
  left_join(accepted_taxa, by = "valid_AphiaID") %>%
  select(-valid_AphiaID)

taxa <- bind_rows(taxa_ok, taxa_fixed) %>%
  mutate_at(c("isMarine", "isBrackish"), ~replace_na(., 0)) %>%
  mutate(in_scope = isMarine + isBrackish > 0)

marine_species <- taxa %>%
  filter(in_scope) %>%
  select(input, AphiaID, scientificName, taxonRank, phylum, class, order, family, genus) %>%
  mutate(species = ifelse(taxonRank =="Species", scientificName, NA_character_)) %>%
  filter(!is.na(species))

saveRDS(marine_species, gbif_marine_species_file)

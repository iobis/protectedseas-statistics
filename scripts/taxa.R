source("requirements.R")
source("common.R")

# TODO this should generate the file that can be used to generate species lists with full taxonomy

gbif_taxa <- readRDS(gbif_marine_taxa_file) %>%
  mutate(source = "gbif")

obis_taxa <- open_dataset(obis_snapshot_path) %>%
  filter(!is.na(species)) %>%
  distinct(AphiaID, kingdom, phylum, class, order, family, genus, species) %>%
  collect() %>%
  mutate(source = "obis")

taxa <- bind_rows(gbif_taxa, obis_taxa)
  
saveRDS(taxa, taxa_file)

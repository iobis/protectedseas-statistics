source("requirements.R")
source("common.R")

gbif_marine_taxa <- readRDS(gbif_marine_taxa_file) %>%
  filter(taxonRank == "Species") %>%
  select(AphiaID, taxonRank, kingdom, phylum, class, order, genus, species = scientificName)
  
obis_taxa <- open_dataset(obis_snapshot_path) %>%
  filter(!is.na(species)) %>%
  distinct(AphiaID, taxonRank, kingdom, phylum, class, order, genus, species) %>%
  collect()

taxa <- bind_rows(gbif_marine_taxa, obis_taxa) %>%
  group_by(species) %>%
  filter(row_number() == 1)
  
saveRDS(taxa, "taxa.rds")

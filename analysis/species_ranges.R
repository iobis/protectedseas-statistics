source("data_preparation/requirements.R")
source("data_preparation/common.R")

taxa <- readRDS(taxa_file)
redlist <- readRDS(redlist_file)
info <- read.csv("shapes/Navigator_Global_121923.csv") %>%
  select(site_id, lfp)

# species, with GBIF name in "input"

species <- taxa %>%
  group_by(species) %>%
  summarize(input = first(input)) %>%
  # TODO: check if some WoRMS names have different GBIF names ("input")
  mutate(input = ifelse(is.na(input), species, input))

vulnerable <- redlist %>%
  # filter(category %in% c("VU", "EN", "CR", "NT")) %>%
  filter(category %in% c("LC")) %>%
  inner_join(species, by = "species")

# query

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

st <- storr::storr_rds("lfp_storr")

for (i in 1:nrow(vulnerable)) {

  species_name <- vulnerable$species[i]
  input_name <- vulnerable$input[i]
  category <- vulnerable$category[i]
  message(glue("{species_name} {category} {i}/{nrow(vulnerable)}"))
  
  if (!st$exists(species_name)) {
    obis_query <- glue("
      select {obis_occurrence_table}.h3, {site_cells_table}.site_id from {obis_occurrence_table}
      left join {site_cells_table} on {site_cells_table}.h3 = {obis_occurrence_table}.h3
      where species = '{species_name}'
    ")
    res <- dbSendQuery(con, obis_query)
    obis_occurrences <- dbFetch(res) %>%
      left_join(info, by = "site_id")
    
    gbif_query <- glue("
      select {gbif_occurrence_table}.h3, {site_cells_table}.site_id from {gbif_occurrence_table}
      left join {site_cells_table} on {site_cells_table}.h3 = {gbif_occurrence_table}.h3
      where species = '{input_name}'
    ")
    res <- dbSendQuery(con, gbif_query)
    gbif_occurrences <- dbFetch(res) %>%
      left_join(info, by = "site_id")
    
    cells <- bind_rows(obis_occurrences, gbif_occurrences) %>%
      group_by(h3) %>%
      summarize(lfp = max(na.omit(lfp))) %>%
      mutate(lfp = ifelse(is.infinite(lfp), 0, lfp))
    
    stats <- cells %>%
      group_by(lfp) %>%
      summarize(f = n() / nrow(cells), cells = n()) %>%
      mutate(species = species_name)
    
    st$set(species_name, stats)
  }

}

results <- st$mget(st$list()) %>%
  bind_rows() %>%
  complete(species, lfp, fill = list(f = 0, cells = 0)) %>%
  select(-category) %>%
  left_join(redlist, by = "species") %>%
  mutate(category = factor(category, levels = c("VU", "EN", "CR"))) %>%
  group_by(species) %>%
  mutate(range = sum(cells))

iqr <- function(z, lower = 0.25, upper = 0.75) {
  data.frame(
    y = median(z),
    ymin = quantile(z, lower),
    ymax = quantile(z, upper)
  )
}

ggplot(data = results) +
  geom_hline(yintercept = 0) +
  geom_jitter(aes(x = lfp, y = f, color = category), height = 0.01, width = 0.1, alpha = 0.4) +
  stat_summary(aes(x = lfp, group = lfp, y = f, shape = "IQR"), fun.data = iqr, size = 0.4) +
  # ggtech::scale_color_tech(theme = "airbnb") +
  scale_color_manual(values = rev(c("#d1495b", "#edae49", "#66a182"))) +
  # scale_color_manual(values = c("#B2182B", "#D6604D", "#F4A582")) +
  # scale_color_manual(values = awtools::a_palette[c(3, 5, 6)]) +
  # scale_color_manual(values = c(awtools::a_palette[3], "#EBA42B", awtools::a_palette[6])) +
  # scale_color_manual(values = rcartocolor::carto_pal(name = "Teal")[2:4]) +
  # scale_color_manual(values = NineteenEightyR::sunset3()[3:5]) +
  scale_shape_manual("fraction", values = 21) +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank()) +
  scale_x_continuous(name = "Level of Fishing Protection (LFP)") +
  scale_y_continuous(name = "Fraction of known distribution") +
  ggtitle("Level of Fishing Protection (LFP) for vulnerable marine species") +
  facet_wrap(~category, ncol = 1)

ggsave("analysis/graphs/species_ranges.png", width = 12, height = 8, dpi = 300, scale = 0.9, bg = "white")

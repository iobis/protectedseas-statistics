source("scripts/requirements.R")
source("scripts/common.R")

info <- read.csv(info_file)
shapes <- read_sf(shapefile_path) %>%
  left_join(info, by = c("SITE_ID" = "site_id"))

info %>%
  group_by(designation) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

info %>%
  group_by(category_name) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

shapes %>% filter(category_name == "IUCN MPA") %>% mapview::mapview()

write_sf(shapes %>% filter(category_name == "IUCN MPA"), "shapes/mpa.gpkg")


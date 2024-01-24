source("data_preparation/requirements.R")
source("data_preparation/common.R")

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

query <- "
  with t as (
  	select occurrence.h3, occurrence.species, redlist.category, max(lfp) as lfp from occurrence
  	left join site_cells on occurrence.h3 = site_cells.h3
  	left join sites on sites.site_id = site_cells.site_id 
  	inner join redlist on occurrence.species = redlist.species 
  	group by occurrence.h3, occurrence.species, redlist.category
  )
  select t.species, category, t.lfp, count(*) as cells, sum(h3.h3_7_area) as area
  from t
  left join h3 on t.h3 = h3.h3_7
  group by t.species, t.lfp
"

res <- dbSendQuery(con, query)
protection <- dbFetch(res)

protection_stats <- protection %>%
  filter(category %in% c("CR", "EN", "VU")) %>%
  mutate(lfp = ifelse(!is.na(lfp), lfp, 0)) %>%
  mutate(lfp = recode(lfp, `0` = "2 or lower", `1` = "2 or lower", `2` = "2 or lower", `3` = "3", `4` = "4", `5` = "5")) %>%
  group_by(species, category, lfp) %>%
  summarize(cells = sum(cells, na.rm = TRUE), area = sum(area, na.rm = TRUE)) %>%
  group_by(species) %>%
  mutate(total_cells = sum(cells, na.rm = TRUE), total_area = sum(area, na.rm = TRUE)) %>%
  group_by(species, category, lfp) %>%
  summarize(cells = sum(cells), fraction_cells = cells / total_cells, fraction_area = area / total_area) %>%
  ungroup() %>%
  complete(nesting(species, category), lfp) %>%
  mutate(
    fraction_cells = ifelse(is.na(fraction_cells) | fraction_cells < 0.001, 0.001, fraction_cells),
    fraction_area = ifelse(is.na(fraction_area) | fraction_area < 0.001, 0.001, fraction_area)
  )

iqr <- function(z, lower = 0.25, upper = 0.75) {
  data.frame(
    y = median(z),
    ymin = quantile(z, lower),
    ymax = quantile(z, upper)
  )
}

ggplot(data = protection_stats) +
  geom_hline(yintercept = 0) +
  geom_jitter(aes(x = lfp, y = fraction_area, color = category), height = 0.01, width = 0.1, alpha = 0.4) +
  stat_summary(aes(x = lfp, group = lfp, y = fraction_area, shape = "IQR"), fun.data = iqr, size = 0.4) +
  # ggtech::scale_color_tech(theme = "airbnb") +
  scale_color_manual(values = c("#d1495b", "#edae49", "#66a182")) +
  # scale_color_manual(values = c("#B2182B", "#D6604D", "#F4A582")) +
  # scale_color_manual(values = awtools::a_palette[c(3, 5, 6)]) +
  # scale_color_manual(values = c(awtools::a_palette[3], "#EBA42B", awtools::a_palette[6])) +
  # scale_color_manual(values = rcartocolor::carto_pal(name = "Teal")[2:4]) +
  # scale_color_manual(values = NineteenEightyR::sunset3()[3:5]) +
  scale_shape_manual("fraction_area", values = 21) +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank()) +
  scale_x_discrete(name = "Level of Fishing Protection (LFP)") +
  scale_y_continuous(name = "Fraction of known distribution in OBIS", trans = "log10", labels = scales::percent_format(scale = 100, accuracy = c(1, 1, 1, 1))) +
  ggtitle("Level of Fishing Protection (LFP) for vulnerable marine species", subtitle = "Each dot represents the component of a species' distribution with a certain LFP") +
  facet_wrap(~category, ncol = 1)

ggsave("analysis/graphs/species_ranges.png", width = 12, height = 8, dpi = 300, scale = 0.9, bg = "white")

# LFP map

# for (level in 3:5) {
#   res <- dbSendQuery(con, glue("select h3 from site_cells left join sites on site_cells.site_id = sites.site_id where lfp = {level}"))
#   cells <- na.omit(dbFetch(res)$h3)
#   cells_5 <- h3jsr::cell_to_polygon(unique(h3jsr::get_parent(cells, 5)))
#   df <- st_as_sf(cells_5, crs = 4326) %>%
#     st_wrap_dateline() %>%
#     st_write(glue("lfp_{level}.gpkg"))
# }

# complete mpa geopackage

# info <- read.csv(info_file)
# shapes <- read_sf(shapefile_path)
# 
# geo <- info %>%
#   select(site_id, lfp) %>%
#   left_join(shapes, by = c("site_id" = "SITE_ID"))
# 
# st_write(geo, "info.gpkg")

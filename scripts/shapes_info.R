source("requirements.R")

info <- read.csv("../protectedseas/shapes/Navigator_Global_121923.csv")

info %>%
  group_by(designation) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

info %>%
  group_by(category_name) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

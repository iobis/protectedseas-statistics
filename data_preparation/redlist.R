source("data_preparation/requirements.R")
source("data_preparation/common.R")

redlist <- data.frame()

page <- 0
while (TRUE) {
  res <- rl_sp(page, key = "a936c4f78881e79a326e73c4f97f34a6e7d8f9f9e84342bff73c3ceda14992b9")$result
  if (length(res) == 0) {
    break
  }
  redlist <- bind_rows(redlist, res)
  page <- page + 1
}

redlist %>%
  filter(is.na(population)) %>%
  select(species = scientific_name, category) %>%
  dbWriteTable(con, redlist_table, ., overwrite = TRUE)

dbSendQuery(con, glue("create index redlist_species on {redlist_table}(species)"))
dbSendQuery(con, "vacuum")

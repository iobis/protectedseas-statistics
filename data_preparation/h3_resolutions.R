source("data_preparation/requirements.R")
source("data_preparation/common.R")

new_res <- 2

con <- dbConnect(RSQLite::SQLite(), sqlite_file)

res <- dbSendQuery(con, "select distinct(h3) from occurrence")
cells <- dbFetch(res) %>%
  pull(h3)
area <- as.integer(h3jsr::cell_area(cells))
parent_cells <- h3jsr::get_parent(cells, new_res)

h3 <- data.frame(cells, parent_cells, area) %>%
  setNames(c(glue("h3_{h3_res}"), glue("h3_{new_res}"), glue("h3_{h3_res}_area")))

dbSendQuery(con, glue("drop table if exists h3"))
dbWriteTable(con, "h3", h3, overwrite = TRUE)

dbSendQuery(con, glue("create index h3_2 on h3(h3_2)"))
dbSendQuery(con, glue("create index h3_7 on h3(h3_7)"))

dbSendQuery(con, "vacuum")

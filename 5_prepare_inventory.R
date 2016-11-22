
source('./lib/utils.R')

inventory.data <- read.csv('./data/inventory__2013.csv', header = TRUE)

dbSendQuery(connection,
            "DROP TABLE IF EXISTS aircrafts")

create.table.statements <-
  paste(readLines("./lib/sql/aircrafts.sql"), collapse = " ")

print("Creating aircrafts table.")
dbSendQuery(connection, create.table.statements)

copy.statement <-
  sprintf("COPY aircrafts FROM '%s/data/inventory__2013.csv", getwd()) %+%
  "' WITH DELIMITER ',' CSV HEADER QUOTE '\"';"

print("Copying data to table")
dbSendQuery(connection, copy.statement)


source('./lib/utils.R')

carriers.data <- read.xls('./data/carriers.xls', header = TRUE)
write.csv(carriers.data, file = "./data/carriers.csv", col.names = FALSE)

dbSendQuery(connection,
            "DROP TABLE IF EXISTS carriers")

create.table.statements <-
  "CREATE TABLE carriers (index varchar(256), code varchar(256), description varchar(256))"

print("Creating carriers table.")
dbSendQuery(connection, create.table.statements)

copy.statement <-
  sprintf("COPY carriers FROM '%s/data/carriers.csv", getwd()) %+%
  "' WITH DELIMITER ',' CSV HEADER;"

print("Copying data to table")
dbSendQuery(connection, copy.statement)

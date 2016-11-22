
source('./lib/utils.R')

airports.data.base <- read.csv('./data/airports.dat.txt', header = FALSE)

colnames(airports.data.base) <-
c(
  "airport_id",
  "name",
  "city",
  "country",
  "iata",
  "icao",
  "latitude",
  "longitude",
  "altitude",
  "timezone",
  "dst",
  "tz"
)

airports.data.base <-
  airports.data.base %>%
  dplyr::filter(country == "United States")

master.codes <-
  read.csv('./data/master-location-identifier-database-20130801.csv',
           header = TRUE) %>%
  dplyr::filter(country3 == 'USA') %>%
  dplyr::filter(wban != "" & icao != "" & iata_xref != "")

master.codes.dedup <-
  master.codes[!duplicated(master.codes[c("lat_prp", "lon_prp")]), ]

airports.data <-
  airports.data.base %>%
  dplyr::right_join(master.codes.dedup, by = c("iata" = "iata_xref"))

airports.data.clean <-
airports.data[which(!is.na(airports.data$wmo)) , ]

airports.data.clean <-
airports.data.clean[which(!is.na(airports.data.clean$airport_id)), ]

airports.data.clean <-
  airports.data.clean %>%
  dplyr::select(airport_id, name, city.x, country.x,
                iata, icao.x, latitude, longitude,
                altitude, timezone, dst, region,
                national_id, wmo, wban, maslib)

write.csv(airports.data.clean, file = "./data/l_airports.csv", col.names = FALSE)

dbSendQuery(connection,
            "DROP TABLE IF EXISTS airports")

create.table.statements <-
  paste(readLines("./lib/sql/lookup.sql"), collapse = " ")

print("Creating flights table.")
dbSendQuery(connection, create.table.statements)

copy.statement <-
  sprintf("COPY airports FROM '%s/data/l_airports.csv", getwd()) %+%
  "' WITH DELIMITER ',' CSV HEADER;"

print("Copying data to table")
dbSendQuery(connection, copy.statement)





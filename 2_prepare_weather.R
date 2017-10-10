source('./lib/utils.R')

GetDataset <- function(year) {
  system(
    "./lib/get_weather_data.sh " %+% year
  )
}

ReadGsod <- function(f) {
  widths <- c(6, 1, 5, 2, 4, 4, 2, 6, 1, 2, 2, 6, 1, 2, 2, 6, 1, 2, 2,
              6, 1, 2, 2, 5, 1, 2, 2, 5, 1, 2, 2, 5, 2, 5, 2, 6, 1, 1,
              6, 1, 1, 5, 1, 1, 5, 2, 6)

  dcol <- "drop"
  cols <- c("STN---", dcol, "WBAN", dcol, "YEAR", "MODA", dcol,
            "TEMP", dcol, "TEMPCount", dcol, "DEWP", dcol,
            "DEWPCount", dcol, "SLP", dcol, "SLPCount", dcol,
            "STP", dcol, "STPCount", dcol, "VISIB", dcol,
            "VISIBCount", dcol, "WDSP", dcol, "WDSPCount", dcol,
            "MXSPD", dcol, "GUST", dcol, "MAX", "MAXFlag", dcol,
            "MIN", "MINFlag", dcol, "PRCP", "PRCPFlag", dcol, "SNDP",
            dcol, "FRSHTT")

  N <- "NULL"
  n <- "numeric"
  i <- "integer"
  h <- "character"
  classes <- c(i, N, i, N, i, i, N, rep(c(n, N, i, N), 6), n, N, n, N,
               rep(c(n, h, N), 2), n, h, N, n, N, i)

  metrics <- read.fwf(file       = f,
                      widths     = widths,
                      skip       = 1,
                      col.names  = cols,
                      colClasses = classes)

  return(metrics)
}

CopyToWeatherTable <- function(year) {
  #dbSendQuery(connection,
  #            "DROP TABLE IF EXISTS weather__2013")

  create.table.statements <-
    paste(readLines("./lib/sql/weather_2013.sql"), collapse = " ")

  print("Creating flights table.")
  dbSendQuery(connection, create.table.statements)

  copy.statement <-
    sprintf("COPY weather FROM '%s/data/%s__noaa_gsod", getwd(), year) %+%
    "' WITH DELIMITER ',' CSV HEADER;"

  print("Copying data to table")
  dbSendQuery(connection, copy.statement)
}

RemoveDataset <- function(year) {
  system()
}

CopyYearlyWeatherDataToPG <- function(year) {
  GetDataset(year)
  filenames <- sprintf("./data/tmp/gsod_%s/", year) %+%
    list.files(path = sprintf("./data/tmp/gsod_%s/", year))

  # Chunking is required here, otherwise for some yet unknown
  # reasons the size of the data set grows exponentially after
  # some number of files are aggregated.
  # Same phenomenon happens both the aggregated file is
  # stored in memory or in the filesystem..
  # (Scatter plot: num_aggregated files / final obj size | Size per file)
  master <- ReadGsod(filenames[1])
  for (i in chunk(from = 2, to = length(filenames), by = 100)) {
    print(sprintf('Aggregating data from %s to %s', min(i), max(i)))
    # We could parallelize that...
    plyr::llply(min(i):max(i),
                function(it) {
                  tmp.data <- ReadGsod(filenames[it])
                  master <<- rbind(master, tmp.data)
                  rm(tmp.data)
                }, .progress = "text"
    )
  }
  print(head(master))
  write.csv(x=master, file= sprintf('./data/%s__noaa_gsod"', year))

  CopyToWeatherTable(year)
  RemoveDataset(year)
}

CopyYearlyWeatherDataToPG("2013")

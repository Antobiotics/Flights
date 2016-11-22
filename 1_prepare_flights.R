source('./lib/utils.R')

`%+%` <- function(a, b) {
  paste0(a, b)
}

BASE_URL <- 'http://www.transtats.bts.gov/Download/On_Time_On_Time_Performance_'
YEARS <- as.character(1997:2014)
MONTHS <- as.character(8:12)


BuildURLs <- function(years, months) {
  url.suffixes <- expand.grid(YEARS, '_', MONTHS, '.zip')
  dl.paths <- apply(url.suffixes, 1, paste0,
                    collapse = '', sep = '')
  return(BASE_URL %+% dl.paths)
}

DownloadOnTimeDataSets <- function(years, months) {
  dl.paths <- BuildURLs(years, months())
  paths.df <-
    data.frame(
      url = dl.paths,
      destfile = "./data/archives" %+% dl.paths,
      stringsAsFactors = FALSE
    )

  m_ply(paths.df, download.file, .progress = "text")
}

ExtractOnTimeDataSets <- function() {
  system('unzip -n "./data/archives/*.zip" -d ..')
  system("rename 's/^On_Time_On_Time_Performance_//' *.csv")
}

CollectDataSet <- function() {
  system("ls *.csv | xargs -I {} sed 's/\"\"//g' {} >> post/processed.csv")
}

CreateDatabase <- function() {
  system("createdb bts_ontime")
}

CrateFlightsTable <- function() {
  dbSendQuery(connection,
              "DROP TABLE IF EXISTS flights")

  create.table.statements <-
    paste(readLines("./lib/sql/flights.sql"), collapse = " ")

  print("Creating flights table.")
  dbSendQuery(connection, create.table.statements)

  copy.statement <-
    sprintf("COPY flights FROM '%s/data/post/processed.csv", getwd()) %+%
    "' WITH DELIMITER ',' CSV HEADER;"

  print("Copying data to table")
  dbSendQuery(connection, copy.statement)


  print("Indexing table")
  indexes.statements <- paste(readLines("./lib/sql/index.sql"), collapse = " ")
  dbSendQuery(connection, indexes.statements)

  print("VACUUM")
  dbSendQuery(connection, "VACUUM")
}

DownloadOnTimeDataSets(YEARS, MONTHS)
ExtractOnTimeDataSets()
CollectDataSet()
CreateDatabase()
CreateFlightsTable()




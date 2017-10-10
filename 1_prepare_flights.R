source('./lib/utils.R')

`%+%` <- function(a, b) {
  paste0(a, b)
}

BTS_DL_URL <- "http://www.transtats.bts.gov/Download/"
BASE_URL <- BTS_DL_URL %+% 'On_Time_On_Time_Performance_'
YEARS <- as.character(1997:2014)
MONTHS <- as.character(1:12)


BuildURLs <- function(years, months) {
  url.suffixes <- expand.grid(YEARS, '_', MONTHS, '.zip')
  dl.paths <- apply(url.suffixes, 1, paste0,
                    collapse = '', sep = '')
  return(BASE_URL %+% dl.paths)
}

dl.data <- function(url, destfile) {
  if(!file.exists(destfile)) {
    download.file(url, destfile)
  }
}

DownloadOnTimeDataSets <- function(years, months) {
  dl.paths <- BuildURLs(years, months())
  dest.paths <- gsub(BTS_DL_URL, "", dl.paths)
  paths.df <-
    data.frame(
      url = dl.paths,
      destfile = "./data/archives/" %+% dest.paths,
      stringsAsFactors = FALSE
    )
  m_ply(paths.df, dl.data, .inform=TRUE, .progress='text')
  warnings()
}

ExtractOnTimeDataSets <- function() {
  system('unzip -n "./data/archives/*.zip" -d ./data')
  system("rename 's/^On_Time_On_Time_Performance_//' *.csv")
}

CollectDataSet <- function() {
  system("ls data/*.csv | xargs -I {} sed 's/\"\"//g' {} >> ./data/post/processed.csv")
}

CreateDatabase <- function() {
  system("createdb bts_ontime")
}

CreateFlightsTable <- function() {
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

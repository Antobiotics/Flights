if (!require('pacman')) {
  install.packages('pacman')
}

pacman::p_load(ggplot2, dplyr,
               forecast, scales,
               seasonal, lubridate,
               timeDate, grid,
               lattice, gridExtra,
               formattable, RPostgreSQL,
               weatherData, plyr, data.table)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 1) {
  working.dir <- args[1]
} else {
  stop('Missing Parameter | Usage: working.dir')
}

setwd(working.dir)

`%+%` <- function(a, b) {
  paste0(a, b)
}

driver <- dbDriver("PostgreSQL")
connection <-
  dbConnect(driver,
            dbname = "bts_ontime",
            host = 'localhost')

origins <- dbGetQuery(connection, "SELECT distinct(origin) FROM flights")$origin

getWeatherData <- function(orig, date) {
  tryCatch({
    weather.data.day <-
      getDetailedWeather(orig,
                         as.character(date),
                         opt_all_columns = TRUE)
    return(weather.data.day %>%
           cbind(data.frame(origin = rep(orig, nrow(weather.data.day)))))
  },
  error = function(e) {
    print(e)
  })
}

getYearlyWeatherData <- function(orig) {
  print(sprintf("Collecting data for airport: %s", orig))
  file.name <- './data/weather/' %+% orig %+% '__2014.csv'
  if (!file.exists(file.name)) {
    tryCatch(
      {
        weather.data.station.yearly <-
          rbindlist(
            plyr::llply(seq(as.Date("2014-01-01"), as.Date("2014-12-31"), "days"),
                        function(day) { getWeatherData(orig, day) },
                        .progress = "text")
          )
          write.table(weather.data.station.yearly,
                      file = file.name,
                      sep = ",")
        return(weather.data.station.yearly)
      },
      error = function(e) {}
    )
  }
}

# Really hacky... Let's see if that works
lapply(X = origins,
       FUN = function(or) { getYearlyWeatherData(or) })



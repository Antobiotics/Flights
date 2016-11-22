if (!require('pacman')) {
  install.packages('pacman')
}

pacman::p_load(ggplot2, dplyr,
               forecast, scales,
               seasonal, lubridate,
               timeDate, grid,
               lattice, gridExtra,
               formattable, RPostgreSQL,
               weatherData, plyr, GetoptLong,
               ff, amap, raster, stringr,
               reshape2, igraph, gdata,
               maps, geosphere, animation,
               cooccur, randomForest,
               data.table, caret)

configGet <- function(data, section, name) {
  return(
    as.character(
      data[which(data$section == section &
                    data$name == name),]$value
    )
  )
}

CONFIGURATION <- data.frame(readIniFile('./client.cfg', token = ':'))


# Change host to the remote host, if needed.
driver <- dbDriver("PostgreSQL")
connection <-
  dbConnect(driver,
            dbname   = configGet(CONFIGURATION, "dbs", "name"),
            host     = configGet(CONFIGURATION, "dbs", "host"),
            user     = configGet(CONFIGURATION, 'dbs', 'user'),
            password = configGet(CONFIGURATION, 'dbs', 'password')
  )

`%+%` <- function(a, b) {
  paste0(a, b)
}

GetSeason <- function(dates) {
    WS <- as.Date("2012-12-15", format = "%Y-%m-%d") # Winter Solstice
    SE <- as.Date("2012-3-15",  format = "%Y-%m-%d") # Spring Equinox
    SS <- as.Date("2012-6-15",  format = "%Y-%m-%d") # Summer Solstice
    FE <- as.Date("2012-9-15",  format = "%Y-%m-%d") # Fall Equinox

    # Convert dates from any year to 2012 dates
    d <- as.Date(strftime(dates, format = "2012-%m-%d"))

    ifelse(d >= WS | d < SE, "Winter",
      ifelse(d >= SE & d < SS, "Spring",
        ifelse(d >= SS & d < FE, "Summer", "Fall")))
}

SummarizeDelay <- function(data) {
  dplyr::summarise(data,
        num_flights   = n(),

        num_delayed_flights = sum(ifelse((dep_del15 + arr_del15) != 0, 1, 0)),
        num_delayed_flights_dep = sum(dep_del15),
        num_delayed_flights_arr = sum(ifelse(arr_del15, 1, 0)),

        avg_dep_delay = mean(dep_delay, na.rm = TRUE),
        avg_arr_delay = mean(arr_delay, na.rm = TRUE),

        med_carrier_delay  = median(carrier_delay, na.rm = TRUE),
        med_weather_delay  = median(weather_delay, na.rm = TRUE),
        med_nas_delay      = median(nas_delay, na.rm = TRUE),
        med_security_delay = median(security_delay, na.rm = TRUE),
        med_late_aircraft_delay = median(late_aircraft_delay, na.rm = TRUE),


        frac_delayed = num_delayed_flights / num_flights,
        frac_dep_delayed = num_delayed_flights_dep / num_flights,
        frac_arr_delayed = num_delayed_flights_arr / num_flights,

        tot_dep_delay_minutes = sum(dep_delay_minutes, na.rm = TRUE),
        tot_arr_delay_minutes = sum(arr_delay_minutes, na.rm = TRUE),

        tot_dep_delay_hours = tot_dep_delay_minutes / 60,
        tot_arr_delay_hours = tot_arr_delay_minutes / 60,

        tot_dep_delay_days = tot_dep_delay_minutes / (60 * 24),
        tot_arr_delay_days = tot_arr_delay_minutes / (60 * 24)
  )
}


PlotDelayTimeOverview <- function(df, var1, var2) {
  p.dow <-
    ggplot(
      df %>%
      dplyr::group_by(day_of_week) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("day_of_week", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "day_of_week", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

  p.holiday <-
    ggplot(
      df %>%
      dplyr::group_by(is_holiday) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("is_holiday", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "is_holiday", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

  p.seasons <-
    ggplot(
      df %>%
      dplyr::group_by(season) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("season", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "season", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

  p.dep.hours <-
    ggplot(
      df %>%
      dplyr::group_by(crs_dep_hour) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("crs_dep_hour", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "crs_dep_hour", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

    p.arr.hours <-
    ggplot(
      df %>%
      dplyr::group_by(crs_arr_hour) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("crs_arr_hour", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "crs_arr_hour", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

  p.months <-
    ggplot(
      df %>%
      dplyr::group_by(month) %>%
      SummarizeDelay() %>%
      dplyr::select_(.dots = c("month", var1, var2)) %>%
      melt(id.vars = 1),
    aes_string(x = "month", y = "value")
    ) +
    geom_bar(aes(fill = variable), stat = 'identity', position = 'dodge')

  grid.arrange(p.dow, p.holiday,
               p.seasons, p.months,
               p.dep.hours, p.arr.hours, ncol = 2, nrow = 3)
}

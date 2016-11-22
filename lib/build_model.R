# Last minute function

BuildModelDataset <- function(month_num = 12) {

  p.flights.data <-
    flights.data %>%
    dplyr::filter(origin == 'ORD' | dest == 'ORD') %>%
    dplyr::filter(month == month_num) %>%
    dplyr::mutate(
      dep_hour = as.integer(dep_time / 100),
      arr_hour = as.integer(arr_time / 100),
      day_num = as.integer(format(as.Date(flight_date), "%d"))
    ) %>%
    dplyr::select(year, month, day_of_week, carrier, crs_dep_time,
                  crs_arr_time, crs_elapsed_time,
                  distance_group, number_of_seats, manufacture_year,
                  temp, visib, fog, rain_drizzle, snow_ice_pellets,
                  hail, thunder, tornado_funnel_cloud, day, day_num,
                  is_holiday, season, crs_dep_hour, crs_arr_hour,
                  acquired_for, aircraft_age,
                  origin, dest,
                  dep_hour, arr_hour, dep_delay, arr_delay)

  p.airports.schedule <-
    BuildSchedule(flights.df = p.flights.data,
                  airports = airports,
                  dep = "origin",
                  arr = "dest",
                  dep_features = c("month", "day_num", "crs_dep_hour"),
                  arr_features = c("month", "day_num", "crs_arr_hour"),
                  sched_dep_features = c("month", "day_num", "dep_hour"),
                  sched_arr_features = c("month", "day_num", "arr_hour"),
                  col.names = c("month", "day_num", "hour")
    )

  p.ord.schedule <-
    p.airports.schedule %>%
    dplyr::filter(iata == 'ORD')

  p.flights.data.with.schedule <-
    rbindlist(
      lapply(X = 1:nrow(p.flights.data), FUN = function(i) {
        row <- p.flights.data[i, ]
        f.hour <- row$dep_hour
        if (row$dest == 'ORD') {
          hour <- row$arr_hour
        }

        schedule.subset <-
          p.ord.schedule %>%
          dplyr::filter(month == row$month
                        & day_num == row$day_num
                        & hour == f.hour)
        schedule.subset <-
          schedule.subset[1, ] %>%
          dplyr::select(-iata, -month, -hour, -day_num)
        return(cbind(row, schedule.subset))
      })
    )

  p.flights.data.with.schedule <-
    p.flights.data.with.schedule %>%
    dplyr::select( -origin, -dest, -city, -latitude,
                   -longitude, -cum_tot_delay_sc, -demand_sc,
                   -lag_sc, -runway_pressure_sc)

  p.flights.data.with.schedule <-
    p.flights.data.with.schedule %>%
    na.omit()

  carriers <- p.flights.data.with.schedule$carrier
  carriers.dummies <- model.matrix(~carriers)[, -1]

  is.holiday <- p.flights.data.with.schedule$is_holiday
  hol.dummies <- model.matrix(~is.holiday)[, -1]

  seasons <- p.flights.data.with.schedule$season
  seasons.dummies <- model.matrix(~seasons)[, -1]

  p.flights.data.with.schedule.dum <-
    p.flights.data.with.schedule %>%
    dplyr::select(-is_holiday, -season, -carrier, -dep_delay) %>%
    cbind(carriers.dummies, hol.dummies, seasons.dummies)

  return(p.flights.data.with.schedule.dum)
}
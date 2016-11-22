BuildSchedule <- function(flights.df = flights,
                          airports = airports,
                          dep = "source",
                          arr = "target",
                          dep_features = c("crs_dep_hour"),
                          arr_features = c("crs_arr_hour"),
                          sched_dep_features = c("dep_hour"),
                          sched_arr_features = c("arr_hour"),
                          col.names = c("hour")) {

  group.dep.features <- c(dep_features, dep)
  group.arr.features <- c(arr_features, arr)

  group.sched.dep.features <- c(sched_dep_features, dep)
  group.sched.arr.features <- c(sched_arr_features, arr)

  sched.departures <-
    flights.df %>%
    dplyr::group_by_(.dots = group.sched.dep.features) %>%
    dplyr::summarise(
      scheduled_departures = n()
    )
  colnames(sched.departures) <- c(col.names, "iata", "sched_dep")

  sched.arrivals <-
    flights.df %>%
    dplyr::group_by_(.dots = group.sched.arr.features) %>%
    dplyr::summarise(
      scheduled_arrivals = n()
    )
  colnames(sched.arrivals) <- c(col.names, "iata", "sched_arr")

  departures <-
    flights.df %>%
    dplyr::group_by_(.dots = group.dep.features) %>%
    dplyr::summarise(
      departures = n()
    )
  colnames(departures) <- c(col.names, "iata", "dep")

  arrivals <-
    flights.df %>%
    dplyr::group_by_(.dots = group.arr.features) %>%
    dplyr::summarise(
      arrivals = n()
    )
  colnames(arrivals) <- c(col.names, "iata", "arr")

  dep.delays <-
    flights.df %>%
    dplyr::group_by_(.dots = group.dep.features) %>%
    dplyr::summarise(
      cum_dep_del = sum(dep_delay)
    )
  colnames(dep.delays) <- c(col.names, "iata", "cum_dep_del")

  arr.delays <-
    flights.df %>%
    dplyr::group_by_(.dots = group.arr.features) %>%
    dplyr::summarise(
      cum_arr_del = sum(arr_delay)
    )
  colnames(arr.delays) <- c(col.names, "iata", "cum_arr_del")

  grid.param <- list()
  lapply(X = c(dep, dep_features), FUN = function(v) {
    grid.param[[v]] <<- unique(flights.df[ , v])
  })

  grid <- expand.grid(grid.param)
  colnames(grid) <- c("iata", col.names)

  airports.schedule <-
    grid %>%
    dplyr::left_join(sched.arrivals, by = c(col.names, "iata")) %>%
    dplyr::left_join(sched.departures, by = c(col.names, "iata")) %>%
    dplyr::left_join(departures, by = c(col.names, "iata")) %>%
    dplyr::left_join(arrivals, by = c(col.names, "iata")) %>%
    dplyr::left_join(arr.delays, by = c(col.names, "iata")) %>%
    dplyr::left_join(dep.delays, by = c(col.names, "iata")) %>%
    dplyr::left_join(airports, by = c("iata"))


  airports.schedule <-
    airports.schedule %>%
    dplyr::mutate(
      demand = arr / sched_arr,
      lag = dep / sched_dep,
      capacity = arr + dep,
      scheduled_capacity = sched_arr + sched_dep,
      runway_pressure = capacity / scheduled_capacity,
      a_t = arr / dep,
      cum_tot_delay = cum_dep_del + cum_arr_del,
      cum_tot_delay_sc = cum_tot_delay / max(cum_tot_delay, na.rm = TRUE),
      demand_sc = demand / max(demand, na.rm = TRUE),
      lag_sc = lag / max(lag, na.rm = TRUE),
      runway_pressure_sc = runway_pressure / max(runway_pressure, na.rm = TRUE)
    )

  airports.schedule[is.na(airports.schedule)] <- 0

  return(airports.schedule)
}
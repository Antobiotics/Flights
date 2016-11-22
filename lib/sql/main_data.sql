SELECT
  year
  , month
  , day_of_week
  , flight_date::date as flight_date
  , unique_carrier
  , airline_id
  , carrier
  , tail_num
  , flight_num
  , origin_airport_id
  , origin
  , origin_city_name
  , origin_state
  , dest_airport_id
  , dest
  , dest_city_name
  , dest_state
  , crs_dep_time
  , dep_time
  , dep_delay
  , dep_delay_minutes
  , dep_del15
  , taxi_out
  , wheels_off
  , wheels_on
  , taxi_in
  , crs_arr_time
  , arr_time
  , arr_delay
  , arr_delay_minutes
  , arr_del15
  , cancelled
  , diverted
  , crs_elapsed_time
  , actual_elapsed_time
  , air_time
  , distance
  , distance_group
  , weather_delay
  , carrier_delay
  , nas_delay
  , security_delay
  , late_aircraft_delay

  , carriers.description

  , airports.iata
  , airports.icao
  , airports.latitude
  , airports.longitude
  , airports.wmo
  , airports.wban

  , aircrafts.number_of_seats
  , aircrafts.model
  , aircrafts.manufacture_year
  , aircrafts.acquisition_date

  , weather.temp
  , weather.visib
  , weather.fog
  , weather.rain_drizzle
  , weather.snow_ice_pellets
  , weather.hail
  , weather.thunder
  , weather.tornado_funnel_cloud

FROM flights

LEFT JOIN (
  SELECT code, description
  FROM carriers
) AS carriers
ON carriers.code = flights.unique_carrier

LEFT JOIN (
  SELECT iata, icao, latitude, longitude, wmo, wban, maslib
  FROM airports
) AS airports
ON airports.iata = flights.origin

LEFT JOIN (
  SELECT tail_number, number_of_seats, model, manufacture_year, acquisition_date
  FROM aircrafts
) as aircrafts
ON aircrafts.tail_number = flights.tail_num

LEFT JOIN (
  SELECT wban, (year || '-' || mo || '-' || da)::date as date, temp, visib
  , fog, rain_drizzle, snow_ice_pellets, hail, thunder, tornado_funnel_cloud
  FROM weather__2013
) as weather
ON airports.wban = weather.wban AND weather.date = flights.flight_date::date

WHERE flights.year = 2013


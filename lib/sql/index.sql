create index "Date" on flights("Year", "Month", "DayofMonth");
create index "Origin" on flights("Origin");
create index "Dest" on flights("Dest");
create index "UniqueCarrier" on flights("UniqueCarrier");
create index "Year" on flights("Year");
create index "FlightNum" on flights("FlightNum");
analyze;
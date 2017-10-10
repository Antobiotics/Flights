create index "date" on flights("year", "month", "dayof_month");
create index "drigin" on flights("origin");
create index "dest" on flights("dest");
create index "uniquecarrier" on flights("uniquecarrier");
create index "year" on flights("year");
create index "flightnum" on flights("flightnum");
analyze;


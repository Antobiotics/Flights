dependencies:
	brew install imagemagick

prepare:
	Rscript 1_prepare_flights.R
	Rscript 2_prepare_weather.R
	Rscript 3_prepare_code_lookups.R
	Rscript 4_prepare_carriers.R
	Rscript 5_prepare_inventory.R

bootstrap:
	swarm_queen bootstrap --instances all
	docker-compose -f services.yml up -d

takedown:
	swarm_queen takedown --instances all

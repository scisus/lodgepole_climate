# workflow to prepare site-specific daily temperature data from PCIC

run `lodgepole_climate/scripts/netcdf_extract.R` to create `output/pcic/PNWNAmet_daily_temps.csv`
- `netcdf_extract.R` pulls temps from the PCIC data for the gridpoints closest to the seed orchard sites. It will also write out the closest PNWNAmet grid points to each site location at `locations/grid_coordinates.csv`

next run the climate adjuster `lodgepole_climate/scripts/adjustPCIC.R` to correct pcic grid data based on monthly mean temps from ClimateBC

This creates `processed/PNWNAmet_adjusted.csv` which contains corrected and uncorrected mean daily temperatures for all sites from 1945-2012.


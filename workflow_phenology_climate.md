# workflow

run `lodgepole_climate/scripts/netcdf_extract.R` to create `lodgepole_climate/output/seed_orchard_sites_pcic_ts.csv`
- `netcdf_extract.R` pulls temps from the PCIC data for the gridpoints closest to the seed orchard sites.

next run the climate adjuster `lodgepole_climate/scripts/PCIC_adjust.R` to correct pcic grid data to specific site and elevation data.

This creates `lodgepole_climate/processed/PCIC_all_seed_orchard_sites_adjusted.csv` which contains corrected and uncorrected mean daily temperatures for all sites from 1945-2012.

Next, calculate forcing units for the sites from the climate data using `calculate_forcingunits.R` and write them to all_clim_PCIC.csv`
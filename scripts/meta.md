# meta for scripts

`netcdf_extract.R` 
- extracts data from netcdf files with [maximum](data/pcic/PNWNAmet_tasmax.nc.nc) and [minimum](data/pcic/PNWNAmet_tasmin.nc.nc) temperatures for [seed orchard sites](seed_orchard_site_coordinates.csv) 
- calculates the mean daily temperature for each day of 1945-2012
- writes the mean daily temperature for each day out to a [file](output/seed_orchard_sites_pcic_ts.csv)
- combines site locations with gridpoint locations and their elevations and [writes it out](seed_orchard_sites_pcic.csv)

`adjustPCIC.R`
- takes data for PCIC data gridpoints near sites and corrects it using a linear model between monthly data at the sites as determined by ClimateNA and the mean of the PCIC data at the nearest gridpoint. 

climateNA monthly site temp = a + b * pcic monthly grid temp

corrected pcic daily = a + b * pcic daily temp
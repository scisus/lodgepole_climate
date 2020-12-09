#meta for lodgepole_climate 

`seed_orchard_site_coordinates.csv` location of seed orchard sites, formatted for ClimateNA

`seed_orchard_sites_pcic.csv` location of seed orchard sites, the closest PCIC gridpoint, and a corrected elevation.

`netcdf_extract.R` 
- extracts data from netcdf files with [maximum](data/pcic/PNWNAmet_tasmax.nc.nc) and [minimum](data/pcic/PNWNAmet_tasmin.nc.nc) temperatures for [seed orchard sites](seed_orchard_site_coordinates.csv) 
- calculates the mean daily temperature for each day of 1945-2012
- writes the mean daily temperature for each day out to a [file](output/seed_orchard_sites_pcic_ts.csv)
- combines site locations with gridpoint locations and their elevations and [writes it out](seed_orchard_sites_pcic.csv)


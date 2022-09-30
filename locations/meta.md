# meta for lodgepole_climate 

Contains location information for 7 seed orchard sites and 2 more northerly sites used for phenology predictions. 

Seed Orchard latitude and longitude data collected by CS Tysor manually using Google Earth, trench and border site lat and lon from ClimateBC. 

Elevation data for sites pulled from GeoNames via `rgbif::elevation` in R using [srtm1](https://doi.org/10.5066/F7PR7TFT) (USGS EROS Archive - Digital Elevation - Shuttle Radar Topography Mission (SRTM) Global). Sampled at a resolution of 2 arc-second by 1 arc-second (~60m x 30m).

Elevation data for grid squares pulled from GeoNames via `rgbif::elevation` in R using [gtopo30](https://doi.org/10.5066/F7DF6PQS)(USGS EROS Archive - Digital Elevation - Global 30 Arc-Second Elevation (GTOPO30)). Sampled at a resolution of 30 arc seconds (~1 km)

`climatebc_locs.csv` actual site locations + closest PNWNAmet gridpoint. lat, lon, elev. formatted for use with ClimateBC. Windows line endings.

`climatebc_parent_locs.csv` latitude, longitude and elevations of parent tree locations formatted for use with ClimateBC. Windows line endings.

`grid_coordinates.csv` actual site locations + closest PNWNAmet gridpoints. lat, lon only

`parent_locs.csv` latitude, longitude and elevations of parent tree locations

`ParentTreeExtractReport_ParentTrees_2014_05_15_13_38_17.csv` Parent tree info extracted from BC Ministry of Forests SPAR on 2014-05-15. 

`site_coord_elev.csv` actual site lat and lon with elevation

`site_coordinates.csv` actual site lat and lon. 

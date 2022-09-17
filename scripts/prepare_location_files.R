library(dplyr)
library(rgbif)

# - get elevation data for sites and grid squares containing those sites, then combine and write out.

# get and write elevation data####
## for sites

site_coord <- read.csv("locations/site_coordinates.csv", header = TRUE, stringsAsFactors = FALSE)

siteelevs <- rgbif::elevation(latitude= site_coord$lat, longitude = site_coord$lon, username="susannah2")
colnames(siteelevs) <- c("lat", "lon", "elev")
site_coord_elev <- dplyr::full_join(seed_orchard_sites, siteelevs)

write.csv(site_coord_elev, "locations/site_coord_elev.csv", row.names = FALSE)

## for pcic gridpoints

grid_coord <- read.csv("locations/grid_coordinates.csv", header = TRUE, stringsAsFactors = FALSE)

gridelevs <- rgbif::elevation(latitude = grid_coord$Grid_lat, longitude=grid_coord$Grid_lon, username="susannah2")
colnames(gridelevs) <- c("Grid_lat", "Grid_lon", "Grid_elev")
grid_coord_elev <- dplyr::full_join(gridelevs, site_coord_elev)

#write.csv(grid_coord_elev, "locations/grid_coord_elev.csv", row.names = FALSE)

# Combine site and grid square location info for ClimateBC

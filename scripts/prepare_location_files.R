# Add elevation to all locations and format a location file for ClimateBC

library(dplyr)
library(rgbif)

# - get elevation data for sites and grid squares containing those sites, then combine and write out.

# get and write elevation data####
## for sites

site_coord <- read.csv("locations/site_coordinates.csv", header = TRUE, stringsAsFactors = FALSE)

siteelevs <- rgbif::elevation(latitude= site_coord$lat, longitude = site_coord$lon, username="susannah2")
colnames(siteelevs) <- c("lat", "lon", "el")
site_coord_elev <- dplyr::full_join(site_coord, siteelevs)

write.csv(site_coord_elev, "locations/site_coord_elev.csv", row.names = FALSE)

## for pcic gridpoints

grid_coord <- read.csv("locations/grid_coordinates.csv", header = TRUE, stringsAsFactors = FALSE) %>%
    rename(lat = Grid_lat, lon = Grid_lon)

gridelevs <- rgbif::elevation(latitude = grid_coord$lat, longitude=grid_coord$lon, username="susannah2")
colnames(gridelevs) <- c("lat", "lon", "el")
grid_coord_elev <- dplyr::full_join(gridelevs, grid_coord) %>%
    select(-contains("Site_"))

# Combine site and grid square location info ####

climatebc_locs <- site_coord_elev %>%
    select(Site, lat, lon, el) %>%
    mutate(id = "site") %>%
    full_join(mutate(grid_coord_elev, id = "grid")) %>%
    select(Site, id, lat, lon, el)

write.csv(climatebc_locs, "locations/climatebc_locs.csv", row.names = FALSE, eol = "\r\n")

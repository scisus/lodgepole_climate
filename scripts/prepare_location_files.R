# Add elevation to locations and format location files for ClimateBC.

# Site_coordinates are seed orchard locations plus additional sites used for model projections
# Grid coordinates are the coordinates of the PNWNAmet grid locations closest to site coordinates
# Parents are the locations and elevations of the parent trees of seed orchard trees.

library(dplyr)
library(rgbif)

# site & grid ######################
# - get elevation data for sites and grid squares containing those sites, then combine and write out.

# get and write elevation data
## for sites

site_coord <- read.csv("locations/site_coordinates.csv", header = TRUE, stringsAsFactors = FALSE)

siteelevs <- rgbif::elevation(latitude= site_coord$lat, longitude = site_coord$lon, elevation_model = "srtm1", username="susannah2")
colnames(siteelevs) <- c("lat", "lon", "el")
site_coord_elev <- dplyr::full_join(site_coord, siteelevs)

write.csv(site_coord_elev, "locations/site_coord_elev.csv", row.names = FALSE)

## for pcic gridpoints

grid_coord <- read.csv("locations/grid_coordinates.csv", header = TRUE, stringsAsFactors = FALSE) %>%
    rename(lat = Grid_lat, lon = Grid_lon)

gridelevs <- rgbif::elevation(latitude = grid_coord$lat, longitude=grid_coord$lon, elevation_model = "srtm3", username="susannah2")
colnames(gridelevs) <- c("lat", "lon", "el")
grid_coord_elev <- dplyr::full_join(gridelevs, grid_coord) %>%
    select(-contains("Site_"))

# Combine site and grid square location info

climatebc_locs <- site_coord_elev %>%
    select(Site, lat, lon, el) %>%
    mutate(id = "site") %>%
    full_join(mutate(grid_coord_elev, id = "grid")) %>%
    select(Site, id, lat, lon, el)

write.csv(climatebc_locs, "locations/climatebc_locs.csv", row.names = FALSE, eol = "\r\n")


# parent ####

pardat <- read.csv("locations/ParentTreeExtractReport_ParentTrees_2014_05_15_13_38_17.csv")

# parent locations and elevations
parent_locs <- pardat %>%
    select(Parent.Tree.Number, contains("Latitude"), contains("Longitude"), Elevation, Seed.Plan.Zone.Code) %>%
    mutate(lat = Latitude.Degrees + Latitude.Minutes/60 + Latitude.Seconds/60^2,
           lon = -(Longitude.Degrees + Longitude.Minutes/60 + Longitude.Seconds/60^2)) %>%
    select(Clone = Parent.Tree.Number, SPU = Seed.Plan.Zone.Code, lat, lon, el = Elevation)

write.csv(parent_locs, "locations/parent_locs.csv", row.names = FALSE)

# parent locations and elevations formatted for climatebc
climatebc_parent_locs <- parent_locs %>%
    rename(id1 = Clone, id2 = SPU)
write.csv(climatebc_parent_locs, "locations/climatebc_parent_locs.csv", row.names = FALSE, eol = "\r\n")

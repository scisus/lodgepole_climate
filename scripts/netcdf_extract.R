# extract site weather data from PCIC netcdf files. netcdf files are for relatively large blocks that include the points of interest. Also record and store grid point locations

# - extracts data from netcdf files with [maximum](data/pcic/PNWNAmet_tasmax_[location].nc.nc) and [minimum](data/pcic/PNWNAmet_tasmin_[location].nc.nc) temperatures for [seed orchard and 2 more northerly sites](location/site_coordinates.csv)
# - calculates the mean daily temperature for each day of 1945-2012
# - writes the mean daily temperature for each day out to a [file](output/PNWNWmet_daily_temps.csv)


library(ncdf4)
library(dplyr)
library(tidyr)

## functions ####

index_get <- function(nc_object) { #nc object is an object created with ncvar_get. pull the metadata for netcdf variable for use in indexing
    temp_meta <- nc_object$var[[1]]

    longitudes <- temp_meta$dim[[1]]$vals
    latitudes <- temp_meta$dim[[2]]$vals
    times <- temp_meta$dim[[3]]$vals

    meta <- list(lons=longitudes, lats=latitudes, times=times)
    return(meta)
}

# get the closest lat lon
get_closest_ref <- function(locations, netcdf_meta) { # locations is a dataframe with Site, lat, and lon columns. netcdf_meta is a list that contains dim information for a netcdf file with named lat and lon lists
    refs <- dplyr::select(locations, Site, lat, lon)
    netcdf_lats <- netcdf_meta$lats
    netcdf_lons <- netcdf_meta$lons

    for (i in 1:nrow(locations)) {
        refs$closest_lat_loc[i] <- which.min(abs(netcdf_lats-locations$lat[i]))
        refs$closest_lat[i] <- netcdf_lats[refs$closest_lat_loc[i]]
        refs$closest_lon_loc[i] <- which.min(abs(netcdf_lons-locations$lon[i]))
        refs$closest_lon[i] <- netcdf_lons[refs$closest_lon_loc[i]]
    }

    return(refs)
}

# pull only temperatures associated with lat/lon of interest
pick_temp_by_location <- function(nc_locations, nc_connection, firstday, lastday) { # nc_locations is output from get_closest_ref and has the lat and lon indexes of the sites of interest. nc_connection is the connection to the netcdf file with the data
    # build a dataframe where each column shows the max temp at a different location
    temps <- data.frame(Date=firstday:lastday)

    for (i in 1:nrow(nc_locations)) {
        temps[,i+1] <- ncvar_get(nc_connection,
                                 start = c(nc_locations$closest_lon_loc[i],
                                           nc_locations$closest_lat_loc[i], 1),
                                 count = c(1,1,-1)) # get the temperature
    }

    colnames(temps)[2:ncol(temps)] <- nc_locations$Site

    # tidy the data
    temp_tidy <- tidyr::gather(temps, key = "Site", value = "temp_in_c", -Date)
    return(temp_tidy)
}



# extract weather data from PCIC netcdf file

extract_pcic <- function(site_locs, maxtemp_nc, mintemp_nc) {

    # dates in these files are days since Jan 1, 1945. Get date locations of dates of interest by replacing dates in first and lastday with your dates of interest
    timestart <- as.Date("1945-01-01")
    firstday <- as.integer(as.Date("1945-01-01") - timestart + 1) # check this
    lastday <- as.integer(as.Date("2012-12-31") - timestart + 1)

    # # read in site locations #############
    # site_locs <- read.csv(site_csv, stringsAsFactors = FALSE, header=TRUE)

    # the netcdf files each contain either maximum or minimum temperatures.

    max_temp_nc <- nc_open(maxtemp_nc)
    min_temp_nc <- nc_open(mintemp_nc)

    # We can also ask the 'nc' object for metadata _about_ the variable we loaded, such as
    # getting its name, units, dimensions, etc. Accessing nc$var this way is accessing metadata,
    # not the variable itself. That was loaded with ncvar_get.

    # get metadata for each variable to use as indexes for extracting the right temperatures


    max_temp_meta <- index_get(max_temp_nc)
    min_temp_meta <- index_get(min_temp_nc)


    locations <- get_closest_ref(site_locs, max_temp_meta) # what is the closest PCIC gridpoint to each site? Should be identical for max and min temp

    # extract only needed temperature data from the netcdf files

    # This is slow
    max_temp <- pick_temp_by_location(locations, max_temp_nc, firstday, lastday)
    min_temp <- pick_temp_by_location(locations, min_temp_nc, firstday, lastday)

    # ncvar_get can't read entire file at once

    # Combine all temp and sites ##################

    max_temps <- dplyr::rename(max_temp, max_temp=temp_in_c)
    min_temps <- dplyr::rename(min_temp, min_temp=temp_in_c)

    alltemps <- dplyr::full_join(max_temps, min_temps) %>%
        mutate(mean_temp = (max_temp + min_temp)/2) %>%
        mutate(Date = timestart - 1 + Date) #%>%
        #rename(Site=site)

    return(list(temps = alltemps, locations = locations))
}


# # read in site locations #############
site_locs <- read.csv("locations/site_coordinates.csv", stringsAsFactors = FALSE, header=TRUE)

seed_orchard_sites <- filter(site_locs, orchard == TRUE)
border_site <- filter(site_locs, Site == "Border")
trench_site <- filter(site_locs, Site == "Trench")

# extract data from PCIC downloads ####
seed_orchard_dat <- extract_pcic(site_locs = seed_orchard_sites,
                                    maxtemp_nc = "data/pcic/PNWNAmet_tasmax_orch.nc.nc",
                                    mintemp_nc = "data/pcic/PNWNAmet_tasmin_orch.nc.nc")

border_site_dat <- extract_pcic(site_locs = border_site,
                                    maxtemp_nc = "data/pcic/PNWNAmet_tasmax_border.nc.nc",
                                    mintemp_nc = "data/pcic/PNWNAmet_tasmin_border.nc.nc")

trench_site_dat <- extract_pcic(site_locs = trench_site,
                                  maxtemp_nc = "data/pcic/PNWNAmet_tasmax_trench.nc.nc",
                                  mintemp_nc = "data/pcic/PNWNAmet_tasmin_trench.nc.nc")

# combine all temperature data ####
all_temps <- rbind(seed_orchard_dat$temps, border_site_dat$temps, trench_site_dat$temps)

# combine all location data - including the lat lon of the pcic grid cells
grid_locs <- rbind(seed_orchard_dat$locations, border_site_dat$locations, trench_site_dat$locations) %>%
    select(-contains("loc"))
colnames(grid_locs) <- c("Site", "Site_lat", "Site_lon", "Grid_lat", "Grid_lon")

# Test ####

#make sure no date at a site has more than one temperature associated with it
toomanytest <- all_temps %>%
    select(Site, Date, mean_temp) %>%
    group_by(Site, Date) %>%
    summarise(tempsperdate = length(mean_temp)) %>%
    filter(tempsperdate > 1)
nrow(toomanytest)==0 #TRUE

# write ####

write.csv(all_temps, 'output/pcic/PNWNAmet_daily_temps.csv', row.names = FALSE)
write.csv(grid_locs, 'locations/grid_coordinates.csv', row.names = FALSE)

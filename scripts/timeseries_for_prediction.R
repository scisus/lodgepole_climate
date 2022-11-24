# This script creates
## a typical daily temperature time series for each site and
## a daily temperature time series for each climate normal period from 1921-2100 (and SSP for future time periods)
# read in and combine monthly historical and future climate normal data
# adjust daily data series to create timeseries for prediction

library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(tidyr)

# read in, filter, and munge historical data ############

histnorm <- list.files( path="data/climateBC/historical normals/", full.names=TRUE ) %>%
    map_dfr( read_csv , id = "fn", show_col_types = FALSE) %>%
    filter(id == "site") %>% # drop grid cell locations
    select(fn, Site, Latitude, Longitude, Elevation, starts_with("Tave")) %>% # only keep average temps
    mutate(period = stringr::str_extract(fn, "\\d{4}_\\d{4}") %>% # create normal period and scenario columns
               stringr::str_replace("_", "-"),
           scenario = "historical") %>%
    select(-fn)

# read in, filter, and munge future data ###########

futnorm <- read.csv("data/climateBC/climatebc_locs_8_ensembleGCMs2011-2100MP.csv") %>%
    filter(id == "site") %>%
    select(Year, Site, Latitude, Longitude, Elevation, starts_with("Tave")) %>%
    mutate(period = stringr::str_extract(Year, "\\d{4}-\\d{4}"),
           scenario = stringr::str_extract(Year, "ssp\\d{3}")) %>%
    select(-Year)

# combine historical and future climate normal periods in one data frame ####
normal_climate <- full_join(histnorm, futnorm) %>%
    tidyr::pivot_longer(contains("Tave")) %>%
    mutate(month = as.numeric(stringr::str_extract(name, "\\d{2}"))) %>%
    rename(normal_mean_monthly_temp = value) %>%
    select(-name)

# add month and doy
datetox <- data.frame(Date_scale = seq(lubridate::ymd('2024-01-01'), lubridate::ymd('2024-12-31'), by = "1 day")) %>%
    mutate(DoY = lubridate::yday(Date_scale), month = lubridate::month(Date_scale))

# generate a typical year ############

pnwnamet <- read.csv("processed/PNWNAmet_adjusted.csv")

# for each site, generate a timeseries of mean temperatures and associated accumulated forcing that reflects the general pattern of temperatures throughout the year. Do this by averaging temperatures on each day between 1945 and 2011 at each site.

typical_ts <- pnwnamet %>%
    mutate(DoY = lubridate::yday(Date)) %>%
    group_by(Site, DoY) %>%
    summarise(mean_mean_temp = mean(mean_temp_corrected)) %>%
    left_join(datetox)

write.csv(typical_ts, "processed/typical_ts.csv", row.names = FALSE)

# create daily time series for each period in normal_climate ########

# monthly temps for daily typical timeseries
mean_monthly_temps_typical_ts <- typical_ts %>%
    left_join(select(datetox, DoY, month)) %>%
    group_by(Site, month) %>%
    summarise(mean_monthly_temp = mean(mean_mean_temp))

# adjust daily time series
daily_ts_normal_periods <- left_join(normal_climate, mean_monthly_temps_typical_ts) %>%
    # calculate an adjustment factor mdiff = mean monthly temp of typical timeseries - normal period mean monthly temp
    mutate(mdiffs = normal_mean_monthly_temp - mean_monthly_temp) %>%
    select(Site, period, scenario, month, mdiffs) %>%
    ungroup() %>%
    full_join(typical_ts) %>%
    # apply adjustment to each day in a typical ts
    mutate(adjusted_mean_temp = mean_mean_temp + mdiffs) %>%
    rename(mean_temp = adjusted_mean_temp) %>%
    select(-mean_mean_temp, -mdiffs)

# test that diffs calculated and applied correctly: mean temperatures of daily_ts_normal_periods should be nearly identical

tf <- daily_ts_normal_periods %>%
    ungroup() %>%
    group_by(Site, period, scenario, month) %>%
    summarise(test_col = mean(mean_temp)) %>%
    full_join(normal_climate) %>%
    mutate(diffs = normal_mean_monthly_temp - test_col)

unique(tf$diffs)

# write out constructed daily time series for all normal periods
write.csv(daily_ts_normal_periods, "processed/normal_daily.csv", row.names = FALSE)

# Extract future climate for sites and pcic points

# libraries ####
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(ggplot2)

# functions ####
# extract monthly average temperature data from climateNA data with id1, id2, Elevation, and Year columns and 12 Tave[1:12] columns
extract_mean_temp <- function(data) {
    
    avgtemp <- data %>% dplyr::select(id1, id2, Elevation, Year, starts_with("Tave")) %>%
        tidyr::gather(key="Month", value="mean_temp", starts_with("Tave")) %>%
        dplyr::mutate(Month = as.numeric(stringr::str_extract(Month, "\\d."))) %>%
        dplyr::rename(Site = id2)
    
    return(avgtemp)
}

# data ####
gcm_files <- list.files("output/climateNA/GCMs", pattern = "csv$")
names(gcm_files) <- stringr::str_extract(gcm_files, "ssp[\\d]{3}")

gcms <- purrr::map(gcm_files, function(x) read.csv(paste0("output/climateNA/GCMs/", x))) %>%
    purrr::map(extract_mean_temp) %>%
    bind_rows(.id = "ssp") %>%
    filter(Month < 7, id1 == "site") %>% # January thru June and site only
    select(-id1)

ggplot(gcms, aes(x = Year, y = mean_temp, group = interaction(Month, ssp), colour = as.factor(Month))) +
    geom_line() +
    facet_grid(Site ~ ssp) +
    scale_colour_brewer(type = "seq") +
    theme_dark() +
    labs(title = "Change in mean monthly temperature", caption="data from 13 model ensemble curated by Mahony et al. 2021")

hist <- read.csv("processed/PCIC_all_seed_orchard_sites_adjusted.csv") %>%
    mutate(Year = lubridate::year(Date), Month = lubridate::month(Date))  %>% # add year and month col
    select(Date, Year, Month, Site, mean_temp_corrected) %>% # drop unneeded cols
    rename(mean_temp = mean_temp_corrected)

# choose a year (1984)

baseyr <- 1984

base <- filter(hist, Year == baseyr, Site == "Sorrento") #366 days

# simplify gcm for dev

badfuture <- filter(gcms, ssp == "ssp585", Site == "Sorrento") # 90 years

# get monthly means for base year

mmt <- base %>% group_by(Site, Year, Month) %>% summarise(mmt = mean(mean_temp)) %>% filter(Month < 7) %>% ungroup() %>% select(Year)

# get differences between monthly temp of base year and monthly temp of a future year

monthly_diffs <- full_join(badfuture, mmt) %>% 
    mutate(mdiff = mean_temp - mmt) %>%
    rename(mmt_gcm = mean_temp, Year_gcm = Year)

# add monthly diffs to daily temps
foo <- base %>%
    full_join(monthly_diffs) %>%
    mutate(mean_temp_gcm = mean_temp + mmt_gcm, DoY = lubridate::yday(Date)) %>%
    filter(Month < 7)

ggplot(foo, aes(x = DoY, y = mean_temp)) +
    geom_line() +
    geom_line(data=foo, aes(x = DoY, y = mean_temp_gcm, colour = Year_gcm, group = Year_gcm))
    
    


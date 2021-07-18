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

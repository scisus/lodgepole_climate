# correct PCIC daily data using ClimateNA monthly data

# - takes data for PCIC data gridpoints near sites and corrects it using a linear model between monthly data at the sites as determined by ClimateNA and the mean of the PCIC data at the nearest gridpoint.
#
# climateNA monthly site temp = a + b * pcic monthly grid temp
#
# corrected pcic daily = a + b * pcic daily temp


library(tidyverse)
library(lubridate)

#read in data ###########

#pcic gridpoint
pcicraw  <- read.csv("output/pcic/seed_orchard_sites_pcic_ts.csv")
#climatena site and gridpoint
cnaraw <- read.csv("output/climateNA/climatena_seedorchardsites_grid_1901-2018Mv6.20.csv")

# Data processing ###############

pcic <- pcicraw %>%
    mutate(Year = year(Date)) %>%
    mutate(DoY = yday(Date)) %>%
    mutate(Month = month(Date)) %>%
    rename(mean_temp_raw = mean_temp)

cna <- cnaraw %>% select(id1, id2, Elevation, Year, starts_with("Tave")) %>%
    gather(key="Month", value="mean_temp", starts_with("Tave")) %>%
    mutate(Month = as.numeric(str_extract(Month, "\\d."))) %>%
    rename(Site = id2)

cnasite <- filter(cna, id1=="site") %>%
    rename(meantempsite = mean_temp) %>%
    select(-id1, -Elevation)
cnagrid <- filter(cna, id1=="grid") %>%
    rename(meantempgrid = mean_temp) %>%
    select(-id1, -Elevation)
cna <- full_join(cnasite, cnagrid)

# compare gridpoints and site locations in ClimateNA

ggplot(filter(cna, Month < 7), aes(x=meantempgrid, y=meantempsite)) +
    geom_point() +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("ClimateNA mean monthly temps 1950-2013 gridpoints vs sitepoints")

# now compare ClimateNA to PCIC data

# calculate pcic monthly temperatures
pcicmonthly <- pcic %>%
    select(mean_temp_raw, Site, Year, Month) %>%
    group_by(Site, Year, Month) %>%
    summarise(meantempgridPCIC = mean(mean_temp_raw))

cna_pcic <- left_join(pcicmonthly, cna)

# compare PCIC gridpoint temps to ClimateNA site temps
ggplot(cna_pcic, aes(x=meantempgridPCIC, y=meantempsite)) +
    geom_point() +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("ClimateNA mean monthly temps at sites vs PCIC mean monthly temps")

#model monthly
corrframemo <- cna_pcic %>%
    split(.$Site) %>%
    map(~ lm(meantempsite ~ meantempgridPCIC, data = .)) %>% #model
    map_dfr("coefficients", .id = ".id") # extract slope and intercept
colnames(corrframemo) <- c("Site", "intercept", "slope")

#create table for paper
# cna_pcic %>%
#     ungroup() %>%
#     tidyr::nest(-Site) %>%
#     dplyr::mutate(
#         fit = purrr::map(data, ~ lm(meantempsite ~ meantempgridPCIC, data=.x)),
#         tidied = purrr::map(fit, broom::tidy)
#     ) %>%
#     tidyr::unnest(tidied) %>%
#     dust() %>%
#     sprinkle(cols=c("estimate", "std.error", "statistic"), round = 2) %>%
#     sprinkle(cols=c("p.value"), fn = quote(pvalString(value)))

knitr::kable(corrframemo)

# apply monthly corrections

pciccorrmo <- pcic %>%
    left_join(corrframemo) %>%
    distinct() %>%
    mutate(mean_temp_corrected = intercept + slope*mean_temp_raw) %>% #correction
    select(-Month, -DoY, -Year) #drop convenience columns

#plot monthly corrections
ggplot(pciccorrmo, aes(x=mean_temp_raw, y=mean_temp_corrected)) +
    geom_point(pch=1)+
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("Raw mean temps vs corrected mean temps")

# plot relationship with equations
ggplot(cna_pcic, aes(x=meantempgridPCIC, y=meantempsite)) +
    geom_point(pch=1) +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("Mean monthly temperatures 1997-2011") +
    xlab("PNWNAmet") +
    ylab("ClimateNA") +
    theme_bw(base_size=15) +
    stat_smooth(method="lm")

write.csv(pciccorrmo, "../lodgepole_climate/processed/PCIC_all_seed_orchard_sites_adjusted.csv", row.names=FALSE)


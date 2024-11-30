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
pcicraw  <- read.csv("output/pcic/PNWNAmet_daily_temps.csv")
#climatebc site and gridpoint
cbcraw <- read.csv("data/climateBC/monthly1901-2021v730.csv")

# Data processing ###############

pcic <- pcicraw %>%
    mutate(Year = year(Date)) %>%
    mutate(DoY = yday(Date)) %>%
    mutate(Month = month(Date)) %>%
    rename(mean_temp_raw = mean_temp)

cbc <- cbcraw %>% select(Site, id, Elevation, Year, starts_with("Tave")) %>%
    gather(key="Month", value="mean_temp", starts_with("Tave")) %>%
    mutate(Month = as.numeric(str_extract(Month, "\\d.")))

cbcsite <- filter(cbc, id=="site") %>%
    rename(meantempsite = mean_temp) %>%
    select(-id, -Elevation)
cbcgrid <- filter(cbc, id=="grid") %>%
    rename(meantempgrid = mean_temp) %>%
    select(-id, -Elevation)
cbc <- full_join(cbcsite, cbcgrid)

# compare gridpoints and site locations in ClimateBC

ggplot(filter(cbc, Month < 7), aes(x=meantempgrid, y=meantempsite)) +
    geom_point() +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("ClimateBC mean monthly temps 1950-2013 gridpoints vs sitepoints", subtitle = "ClimateBC monthly estimates are quite similar for grid points and sitepoints")

PNWNAmetClimateBCcomp <- cbc %>%
    split(.$Site) %>%
    map( ~ lm(meantempsite ~ meantempgrid, data = .)) %>%
    map_dfr("coefficients", .id = ".id")

PNWNAmetClimateBCcomp <- cbc %>%
    split(.$Site) %>%
    map( ~ {
        model <- lm(meantempsite ~ meantempgrid, data = .)
        data.frame(intercept = coef(model)[1], slope = coef(model)[2], r_squared = summary(model)$r.squared)
    }) %>%
    bind_rows(.id = ".id") %>%
    arrange(slope, )

# now compare ClimateBC to PCIC data

# calculate pcic monthly temperatures
pcicmonthly <- pcic %>%
    select(mean_temp_raw, Site, Year, Month) %>%
    group_by(Site, Year, Month) %>%
    summarise(meantempgridPCIC = mean(mean_temp_raw))

cbc_pcic <- left_join(pcicmonthly, cbc)

# compare PCIC gridpoint temps to ClimateBC site temps
ggplot(cbc_pcic, aes(x=meantempgridPCIC, y=meantempsite)) +
    geom_point() +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("ClimateBC mean monthly temps at sites vs PCIC mean monthly temps")

#model monthly
corrframemo <- cbc_pcic %>%
    split(.$Site) %>%
    map(~ lm(meantempsite ~ meantempgridPCIC, data = .)) %>% #model
    map_dfr("coefficients", .id = ".id") # extract slope and intercept
colnames(corrframemo) <- c("Site", "intercept", "slope")
saveRDS(corrframemo, '../flowering-cline/tables/corrframemo.rds')

#create table for paper
# cbc_pcic %>%
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

knitr::kable(corrframemo, row.names = FALSE, digits = 2)

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
ggplot(cbc_pcic, aes(x=meantempgridPCIC, y=meantempsite)) +
    geom_point(pch=1) +
    facet_wrap("Site") +
    geom_abline(slope=1, intercept=0) +
    ggtitle("Mean monthly temperatures 1997-2011") +
    xlab("PNWNAmet") +
    ylab("ClimateBC") +
    theme_bw(base_size=15) +
    stat_smooth(method="lm")

write.csv(pciccorrmo, "processed/PNWNAmet_adjusted.csv", row.names=FALSE)


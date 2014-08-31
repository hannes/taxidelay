rr <- read.csv("out1.tsv.bz2",sep="\t",header=F,stringsAsFactors=F)
names(rr) <- c("trip_distance","crowfiles_distance","pickup_hour","actual_duratrion","otp_duration")

library(dplyr)
library(ggplot2)
library(ggthemes)

theme <- theme_few(base_size = 14)

dd <- tbl_dt(rr) %>% mutate(diff=(actual_duratrion-otp_duration)/60) %>% group_by(pickup_hour) %>% summarize(avgdelay=mean(diff),sd=sd(diff))

ggplot(dd, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd)) + geom_line(aes(y=avgdelay)) +
  geom_text(aes(y=avgdelay,label=round(avgdelay))) +
  theme + xlab("Hour of day") + ylab("Delay (min)") + ggtitle("New York Taxi Delays")

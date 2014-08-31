library(dplyr)
library(ggplot2)
library(ggthemes)

rr <- read.csv("out.tsv",sep="\t",header=F,stringsAsFactors=F)
names(rr) <- c("trip_distance","crowfiles_distance","weekday","pickup_hour","actual_duratrion","otp_duration")
theme <- theme_few(base_size = 14)

dd <- tbl_dt(rr) %>% mutate(diff=(actual_duratrion-otp_duration)/60)

print(group_by(dd,weekday) %>% summarize(count=n()))

std <- function(x) quantile(x,.95)

# by hour
ddd <- dd %>%  group_by(pickup_hour) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddd, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Hour of day") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Hour")

# by weekday
ddw <- dd %>%  group_by(weekday) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddw, aes(x=weekday)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Weekday") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Weekday")

# by hour and weekday
ddbd <- dd %>%  group_by(weekday,pickup_hour) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbd, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  #geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Hour of day") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Weekday and Hour") + facet_grid(.~ weekday)

# by distance
ddbds <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbds, aes(x=distancegrp)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Distance (km)") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Distance")

# by distance and weekday
ddbdsw <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(weekday,distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbdsw, aes(x=distancegrp)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
#  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Distance") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Weekday and Distance") + facet_grid(.~ weekday)

# by distance and hour
ddbdsh <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(pickup_hour,distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbdsh, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  #geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Hour of day") + ylab("Delay (min)") + ggtitle("New York Taxi Delays by Distance and Hour") + facet_grid(. ~ distancegrp)



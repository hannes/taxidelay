library(dplyr)
library(ggplot2)
library(ggthemes)

rr <- read.csv("out.tsv",sep="\t",header=F,stringsAsFactors=F)
names(rr) <- c("license","trip_distance","crowfiles_distance","weekday","pickup_hour","actual_duration","otp_duration")
dd <- tbl_dt(rr) %>% filter(trip_distance > 100) %>% mutate(diff=((actual_duration-otp_duration)/60)/(trip_distance/1000))

drivers <- read.csv("drivers.csv",stringsAsFactors=F)[,1:2]
names(drivers) <- c("license","name")
drivers$license <- as.character(drivers$license)

driversaggr <- dd %>% group_by(license) %>% 
  summarize(mdiff=mean(diff),n=n(),ttimehrs=round(sum(actual_duration)/3600),tdistkms=round(sum(trip_distance)/1000)) %>% 
  inner_join(drivers,copy=T,by=c("license"))

print(driversaggr %>% filter(n>10) %>% arrange(mdiff) %>% select(name,mdiff) %>% head(10))
print(driversaggr %>% arrange(desc(tdistkms)) %>% select(name,tdistkms) %>% head(10))
print(driversaggr %>% arrange(desc(ttimehrs)) %>% select(name,ttimehrs) %>% head(10))

# some housekeeping
print(group_by(dd,weekday) %>% summarize(count=n()))

std <- function(x) quantile(x,.99)
theme <- theme_few(base_size = 14)

# by hour
pdf("byhour.pdf",height=5,width=9)
ddd <- dd %>%  group_by(pickup_hour) %>% summarize(avgdelay=mean(diff,na.rm=T),ql=quantile(diff,.95),qu=quantile(diff,.05)) 
ggplot(ddd, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=ql, ymax=qu),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=round(avgdelay,1))) +
  theme + xlab("Hour of day") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Hour")
dev.off()
# this might be enough

# by hour and weekday
ddbd <- dd %>%  group_by(weekday,pickup_hour) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ddbd <- as.data.frame(collect(ddbd))

ddbd$weekdayn <- factor(ddbd$weekday,ordered=T)
levels(ddbd$weekdayn) <- c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")

pdf("byday.pdf",height=5,width=9)
ggplot(ddbd, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  #geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Hour of day") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Weekday and Hour") + 
  facet_grid(.~weekdayn)
dev.off()


stop()

# by weekday
ddw <- dd %>% group_by(weekday) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddw, aes(x=weekday,group=1)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Weekday") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Weekday")


# by distance
ddbds <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbds, aes(x=distancegrp)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  #geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Distance (km)") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Distance")

# by distance and weekday
ddbdsw <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(weekday,distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbdsw, aes(x=distancegrp)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
#  geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Distance") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Weekday and Distance") + facet_grid(.~ weekday)

# by distance and hour
ddbdsh <- dd %>% mutate(distancekm = floor(trip_distance/1000)) %>% 
  mutate(distancegrp = ifelse(distancekm > 10,11,distancekm)) %>%
  group_by(pickup_hour,distancegrp) %>% summarize(avgdelay=mean(diff),sd=std(diff)) 
ggplot(ddbdsh, aes(x=pickup_hour)) + 
  geom_ribbon(aes(ymin=avgdelay-sd, ymax=avgdelay+sd),fill="yellow",alpha=.5) + 
  geom_line(aes(y=avgdelay)) + geom_point(aes(y=avgdelay)) +
  #geom_text(aes(hjust=0,angle=90,y=avgdelay+.5,label=paste0(round(avgdelay),"±",round(sd)))) +
  theme + xlab("Hour of day") + ylab("Delay (min/km)") + ggtitle("New York Taxi Delays by Distance and Hour") + facet_grid(. ~ distancegrp)



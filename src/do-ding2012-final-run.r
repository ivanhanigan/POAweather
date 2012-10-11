
###########################################################################
# newnode: do-final-run

# get tempnswpoa06stations

for(state in  c('nsw')){ #,'vic','qld','sa','wa','tas','nt','act')){
# state <- 'nsw'
dbSendQuery(ch,
paste(
"select t1.poa_code,
weather_bom.combstats.stnum,
st_distance(
  weather_bom.combstats.the_geom,
  t1.the_geom_centroids
) as distances
into public.temp",state,"poa06stations
from abs_poa.",state,"poa06 t1,
weather_bom.combstats
where st_distance(
weather_bom.combstats.the_geom,
 t1.the_geom_centroids
)<=0.5
order by poa_code, distances;
",sep="")
)

# add index to station number
dbSendQuery(ch,
paste('
create index "station_key" on public.temp',state,'poa06stations
using btree
(stnum);
alter table public.temp',state,'poa06stations cluster on "station_key";
', sep = '')
)

for(i in 1:nrow(weathervars)){
  # i <- 1
  wvar <- weathervars[i,1]
  qvar <- weathervars[i,2]
print(wvar); print(qvar)
 for(yy in 1990:2010){
#yy <- 1990
data <- dbGetQuery(ch,
#cat(
paste("select t1.poa_code, cast(year || '-' || month || '-' || day as date),
sum(t2.",wvar,"*(1/(t1.distances^2))) / sum(1/(t1.distances^2)) as ",wvar,"
from public.temp",state,"poa06stations as t1
join weather_bom.bom_daily_data_1990_2010 as t2
on t1.stnum=t2.station_number
where year = ",yy," and
(",qvar," = 'Y' or ",qvar," = 'N') and
",wvar," is not null
group by t1.poa_code,
cast(year || '-' || month || '-' || day as date)
order by date;
", sep="")
)
## str(data)
## with(data, plot(date, data[,wvar], type='l'))
## head(data)

# write out result to CSV
write.csv(data, paste('data/ding2012-',wvar,'-',state,'.csv',sep=""))
}
# tidy
dbSendQuery(ch,
paste("drop table public.temp",state,"poa06stations",sep=""))

}
}

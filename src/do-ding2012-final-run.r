
###########################################################################
# newnode: do-final-run
# there is currently a problem with the NT (being fixed)
for(state in  c('nsw','vic','qld','sa','wa','tas','act')){
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
)<=0.75
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
# str(data)
# names(table(data$poa_code))
## with(data, plot(date, data[,wvar], type='l'))
## head(data)

# write out result to CSV
if(yy == 1990){
write.csv(data, paste('data/ding2012-',wvar,'-',state,'.csv',sep=""), row.names=F)
} else {
write.table(data,
paste('data/ding2012-',wvar,'-',state,'.csv',sep=""), sep = ',',
append = T, row.names=F, col.names = F)
}

# a qc table
## if(yy == 2009){
## data$poa_code <- as.factor(data$poa_code)
## data2 <- tapply(data[,wvar], data$poa_code, mean, na.rm = T)
## data3 <- as.matrix(data2)
## head(data3)
## data3 <- as.data.frame(data3)
## str(data3)
## if(state == 'nsw'){
## dbWriteTable(ch,paste("temppoa06",substr(wvar,1,20),sep=""),
## data3)
## } else {
## dbWriteTable(ch,paste("temppoa06",substr(wvar,1,20),sep=""),
## data3, append = T)
## }
## }

}
# tidy
dbSendQuery(ch,
paste("drop table public.temp",state,"poa06stations",sep=""))

}
}

# quick visualisation of the 1990 annual average temperatures I made
# in the first loop
## dbSendQuery(ch,
## 'select t1.*, t2.the_geom
## into public.temppoa06map
## from temppoa06average_daily_temper t1
## join abs_poa.auspoa06 t2
## on t1."row.names" = t2.poa_2006;
## alter table public.temppoa06map add column gid2 serial primary key;
## ')

#dbSendQuery(ch,"drop table temppoa06average_daily_temper;")
#dbSendQuery(ch,"drop table public.temppoa06map;")

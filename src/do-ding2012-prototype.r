
###########################################################################
# newnode: do-prototype
postIDW(vname="average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c",
        param_name="avtemp")
# this uses the geographic centroid.  subsequent final run uses pop weighted centre
dbSendQuery(ch,
"select nswpoa.poa_2006,
   st_centroid(nswpoa.the_geom)
into public.tempnswpoa06
from  abs_poa.nswpoa06 nswpoa;
alter table public.tempnswpoa06 add column gid2 serial primary key;

ALTER TABLE public.tempnswpoa06 ALTER COLUMN st_centroid SET NOT NULL;
CREATE INDEX name_for_index2 on public.tempnswpoa06 using GIST(st_centroid);
ALTER TABLE public.tempnswpoa06 CLUSTER ON name_for_index2;
")

# --drop table public.tempnswpoa06stations;
dbSendQuery(ch,
"select nswpoa.poa_2006,
weather_bom.combstats.stnum,
st_distance(
  weather_bom.combstats.the_geom,
  nswpoa.st_centroid
) as distances
into public.tempnswpoa06stations
from  (select * from public.tempnswpoa06) nswpoa,
weather_bom.combstats
where st_distance(
weather_bom.combstats.the_geom,
 st_centroid
)<=0.5
order by poa_2006, distances;

select *, st_buffer(st_centroid, 0.5) into public.tempbuffer from public.tempnswpoa06 where poa_2006 = '2000';
alter table public.tempbuffer add column gid3 serial primary key;
")

data <- dbGetQuery(ch,
"select t1.poa_2006,t1.poa_2006, cast(year || '-' || month || '-' || day as date) , count(station_number) as nostations,
sum(t2.precipitation_in_the_24_hours_before_9am_local_time_in_mm*(1/(t1.distances^2))) / sum(1/(t1.distances^2)) as rain
from public.tempnswpoa06stations as t1
join weather_bom.bom_daily_data_1990_2010 as t2
on t1.stnum=t2.station_number
          where poa_2006 = '2000' and
          (quality_of_precipitation_value = 'Y' or quality_of_precipitation_value = 'N') and
          precipitation_in_the_24_hours_before_9am_local_time_in_mm is not null
          group by t1.poa_2006, t1.poa_2006, cast(year || '-' || month || '-' || day as date)
          order by date;
")
with(data, plot(date, rain))

data2 <- dbGetQuery(ch,
"select t1.poa_2006,t1.poa_2006, cast(year || '-' || month || '-' || day as date) , station_number,
t2.precipitation_in_the_24_hours_before_9am_local_time_in_mm, quality_of_precipitation_value, distances
from public.tempnswpoa06stations as t1
join weather_bom.bom_daily_data_1990_2010 as t2
on t1.stnum=t2.station_number
          where date = '2010-02-28' and year = 2010 and poa_2006 = '2000' and
          precipitation_in_the_24_hours_before_9am_local_time_in_mm is not null
          order by date;
")

# tidy up
dbSendQuery(ch,
"drop table public.tempnswpoa06;
drop table public.tempnswpoa06stations;
drop table public.tempbuffer;
")

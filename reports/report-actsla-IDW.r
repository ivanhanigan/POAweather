# this is a small project to demo the ACT weather by suburb


################ 
# func
# func-connect2postgres
source('src/connect2postgres.r')
##################
# func-postIDW
source('src/postIDW.r')

##########################
# do
ch <- connect2postgres(hostip='pdb2.anu.edu.au',db='gislibrary',user='gislibrary',p='gislibrary')
# enter password at console
# change for demo
dbSendQuery(ch,"ALTER USER student1 WITH PASSWORD 'horsebatterycorrectstaple'")

dbGetQuery(ch,
           'select * from weather_bom.combstats limit 1')

# use default for actslao01
postIDW(vname="average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c",
        param_name="avtemp")

actslaweather <- dbGetQuery(ch,
                            "select t1.sla_name,t1.sla_code, cast(year || '-' || month || '-' || day as date) ,
          sum(t2.average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c*(1/(t1.distances^2))) / sum(1/(t1.distances^2)) as avtemp
          from 
          (
          select abs_sla.actsla01.sla_name,abs_sla.actsla01.sla_code,weather_bom.combstats.stnum,
          st_distance(
          weather_bom.combstats.the_geom, 
          st_centroid(abs_sla.actsla01.the_geom)
          ) as distances  
          from abs_sla.actsla01, weather_bom.combstats
          where st_distance(
          weather_bom.combstats.the_geom, 
          st_centroid(abs_sla.actsla01.the_geom))<=0.15
          ) as t1 
          join (select * from weather_bom.bom_daily_data_1990_2010 where year = 2010) as t2
          on t1.stnum=t2.station_number 
          where average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c is not null
          group by t1.sla_name, t1.sla_code, cast(year || '-' || month || '-' || day as date)
                            ")

# clean
str(actslaweather)
head(actslaweather)
slas <- names(table(actslaweather$sla_name))

with(subset(actslaweather, sla_name == 'Kaleen'),
     plot(date, avtemp, type = 'l')
)
for(i in 1:length(slas)){
  with(subset(actslaweather, sla_name == slas[i]),
       lines(date, avtemp,col=i)
  )  
}


# Inverse distance weighted averages to calculate weather data for zones
# 
# We wrote a paper on this in 2005 that is still relevant regarding the choice of target location to calculate distances to: the geographic centre, the population weighted centre or the centres of sub-areas and then weighted aggregation of these.
# 
# external link: http://ij-healthgeographics.com/content/5/1/38
# 
# The basic form of an IDW average of some station_data table, weighted by distances calculated from a table of stations_locations to the centres of some area_data table in Postgres is:
#   
#   select t1.area_name,t2.dates,
# sum(t2.data*(1/(t1.distances^2))) / sum(1/(t1.distances^2)) as weighted_data 
# from 
# (
#   select area_data.area_name,station_locations.station_number,
#   st_distance(
#     station_locations.the_geom, 
#     st_centroid(area_data.the_geom)
#   ) as distances	
#   from area_data, station_locations
#   where st_distance(
#     station_locations.the_geom, 
#     st_centroid(area_data.the_geom))<= search_window
# ) as t1 
# join station_data as t2
# on t1.station_number=t2.station_number 
# group by t1.area_name,t2.dates;
# 
# Indexing is usually required as the query can take a long time.
# 
# I also find that calculating the distances and creating a static lookup table can improve the time taken.
# An R function that will create the query
# 
# here is a function that will create the query for different area_data and station_data tables (names can be found from the online data catalogue).

postIDW <- function( 
  area_data='abs_sla.actsla01',
  area_name='sla_name',
  area_code='sla_code',
  station_data='weather_bom.bom_daily_data_1990_2010',
  station_data_number='station_number',
  station_location_table='weather_bom.combstats',
  station_location_number='stnum',
  param_name='maxtemp',
  vname='maximum_temperature_in_24_hours_after_9am_local_time_in_degrees',
  timevar=" cast(year || '-' || month || '-' || day as date) ", 
  search_window=0.5
  ){
  
  
  cat(
    paste("
select t1.",area_name,",t1.",area_code,",",timevar,",
          sum(t2.",vname,"*(1/(t1.distances^2))) / sum(1/(t1.distances^2)) as ",param_name,"
          from 
          (
          select ",area_data,".",area_name,",",area_data,".",area_code,",",station_location_table,".",station_location_number,",
          st_distance(
          ",station_location_table,".the_geom, 
          st_centroid(",area_data,".the_geom)
          ) as distances	
          from ",area_data,", ",station_location_table,"
          where st_distance(
          ",station_location_table,".the_geom, 
          st_centroid(",area_data,".the_geom))<=",search_window,"
          ) as t1 
          join ",station_data," as t2
          on t1.",station_location_number,"=t2.",station_data_number," 
          where ",vname," is not null
          group by t1.",area_name,", t1.",area_code,",",timevar,";", sep="")
)
  
}

#################
# now the parameter can be changed
# postIDW(vname="average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c",
#        param_name="avtemp")

#################
# or the locations as well
#postIDW(area_data='abs_sla.vicsla01',area_name='sla_name',area_code='sla_code',vname="average_daily_temperature_calculated_by_averaging_the_max_and_min_temperatures_in_degrees_c",param_name="avtemp")

#area_data= any area data in the postGIS server
#area_name= the names
#area_code= the codes
#station_data= the schema.tablename with the data to IDW average
#station_data_number= 'station_number'
#station_location_table= the schema.tablename with the locations of the stations with data to IDW average
#station_location_number='stnum'
#param_name= a short name ie 'maxtemp'
#vname= the original long name ie 'maximum_temperature_in_24_hours_after_9am_local_time_in_degrees'
#timevar= in the daily BoM data it is " cast(year || '-' || month || '-' || day as date) ".  In the 3 hourly dataset it is different
#search_window= this is in decimal degrees if projection is GDA94 or similar.  to use metres change ST_Distance to ST_Distance_Sphere
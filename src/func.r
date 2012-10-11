
###########################################################################
# newnode: connect2postgres
################ 
source('src/connect2postgres.r')
ch <- connect2postgres(hostip='130.56.102.41',db='delphe',user='student1')

###########################################################################
# newnode: postIDW
##################
source('src/postIDW.r')

###########################################################################
# newnode: weathervars
weathervars <- matrix(c(
   'average_daily_temperature_calculated_by_averaging_the_max_and_m',
   'quality_of_average_daily_temperature_min_max_2_',
   'maximum_temperature_in_24_hours_after_9am_local_time_in_degrees',
   'quality_of_maximum_temperature_in_24_hours_after_9am_local_time',
   'minimum_temperature_in_24_hours_before_9am_local_time_in_degree',
   'quality_of_minimum_temperature_in_24_hours_before_9am_local_tim',
   'average_daily_dew_point_temperature_in_degrees_c',
   'quality_of_overall_dew_point_temperature_observations_used',
   'precipitation_in_the_24_hours_before_9am_local_time_in_mm',
   'quality_of_precipitation_value',
   'mean_daily_wind_speed_in_km_h',
   'quality_of_mean_daily_wind_speed'
),ncol=2,byrow=T)
#weathervars

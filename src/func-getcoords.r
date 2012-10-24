
###########################################################################
# newnode: func-getcoords
# extract for ccd

# func


getcoords <- function(ccd, censustable = 'abs_cd.nswcd06', ch){
  if(!exists('ch')) stop('ch not found, please connect to postgis database using connect2postgres')
  coords <- dbGetQuery(ch,
                       sprintf("select cd_code, st_x(st_centroid(the_geom)) as longitude,
                               st_y(st_centroid(the_geom)) as latitude 
                               from %s 
                               where cd_code = %s limit 1", censustable, ccd)
  )
  return(coords)  
}

#### DO ####
ch <- connect2postgres('130.56.102.41', db='delphe', user='student1')
for(ccd in c(1010104, 1010107, 1010108)){
coords <- getcoords(ccd = ccd, ch = ch)
print(coords)
}

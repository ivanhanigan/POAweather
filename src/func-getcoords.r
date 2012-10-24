# extract for ccd

# func
# a function to connect to PostgreSQL 8.4
connect2postgres <- function(hostip=NA,db=NA,user=NA, p=NA, os = 'linux', pgutils = c('/home/ivan/tools/jdbc','c:/pgutils')){
  if(is.na(hostip)){
    hostip=readline('enter hostip: ')
  } 
  if(is.na(db)){
    db=readline('enter db: ')
  }
  if(is.na(user)){
    user=readline('enter user: ')
  }
  if(is.na(p)){
    pwd=readline(paste('enter password for user ',user, ': ',sep=''))
  } else {
    pwd <- p
  }
  if(os == 'linux'){
    if (!require(RPostgreSQL)) install.packages('RPostgreSQL', repos='http://cran.csiro.au'); require(RPostgreSQL)
    con <- dbConnect(PostgreSQL(),host=hostip, user= user, password=pwd, dbname=db)
  } else { 
    if (!require(RJDBC)) install.packages('RJDBC'); require(RJDBC) 
    # This downloads the JDBC driver to your selected directory if needed
    if (!file.exists(file.path(pgutils,'postgresql-8.4-701.jdbc4.jar'))) {
      dir.create(pgutils,recursive =T)
      download.file('http://jdbc.postgresql.org/download/postgresql-8.4-701.jdbc4.jar',file.path(pgutils,'postgresql-8.4-701.jdbc4.jar'),mode='wb')
    }
    # connect
    pgsql <- JDBC( 'org.postgresql.Driver', file.path(pgutils,'postgresql-8.4-701.jdbc4.jar'))
    con <- dbConnect(pgsql, paste('jdbc:postgresql://',hostip,'/',db,sep=''), user = user, password = pwd)
  }
  # clean up
  rm(pwd)
  return(con)
}

#  ch <- connect2postgres()
# enter password at console


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




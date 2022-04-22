####################################################################################
# SWAT Input preperation
# Manh-Hung Le - 2021 July 20
# objectives:
# - convert precipitation to SWAT format
# - for SWAT 2012 version
####################################################################################
library(tidyverse)
library(raster)
library(sf)
library(psych)
library(tidyverse)
library(tictoc)
library(lubridate)

# swat folder
maindir = 'D:/multiSwat_inputPre'
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')
nb = length(basinNames)


for(ib in 1:nb) {
  tic()
  # path
  projPath = paste(maindir,'/','swat_',riverSystems[ib],'_',basinNames[ib], sep = '')
  rawPath = file.path(projPath, '00DataPreparation','processedClim')
  catchName =  basinNames[ib]
  cat(catchName,'\n')
  
  # create output folder - centroid 
  processPath = file.path(projPath,'01input','02cliDat','precip')
  # read files 
  dat = read.csv(paste(rawPath,'/','preImerg.csv', sep = ''))
  pCoord = read.csv(paste(rawPath,'/','preImergcoord.csv', sep = ''))
  ngrid = nrow(pCoord)
  
  ###### Create metadata#######
  
  # convert points data from wgs to utm 48n
  # EPSG:4326 - WGS 84
  # EPSG: 32448 - UTM 48N 
  
  colnames(pCoord) = c('x','y')
  pCoordSp = pCoord
  coordinates(pCoordSp) <- c("x", "y")
  proj4string(pCoordSp) <- CRS("+init=epsg:4326") # WGS 84
  
  CRS.new = CRS("+init=epsg:32448")
  pCoordutmSp = spTransform(pCoordSp, CRS.new)
  
  # check
  # dem data - to create elevation
  dem_hdyshed = raster::raster(paste(projPath,'/01input/01catAtr/dem','/',
                             catchName,'dem_u48n.tif', sep = ''))
  
  
  plot(dem_hdyshed, main = catchName)
  plot(pCoordutmSp, add= T)
  
  
  eleDat =  raster::extract(dem_hdyshed, pCoordutmSp)
  eleDat[is.na(eleDat)] = -999
  summary(eleDat)
  
  # create meta data for one DEM
  metaPrec = data.frame(ID = numeric(ngrid),
                        NAME = numeric(ngrid),
                        LAT = numeric(ngrid),
                        LONG = numeric(ngrid),
                        ELEVATION = numeric(ngrid))
  sName = colnames(dat)[-1]
  for(iS in 1:ngrid){
    metaPrec$ID[iS] = iS
    metaPrec$NAME[iS] = sName[iS]
    metaPrec$LAT[iS] = pCoord$y[iS]
    metaPrec$LONG[iS] = pCoord$x[iS]
    metaPrec$ELEVATION[iS] = eleDat[iS]
  }
  
  opFile = paste(processPath,'/','pcp_hdyshed','.txt',sep = '')
  write.table( metaPrec, opFile,sep = ',', row.names = F, quote = F)
  ###### create files ##########
  startDate = as.Date(dat[1,1], format = '%Y-%m-%d')
  firstLine = paste0(formatC(year(startDate), width = 4, flag = 0),
                   formatC(month(startDate), width = 2, flag = 0), 
                   formatC(day(startDate), width = 2, flag = 0),
                   sep = '')
  datO = dat[,-1] # remove date column
  
  #-----------------------------------------
  Interpolation = function(TS){
    library(zoo)
    TS2 = na.approx(TS)
    TS = TS2
    return(TS2)
    
  }
  #--------------------------------------
  for(iS in 1:ncol(datO)){
    FileName = sName[iS]
    TS = datO[,iS]
    # Step1: Interpolation Missing Value
    # check NA location
    t= which(is.na(TS) == TRUE)
    
    if (length(t) != 0){
      TS = Interpolation(TS)
    }
    
    #Step2: Write down the txt file
    
    f <- paste(processPath,'/',FileName,".txt",sep = "")
    if (file.exists(f)){
      file.remove(f)
    }
    
    write.table(firstLine, paste(processPath,'/',FileName,".txt",sep = ""), quote = FALSE, append = TRUE, row.names = F, col.names = F)
    write.table(TS, paste(processPath,'/',FileName,".txt",sep = ""), quote = FALSE, append = TRUE, row.names = F,col.names = F)
  }
  toc()
}
  




 


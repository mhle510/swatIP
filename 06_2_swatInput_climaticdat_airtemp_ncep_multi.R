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
  processPath = file.path(projPath,'01input','02cliDat','airtem')
  
  txDat = read.csv(paste(rawPath,'/','txncep.csv', sep = ''))
  tmDat = read.csv(paste(rawPath,'/','tmncep.csv', sep = ''))
  
  txDat[,-1] = round(txDat[,-1],2)
  tmDat[,-1] = round(tmDat[,-1],2)
  tCoord = read.csv(paste(rawPath,'/','tncepcoord.csv', sep = ''))
  
  ngrid = nrow(tCoord)
  
  ###### Create metadata#######
  
  # convert points data from wgs to utm 48n
  # EPSG:4326 - WGS 84
  # EPSG: 32448 - UTM 48N 
  colnames(tCoord) = c('x','y')
  tCoordSp = tCoord
  coordinates(tCoordSp) <- c("x", "y")
  proj4string(tCoordSp) <- CRS("+init=epsg:4326") # WGS 84
  
  CRS.new = CRS("+init=epsg:32448")
  tCoordutmSp = spTransform(tCoordSp, CRS.new)
  
  # check
  # check
  # dem data - to create elevation
  dem_hdyshed = raster::raster(paste(projPath,'/01input/01catAtr/dem','/',
                                     catchName,'dem_u48n.tif', sep = ''))
  
  plot(dem_hdyshed, main = catchName)
  plot(tCoordutmSp, add= T)
  
  
  eleDat =  raster::extract(dem_hdyshed, tCoordutmSp)
  eleDat[is.na(eleDat)] = -999
  summary(eleDat)
  
  # create meta data for one DEM
  metaTemp = data.frame(ID = numeric(ngrid),
                        NAME = numeric(ngrid),
                        LAT = numeric(ngrid),
                        LONG = numeric(ngrid),
                        ELEVATION = numeric(ngrid))
  sName = colnames(txDat)[-1]
  for(iS in 1:ngrid){
    metaTemp$ID[iS] = iS
    metaTemp$NAME[iS] = sName[iS]
    metaTemp$LAT[iS] = tCoord$y[iS]
    metaTemp$LONG[iS] = tCoord$x[iS]
    metaTemp$ELEVATION[iS] = eleDat[iS]
  }
  
  opFile = paste(processPath,'/','temp_hdyshed','.txt',sep = '')
  write.table(metaTemp, opFile,sep = ',', row.names = F, quote = F)
  
  
  
  ###### create files ##########
  startDate = as.Date(tmDat[1,1], format = '%Y-%m-%d')
  firstLine = paste0(formatC(year(startDate), width = 4, flag = 0),
                     formatC(month(startDate), width = 2, flag = 0), 
                     formatC(day(startDate), width = 2, flag = 0),
                     sep = '')
  
  txDatO = txDat[,-1] # remove first column
  tmDatO = tmDat[,-1]
  
  
  #-----------------------------------------
  Interpolation = function(TS){
    library(zoo)
    TS2 = na.approx(TS)
    TS = TS2
    return(TS2)
    
  }
  #--------------------------------------
  
  
  for(iS in 1:ncol(txDatO)){
    fileName = sName[iS]
    
    # Step1: Interpolation Missing Value
    # check NA location
    TS1 = txDatO[,iS]
    TS2 = tmDatO[,iS]
    
    infill = function(TS){
      t= which(is.na(TS) == TRUE)
      
      if (length(t) != 0){
        TS = Interpolation(TS)
      }
      return(TS)
    }
    
    TS1 = infill(TS1); TS2 = infill(TS2)
    TScombined = data.frame(TS1,TS2)
    
    #Step2: Write down the txt file
    
    f <- paste(processPath,'/',fileName,".txt",sep = "")
    if (file.exists(f)){
      file.remove(f)
    }
    
    fileOp = paste(processPath, '/',fileName,'.txt', sep  ='')
    write.table(firstLine, fileOp, quote = FALSE, append = TRUE, row.names = F, col.names = F)
    write.table(TScombined, fileOp, quote = FALSE, append = TRUE, row.names = F,col.names = F, sep = ",")
  }
  toc()
}
  




 


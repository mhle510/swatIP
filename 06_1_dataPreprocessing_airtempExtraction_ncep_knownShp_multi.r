####################################################################################
# Manh-Hung Le - 2021 June 29
# objectives:
# extract vnGP precipitation dataset from a shapefile
####################################################################################
library(lubridate)
library(ncdf4)
library(tidyverse)
library(raster)
library(sp)
library(rgdal)
library(readxl)
library(tidyverse)
library(lubridate)
library(rgeos)
library(parallel)
library(tictoc)

# swat folder
maindir = 'XXX/multiSwat_inputPre'
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')
nb = length(basinNames)

# temp folder
airtempPath = 'XXX/CFSv2_vnbasins'
txFiles = list.files(paste(airtempPath,'/','tmax',sep = ''), pattern = '.tif', full.names = T,recursive = T)
tmFiles = list.files(paste(airtempPath,'/','tmin',sep = ''), pattern = '.tif', full.names = T,recursive = T)
nd = length(txFiles)

# read tmax and tmin raster files
date = substr(basename(tmFiles), 1, 8)
dateF = make_date(year = substr(date,1,4), month = substr(date,5,6), day = substr(date,7,8))


for(ib in 1:nb){
  tic()
  mainPath = paste(maindir,'/','swat_',riverSystems[ib],'_',basinNames[ib], sep = '')
  catname = basinNames[ib]
  cat('========= catchment', catname,"==========", '\n')
  basinShp = readOGR(paste(maindir,'/','0_inputPreparation','/','knownSubbasins','/',
                           catname,'_subs.shp', sep = ''), verbose = F)
  # create new folder to store precipitation at centroid sub-basins
  dir.create(file.path(mainPath, '00dataPreparation','processedClim'), showWarnings = F)
  processedPath = file.path(mainPath, '00dataPreparation','processedClim')
  
  CRS.wgs = CRS("+init=epsg:4326")
  basinShpwgs = spTransform(basinShp, CRS.wgs)
  nameSub = basinShpwgs$Subbasin
  nShp = length(basinShpwgs)
  gridPoints = data.frame(name = paste('p',
                                       paste0(formatC(as.numeric(nameSub),width = 3,flag = 0)),sep = ''),
                          X = getSpPPolygonsLabptSlots(basinShpwgs)[,1],
                          Y = getSpPPolygonsLabptSlots(basinShpwgs)[,2])
  
  no_cores = detectCores(logical = TRUE)
  cl = makeCluster(no_cores-10)  
  #registerDoParallel(cl)  
  
  # export library raster to all cores
  clusterEvalQ(cl, library("raster"))
  
  #cat('========= working with subbasin ==========','\n')
  txDat = mat.or.vec(nd, nShp)
  tmDat = mat.or.vec(nd, nShp)
  
  # convert basin from SpatialPolygonsDataFrame to SpatialPolygons (required format by the extract() function)
  basinGeom = geometry(basinShpwgs)
  
  tx = parLapply(cl = cl, 1:nd,
                function(ll,txFiles,basinGeom){
                  # note that we need to explicitly declare all "external" variables used inside clusters
                  rawRas = raster(txFiles[[ll]]) # read raster in this step
                  opDat = lapply(1:length(basinGeom),FUN = function(i){
                    tx = data.frame(extract(rawRas, basinGeom[i], weights = TRUE, normalizeWeights= TRUE))
                    round(sum(tx[,1]*tx[,2]),2)
                  })
                  # merge data from list to a vector
                  do.call(c,opDat)
                }, txFiles,basinGeom # you need to pass these variables into the clusters
  )
  
  tm = parLapply(cl = cl, 1:nd,
                function(ll,tmFiles,basinGeom){
                  # note that we need to explicitly declare all "external" variables used inside clusters
                  rawRas = raster(tmFiles[[ll]]) # read raster in this step
                  opDat = lapply(1:length(basinGeom),FUN = function(i){
                    tm = data.frame(extract(rawRas, basinGeom[i], weights = TRUE, normalizeWeights= TRUE))
                    round(sum(tm[,1]*tm[,2]),2)
                  })
                  # merge data from list to a vector
                  do.call(c,opDat)
                }, tmFiles,basinGeom # you need to pass these variables into the clusters
  )
  
  txDat = do.call(rbind,tx) 
  tmDat = do.call(rbind,tm)

  txDat = data.frame(date = dateF,
                    txDat)
  tmDat = data.frame(date = dateF,
                     tmDat)
  
  colnames(txDat) = c('date',
                       paste('t',paste0(formatC(as.numeric(nameSub),width = 3,flag = 0)),sep = ''))
  colnames(tmDat) = c('date',
                      paste('t',paste0(formatC(as.numeric(nameSub),width = 3,flag = 0)),sep = ''))
  pointsCoord = gridPoints[,c(2:3)]
  
  write.csv(txDat, paste(processedPath,'/','txncep.csv', sep = ''), row.names = F)
  write.csv(tmDat, paste(processedPath,'/','tmncep.csv', sep = ''), row.names = F)
  write.csv(pointsCoord, paste(processedPath,'/','tncepcoord.csv', sep = ''), row.names = F)
  toc()
}

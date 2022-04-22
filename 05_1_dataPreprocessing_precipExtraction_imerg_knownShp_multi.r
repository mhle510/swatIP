####################################################################################
# Manh-Hung Le - 2021 June 29
# objectives:
# extract precipitation dataset from a shapefile
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
library(tictoc)
library(parallel)
library(doParallel)

# swat folder
maindir = 'D:/multiSwat_inputPre'
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')
nb = length(basinNames)

# precip folder
pretifPath = 'F:/GlobalRainfall/processed_imergf_vnbasins'
years = seq(2010,2019,1)
preFiles = list.files(paste(pretifPath,'/',years,sep = ''), pattern = '.tif', full.names = T,recursive = T)
nd = length(preFiles)

# read precip raster files and extract dates 
date = substr(basename(preFiles), 8, 15)
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
  #cat('========= working with subbasin ==========','\n')
  preDat = mat.or.vec(nd, nShp)
  
  #noCores = detectCores() - 12
  #cl1 = makeCluster(noCores)
  
  no_cores = detectCores(logical = TRUE)
  cl = makeCluster(no_cores-12)  
  #registerDoParallel(cl)  
  
  # export library raster to all cores
  clusterEvalQ(cl, library("raster"))
  
  # convert basin from SpatialPolygonsDataFrame to SpatialPolygons (required format by the extract() function)
  basinGeom = geometry(basinShpwgs)
  
  tic()
  t = parLapply(cl = cl, 1:nd,
                function(ll,preFiles,basinGeom){
                  # note that we need to explicitly declare all "external" variables used inside clusters
                  rawRas = raster(preFiles[[ll]]) # read raster in this step
                  opDat = lapply(1:length(basinGeom),FUN = function(i){
                    t = data.frame(extract(rawRas, basinGeom[i], weights = TRUE, normalizeWeights= TRUE))
                    round(sum(t[,1]*t[,2]),2)
                  })
                  # merge data from list to a vector
                  do.call(c,opDat)
                }, preFiles,basinGeom # you need to pass these variables into the clusters
  )
  toc()
  preDat = do.call(rbind,t) # each subcatchment is a column
  
  preDat = data.frame(date = dateF,
                      preDat)
  
  colnames(preDat) = c('date',
                       paste('p',paste0(formatC(as.numeric(nameSub),width = 3,flag = 0)),sep = ''))
  pointsCoord = gridPoints[,c(2:3)]
  
  write.csv(preDat, paste(processedPath,'/','preImerg.csv', sep = ''), row.names = F)
  write.csv(pointsCoord, paste(processedPath,'/','preImergcoord.csv', sep = ''), row.names = F)
  toc()
}

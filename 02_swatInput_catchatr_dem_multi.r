####################################################################################
# Manh-Hung Le - 2021 June 20
# objectives:
# - extract dem information for each basin given known its study box 
# - convert dem projection from geographic coordinates (wgs 84) to projected coordinates (utm 48n)
####################################################################################

library(rgdal)
library(raster)
library(tidyverse)
library(sp)
library(readxl)

# path setup
maindir = 'D:/multiSwat_inputPre'
basinNames = c('gvo','chu','xla','gso','nkh', 'slu','bye','aho')
riverSystems = c('sk', 'ht','ma','mk','ca','sk','mk','sk')
nb = length(basinNames)
# metadata
metaData = read.csv(file.path(maindir,'0_inputPreparation','metaData_daProject.csv'))



# hydshedDem
rawDEM = raster(file.path(maindir,'0_inputPreparation/rawdem/vnbasins_3s/hdr.adf'))

for(ii in 1:nb){
  mainPath = paste(maindir,'/','swat_',riverSystems[ii],'_',basinNames[ii], sep = '')
  catname = basinNames[ii]
  cat(catname,'\n')
  boxName = paste(basinNames[ii],'_studyBox.shp', sep = '')
  studyBox = readOGR(file.path(mainPath,'00dataPreparation','studyBox',
                               boxName))
  processedPath =  file.path(mainPath, '01input','01catAtr','dem')
 
  # crop DEM to study box
  croppedDEM = mask(rawDEM, mask = studyBox, na.rm = T)
  croppedDEM = crop(croppedDEM,y =studyBox, na.rm = T)  
  
  #plot(croppedDEM)
  #croppedDEM
  # convert DEM coordination from WGS 84 to UTM 48N
  # EPSG:4326 - WGS 84
  # EPSG: 32448 - UTM 48N 
  # ref: https://spatialreference.org/ref/epsg/?search=utm+48&srtext=Search
  croppedDEM_UTM48 = projectRaster(croppedDEM, res = 90, crs = "+init=epsg:32448",
                                   method="bilinear")
  
  # Plotting two raster files
  par(mfrow = c(1, 2))
  plot(croppedDEM,axes = TRUE, main = "Lat-Long Coordinates", cex.axis = 0.95)
  plot(croppedDEM_UTM48, axes = TRUE, main = "UTM Coordinates",  cex.axis = 0.95)
  opFile = paste(processedPath, '/',catname,'dem_u48n.tif', sep = '')
  raster::writeRaster(croppedDEM_UTM48,
                      opFile,
                      format = "GTiff", overwrite = T )
}


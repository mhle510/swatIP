####################################################################################
# Manh-Hung Le - 2021 June 20
# objectives:
# - define a study box
# - projected soil
####################################################################################

library(rgdal)
library(raster)
library(tidyverse)
library(sp)
library(readxl)
#library(xlsx)

maindir = 'XXX/multiSwat_inputPre'
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')
nb = length(basinNames)

# metadata
metaData = read.csv(file.path(maindir,'0_inputPreparation','metaData_daProject.csv'))

# meta for soil
soilclass = read.csv(file.path(maindir, '0_inputPreparation', 'processedsoil','soilreclassification.csv'))
soilmetaData = read_xls(file.path(maindir, '0_inputPreparation','processedsoil','usersoil_fao_vnbasin_final.xls'), sheet = 'usersoil')

# raw soil
rawsoil = raster(file.path(maindir,'0_inputPreparation/processedsoil/recsoilfao_wgs.tif'))

for(ii in 1:nb){
  mainPath = paste(maindir,'/','swat_',riverSystems[ii],'_',basinNames[ii], sep = '')
  catname = basinNames[ii]
  cat(catname,'\n')
  boxName = paste(basinNames[ii],'_studyBox.shp', sep = '')
  studyBox = readOGR(file.path(mainPath,'00dataPreparation','studyBox',
                               boxName))
  processedPath =  file.path(mainPath, '01input','01catAtr','soil')
  
  
  # crop luc to study box
  croppedsoil = mask(rawsoil, mask = studyBox, na.rm = T)
  croppedsoil = crop(croppedsoil,y = studyBox, na.rm = T)  
  
  #plot(croppedsoil)
  ##cropped
  # convert DEM coordination from WGS 84 to UTM 48N
  # EPSG:4326 - WGS 84
  # EPSG: 32448 - UTM 48N 
  # ref: https://spatialreference.org/ref/epsg/?search=utm+48&srtext=Search
  croppedsoil_UTM48 = projectRaster(croppedsoil, res = 1000, crs = "+init=epsg:32448",
                                   method="ngb")
  
  # Plotting two raster files
  par(mfrow = c(1, 2))
  plot(croppedsoil,axes = TRUE, main = "Lat-Long Coordinates", cex.axis = 0.95)
  plot(croppedsoil_UTM48, axes = TRUE, main = "UTM Coordinates",  cex.axis = 0.95)
  opFile = paste(processedPath, '/',catname,'soil_u48n.tif', sep = '')
  raster::writeRaster(croppedsoil_UTM48,
                      opFile,
                      format = "GTiff", overwrite = T )
  
  soilID = unique(croppedsoil)
  locID = which(soilclass$newCode %in% soilID)
  
  # export metadata
  datSoil = data.frame(SOIL_ID = soilclass$newCode[locID],
                   SNAME = soilclass$SNAME[locID])
  datUsersoil = data.frame(soilmetaData[locID,])
  
  #excelopsoilFile = paste(mainPath, '/','01input','/',catname,'_soils.xlsx',sep = '')
  csvopsoilFile = paste(mainPath, '/','01input','/',catname,'_soils.csv',sep = '')
  #write.xlsx(datSoil, excelopsoilFile, sheetName = paste(catname,'_soils',sep = ''), 
  #           col.names = TRUE, row.names = FALSE, append = FALSE)
  write.csv(datSoil, csvopsoilFile ,  row.names = F)
  
  #excelopusersoilFile = paste(mainPath, '/','01input','/',catname,'_usersoils.xlsx',sep = '')
  csvopusersoilFile = paste(mainPath, '/','01input','/',catname,'_usersoils.csv',sep = '')
  #write.xlsx(datUsersoil, excelopusersoilFile, sheetName = paste(catname,'_usersoils',sep = ''), 
  #           col.names = TRUE, row.names = FALSE)
  write.csv(datUsersoil, csvopusersoilFile ,  row.names = F)
}




















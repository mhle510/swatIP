####################################################################################
# Manh-Hung Le - 2021 Aug 21
# objectives:
# - define a study box
# requirements
# projected land cover
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

# luc meta Data
lumetaData = readxl::read_xlsx(file.path(maindir,'0_inputPreparation','rawlu','modis_landuse_metaData.xlsx'),
                               sheet = 'IGBP_SWAT_classification')

# import luc data
rawluc = raster(file.path(maindir, '0_inputPreparation','processedlu/reclu2016_wgs.tif'))

for(ii in 1:nb){
  mainPath = paste(maindir,'/','swat_',riverSystems[ii],'_',basinNames[ii], sep = '')
  catname = basinNames[ii]
  cat(catname,'\n')
  boxName = paste(basinNames[ii],'_studyBox.shp', sep = '')
  studyBox = readOGR(file.path(mainPath,'00dataPreparation','studyBox',
                               boxName))
  processedPath =  file.path(mainPath, '01input','01catAtr','luc')
  

  # crop luc to study box
  croppedluc = mask(rawluc, mask = studyBox, na.rm = T)
  croppedluc = crop(croppedluc,y = studyBox, na.rm = T)  
  
  #plot(croppedDEM)
  #cropped
  # convert DEM coordination from WGS 84 to UTM 48N
  # EPSG:4326 - WGS 84
  # EPSG: 32448 - UTM 48N 
  # ref: https://spatialreference.org/ref/epsg/?search=utm+48&srtext=Search
  croppedluc_UTM48 = projectRaster(croppedluc, res = 500, crs = "+init=epsg:32448",
                                   method="ngb")
  
  # Plotting two raster files
  par(mfrow = c(1, 2))
  plot(croppedluc,axes = TRUE, main = "Lat-Long Coordinates", cex.axis = 0.95)
  plot(croppedluc_UTM48, axes = TRUE, main = "UTM Coordinates",  cex.axis = 0.95)
  opFile = paste(processedPath, '/',catname,'luc_u48n.tif', sep = '')
  raster::writeRaster(croppedluc_UTM48,
                      opFile,
                      format = "GTiff", overwrite = T )
  lucID = unique(croppedluc)
  locID = which(lumetaData$Reclass %in% lucID)
  
  # export metadata
  dat = data.frame(LANDUSE_ID = lumetaData$Reclass[locID],
                   SWAT_CODE = lumetaData$SWATSymbol[locID])
  
  excelopFile = paste(mainPath, '/','01input','/',catname,'_landuses.xlsx',sep = '')
  csvopFile = paste(mainPath, '/','01input','/',catname,'_landuses.csv',sep = '')
  #write.xlsx(dat, excelopFile, sheetName = paste(catname,'_landuses',sep = ''), 
  #           col.names = TRUE, row.names = FALSE, append = FALSE)
  write.csv(dat, csvopFile, row.names = F)
}

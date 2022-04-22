####################################################################################
# Manh-Hung Le - 2021 Aug 21
# objectives:
# - define a study box
####################################################################################

library(rgdal)
library(raster)
library(tidyverse)
library(sp)
library(readxl)
# path setup
maindir = 'D:/multiSwat_inputPre'
# basin name and river system (pair one to one)
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')

metaData = read.csv(file.path(maindir,'0_inputPreparation','metaData_daProject.csv'))
# reference boundaries
refPath = file.path(maindir, '0_inputPreparation/refcatchments')
refBoundaries = c('SK_GiaVong','SK_Anhoa', 'MK_Banyen', 'SK_Songluy', 'HT_Chu','MK_GiangSon','CA_nkhanh','Ma_Xala')

# total basins
n = length(basinNames)
for(ii in 1:n){

  aoiPath = paste(refPath,'/',refBoundaries[ii],'.shp', sep = '')
  aoi = readOGR(aoiPath)
  
  extVal =  0.5 # roughly 50 km
  x1 = extent(aoi)@xmin - extVal
  x2 = extent(aoi)@xmax + extVal
  y1 = extent(aoi)@ymin - extVal
  y2 = extent(aoi)@ymax + extVal
  # create a study box
  # x1, y1
  # x1, y2
  # x2, y2
  # x2, y1
  # x1, y1
  studyBox = matrix(c(x1,y1,
                      x1,y2,
                      x2,y2,
                      x2,y1,
                      x1,y1),
                    ncol = 2, byrow= TRUE)
  studyBoxPol = Polygon(studyBox)
  studyBoxPol = SpatialPolygons(list(Polygons(list(studyBoxPol), ID = "Box")), 
                                proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
  
  plot(studyBoxPol,  border = 'blue', main = metaData$name[ii])
  plot(aoi,add = T)
  # add outlet
  points(metaData$lon[ii], metaData$lat[ii],
         cex = 1.6, pch  = 16)
  
  folderName = paste('swat','_',riverSystems[ii],'_',
                     basinNames[ii], sep = '')
  opFile = paste(basinNames[ii],'_studyBox.shp', sep = '')
  
  # save your study box as a shapfile
  shapefile(studyBoxPol, 
            filename = file.path(maindir,folderName,'00dataPreparation','studyBox',opFile), overwrite = T)
  
}

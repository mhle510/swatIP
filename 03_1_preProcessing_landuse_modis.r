####################################################################################
# Manh-Hung Le - 2021  Aug 22
# objectives:
# - analyze land use 
# - reclassify and create look at table
####################################################################################
library(raster)
library(readxl)
library(tidyverse)
library(sp)
library(sf)
library(ggplot2)
# setup path
maindir = 'D:/multiSwat_inputPre'
rawlu = raster(file.path(maindir, '0_inputPreparation/rawlu/lu2016.tif'))
metaData = readxl::read_xlsx(file.path(maindir, '0_inputPreparation/rawlu/modis_landuse_metaData.xlsx'),sheet = 'IGBP_classification')
newmetaData = readxl::read_xlsx(file.path(maindir, '0_inputPreparation/rawlu/modis_landuse_metaData.xlsx'),sheet = 'IGBP_SWAT_classification')

# create new folder to store results after processing
dir.create(file.path(maindir, '0_inputPreparation','processedlu'), showWarnings = F)
processedPath = file.path(maindir, '0_inputPreparation','processedlu')

# own-built function
source(file.path(maindir,'rCode','rasterdf.r'))

rawludf = rasterdf(rawlu)
table(rawludf$value)

# land use attributes
lcNames = metaData$ClassName
lcColors = metaData$ColorCode
names(lcColors) = as.character(metaData$Class)

# replot - problem with color order for legend
ggplot(data = rawludf) +
  geom_raster(aes(x = x, y = y, fill = as.character(value))) + 
  scale_fill_manual(name = "Land cover",
                    values = lcColors,
                    labels = lcNames,
                    na.translate = FALSE) +
  coord_sf(expand = F) +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.background = element_rect(fill = "white", color = "black"))


# reclassify raster data
oldclas = unique(rawlu)
oldclas
newclas = metaData$Reclass

lookup = data.frame(oldclas, newclas)
reclu = subs(rawlu, lookup)

newnames = newmetaData$ClassName
newcols = newmetaData$ColorCode
names(newcols) = as.character(seq(1,10,1))
newcols

# plot reclassify raster
recludf = rasterdf(reclu)
ggplot(data = recludf) +
  geom_raster(aes(x = x, y = y, fill = as.character(value))) + 
  scale_fill_manual(name = "Land cover",
                    values = newcols,
                    labels = newnames,
                    na.translate = FALSE) +
  coord_sf(expand = F) 



# convert coordination from WGS 84 to UTM 48N
# EPSG:4326 - WGS 84
# EPSG: 32448 - UTM 48N 
# ref: https://spatialreference.org/ref/epsg/?search=utm+48&srtext=Search
reclu_utm48 = projectRaster(reclu, res = 500, crs = "+init=epsg:32448",
                             method="ngb")

reclu_utm48df = rasterdf(reclu_utm48)
ggplot(data = reclu_utm48df) +
  geom_raster(aes(x = x, y = y, fill = as.character(value))) + 
  scale_fill_manual(name = "Land cover",
                    values = newcols,
                    labels = newnames,
                    na.translate = FALSE) +
  coord_sf(expand = F) 


raster::writeRaster(reclu_utm48,
                    file.path(processedPath, 'reclu2016_u48n.tif'),
                    format = "GTiff", overwrite = T )

raster::writeRaster(reclu,
                    file.path(processedPath, 'reclu2016_wgs.tif'),
                    format = "GTiff", overwrite = T )






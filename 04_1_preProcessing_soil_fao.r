####################################################################################
# Manh-Hung Le - 2021  Aug 22
# objectives:
# - analyze fao soil 
# - reclassify from soil mapping unit (SMU) to new code with name following 
# symbol 74 and symbol 90
####################################################################################
library(raster)
library(readxl)
library(tidyverse)
library(sp)
library(ggplot2)
library(colorRamps)

maindir = 'XXX/multiSwat_inputPre'
rawsoil = raster(file.path(maindir, '0_inputPreparation/rawsoil/hwsd_crop/hdr.adf'))

dir.create(file.path(maindir,'0_inputPreparation','processedsoil'), showWarnings = F)
processedPath = file.path(maindir,'0_inputPreparation','processedsoil')

# import soil database
soildbPath = file.path(maindir,'0_inputPreparation/rawsoil/soil_hwsd_database')
hwsdDat = readxl::read_xlsx(file.path(soildbPath, 'HWSD_DATA.xlsx'))
sym74 = readxl::read_xlsx(file.path(soildbPath, 'D_SYMBOL74.xlsx'))
sym85 = readxl::read_xlsx(file.path(soildbPath, 'D_SYMBOL85.xlsx'))
sym90 = readxl::read_xlsx(file.path(soildbPath, 'D_SYMBOL90.xlsx'))
symCombined = readxl::read_xlsx(file.path(soildbPath, 'D_SYMBOL74_85_90.xlsx'))
textUSDA = readxl::read_xlsx(file.path(soildbPath, 'D_USDA_TEX_CLASS.xlsx'))

# own-built function
source(file.path(maindir,'rCode','soil_hwsd_extraction_combined.r'))
source(file.path(maindir,'rCode','rasterdf.r'))


# plot soil data
plot(rawsoil)

unique(rawsoil)
summary(unique(rawsoil))

# assign NA 
rawsoil[rawsoil == 0] = NA
rawsoil[rawsoil == 11932] = NA # nodata
plot(rawsoil)
summary(rawsoil)

# obtain soil code
soilCode = unique(rawsoil)
usersoilDfAdj = soil_hwsd_extracttion_combined(soilCode, hwsdDat, sym74, sym90, textUSDA)


# remove class with zero soil layers
locZerolayer = which(usersoilDfAdj$NLAYES == 0)
usersoilDfAdj$SNAME_FULL[locZerolayer]
usersoilDfAdj$SMU[locZerolayer]

# mannual write down!!!
smuZerolayer = c(11926,3963,11928,11927,6997,11930,6998,11925,11929)
# remove water bodies
for(izero in 1:length(smuZerolayer)){
  rawsoil[rawsoil == smuZerolayer[izero]] = NA
}

length(unique(rawsoil))

usersoilDfAdjFinal = usersoilDfAdj[-locZerolayer,]
usersoilDfAdjFinal = data.frame(newCode = seq(1,nrow(usersoilDfAdjFinal),1),
                            usersoilDfAdjFinal)
write.csv(usersoilDfAdjFinal, file.path(processedPath,'soilreclassification.csv'), row.names = F)

# create look at table between old class and new class

nNew = nrow(usersoilDfAdjFinal)

lookup = NULL
ii = 1
while(ii <= nNew){
  strSmu = usersoilDfAdjFinal$SMU[ii]
  hypLoc = unlist(gregexpr('_', strSmu))
  nSmu = length(hypLoc)
  
  if (nSmu == 1){
    subLookup = data.frame(old_class = substr(strSmu, 1, hypLoc - 1),
                           new_class = ii)
    lookup  = rbind.data.frame(lookup , subLookup)
  } else {
    startid = c(1, hypLoc[1:(nSmu-1)]+1)
    endid = c(hypLoc[1:nSmu]-1)
    for(is in 1: length(startid)){
      subLookup = data.frame(old_class = substr(strSmu, startid[is], endid[is]),
                             new_class = ii)
      lookup  = rbind.data.frame(lookup , subLookup)
    }
  }
  ii = ii + 1
}

#length(unique(rawsoil))


rcsoil = subs(rawsoil, lookup)

newcols = matlab.like(nNew)
names(newcols) = seq(1,nNew,1)
newcols
newnames = usersoilDfAdjFinal$SNAME


# plot reclassify raster
rcsoildf = rasterdf(rcsoil)
# convert coordination from WGS 84 to UTM 48N
# EPSG:4326 - WGS 84
# EPSG: 32448 - UTM 48N 
# ref: https://spatialreference.org/ref/epsg/?search=utm+48&srtext=Search
rcsoil_utm48n = projectRaster(rcsoil, res = 1000, crs = "+init=epsg:32448",
                              method="ngb")

rcsoil_utm48ndf = rasterdf(rcsoil_utm48n)

raster::writeRaster(rcsoil,
                    file.path(processedPath, 'recsoilfao_wgs.tif'),
                    format = "GTiff", overwrite = T )

raster::writeRaster(rcsoil_utm48n,
                    file.path(processedPath, 'recsoilfao_u48n.tif'),
                    format = "GTiff", overwrite = T )






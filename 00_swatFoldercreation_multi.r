####################################################################################
# SWAT Input Preparation
# Manh-Hung Le - 2021 Aug 20
# objectives:
# - create folder for SWAT
####################################################################################

library(rgdal)
library(readxl)
# short basin name - full basin name
# gvo - Gia Vong
# aho - An Hoa
# bye - Ban Yen
# slu - Song Luy
# chu - Chu
# gso - Giang Son
# nkh - Nghia khanh
# xla - Xa La

# path setup
maindir = 'XXX/multiSwat_inputPre'
basinNames = c('gvo','aho','bye','slu', 'chu','gso','nkh','xla')
riverSystems = c('sk', 'sk','mk','sk','ht','mk','ca','ma')

# length of 
nb = length(basinNames)


for(ib in 1: nb){
 folderName = paste('swat','_',riverSystems[ib],'_',
                    basinNames[ib], sep = '')
 
 dir.create(file.path(maindir,folderName), showWarnings = F)
 dir.create(file.path(maindir,folderName, '00dataPreparation'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '00dataPreparation','studyBox'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '00dataPreparation','rCode'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '01input'), showWarnings = F)

 dir.create(file.path(maindir,folderName, '01input','01catAtr'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '01input','02cliDat'), showWarnings = F)
 
 dir.create(file.path(maindir,folderName, '01input','01catAtr','dem'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '01input','01catAtr','soil'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '01input','01catAtr','luc'), showWarnings = F)
 
 dir.create(file.path(maindir,folderName, '01input','02cliDat','precip'), showWarnings = F)
 dir.create(file.path(maindir,folderName, '01input','02cliDat','airtem'), showWarnings = F)
}


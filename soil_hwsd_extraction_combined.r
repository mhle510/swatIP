soil_hwsd_extracttion_combined = function(soilCode, hwsdDat, sym74,  sym90, textUSDA ){
  ###################################################################################
  # Soil Database for SWAT
  # Manh-Hung Le - 2021 Feb 27
  # objectives:
  ####################################################################################

  ns = length(soilCode)
  usersoilDf = data.frame(SMU = soilCode,
                          SNAME = character(ns),
                          SNAME_FULL = character(ns),
                          NLAYES = numeric(ns),
                          HYDGRP = character(ns),
                          Z1 =  numeric(ns),
                          OC1 =  numeric(ns),
                          Clay1 =  numeric(ns),
                          Silt1 =  numeric(ns),
                          Sand1 =  numeric(ns),
                          Rock1 =  numeric(ns),
                          Z2 =  numeric(ns),
                          OC2 =  numeric(ns),
                          Clay2 =  numeric(ns),
                          Silt2 =  numeric(ns),
                          Sand2 =  numeric(ns),
                          Rock2 =  numeric(ns)
  )
  
  for(ii in 1:ns){
    smu = usersoilDf$SMU[ii]
    locSmu = which(smu == hwsdDat$MU_GLOBAL)
    # get share among soil
    shareInfo = hwsdDat$SHARE[locSmu]
    # select the largest soil 
    locSmuAdj = locSmu[which(shareInfo == max(shareInfo))][1]
    # link with name
    if (smu < 7000 ){
      # link with SYM74 name
      usersoilDf$SNAME[ii] = hwsdDat$SU_SYM74[locSmuAdj] 
      usersoilDf$SNAME_FULL[ii] = sym74$VALUE[which(sym74$SYMBOL == usersoilDf$SNAME[ii])]
    } else {
      # link with SYM90 name
      usersoilDf$SNAME[ii] = hwsdDat$SU_SYM90[locSmuAdj] 
      usersoilDf$SNAME_FULL[ii] = sym90$VALUE[which(sym90$SYMBOL == usersoilDf$SNAME[ii])]
    }
    
    
    # two layers soil information
    usersoilDf$Z1[ii] = 300
    usersoilDf$OC1[ii] = as.numeric(hwsdDat$T_OC[locSmuAdj])
    usersoilDf$Clay1[ii] = as.numeric(hwsdDat$T_CLAY[locSmuAdj])
    usersoilDf$Silt1[ii] = as.numeric(hwsdDat$T_SILT[locSmuAdj])
    usersoilDf$Sand1[ii] = as.numeric(hwsdDat$T_SAND[locSmuAdj])
    usersoilDf$Rock1[ii] = 0
    
    usersoilDf$Z2[ii] = 1000
    usersoilDf$OC2[ii] = as.numeric(hwsdDat$S_OC[locSmuAdj])
    usersoilDf$Clay2[ii] = as.numeric(hwsdDat$S_CLAY[locSmuAdj])
    usersoilDf$Silt2[ii] = as.numeric(hwsdDat$S_SILT[locSmuAdj])
    usersoilDf$Sand2[ii] = as.numeric(hwsdDat$S_SAND[locSmuAdj])
    usersoilDf$Rock2[ii] = 0
    
    # determine soil layer
    if(is.na(usersoilDf$Clay1[ii]) & is.na(usersoilDf$Silt1[ii]) & is.na(usersoilDf$Sand1[ii])){
      if(is.na(usersoilDf$Clay2[ii]) & is.na(usersoilDf$Silt2[ii]) & is.na(usersoilDf$Sand2[ii])){
        usersoilDf$NLAYES[ii] = 0
        usersoilDf$HYDGRP[ii] = NA
      } else {
        usersoilDf$NLAYES[ii] = 1  
        # hydraulic conductivity
        texture = as.numeric(hwsdDat$T_USDA_TEX_CLASS[locSmuAdj])
        usersoilDf$HYDGRP[ii] = textUSDA$HYDGRP[which(texture == textUSDA$CODE)]
      }  
    } else {
      if(is.na(usersoilDf$Clay2[ii]) & is.na(usersoilDf$Silt2[ii]) & is.na(usersoilDf$Sand2[ii])){
        usersoilDf$NLAYES[ii] = 1
        texture = as.numeric(hwsdDat$T_USDA_TEX_CLASS[locSmuAdj])
        usersoilDf$HYDGRP[ii] = textUSDA$HYDGRP[which(texture == textUSDA$CODE)]
      } else {
        usersoilDf$NLAYES[ii] = 2  
        # hydraulic conductivity
        texture = as.numeric(hwsdDat$T_USDA_TEX_CLASS[locSmuAdj])
        usersoilDf$HYDGRP[ii] = textUSDA$HYDGRP[which(texture == textUSDA$CODE)]
      }  
    }
  }
  
  # indentify sname without duplicate
  snam = usersoilDf$SNAME[!duplicated(usersoilDf$SNAME)]
  ns2 = length(snam)
  
  usersoilDfAdj = data.frame(SMU = character(ns2),
                             SNAME = snam,
                             SNAME_FULL = character(ns2),
                             NLAYES = numeric(ns2),
                             HYDGRP = character(ns2),
                             Z1 =  numeric(ns2),
                             OC1 =  numeric(ns2),
                             Clay1 =  numeric(ns2),
                             Silt1 =  numeric(ns2),
                             Sand1 =  numeric(ns2),
                             Rock1 =  numeric(ns2),
                             Z2 =  numeric(ns2),
                             OC2 =  numeric(ns2),
                             Clay2 =  numeric(ns2),
                             Silt2 =  numeric(ns2),
                             Sand2 =  numeric(ns2),
                             Rock2 =  numeric(ns2)
  )
  
  for(ii in 1:ns2){
    loc = which(usersoilDf$SNAME == usersoilDfAdj$SNAME[ii])
    tmp = usersoilDf[loc,]
    
    usersoilDfAdj$SNAME_FULL[ii] = usersoilDf$SNAME_FULL[loc[1]]
    
    # identify similar SMU 
    setSMU = c(tmp$SMU)
    n = length(setSMU)
    
    id = 1
    strSMU = ""
    while(id <= n){
      strSMU = paste(setSMU[id],'_',strSMU, sep = "")  
      id = id +1
    }
    
    usersoilDfAdj$SMU[ii] = strSMU
    
    # average values for two layer soils
    usersoilDfAdj$Z1[ii] = 300
    usersoilDfAdj$OC1[ii] = round(mean(tmp$OC1,na.rm  = T),2)
    usersoilDfAdj$Clay1[ii] = round(mean(tmp$Clay1,na.rm  = T),0)
    usersoilDfAdj$Silt1[ii] = round(mean(tmp$Silt1,na.rm  = T), 0)
    usersoilDfAdj$Sand1[ii] = round(mean(tmp$Sand1,na.rm  = T),0)
    usersoilDfAdj$Rock1[ii] = 0
    
    usersoilDfAdj$Z2[ii] = 1000
    usersoilDfAdj$OC2[ii] = round(mean(tmp$OC2,na.rm  = T),2)
    usersoilDfAdj$Clay2[ii] = round(mean(tmp$Clay2,na.rm  = T),0)
    usersoilDfAdj$Silt2[ii] = round(mean(tmp$Silt2,na.rm  = T),0)
    usersoilDfAdj$Sand2[ii] = round(mean(tmp$Sand2,na.rm  = T),0)
    usersoilDfAdj$Rock2[ii] = 0
    
    # select nlayer
    atrLayer = data.frame(table(tmp$NLAYES))
    domVal = which(atrLayer[,2]==max(atrLayer[,2]))[1]
    usersoilDfAdj$NLAYES[ii] = as.numeric(as.character(atrLayer[1,domVal]))
    
    # select Hydraulic group
    atrHydraulic = data.frame(table(tmp$HYDGRP))
    if(dim(atrHydraulic)[1] == 0){
      usersoilDfAdj$HYDGRP[ii] = NA
    } else {
      domVal = which(atrHydraulic[,2] == max(atrHydraulic[,2]))[1]
      usersoilDfAdj$HYDGRP[ii] = as.character(atrHydraulic[domVal,1])
    }
    
  }
  
  # remove d
  return(usersoilDfAdj)
}


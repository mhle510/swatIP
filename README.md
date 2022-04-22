# swat-ip
swat-ip (swat input preparation)

This code introduces how to prepare forcing inputs data to create a SWAT project(s) step by step. This code is suitable for a large-sample SWAT modelling project purpose.

## Motivation
The hydrological SWAT model, like other semi-distributed hydrological models, requires a large amount of input datasets with restricted format. If we consider a completed SWAT project includes input preparation (step 1), model setup (step 2), and model calibration (step 3), the input preparation, interestingly, accounts for 60-70% of total time ( based on my experience). This is a considerable workload if you want to run SWAT in multiple seperately catchments. However, most of publicaly available codes I found is to focus on how to run and calibrate SWAT model (step 2 and 3 mentioned above) but not a single document working on input preparation. Therfore, this code aims to fill in this gap. I provide ceartain datasets in Central and South East Asia region (8.5N-34N, 93.5E-109.6E) but you can apply this code framework for your own interested regions if you use the same datasets as I used (see Datasets and SWAT version section). In the end, you may see this code being useful as you can prepare inputs for multiple SWAT projects faster, so that you will have more time spending on more fun parts (run and calibrate SWAT).

## Datasets and SWAT version
Forcing inputs include:
1. Catchment Attributes
  * Digital elevation model (hydroshed dem)
  * Land use (modis land use) 
  * Soil (FAO) 
They are used to
 * delinate watershed (dem) 
 * create hydrologic response unit (hru) (dem, land use, soil) 
2. Climatic Datasets
  * Daily precipitation (GPM IMERG Final run)
  * Daily air maximum and minimum tempeature (CFSV2)
They are used as
 * forcing input in SWAT Editor 
These forcing inputs have been tested successfully with 
 * QGIS 2.61 and QSWAT v1.7, and SWAT Editor 2012.10_5.21 
 
Demo data in this code is from Le et al. 2022 (see Citations section)

## Citations
If you find my codes useful, please cite the following papers:

Le, M. H., Lakshmi, V., Bolten, J., & Bui, D. D. (2020). Adequacy of Satellite-derived Precipitation Estimate for Hydrological modeling in Vietnam Basins. Journal of Hydrology, 124820

Le, M.H., Nguyen Q.B., Pham, H.T., Patil, A.A., Do H.X., Ramsankaran R., Bolten, J.& Lakshmi, V (2022). Assimilation of SMAP products in streamflow simulations – Is spatial information more important than temporal information. Remote Sensing, 14(7), 1607

## Software requirements
 * Shapefile of your study area (optional) or general coordinations of your study area (in latitude, longitude)
 * R software 

## Datasets
Data needed for this code is available at https://drive.google.com/drive/u/1/folders/1nIzLyRCBKgl3f2tGvXgSKBOGqTj7qs3X
You can download these datasets and change path folder in the code accordingly.
 0_inputPreparation: folder contains datasets for step 0, step 1, step 2, step 3, and step 4
 rasters_precip: folder contains daily precipitation from GPM IMERG Final run (in .tif format), which requires for step 5
 rasters_airtemp: folder contains daily maximum and minimum air temperature from CFSV2 (in .tif format), which requires for step 6
 demo_results: completely input files after running this code (for reference).
 
## Step by steps

0. Folder creation
<run 00_swatFoldercreation_multi.r>: automatically create folders for different SWAT projects
1. Get to know your study
* <01_getKnowyourStudy_multi.r>: create a "study box" for different SWAT projects. All catchment attributes (DEM, land cover, soil) will be extracted for that "study box".
2. DEM preparation
* <02_swatInput_catchatr_dem_multi.r>: create DEM input datasets for mutiple SWAT projects from a DEM source (geographical coordinates, WGS 84).
3. Land cover preparation
* <03_1_preProcessing_landuse_modis.r>: from a source of Land cover (geographical coordinates, WGS 84), preparing a land use meta data with SWAT format
* <03_2_swatInput_catchatr_lu_multi.r>: create land cover input datasets for mutiple SWAT projects from a land use data in step 03_1
4. Soil preparation
* <04_1_preProcessing_soil_fao.r> from a source of soil data (geographical coordinates, WGS 84), preparing  soil meta data with SWAT formart
* <04_2_swatInput_catchatr_soil_multi.r> create soil input datasets for mutiple SWAT projects from the soil data in step 04_1
5. Precipitation
* <05_1_dataPreprocessing_precipExtraction_imerg_knownShp_multi.r> this step is option, it can only work if you delinate watersheds and have subbasins for your catchments. It can help you to estimate rainfall timeseries for each subbasin (at subbasin's centroid).
* <05_2_swatInput_climaticdat_rainformat_imerg_multi.r> this step create rainfall timeseries with SWAT format. 
6. Air temperature
* <06_1_dataPreprocessing_airtempExtraction_ncep_knownShp_multi.r> this step is option, it can only work if you delinate watersheds and have subbasins for your catchments. It can help you to estimate air temperature (maximum and minimum) timeseries for each subbasin (at subbasin's centroid).
* <06_2_swatInput_climaticdat_airtemp_ncep_multi.r> this step create air temperature timeseries with SWAT format. 

rasterdf = function (x, aggregate = 1)
{
    resampleFactor <- aggregate
    inputRaster <- x
    inCols <- ncol(inputRaster)
    inRows <- nrow(inputRaster)
    resampledRaster <- raster(ncol = (inCols/resampleFactor),
        nrow = (inRows/resampleFactor))
    extent(resampledRaster) <- extent(inputRaster)
    y <- resample(inputRaster, resampledRaster, method = "ngb")
    coords <- xyFromCell(y, seq_len(ncell(y)))
    dat <- stack(as.data.frame(getValues(y)))
    names(dat) <- c("value", "variable")
    dat <- cbind(coords, dat)
    dat
}
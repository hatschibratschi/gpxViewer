# libs --------------------------------------------------------------------
library(shiny)
library(DT)
library(sf)
library(leaflet)
library(sfarrow)
library(dplyr)
library(utils)
library(digest)
library(tools)

# options -----------------------------------------------------------------
options(shiny.host = "0.0.0.0")
options(shiny.port = 3838)

# functions ---------------------------------------------------------------
generate_wkt_hash = function(geometry) {
  wkt = sf::st_as_text(geometry)
  hash = digest::digest(wkt, algo = "md5")
  return(hash)
}

loadGeom = function(inputFile){
  # upload only one parquet or multiple gpx-files
  ext = tools::file_ext(inputFile$name)
  df = NULL
  if (length(ext) == 1 && tolower(ext) == 'parquet') {
    df = sfarrow::st_read_parquet(dsn = inputFile$datapath)
  } else if (length(ext) > 0 & all(tolower(ext) == 'gpx')){
    sfData = lapply(1:length(inputFile$name), function(i) {
      print(paste0('load ', inputFile$name[i]))
      d = sf::st_read(dsn = inputFile$datapath[i], layer = "tracks", quiet = TRUE) 
      d = d[!st_is_empty(d), c('geometry')]
      d$name = tools::file_path_sans_ext(inputFile$name[i])
      d$km = round(as.numeric(st_length(d$geometry) / 1000), 2)
      d
    })
    # list of sf-data.frames to one data.frame
    sfData = do.call(rbind, sfData)
    sfData$geom_hash = sapply(sfData$geometry, generate_wkt_hash)
    sfData$id = 1:nrow(sfData)
    df = sfData
  } else {
    print('upload one parquet or multiple gpx files')
  }
  df
}

removeDuplicatedByHash = function(x, by){
  x$id = 1:nrow(x)
  by2 = c('id', by)
  uniqueIds = x[, by2] |> 
    as.data.frame() |> 
    group_by_at(by) |> 
    summarise(id = min(id))
  x[x$id %in% uniqueIds$id,]
}

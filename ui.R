ui = fluidPage(
  
  titlePanel("gpx Viewer", windowTitle = "gpx Viewer"),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Files"
               , icon = icon("file")
               , fileInput("upload", "Upload a GPX or PARQUET file(s)"
                           , multiple = TRUE
                           , accept = c(".gpx", ".parquet"))
               , dataTableOutput("fileList")
               , checkboxInput("dt_sel", "select all", value = FALSE)
               , actionButton('clearData', 'Clear data')
               , downloadButton("download", "Download .parquet")
      )
      , tabPanel("Map"
                 , icon = icon("map")
                 , tags$style(type = "text/css", "#map {height: calc(100vh - 130px) !important;}")
                 , leafletOutput("map")
      )
    )
    , width = 12
  )
)

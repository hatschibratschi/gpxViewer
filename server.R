server = function(input, output, session) {

# data --------------------------------------------------------------------
  # Reactive value to store and update the combined data
  combinedData = reactiveValues(df = data.frame())
  
  observeEvent(input$upload, {
    req(input$upload)
    df = loadGeom(input$upload)
    
    # Check if the combined data frame is empty
    if (is.null(combinedData$df) || length(combinedData$df) == 0) {
      combinedData$df = df
    } else {
      df = rbind(combinedData$df, df)
      print(paste0('number of rows ', nrow(df)))
      df = removeDuplicatedByHash(x = df, by = 'geom_hash')
      print(paste0('number of rows ', nrow(df)))
      combinedData$df = df
      print('new combinedData')
      #print(combinedData$df)
    }
    df = combinedData$df
    selectRows(dt_proxy, 1:nrow(df))
  })
  
# DT ----------------------------------------------------------------------
  output$fileList = renderDataTable(
    {
      df = combinedData$df
      if (!is.null(df) & length(df) > 0) {
        df = as.data.frame(df)
        df = df[, c('name', 'km')]
      } else {
        df = data.frame(name = '', km = '', geom_hash = '')
      }
      # print('data for DT')
      # print(df)
      df
    }
    , rownames= FALSE
  )
  
  # Create a proxy for the DataTable after it's rendered
  dt_proxy <- DT::dataTableProxy("fileList")

  observeEvent(input$dt_sel, {
    print('select all pressed')
    df = combinedData$df

    if (isTRUE(input$dt_sel) & !is.null(combinedData$df) & length(combinedData$df) > 0) {
      selectRows(dt_proxy, 1:nrow(df))
    } else {
      selectRows(dt_proxy, NULL)
    }
  })

  observe({
    # Access selected rows using the known ID
    selected_rows <- input$fileList_rows_selected
    # print(selected_rows)
  })  
  
# map ---------------------------------------------------------------------
  output$map = renderLeaflet({
    
    data = combinedData$df[input$fileList_rows_selected,] # show only DT-selected rows

    leaflet::leaflet() %>%
      leaflet::addTiles(group = "OSM (default)") %>%
      leaflet::addProviderTiles(providers$CyclOSM, group = "CyclOSM") %>%
      leaflet::addProviderTiles(providers$BasemapAT.grau, group = "AT.grau") %>%
      leaflet::addPolylines(data = data
                   , label = paste(data$name, data$km, 'km')
                   , labelOptions = labelOptions(textsize = "14px")
                   , highlightOptions = highlightOptions(color = "orange", weight = 7, opacity = 1, bringToFront = TRUE)
      ) %>%
      leaflet::addLayersControl(
        baseGroups = c("OSM (default)", "CyclOSM", "AT.grau")
      )
  })

# download ----------------------------------------------------------------
  output$download <- downloadHandler(
    filename = 'gpxViewer.parquet',
    content = function(file) {
      sfarrow::st_write_parquet(obj = combinedData$df, dsn = file)
    }
  )
}

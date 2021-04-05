server <- function(input, output, session) {
  
  
  observeEvent(input$synth_btn, {
    # Read Audio File
    inpt_audio <<- readWave(paste0(AUDIO_PATH, tolower(input$sound_slct), ".wav"))

    # Scale Audio Input
    x <<- t(inpt_audio@left / 2^(inpt_audio@bit - 1))

    # Synthasize Frequency Shifted Audio
    y <<- audioPitchShift(x, 1024, input$freq_shift_inpt)
    # convert Synthasized Audio to wav
    synth_wave <- Wave(left = y, samp.rate = inpt_audio@samp.rate, bit = inpt_audio@bit)
    #save wav file
    savewav(synth_wave, filename = SYNTH_AUDIO_PATH)
    #hacky play audio
    insertUI(selector = "#synth_btn",
             where = "beforeBegin",
             ui = tags$audio(src = "synthSoundWave.wav", type = "audio/wav", autoplay = TRUE, controls = NA, style="display:none;")
    )
  })
  
  
  # Produce plot of audio sample before and after being synthesized
  observeEvent(input$synth_btn, {

    # Raw Audio Input Plot
    data_x <- data_frame(val = c(x))
    output$rawAudioPlot <- renderPlotly({
      P <- ggplot(data = data_x, aes(x = as.numeric(row.names(data_x)), y = val)) +
        geom_line(stat = "identity", color = "darkblue") +
        xlab("Sample Index") +
        ylab("Normalized Amplitude") +
        ylim(-1, 1) +
        ggtitle("Raw Audio Input")
      plotly::ggplotly(P, height = 400, tooltip = c("x", "y")) %>% layout(dragmode = "select", paper_bgcolor = "transparent")
    })
    
    # Synthesized Audio Input Plot
    if (input$freq_shift_inpt == 0) {
      output$synthAudioPlot <- renderPlotly({
        P <- ggplot(data = data_x, aes(x = as.numeric(row.names(data_x)), y = val)) +
          geom_line(stat = "identity", color = "darkred") +
          xlab("Sample Index") +
          ylab("Normalized Amplitude") +
          ylim(-1, 1) +
          ggtitle("Raw Audio Input")
        plotly::ggplotly(P, height = 400, tooltip = c("x", "y")) %>% layout(dragmode = "select", paper_bgcolor = "transparent")
      })
    } else {
      data_y <- data_frame(val = y)
      output$synthAudioPlot <- renderPlotly({
        P <- ggplot(data = data_y, aes(x = as.numeric(row.names(data_y)), y = val)) +
          geom_line(stat = "identity", color = "darkred") +
          xlab("Sample Index") +
          ylab("Normalized Frequency") +
          ylim(-1, 1) +
          ggtitle("Synthesized Audio Output")
        plotly::ggplotly(P, height = 400, tooltip = c("x", "y")) %>% layout(dragmode = "select", paper_bgcolor = "transparent")
      })
    }
  })
}

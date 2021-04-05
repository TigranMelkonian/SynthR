library(httr)
library(shiny)
library(plotly)
source("utils.R")
library(lubridate)
library(shinythemes)
library(rsconnect)


ui <- navbarPage(

  #################################################################################################
  #                                       Main Navpage Body                                      #
  ###############################################################################################
  theme = shinytheme("lumen"),
  inverse = F,
  title = tags$header("SYNTHR", tags$style("margin-right: 150px;")),
  windowTitle = "SYNTHR",
  collapsible = T,
  position = "static-top",
  
  ##########################################
  # Home - Tool info Text  & User Briefing#
  ########################################

  tabPanel(
    title = "Home",
    icon = icon("home", lib = "font-awesome", "fa-1x"),
    withTags({
      div(
        class = "header", checked = NA, style = "text-align:center;",
        h1(img(src = "analyze_sound_wave.png", alt = "User Avatar", width = "100", height = "100"), " WELCOM TO SYNTHR ", img(src = "analyze_sound_wave.png", alt = "User Avatar", width = "100", height = "100", style = "transform: rotate(180deg);"))
      )
    }),
    style = "min-height: 100vh;",
    fluidRow(
      column(
        width = 12, align = "center",
        withTags({
          div(
            class = "body",
            h4("With this tool you can vary the pitch of preloaded audio samples"),
            hr()
          )
        })
      )
    ), 
    fluidRow(
      style = "margin-left: 15px;margin-right: 15px; margin-bottom: 50px;",
      column(
        10,
        h2(strong("FREQUENCY SHIFTING")),
        br(),
        p(strong("This tool allows you to change pitch of a preloaded audio file while maintaining its tempo. The pitch can be changed to positive or negative 15 semitones which correspond to an octave up or down.")),
        tags$ul(
          tags$li("The pitch of a sound corresponds to the set of frequencies the sound is made of. What pitch shifting does is it takes the original sound produced at a given pitch and changes its frequencies. For instance, by shifting up the pitch of a man who is speaking, we could end up with a sound where it sounds like a mouse is speaking instead."),
          tags$li("One notable early practitioner of pitch shifting in music is Chuck Berry, who used the technique to make his voice sound younger. Many of the Beatles' records from 1966 and 1967 were made by recording instrumental tracks a half-step higher and the vocals correspondingly low. Examples include 'Rain', 'I'm Only Sleeping', and 'When I'm Sixty-Four'."),
          tags$li("Wikipedia: The simplest way to change the duration or pitch of a digital audio clip is through sample rate conversion. This is a mathematical operation that effectively rebuilds a continuous waveform from its discrete samples and then re-samples that waveform again at a different rate. When the new samples are played at the original sampling frequency, the audio clip sounds faster or slower. Unfortunately, the frequencies in the sample are always scaled at the same ratio as the speed, transposing its perceived pitch up or down in the process. In other words, slowing down the recording lowers the pitch, speeding it up raises the pitch."),
          strong(p("Basic steps (Wikipedia):")),
          tags$ol(
            tags$li("Compute the instantaneous frequency/amplitude relationship of the signal using the STFT, which is the discrete Fourier transform of a short, overlapping and smoothly windowed block of samples"),
            tags$li("Apply some processing to the Fourier transform magnitudes and phases (like resampling the FFT blocks)"),
            tags$li("Perform an inverse STFT by taking the inverse Fourier transform on each chunk and adding the resulting waveform chunks, also called overlap and add (OLA)")
          )
        ),
        br(),
        h2(strong("ALGORITHM")),
        br(),
        p(strong("Step-by-step methodology of how SYNTHR alters the pitch of audio input.")),
        tags$ol(
          tags$li("Determine the scaling factor (semitone shift) that will be used to stretch or compress the original audio spectrum inorder to alter pitch. Negative compresses, positive stretches the original audio signal."),
          tags$li("Split original, continuous audio signal into multiple frame sections. These audio frame sections, from the original audio sample, overlap eachother by 75%. These frames are used to stretch or compress the original audio signal."),
          tags$li("To ensure signal continuity, after sectioning the original audio signal into frames, we need a phase vocoder which will help interpolate signal information present in the frequency domain of audio signals by using phase information derived from a FFT (frequency transform). "),
          tags$li("The phase vocoder consits of three parts:",
                  tags$ol(
                    tags$li("Analysis: The audio signal framing process alters the spectrum of the original audio signal frequency, in-order to reduce the alliasing effect of framing, a Hanning window of size N (number of audio samples) is used. Then, for each audio frame, we get the Fast Fourier Transform (FFT), the abs magnitude of the frame, and the phase angle of the frame to adjust the phase in the frequency domain for our curent audio frame."),
                    tags$li("Processing: After applying a FFT we get N frequency bins strating from 0 up to (N-1)/N * f_s with an interval of f_s/N where f_s is the sampling rate frequency. To prevent smearing of signal information between consequtive audio signal frames, we first get the phase angel difference between the previous audio frame and the current audio frame, remove the expected phase difference, map the result to -pi/pi range, get the true frequency of the audio frame, and finaly calculate the cumulative final phase."),
                    tags$li("Synthesis: Next, we use an inverse Fast Fourier Transform (IFFT) on each audio frame frequency spectrum. This results is then windowed with a Hanning window to smoth the synthessized signal. Finally, we must resample (interpolate) our synthesized signal to restore the time duration of the original audio input. I use linear interpolation as a low-pass filter approximate and fill-in signal values."),
                  ))
        ),
        br(),
        h2(strong("INSTRUCTIONS")),
        br(),
        p(strong("Follow the steps listed below when using SYNTHR tool:")),
        tags$ol(
          tags$li("Select a preloaded audio .WAV file from the leftmost dropdown selector"),
          tags$li("Designate your desired pitch scaling factor. Note, extreme semitone values, especially for positive semitones, may produce noisy synthysized audio output."),
          tags$li("Click the 'SYNTHESIZE' button to generate synthasyzed audio each time you update the tool, following steps 1-2.")
        )
      )
  )),
  
  ######################
  # SYNTHR TOOL PANEL #
  ####################
  
  tabPanel(
    title = "",
    icon = icon("music", lib = "font-awesome", "fa-1x"),
    style = "min-height: 100vh;",
    fluidRow(
      width = 12,
      align = "center",
      style = "margin-left: 15%; margin-right: 15%;padding-top:5%;",
      column(
        3,
        # SELECT AUDIO SAMPLE
        selectInput(
          "sound_slct",
          label = "SELECT WAV FILE",
          choices = toupper(availableAudioSamples),
          multiple = FALSE,
          selectize = TRUE
        )
      ),
      column(
        6,
        style = "padding-right:0;",
        # SELECT DESIRED FREQUENCY/PITCH SEMITONE SHIFT
        sliderInput(
          "freq_shift_inpt",
          label = "SELECT FREQUENCY SHIFT",
          step = 1, min = -15, max = 15, value = 0
        )
      ),
      column(
        3,
        style = "margin-top:1.7%;",
        # GO BTN TO PRODUCE AUDIO AND PLOTS
        actionButton(
          "synth_btn",
          "SYNTHESIZE"
        )
      )
    ),
    fluidRow(
      # before and after audio plots
      column(
        6,
        # RAW AUDIO PLOT
        plotlyOutput(
          "rawAudioPlot",
          height = "100%"
        ),
        conditionalPanel(
          condition = "$('html').hasClass('shiny-busy')",
          tags$div("Loading Plot...", id = "loadmessage")
        )
      ),
      column(
        6,
        # SYNTHESIZED AUDIO PLOT
        plotlyOutput(
          "synthAudioPlot",
          height = "100%"
        ),
        conditionalPanel(
          condition = "$('html').hasClass('shiny-busy')",
          tags$div("Loading Plot...", id = "loadmessage")
        )
      )
    )
  )
)

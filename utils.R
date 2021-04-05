# Libraries & Packages
library(readr)
library(tuneR)
library(e1071)
library(dplyr)
library(signal)
library(matlib)
library(pracma)
library(phonTools)

# Set working directory and data (sample audio) path
WD <- getwd()
AUDIO_PATH <- paste0(WD, "/sample_audio/")


###########################################################################
#                          - audioPitchSHift -
# This function takes a vector of samples in the time-domain and shifts
# the pitch by the number of steps specified. Each step corresponds to
# half a tone. A phase vocoder is used to time-stretch the signal and
# then linear interpolation is performed to get the desired pitch shift
###########################################################################
audioPitchShift <- function(audioInpt, winSize, step) {
  # Initialize Parameters
  hop <- winSize * .25
  alpha <- 2^(step / 12)
  hopOut <- round(alpha * hop)
  wn <- hanning.window(winSize * 2 + 1)
  wn <- wn[seq(2, length(wn), 2)]

  # Source Audio File
  x <- audioInpt

  x <- matrix(c(zeros(hop * 3, 1), x))

  # Initialization
  # Create a frame matrix for the current input
  audioFrames <- createAudioFrames(x, hop, winSize)
  y <- audioFrames[[1]]
  nFramesInput <- unlist(audioFrames[2])

  # Create a frame matrix to receive processed frames
  numberFramesOutput <- nFramesInput
  outputy <- zeros(numberFramesOutput, winSize)
  # Initialize cumulative phase
  phaseCumulative <- 0
  # Initialize previous frame phase
  previousPhase <- 0


  for (index in 1:nFramesInput) {

    ## Analysis

    # Get current frame to be processed
    currentFrame <- y[index, ]

    # Window the frame
    currentFrameWindowed <- currentFrame * wn / sqrt(((winSize / hop) / 2))

    # Get the FFT
    currentFrameWindowedFFT <- fft(currentFrameWindowed)

    # Get the magnitude
    magFrame <- abs(currentFrameWindowedFFT)

    # Get the angle
    phaseFrame <- atan2(Im(currentFrameWindowedFFT), Re(currentFrameWindowedFFT))
    ## Processing

    # Get the phase difference

    deltaPhi <- phaseFrame - previousPhase
    previousPhase <- phaseFrame

    # Remove the expected phase difference
    deltaPhiPrime <- deltaPhi - (hop * 2 * pi * (0:(winSize - 1)) / winSize)

    # Map to -pi/pi range
    deltaPhiPrimeMod <- (deltaPhiPrime + pi) %% (2 * pi) - pi

    # Get the true frequency
    trueFreq <- 2 * pi * (0:(winSize - 1)) / winSize + deltaPhiPrimeMod / hop

    # Get the final phase
    phaseCumulative <- phaseCumulative + hopOut * trueFreq

    # Remove the 60 Hz noise. This is not done for now but could be
    # achieved by setting some bins to zero.

    ## Synthesis

    # Get the magnitude
    outputMag <- magFrame

    # Produce output frame
    outputFrame <- Re(ifft(outputMag * exp(1i * phaseCumulative)))

    # Save frame that has been processed
    outputy[index, ] <- outputFrame * wn / sqrt(((winSize / hopOut) / 2))
  }

  # Overlap add in a vector
  outputTimeStretched <- concatAudioFrames(outputy, hopOut)

  # Resample with linearinterpolation
  xvec <- c(0:(length(outputTimeStretched) - 1))
  yvec <- c(outputTimeStretched)
  xi <- c(seq(0, length(outputTimeStretched) - 1, alpha))
  outputTime <- interp1(xvec, yvec, xi)

  # Return the result
  outputVector <- outputTime

  return(outputVector)
}


#########################################################################
#                         - createAudioFrames -
# This function splits a vector in overlapping frames and stores these  
# frames into a matrix
########################################################################
createAudioFrames <- function(x, hop, winSize) {
  # Find the max number of slices that can be obtained
  numberSlices <- floor((length(x) - winSize) / hop)

  # Truncate if needed to get only a integer number of hop
  x <- x[1:(numberSlices * hop + winSize)]

  # Create a matrix with time slices
  vectorFrames <- zeros(floor(length(x) / hop), winSize)

  # Fill the matrix
  for (index in 1:numberSlices) {
    indexTimeStart <- (index - 1) * hop + 1
    indexTimeEnd <- (index - 1) * hop + winSize

    vectorFrames[index, ] <- x[indexTimeStart:indexTimeEnd]
  }
  return(list(vectorFrames, numberSlices))
}


##################################################################
#                     - concatAudioFrames -
# This function overlap adds the frames from the input matrix
##################################################################
concatAudioFrames <- function(audioFramesMat, hop) {

  # Get the number of frames
  numberFrames <- nrow(audioFramesMat)

  # Get the size of each frame
  sizeFrames <- ncol(audioFramesMat)

  # Define an empty vector to receive result
  vectorTime <- zeros(numberFrames * hop - hop + sizeFrames, 1)

  timeIndex <- 1

  # Loop for each frame and overlap-add
  for (index in 1:numberFrames) {
    vectorTime[timeIndex:(timeIndex + sizeFrames - 1)] <- vectorTime[timeIndex:(timeIndex + sizeFrames - 1)] + audioFramesMat[index, ]

    timeIndex <- timeIndex + hop
  }
  return(vectorTime)
}


##############################################################################
#                       - getAvailableSampleAudio -
# This function gets the list of names of all the available sample audio files 
# I have preloaded in local dir: sample_audio
##############################################################################
getAvailableSampleAudio <- function(audio_dir) {
  sample_audio_list <- unlist(strsplit(list.files(AUDIO_PATH), split = ".wav"))
  return(sample_audio_list)
}

# Call getAvailableSampleAudio to set global list of available audio samples in local dir
availableAudioSamples <- getAvailableSampleAudio(AUDIO_PATH)


# Expects: NA
# Does: To run after any final updates were made to this Shiny App 
#       so that updates are reflected on version hosted on shiny.io server
# Returns: NA
update_shinyio <- function() {
  rsconnect::deployApp(paste0(getwd()))
}


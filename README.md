<div align="center"><h1>SYNTHR</h1></div>

## FREQUENCY SHIFTING

### This tool allows you to change pitch of a preloaded audio file while maintaining its tempo. The pitch can be changed to positive or negative 15 semitones which correspond to an octave up or down.

* The pitch of a sound corresponds to the set of frequencies the sound is made of. What pitch shifting does is it takes the original sound produced at a given pitch and changes its frequencies. For instance, by shifting up the pitch of a man who is speaking, we could end up with a sound where it sounds like a mouse is speaking instead.
* One notable early practitioner of pitch shifting in music is Chuck Berry, who used the technique to make his voice sound younger. Many of the Beatles' records from 1966 and 1967 were made by recording instrumental tracks a half-step higher and the vocals correspondingly low. Examples include 'Rain', 'I'm Only Sleeping', and 'When I'm Sixty-Four'.
* Wikipedia: The simplest way to change the duration or pitch of a digital audio clip is through sample rate conversion. This is a mathematical operation that effectively rebuilds a continuous waveform from its discrete samples and then re-samples that waveform again at a different rate. When the new samples are played at the original sampling frequency, the audio clip sounds faster or slower. Unfortunately, the frequencies in the sample are always scaled at the same ratio as the speed, transposing its perceived pitch up or down in the process. In other words, slowing down the recording lowers the pitch, speeding it up raises the pitch.
* Basic steps (Wikipedia):

    * Compute the instantaneous frequency/amplitude relationship of the signal using the STFT, which is the discrete Fourier transform of a short, overlapping and smoothly windowed block of samples
    * Apply some processing to the Fourier transform magnitudes and phases (like resampling the FFT blocks)
    * Perform an inverse STFT by taking the inverse Fourier transform on each chunk and adding the resulting waveform chunks, also called overlap and add (OLA)

## ALGORITHM

### Step-by-step methodology of how SYNTHR alters the pitch of audio input.

* Determine the scaling factor (semitone shift) that will be used to stretch or compress the original audio spectrum in order to alter pitch. Negative compresses, positive stretches the original audio signal.
* Split original, continuous audio signal into multiple frame sections. These audio frame sections, from the original audio sample, overlap each other by 75%. These frames are used to stretch or compress the original audio signal.
* To ensure signal continuity, after sectioning the original audio signal into frames, we need a phase vocoder which will help interpolate signal information present in the frequency domain of audio signals by using phase information derived from a FFT (frequency transform).
* The phase vocoder consits of three parts:
    * Analysis: The audio signal framing process alters the spectrum of the original audio signal frequency, in-order to reduce the aliasing effect of framing, a Hanning window of size N (number of audio samples) is used. Then, for each audio frame, we get the Fast Fourier Transform (FFT), the abs magnitude of the frame, and the phase angle of the frame to adjust the phase in the frequency domain for our current audio frame.
    * Processing: After applying a FFT we get N frequency bins starting from 0 up to (N-1)/N * f_s with an interval of f_s/N where f_s is the sampling rate frequency. To prevent smearing of signal information between consecutive audio signal frames, we first get the phase angel difference between the previous audio frame and the current audio frame, remove the expected phase difference, map the result to -pi/pi range, get the true frequency of the audio frame, and finally calculate the cumulative final phase.
    * Synthesis: Next, we use an inverse Fast Fourier Transform (IFFT) on each audio frame frequency spectrum. This result is then windowed with a Hanning window to smooth the synthesized signal. Finally, we must resample (interpolate) our synthesized signal to restore the time duration of the original audio input. I use linear interpolation as a low-pass filter approximate and fill-in signal values.

## INSTRUCTIONS

### Follow the steps listed below when using SYNTHR tool:

* Select a preloaded audio .WAV file from the leftmost dropdown selector
* Designate your desired pitch scaling factor. Note, extreme semitone values, especially for positive semitones, may produce noisy synthysized audio output.
* Click the 'SYNTHESIZE' button to generate synthasyzed audio each time you update the tool, following steps 1-2.

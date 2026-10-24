# Example: waveform and spectrum of a single note

This example plays a note, then plots the waveform and spectrum of it. It
is written to be pasted into a Pluto or Jupyter notebook.

```julia
using SoundBank
using Plots   # or any plotting package of your choice
using FFTW

bank = UniversityIowaSBank()
piano = instrument(bank, :piano)

# --- Playback ---

c4 = note(piano, "C4")
play(c4)

# --- Waveform ---

buffer = audio(c4)
samples = buffer.samples
sample_rate = buffer.sample_rate

t = (0:length(samples)-1) ./ sample_rate
plot(t[1:2000], samples[1:2000];
     xlabel = "time (s)", ylabel = "amplitude", title = "C4 waveform (first 2000 samples)")

# --- Spectrum ---

spectrum = abs.(fft(samples))
freqs = (0:length(samples)-1) .* (sample_rate / length(samples))

# Only the first half of the spectrum is meaningful for real-valued input.
half = 1:(length(samples) ÷ 2)
plot(freqs[half], spectrum[half];
     xlabel = "frequency (Hz)", ylabel = "magnitude", title = "C4 spectrum",
     xlims = (0, 2000))
```

## Notes on pitches and dynamics

- Pitch names follow the pattern `<letter><accidental?><octave>`, e.g. `"C4"`,
  `"Bb3"`, `"F#2"`. Supported letters are `A`-`G`; accidentals are `#` or `b`.
- The piano recordings span `A0` to `C8`; the guitar recordings span `G2`
  to `A5`.
- Supported dynamics for piano are `:pp` (soft), `:mf` (medium), and `:ff`
  (loud). Guitar recordings are only available at `:ff`. The default for
  `note` is `:ff` for both instruments.



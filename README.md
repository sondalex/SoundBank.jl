# SoundBank.jl

[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)
[![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://sondalex.github.io/SoundBank.jl)

Easy access to recorded musical instrument notes, for playing single notes.

## Installation

**Dependencies**

On rhel based system:

```bash
sudo dnf install libnsl
```

```julia
using Pkg
Pkg.add(path = "path/to/SoundBank") # or Pkg.add("SoundBank") once registered
```

## Usage

```julia
using SoundBank
using Unitful, IntervalSets

bank = UniversityIowaSBank()
piano = instrument(bank, :piano)
guitar = instrument(bank, :guitar)

c4 = note(piano, "C4"; dynamic = :ff)
play(c4)
play(c4, 0.5u"s" .. 2u"s") # trim before playing

guitar_a3 = note(guitar, "A3") # guitar is only available at :ff

# Retrieve decoded audio for analysis
buffer = audio(c4)
samples = buffer.samples
sample_rate = buffer.sample_rate

trimmed = audio(c4, 0.5u"s" .. 2u"s") # trim without playing

# Chords: mix multiple notes together
c_major = chord(note(piano, "C4"), note(piano, "E4"), note(piano, "G4"))
play(c_major)
chord_buffer = audio(c_major) # notes are averaged together by default
raw_sum = mix(audio(note(piano, "C4")), audio(note(piano, "E4")); average = false)

using FFTW
spectrum = abs.(fft(samples))
```

Pitches are written like `"C4"` or `"Bb3"` (note letter A-G, optional `#` or
`b`, octave number). The supported piano range is A0 to C8, matching the
University of Iowa recordings. The supported guitar range is G2 to A5.

For guitar, each pitch is backed by a single recording, chosen as the
lowest (deepest) string on which that pitch is playable in the source
University of Iowa recordings (guitar notes are recorded per-string, and
many pitches exist on more than one string with slightly different
timbre -- see [NOTICE.md](NOTICE.md) and the
[`university-iowa-guitar-samples`](https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples)
dataset for details). Guitar recordings are only available at the `:ff`
dynamic, unlike piano's `:pp`/`:mf`/`:ff`. The default dynamic for `note`
is `:ff` for both instruments.

## Bank of Sounds

### University of Iowa

Piano sound from the [University of Iowa Musical Instrument Samples (MIS)](https://theremin.music.uiowa.edu/MISpiano.html)
collection, re-hosted (and served from) the
[`sondalex/university-iowa-piano-samples`](https://huggingface.co/datasets/sondalex/university-iowa-piano-samples)
Hugging Face dataset.

Guitar sound from the same [University of Iowa MIS](https://theremin.music.uiowa.edu/MISguitar.html)
collection, re-hosted (and served from) the
[`sondalex/university-iowa-guitar-samples`](https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples)
Hugging Face dataset.

See [NOTICE.md](NOTICE.md) for attribution and licensing notes about the recordings themselves.

`recordings.toml` maps each instrument/pitch/dynamic recording to its
download URL and sha256 in the relevant dataset; `src/artifacts.jl`
downloads and verifies a recording only the first time it is actually
requested. See [CONTRIBUTING.md](CONTRIBUTING.md) if you need to
regenerate `recordings.toml` (e.g. after a dataset is updated).


## Testing

```julia
using Pkg
Pkg.test("SoundBank")
```


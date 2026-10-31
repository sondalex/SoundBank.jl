# Notice: Recording attribution and licensing

SoundBank.jl does not bundle any audio recordings. At runtime, it downloads
recordings on demand from Hugging Face datasets re-hosting copies of
recordings originally published by:

> University of Iowa Electronic Music Studios, Musical Instrument Samples
> https://theremin.music.uiowa.edu/MISpiano.html

Piano recordings are served from the
[`university-iowa-piano-samples`](https://huggingface.co/datasets/sondalex/university-iowa-piano-samples)
dataset. Guitar recordings are served from the
[`university-iowa-guitar-samples`](https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples)
dataset; the University of Iowa only publishes guitar recordings as
multi-note range files per string and dynamic (e.g. one file covering
every note from E2 to B2 on the low E string), so that dataset re-hosts
those ranges manually split into one file per note. For pitches playable
on more than one guitar string, `recordings.toml` (see
`scripts/generate_recordings_manifest.jl`) keeps only the recording from
the lowest (deepest) string able to produce that pitch, so each guitar
pitch resolves to exactly one recording.

The University of Iowa's site states that these recordings are freely
available for use in projects. As of this writing, the source does not
attach a specific standard open-source or Creative Commons license (e.g. no
SPDX identifier) to the recordings. This package therefore does **not**
claim any particular license for the recordings themselves; the above
permission statement from the source should be independently verified by
users for their own use case, especially for commercial or redistributive
purposes.

Recordings are cached locally using [Scratch.jl](https://github.com/JuliaPackaging/Scratch.jl) after
first download.

## Software license

The SoundBank.jl source code itself is distributed under the MIT License;
see `LICENSE`.

"""
    SoundBank

Easy access to recorded musical instrument notes.

```julia
using SoundBank
using Unitful, IntervalSets

bank = UniversityIowaSBank()
piano = instrument(bank, :piano)

c4 = note(piano, "C4")
play(c4)
play(c4, 0.5u"s" .. 2u"s")  # trim before playing

buffer = audio(c4)
samples, sample_rate = buffer.samples, buffer.sample_rate

c_major = chord(note(piano, "C4"), note(piano, "E4"), note(piano, "G4"))
play(c_major)
```

See the project README for data source attribution and licensing notes.
"""
module SoundBank

include("notes.jl")
include("artifacts.jl")
include("audio.jl")
include("timespan.jl")
include("chord.jl")
include("visualize.jl")
include("playback.jl")

export audio, play
export AudioBuffer
export TimeSpan, duration
export bundled_note_path
export UniversityIowaSBank, instrument, note, Sound
export chord, Chord, mix

end # module SoundBank

"""
Chords: mixing multiple single notes ([`Sound`](@ref)s) into one
[`AudioBuffer`](@ref).
"""

"""
    Chord{S}

Multiple [`Sound`](@ref)s selected to be played together. A `Chord` does
not hold any decoded audio; call [`audio`](@ref) to mix the underlying
notes into a single [`AudioBuffer`](@ref).
"""
struct Chord{S}
    sounds::Vector{S}
end

"""
    chord(sounds::Sound...) -> Chord

Build a [`Chord`](@ref) from two or more [`Sound`](@ref)s.

```julia
c = chord(note(piano, "C4"), note(piano, "E4"), note(piano, "G4"))
play(c)
```
"""
function chord(sounds::Sound...)::Chord
    length(sounds) >= 2 || throw(
        ArgumentError("a chord requires at least 2 notes, got $(length(sounds))"),
    )
    return Chord(collect(sounds))
end

"""
    mix(buffers::AudioBuffer...; average::Bool = true) -> AudioBuffer

Mix two or more [`AudioBuffer`](@ref)s into one by summing their samples.

All buffers must share the same sample rate, or an `ArgumentError` is
thrown. Buffers of different lengths are zero-padded (at the end) to the
length of the longest buffer before summing.

By default (`average = true`) the sum is divided by the number of
buffers, which avoids clipping when combining notes whose samples are
each already within `[-1, 1]`. Pass `average = false` to get the raw sum
instead.
"""
function mix(buffers::AudioBuffer...; average::Bool = true)::AudioBuffer
    isempty(buffers) && throw(ArgumentError("mix requires at least 1 buffer"))

    rate = first(buffers).sample_rate
    for buf in buffers
        buf.sample_rate == rate || throw(
            ArgumentError(
                "cannot mix buffers with different sample rates: $(rate) vs $(buf.sample_rate)",
            ),
        )
    end

    n = maximum(length, buffers)
    total = zeros(Float64, n)
    for buf in buffers
        total[1:length(buf)] .+= buf.samples
    end
    average && (total ./= length(buffers))

    return AudioBuffer(total, rate)
end

"""
    audio(chord::Chord) -> AudioBuffer

Resolve and decode each note in `chord`, then [`mix`](@ref) them into a
single [`AudioBuffer`](@ref).
"""
function audio(chord::Chord)::AudioBuffer
    return mix(audio.(chord.sounds)...)
end

"""
    audio(chord::Chord, span::TimeSpan) -> AudioBuffer

Resolve, decode, and trim each note in `chord` to `span` (e.g.
`0.5u"s" .. 2u"s"`), then [`mix`](@ref) them into a single
[`AudioBuffer`](@ref). See [`TimeSpan`](@ref) for how out-of-range
endpoints are handled.
"""
function audio(chord::Chord, span::TimeSpan)::AudioBuffer
    return mix((audio(sound, span) for sound in chord.sounds)...)
end

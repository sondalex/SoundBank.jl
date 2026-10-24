"""
Audio representation and decoding.

Converts cached, encoded recordings into numerical samples suitable for
playback, plotting, and signal processing.
"""

using FileIO
using LibSndFile
using SampledSignals: nchannels, samplerate

"""
    AudioBuffer{T<:AbstractFloat}

Decoded audio: a vector of samples and the sample rate (in Hz) they were
recorded at. For multi-channel recordings, `samples` holds one channel
(channel averaging is applied during decoding); see [`audio`](@ref).
"""
struct AudioBuffer{T <: AbstractFloat}
    samples::Vector{T}
    sample_rate::Int
end

Base.length(buf::AudioBuffer) = length(buf.samples)

"""
    audio(sound::Sound) -> AudioBuffer

Resolve and decode the recording for `sound`, returning an
[`AudioBuffer`](@ref) of `Float64` samples.

The recording is served from a bundled, per-note artifact (see
`artifacts.jl`): installed into the local Julia depot on first use for
that specific pitch/dynamic (no network access required thereafter, and
other notes' recordings are never downloaded just to play this one).
Throws an `ArgumentError` if no bundled recording exists for the exact
pitch/dynamic requested.

Multi-channel recordings are averaged down to a single channel. Decoding
errors and unsupported files raise an informative `ErrorException`.
"""
function audio(sound::Sound)::AudioBuffer
    path = bundled_note_path(sound)
    return decode_audio_file(path)
end

"""
    decode_audio_file(path) -> AudioBuffer

Decode a local AIFF (or other `libsndfile`-supported) file into an
[`AudioBuffer`](@ref). Separated from [`audio`](@ref) so it can be tested
directly against a local fixture without downloading anything.
"""
function decode_audio_file(path::AbstractString)::AudioBuffer
    isfile(path) || throw(ErrorException("cannot decode: no such file $(path)"))

    stream = try
        loadstreaming(path)
    catch err
        throw(ErrorException("failed to open audio file $(path): $(err)"))
    end

    try
        rate = Int(samplerate(stream))
        data = read(stream)
        channels = nchannels(stream)
        samples = if channels <= 1
            Vector{Float64}(vec(data))
        else
            # Average channels down to mono.
            Vector{Float64}(vec(sum(Float64.(data); dims = 2)) ./ channels)
        end
        isempty(samples) && throw(ErrorException("decoded audio file $(path) has no samples"))
        return AudioBuffer(samples, rate)
    catch err
        err isa ErrorException && rethrow(err)
        throw(ErrorException("failed to decode audio file $(path): $(err)"))
    finally
        close(stream)
    end
end

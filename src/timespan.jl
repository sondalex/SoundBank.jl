"""
Time spans for trimming audio before decoding it fully or sending it to the
playback device.

A [`TimeSpan`](@ref) is expressed with [`Unitful`](https://github.com/PainterQubits/Unitful.jl)
time quantities and the [`IntervalSets`](https://github.com/JuliaMath/IntervalSets.jl)
`..` operator, e.g. `0.5u"s" .. 2u"s"`.
"""

using Unitful
using IntervalSets

"""
    TimeSpan

A closed interval of `Unitful.Time` quantities, e.g. `0.5u"s" .. 2u"s"`,
describing a span of audio to keep. Accepted by [`audio`](@ref) and
[`play`](@ref) to trim a recording.

Endpoints outside the actual duration of a recording (including `Inf * u"s"`)
are clamped to the start/end of the recording rather than raising an error;
see [`sample_range`](@ref).
"""
const TimeSpan = ClosedInterval{<:Unitful.Time}

"""
    duration(buf::AudioBuffer) -> Unitful.Time

The duration of `buf`, computed from its sample count and sample rate.
"""
duration(buf::AudioBuffer) = (length(buf) / buf.sample_rate) * u"s"

"""
    sample_range(span::TimeSpan, buf::AudioBuffer) -> UnitRange{Int}

Convert `span` into a 1-based sample index range into `buf.samples`.

Endpoints are clamped into `[0s, duration(buf)]` (so `Inf * u"s"`, or a
negative lower bound, are both accepted and simply mean "to/from the end of
the recording"). Throws an `ArgumentError` if, after clamping, the span is
empty or inverted.
"""
function sample_range(span::TimeSpan, buf::AudioBuffer)::UnitRange{Int}
    total = duration(buf)
    from = clamp(leftendpoint(span), zero(total), total)
    to = clamp(rightendpoint(span), zero(total), total)
    from < to || throw(
        ArgumentError(
            "empty or inverted time span $(span) for a recording of duration $(total)",
        )
    )

    i = round(Int, ustrip(u"s", from) * buf.sample_rate) + 1
    j = round(Int, ustrip(u"s", to) * buf.sample_rate)
    return max(i, 1):min(j, length(buf))
end

"""
    audio(sound::Sound, span::TimeSpan) -> AudioBuffer

Resolve, decode, and trim the recording for `sound` to `span` (e.g.
`0.5u"s" .. 2u"s"`). See [`TimeSpan`](@ref) and [`sample_range`](@ref) for how
out-of-range endpoints are handled.
"""
function audio(sound::Sound, span::TimeSpan)::AudioBuffer
    buf = audio(sound)
    r = sample_range(span, buf)
    return AudioBuffer(buf.samples[r], buf.sample_rate)
end

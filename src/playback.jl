"""
Playback.

The playback backend (PortAudio) is isolated behind the small internal
function [`send_to_device`](@ref) so that it can be swapped out or mocked
in tests without touching the public `play` API.

Using PortAudio requires a system audio library (PortAudio) to be
available: on Linux this is typically provided by ALSA or PulseAudio, on
macOS by CoreAudio, and on Windows by WASAPI/DirectSound. Environments
without an audio device (e.g. CI, containers) can still load and use every
other part of this package; only `play` requires a device.
"""

using PortAudio: PortAudioStream

"""
    play(sound::Sound; animate::Bool = true)

Load the audio for `sound` and play it through the default output device.

While playing, a terminal animation is shown (see
[`animate_playback`](@ref)); pass `animate = false` to disable it. The
animation is automatically skipped when `stdout` is not an interactive
terminal (e.g. in CI or when output is redirected).
"""
function play(sound::Sound; animate::Bool = true)::Nothing
    buf = audio(sound)
    play_with_animation(buf; animate)
    return nothing
end

"""
    play(sound::Sound, span::TimeSpan; animate::Bool = true)

Load the audio for `sound`, trim it to `span` (e.g. `0.5u"s" .. 2u"s"), and
play it through the default output device. See [`TimeSpan`](@ref) for how
out-of-range endpoints are handled.

See [`play(::Sound)`](@ref) for details on the `animate` keyword.
"""
function play(sound::Sound, span::TimeSpan; animate::Bool = true)::Nothing
    buf = audio(sound, span)
    play_with_animation(buf; animate)
    return nothing
end

"""
    play(chord::Chord; animate::Bool = true)

Load and mix the audio for each note in `chord`, and play the result
through the default output device.

See [`play(::Sound)`](@ref) for details on the `animate` keyword.
"""
function play(chord::Chord; animate::Bool = true)::Nothing
    buf = audio(chord)
    play_with_animation(buf; animate)
    return nothing
end

"""
    play(chord::Chord, span::TimeSpan; animate::Bool = true)

Load and mix the audio for each note in `chord`, trim it to `span` (e.g.
`0.5u"s" .. 2u"s"`), and play the result through the default output
device. See [`TimeSpan`](@ref) for how out-of-range endpoints are
handled.

See [`play(::Sound)`](@ref) for details on the `animate` keyword.
"""
function play(chord::Chord, span::TimeSpan; animate::Bool = true)::Nothing
    buf = audio(chord, span)
    play_with_animation(buf; animate)
    return nothing
end

"""
    play_with_animation(buf::AudioBuffer; animate::Bool = true)

Send `buf` to the output device while concurrently showing a terminal
VU-meter animation (see [`animate_playback`](@ref)).

The audio write happens on a separate task (`@async`) so the animation
loop in the calling task can redraw the terminal while playback is in
progress. Any exception raised while sending audio to the device (e.g. no
output device available) propagates to the caller via `wait`.

When `animate` is `false`, or when `stdout` is not an interactive
terminal, this simply calls [`send_to_device`](@ref) synchronously with no
animation overhead.
"""
function play_with_animation(buf::AudioBuffer; animate::Bool = true)::Nothing
    if !animate || !isa(stdout, Base.TTY)
        send_to_device(buf)
        return nothing
    end

    audio_task = @async send_to_device(buf)
    try
        animate_playback(buf)
    finally
        wait(audio_task)
    end
    return nothing
end

"""
    send_to_device(buf::AudioBuffer)

Send decoded audio to the system's default output device. This is the only
function in the package that depends on the playback backend; replacing or
mocking playback only requires replacing this function.
"""
function send_to_device(buf::AudioBuffer)::Nothing
    try
        PortAudioStream(0, 2; samplerate = Float64(buf.sample_rate)) do stream
            write(stream, buf.samples)
        end
    catch err
        throw(ErrorException("failed to play audio through the default output device: $(err)"))
    end
    return nothing
end

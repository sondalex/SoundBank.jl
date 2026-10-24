"""
Terminal spinner + progress animation shown while [`play`](@ref) is
running.

This is a time-driven visual (not a live tap into the audio device or an
amplitude visualization): it combines a rotating braille spinner (as seen
in tools like Pkg) with a traveling marker positioned by elapsed playback
time over `duration(buf)`. No plotting dependency is required.
"""

const SPINNER_FRAMES = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
const SPINNER_INTERVAL_SECONDS = 0.08
const ANIMATION_REFRESH_SECONDS = 0.08

const TRACK_WIDTH = 30
const TRACK_FILL_CHAR = '·'
const TRACK_MARKER_CHAR = '●'

"""
    spinner_frame(elapsed_seconds::Real) -> Char

The spinner glyph to display at `elapsed_seconds`, cycling through
`SPINNER_FRAMES` every `SPINNER_INTERVAL_SECONDS`, independent of
playback progress.
"""
function spinner_frame(elapsed_seconds::Real)::Char
    index = floor(Int, elapsed_seconds / SPINNER_INTERVAL_SECONDS)
    return SPINNER_FRAMES[mod1(index + 1, length(SPINNER_FRAMES))]
end

"""
    render_progress(elapsed_seconds::Real, total_seconds::Real; width::Int = TRACK_WIDTH) -> String

Render a `width`-character track of `TRACK_FILL_CHAR`, with
`TRACK_MARKER_CHAR` placed at the position corresponding to
`elapsed_seconds / total_seconds` (clamped to `[0, 1]`), wrapped in
`[...]`.

`total_seconds <= 0` places the marker at the start of the track.
"""
function render_progress(elapsed_seconds::Real, total_seconds::Real; width::Int = TRACK_WIDTH)::String
    fraction = total_seconds > 0 ? clamp(elapsed_seconds / total_seconds, 0.0, 1.0) : 0.0
    marker_index = clamp(round(Int, fraction * (width - 1)) + 1, 1, width)

    chars = fill(TRACK_FILL_CHAR, width)
    chars[marker_index] = TRACK_MARKER_CHAR
    return "[" * String(chars) * "]"
end

"""
    render_frame(elapsed_seconds::Real, total_seconds::Real) -> String

Combine [`spinner_frame`](@ref) and [`render_progress`](@ref) into a
single line, e.g. `"⠹ [●·····························]"`.
"""
function render_frame(elapsed_seconds::Real, total_seconds::Real)::String
    return "$(spinner_frame(elapsed_seconds)) $(render_progress(elapsed_seconds, total_seconds))"
end

"""
    animate_playback(buf::AudioBuffer)

Render a spinner + progress animation in the terminal for the duration of
`buf`, redrawing a single line in place until `duration(buf)` has elapsed.

No-op (returns immediately) when `stdout` is not an interactive terminal,
so it is always safe to call headlessly (e.g. in CI or when output is
redirected to a file).
"""
function animate_playback(buf::AudioBuffer)::Nothing
    isa(stdout, Base.TTY) || return nothing

    total_seconds = length(buf) / buf.sample_rate
    total_seconds > 0 || return nothing

    print(stdout, "\e[?25l")  # hide cursor
    start = time()
    try
        while true
            elapsed = time() - start
            elapsed >= total_seconds && break
            print(stdout, "\r", render_frame(elapsed, total_seconds), "\e[K")
            flush(stdout)
            sleep(ANIMATION_REFRESH_SECONDS)
        end
    finally
        print(stdout, "\r\e[K", "\e[?25h")  # clear line, restore cursor
        flush(stdout)
    end
    return nothing
end

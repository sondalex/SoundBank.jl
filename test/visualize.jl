@testset "visualize" begin
    @testset "spinner_frame" begin
        # Cycles through all frames in order as elapsed time advances.
        n = length(SoundBank.SPINNER_FRAMES)
        for i in 0:(n - 1)
            elapsed = i * SoundBank.SPINNER_INTERVAL_SECONDS
            @test SoundBank.spinner_frame(elapsed) == SoundBank.SPINNER_FRAMES[i + 1]
        end

        # Wraps around after a full cycle.
        wrapped_elapsed = n * SoundBank.SPINNER_INTERVAL_SECONDS
        @test SoundBank.spinner_frame(wrapped_elapsed) == SoundBank.SPINNER_FRAMES[1]

        # Deterministic for a given elapsed time.
        @test SoundBank.spinner_frame(0.3) == SoundBank.spinner_frame(0.3)
    end

    @testset "render_progress" begin
        width = 10

        # Marker at the start for elapsed = 0.
        start = SoundBank.render_progress(0.0, 2.0; width)
        @test start == "[" * SoundBank.TRACK_MARKER_CHAR * SoundBank.TRACK_FILL_CHAR^(width - 1) * "]"

        # Marker at the end once elapsed >= total (clamped, not an error).
        at_end = SoundBank.render_progress(2.0, 2.0; width)
        @test at_end == "[" * SoundBank.TRACK_FILL_CHAR^(width - 1) * SoundBank.TRACK_MARKER_CHAR * "]"
        past_end = SoundBank.render_progress(100.0, 2.0; width)
        @test past_end == at_end

        # Roughly proportional in between. Use `collect` rather than
        # indexing/searching the `String` directly, since `TRACK_FILL_CHAR`
        # and `TRACK_MARKER_CHAR` are multi-byte UTF-8 characters and
        # `findfirst` on a `String` returns byte offsets, not character
        # positions.
        halfway = SoundBank.render_progress(1.0, 2.0; width)
        marker_pos = findfirst(==(SoundBank.TRACK_MARKER_CHAR), collect(halfway))
        @test 4 <= marker_pos <= 8  # middle-ish of "[" + width chars + "]"

        # total_seconds <= 0 places the marker at the start rather than
        # erroring (e.g. divide by zero).
        zero_total = SoundBank.render_progress(0.5, 0.0; width)
        @test zero_total == start

        # Output format: brackets, fixed width.
        @test length(halfway) == width + 2
        @test startswith(halfway, "[")
        @test endswith(halfway, "]")
    end

    @testset "render_frame" begin
        frame = SoundBank.render_frame(0.0, 2.0)
        @test frame == "$(SoundBank.SPINNER_FRAMES[1]) $(SoundBank.render_progress(0.0, 2.0))"
    end

    @testset "animate_playback is a no-op when stdout is not a TTY" begin
        rate = 8000
        buf = AudioBuffer(zeros(rate), rate)  # 1 second of silence

        # Redirect stdout to a pipe (not a Base.TTY) so this is safe to run
        # headlessly/in CI: should return immediately without blocking or
        # writing escape codes anywhere observable.
        mktemp() do _, io
            elapsed = @elapsed redirect_stdout(io) do
                SoundBank.animate_playback(buf)
            end
            @test elapsed < 0.5
        end
    end
end

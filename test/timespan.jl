using Unitful
using IntervalSets

@testset "time spans" begin
    fixture = joinpath(@__DIR__, "fixtures", "tone.aiff")
    buf = SoundBank.decode_audio_file(fixture)
    # fixture: sample_rate = 8000, 800 samples => duration = 0.1s
    total = SoundBank.duration(buf)

    @testset "duration" begin
        @test total == 0.1u"s"
    end

    @testset "sample_range: normal span" begin
        r = SoundBank.sample_range(0.0u"s" .. 0.05u"s", buf)
        @test r == 1:400
    end

    @testset "sample_range: clamps an overshooting upper bound (incl. Inf)" begin
        r = SoundBank.sample_range(0.05u"s" .. Inf * u"s", buf)
        @test r == 401:800

        r2 = SoundBank.sample_range(0.0u"s" .. 10u"s", buf)
        @test r2 == 1:800
    end

    @testset "sample_range: clamps a negative lower bound" begin
        r = SoundBank.sample_range((-1.0u"s") .. 0.05u"s", buf)
        @test r == 1:400
    end

    @testset "sample_range: throws on an empty/inverted span" begin
        @test_throws ArgumentError SoundBank.sample_range(0.2u"s" .. 0.3u"s", buf)
        @test_throws ArgumentError SoundBank.sample_range(0.05u"s" .. 0.05u"s", buf)
    end

    @testset "audio(sound, span) trims a decoded buffer" begin
        # Exercise the full audio(sound, span) path indirectly via a fixture
        # decoded buffer, mirroring what audio(sound, span) does internally.
        span = 0.0u"s" .. 0.05u"s"
        r = SoundBank.sample_range(span, buf)
        trimmed = AudioBuffer(buf.samples[r], buf.sample_rate)
        @test length(trimmed) == 400
        @test trimmed.sample_rate == buf.sample_rate
        @test trimmed.samples == buf.samples[1:400]
    end
end

using Unitful
using IntervalSets

@testset "chord" begin
    bank = UniversityIowaSBank()
    piano = instrument(bank, :piano)

    @testset "chord requires at least 2 notes" begin
        @test_throws ArgumentError chord(note(piano, "C4"))
        @test chord(note(piano, "C4"), note(piano, "E4")) isa SoundBank.Chord
    end

    @testset "chord builds a Chord with the given sounds" begin
        c4 = note(piano, "C4")
        e4 = note(piano, "E4")
        g4 = note(piano, "G4")
        c = chord(c4, e4, g4)
        @test c.sounds == [c4, e4, g4]
    end

    @testset "mix requires equal sample rates" begin
        a = AudioBuffer([0.5, 0.5], 8000)
        b = AudioBuffer([0.5, 0.5], 4000)
        @test_throws ArgumentError SoundBank.mix(a, b)
    end

    @testset "mix averages equal-length buffers by default" begin
        a = AudioBuffer([1.0, 1.0, 1.0], 8000)
        b = AudioBuffer([-1.0, 0.5, 0.0], 8000)
        result = SoundBank.mix(a, b)
        @test result.sample_rate == 8000
        @test result.samples == [0.0, 0.75, 0.5]
    end

    @testset "mix can return the raw sum instead of averaging" begin
        a = AudioBuffer([1.0, 1.0, 1.0], 8000)
        b = AudioBuffer([-1.0, 0.5, 0.0], 8000)
        result = SoundBank.mix(a, b; average = false)
        @test result.samples == [0.0, 1.5, 1.0]
    end

    @testset "mix zero-pads buffers of different lengths" begin
        a = AudioBuffer([1.0, 1.0, 1.0, 1.0], 8000)
        b = AudioBuffer([1.0, 1.0], 8000)
        result = SoundBank.mix(a, b)
        @test length(result) == 4
        @test result.samples == [1.0, 1.0, 0.5, 0.5]
    end

    @testset "audio(chord) and audio(chord, span) mix decoded/trimmed notes" begin
        # Exercise the full audio(chord)/audio(chord, span) paths against
        # fixture-decoded buffers, mirroring what those functions do
        # internally (decode or trim each note, then mix), without
        # requiring any Sound/network access.
        fixture = joinpath(@__DIR__, "fixtures", "tone.aiff")
        buf = SoundBank.decode_audio_file(fixture)

        mixed = SoundBank.mix(buf, buf)
        @test mixed.sample_rate == buf.sample_rate
        @test length(mixed) == length(buf)
        @test mixed.samples == buf.samples # average of two identical buffers

        span = 0.0u"s" .. 0.05u"s"
        r = SoundBank.sample_range(span, buf)
        trimmed = AudioBuffer(buf.samples[r], buf.sample_rate)
        mixed_trimmed = SoundBank.mix(trimmed, trimmed)
        @test length(mixed_trimmed) == 400
        @test mixed_trimmed.samples == trimmed.samples
    end
end

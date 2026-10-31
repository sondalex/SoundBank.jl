using Mocking
using Unitful
using IntervalSets

Mocking.activate()

@testset "playback" begin
    bank = UniversityIowaSBank()
    piano = instrument(bank, :piano)
    c4 = note(piano, "C4"; dynamic = :pp)
    buf = audio(c4)

    @testset "play_with_animation(animate=false) delegates to send_to_device" begin
        calls = Ref(0)
        patch = @patch function SoundBank.send_to_device(b::SoundBank.AudioBuffer)
            calls[] += 1
            @test b === buf
            return nothing
        end
        apply(patch) do
            @test SoundBank.play_with_animation(buf; animate = false) === nothing
        end
        @test calls[] == 1
    end

    @testset "play_with_animation(animate=true) still only sends once when stdout is not a TTY" begin
        # In CI/test runs stdout isn't a Base.TTY, so the animate=true branch
        # falls back to the same synchronous path as animate=false.
        calls = Ref(0)
        patch = @patch function SoundBank.send_to_device(b::SoundBank.AudioBuffer)
            calls[] += 1
            return nothing
        end
        apply(patch) do
            @test SoundBank.play_with_animation(buf; animate = true) === nothing
        end
        @test calls[] == 1
    end

    @testset "play(::Sound) delegates to play_with_animation" begin
        calls = Ref(0)
        patch = @patch function SoundBank.send_to_device(b::SoundBank.AudioBuffer)
            calls[] += 1
            return nothing
        end
        apply(patch) do
            @test play(c4; animate = false) === nothing
        end
        @test calls[] == 1
    end

    @testset "play(::Sound, ::TimeSpan) delegates to play_with_animation" begin
        calls = Ref(0)
        patch = @patch function SoundBank.send_to_device(b::SoundBank.AudioBuffer)
            calls[] += 1
            return nothing
        end
        apply(patch) do
            @test play(c4, 0.0u"s" .. duration(buf); animate = false) === nothing
        end
        @test calls[] == 1
    end

    @testset "play(::Chord) and play(::Chord, ::TimeSpan) delegate to play_with_animation" begin
        other = note(piano, "E4"; dynamic = :pp)
        c = chord(c4, other)
        chord_buf = audio(c)

        calls = Ref(0)
        patch = @patch function SoundBank.send_to_device(b::SoundBank.AudioBuffer)
            calls[] += 1
            return nothing
        end
        apply(patch) do
            @test play(c; animate = false) === nothing
            @test play(c, 0.0u"s" .. duration(chord_buf); animate = false) === nothing
        end
        @test calls[] == 2
    end

    @testset "send_to_device raises an informative error without a real device" begin
        @test_throws ErrorException SoundBank.send_to_device(buf)
    end
end

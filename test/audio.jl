@testset "audio decoding" begin
    fixture = joinpath(@__DIR__, "fixtures", "tone.aiff")

    @testset "decodes a known fixture" begin
        buf = SoundBank.decode_audio_file(fixture)
        @test buf.sample_rate == 8000
        @test length(buf.samples) == 800
        @test eltype(buf.samples) <: AbstractFloat
        @test !isempty(buf.samples)
        @test maximum(abs, buf.samples) <= 1.0
    end

    @testset "missing file raises an informative error" begin
        @test_throws ErrorException SoundBank.decode_audio_file(joinpath(@__DIR__, "fixtures", "does_not_exist.aiff"))
    end
end

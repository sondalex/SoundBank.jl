using Test
using SoundBank

@testset "SoundBank.jl" begin
    include("notes.jl")
    include("audio.jl")
    include("timespan.jl")
    include("chord.jl")
    include("visualize.jl")
    include("artifacts.jl")
    include("playback.jl")
end

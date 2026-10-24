using Test
using SoundBank

@testset "SoundBank.jl" begin
    include("notes.jl")
    include("audio.jl")
    include("timespan.jl")
    include("chord.jl")
    include("visualize.jl")
end

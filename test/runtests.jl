using Test
using SoundBank

const TEST_HEADLESS = lowercase(
    get(ENV, "SOUNDBANK_HEADLESS", "false")
) in ("true", "1", "yes")

@testset "SoundBank.jl" begin
    include("notes.jl")
    include("audio.jl")
    include("timespan.jl")
    include("chord.jl")
    include("visualize.jl")
    include("artifacts.jl")
    include("playback.jl")
end

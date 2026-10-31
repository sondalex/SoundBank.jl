"""
Bundled recordings: downloaded directly, lazily, and cached locally.

Each recording (one pitch, one dynamic) is one entry in `recordings.toml`
(see `scripts/generate_recordings_manifest.jl`), giving its URL -- in the
`university-iowa-piano-samples` dataset,
https://huggingface.co/datasets/sondalex/university-iowa-piano-samples --
and its sha256. 

This is deliberately *not* a `Pkg.Artifacts`
`Artifacts.toml`: `Pkg.Artifacts`'s download mechanism always expected the
fetched URL to point to a tarball.
"""

using Downloads
using ProgressMeter
using SHA
using TOML
using Scratch

"""
    recordings_manifest_path() -> String

Path to the `recordings.toml` manifest bundled with this package.
"""
recordings_manifest_path() = normpath(joinpath(@__DIR__, "..", "recordings.toml"))


dataset_dir = ""

function __init__()
    return global dataset_dir = get_scratch!(@__MODULE__, "dataset")
end


"""
    load_recordings_manifest() -> Dict{String,Any}

Parse [`recordings_manifest_path`](@ref) into a name -> entry dict. Entry
keys are `"url"`, `"sha256"`, `"filename"`, `"pitch"`, `"dynamic"`.
"""
function load_recordings_manifest()
    path = recordings_manifest_path()
    isfile(path) || throw(ErrorException("recordings manifest not found at $(path)"))
    return TOML.parsefile(path)
end

sha256_of(path::AbstractString) = bytes2hex(open(sha256, path))

"""
    bundled_note_path(sound::Sound) -> String

Local filesystem path to the recording for `sound`, downloading it first
if necessary (only that one recording is fetched, not the whole
collection -- see module docstring above). Throws an `ArgumentError` if
no bundled recording exists for the exact pitch/dynamic requested. Only
resolves a path; call [`decode_audio_file`](@ref) on the result to load
the actual samples.

```julia
path = bundled_note_path(note(piano, "C4"; dynamic = :pp))
buffer = decode_audio_file(path)
```
"""
function bundled_note_path(sound::Sound)
    inst = sound.instrument
    bank = inst.bank
    name = artifact_member_name(bank, inst, sound.pitch, sound.dynamic)

    manifest = load_recordings_manifest()
    haskey(manifest, name) || throw(
        ArgumentError(
            "no bundled recording for pitch $(repr(sound.pitch)), dynamic " *
                "$(repr(sound.dynamic)) (looked for recording $(repr(name)))"
        )
    )
    entry = manifest[name]

    dest = joinpath(dataset_dir, entry["filename"])
    if isfile(dest) && sha256_of(dest) == entry["sha256"]
        return dest
    end

    tmp = dest * ".part"
    try
        bar = Ref{Union{Nothing, Progress, ProgressUnknown}}(nothing)
        Downloads.download(
            entry["url"],
            tmp;
            progress = (total, now) -> begin
                if total > 0
                    if bar[] === nothing || !(bar[] isa Progress) || bar[].n != total
                        bar[] = Progress(
                            total;
                            desc = "Downloading $(entry["filename"]): ",
                            barlen = 40,
                        )
                    end
                    ProgressMeter.update!(bar[], now)
                elseif now > 0
                    if bar[] === nothing
                        bar[] = ProgressUnknown(
                            desc = "Downloading $(entry["filename"]): ",
                        )
                    end
                    ProgressMeter.update!(bar[], now)
                end
            end,
        )
        b = bar[]
        b === nothing || finish!(b)
        actual = sha256_of(tmp)
        if actual != entry["sha256"]
            throw(
                ErrorException(
                    "checksum mismatch downloading $(entry["url"]): expected " *
                        "$(entry["sha256"]), got $(actual)"
                )
            )
        end
        mv(tmp, dest, force = true)
    finally
        rm(tmp, force = true)
    end
    return dest
end

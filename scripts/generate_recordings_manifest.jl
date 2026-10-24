#!/usr/bin/env julia
"""
Generate/update `recordings.toml` for SoundBank.jl: a small manifest, one
entry per bundled recording, each binding an `artifact_member_name` (see
`src/notes.jl`) to the URL it is served from in the relevant Hugging Face
dataset and that file's sha256.

Two instruments are currently supported:

- piano, served from `university-iowa-piano-samples`: already one file
  per (dynamic, pitch), under `university_iowa/`.
- guitar, served from `university-iowa-guitar-samples`: one file per
  (dynamic, string, pitch), under `samples/`. Since the same pitch can be
  played on more than one string, for each pitch only the recording from
  the lowest (deepest) string able to produce it is kept, so every
  guitar pitch resolves to exactly one recording -- see NOTICE.md.
"""

using Downloads
using TOML

"""
    load_checksums(base_url) -> Dict{String,String}

Download `<base_url>/checksums.toml` and parse its `[sha256]` table:
relative path (e.g. "university_iowa/Piano.pp.C4.aiff") -> sha256.
"""
function load_checksums(base_url::AbstractString)
    path = Downloads.download("$(base_url)/checksums.toml")
    data = TOML.parsefile(path)
    haskey(data, "sha256") || error("no [sha256] table in $(base_url)/checksums.toml")
    return data["sha256"]
end

"""
    artifact_member_name(inst, dynamic, pitch) -> String

Must match `artifact_member_name(::UniversityIowaSBank, ...)` in
`src/notes.jl`.
"""
artifact_member_name(inst::AbstractString, dynamic::AbstractString, pitch::AbstractString) =
    "$(inst)_$(dynamic)_$(pitch)"

"""
    piano_entries(base_url) -> Vector{<:NamedTuple}

One entry per `university_iowa/Piano.<dynamic>.<pitch>.aiff` file in
`checksums.toml` at `base_url` -- already one recording per
(dynamic, pitch), no canonicalization needed.
"""
function piano_entries(base_url::AbstractString)
    checksums = load_checksums(base_url)
    isempty(checksums) && error("checksums.toml at $(base_url) lists no files")

    subdir = "university_iowa"
    rels = sort(filter(rel -> startswith(rel, "$(subdir)/") && endswith(rel, ".aiff"), collect(keys(checksums))))
    isempty(rels) && error("no $(subdir)/*.aiff entries found in checksums.toml at $(base_url)")

    return map(rels) do rel
        filename = basename(rel)
        # filename like "Piano.pp.C4.aiff" -> dynamic="pp", pitch="C4"
        parts = split(filename, '.')
        dynamic, pitch = parts[2], parts[3]
        (
            name = artifact_member_name("piano", dynamic, pitch),
            filename = filename,
            pitch = pitch,
            dynamic = dynamic,
            sha256 = checksums[rel],
            url = "$(base_url)/$(rel)",
        )
    end
end

"""
    GUITAR_STRING_PRIORITY

Guitar strings, low (deepest) to high, used to pick a single canonical
recording for pitches playable on more than one string: lower number
wins. `sulE` is the low (6th) string, `sul_E` (with underscore) the
high (1st) string -- both tuned to E, an octave apart.
"""
const GUITAR_STRING_PRIORITY = Dict(
    "sulE" => 1,
    "sulA" => 2,
    "sulD" => 3,
    "sulG" => 4,
    "sulB" => 5,
    "sul_E" => 6,
)

"""
    guitar_entries(base_url) -> Vector{<:NamedTuple}

One entry per unique pitch found under `samples/Guitar.<dynamic>.<string>.<pitch>.aiff`
files in `checksums.toml` at `base_url`. Pitches available on more than
one string keep only the recording from the lowest-priority
(deepest) string -- see [`GUITAR_STRING_PRIORITY`](@ref).
"""
function guitar_entries(base_url::AbstractString)
    checksums = load_checksums(base_url)
    isempty(checksums) && error("checksums.toml at $(base_url) lists no files")

    subdir = "samples"
    rels = sort(filter(rel -> startswith(rel, "$(subdir)/") && endswith(rel, ".aiff"), collect(keys(checksums))))
    isempty(rels) && error("no $(subdir)/*.aiff entries found in checksums.toml at $(base_url)")

    candidates = map(rels) do rel
        filename = basename(rel)
        # filename like "Guitar.ff.sulE.E2.aiff" -> dynamic="ff", string="sulE", pitch="E2"
        parts = split(filename, '.')
        dynamic, string_tag, pitch = parts[2], parts[3], parts[4]
        haskey(GUITAR_STRING_PRIORITY, string_tag) ||
            error("unrecognized guitar string tag $(repr(string_tag)) in $(rel)")
        (
            filename = filename,
            pitch = pitch,
            dynamic = dynamic,
            string_tag = string_tag,
            priority = GUITAR_STRING_PRIORITY[string_tag],
            sha256 = checksums[rel],
            url = "$(base_url)/$(rel)",
        )
    end

    # Keep, per (dynamic, pitch), only the candidate from the lowest-priority string.
    best = Dict{Tuple{String, String}, eltype(candidates)}()
    for c in candidates
        key = (c.dynamic, c.pitch)
        if !haskey(best, key) || c.priority < best[key].priority
            best[key] = c
        end
    end

    return [
        (
            name = artifact_member_name("guitar", c.dynamic, c.pitch),
            filename = c.filename,
            pitch = c.pitch,
            dynamic = c.dynamic,
            sha256 = c.sha256,
            url = c.url,
        )
            for c in sort(collect(values(best)); by = c -> (c.dynamic, c.pitch))
    ]
end

function write_manifest(path::AbstractString, entries::Vector{<:NamedTuple})
    return open(path, "w") do io
        println(io, "# Generated by scripts/generate_recordings_manifest.jl. One entry per")
        println(io, "# bundled recording (piano, from `university-iowa-piano-samples`; guitar,")
        println(io, "# from `university-iowa-guitar-samples` -- see NOTICE.md for attribution).")
        println(io, "# `src/artifacts.jl` downloads and caches each recording lazily (only on")
        println(io, "# first use of that specific instrument/pitch/dynamic), verifying `sha256`")
        println(io, "# before trusting the download.")
        println(io)
        for e in entries
            println(io, "[\"$(e.name)\"]")
            println(io, "url = \"$(e.url)\"")
            println(io, "sha256 = \"$(e.sha256)\"")
            println(io, "filename = \"$(e.filename)\"")
            println(io, "pitch = \"$(e.pitch)\"")
            println(io, "dynamic = \"$(e.dynamic)\"")
            println(io)
        end
    end
end

function cli()
    if length(ARGS) != 3
        println(
            stderr, """
            usage: julia generate_recordings_manifest.jl <manifest_toml> <piano_base_url> <guitar_base_url>

              manifest_toml       Path to write/update, e.g. recordings.toml
              piano_base_url      Base URL piano recordings are served from, e.g.
                                   https://huggingface.co/datasets/sondalex/university-iowa-piano-samples/resolve/main
              guitar_base_url     Base URL guitar recordings are served from, e.g.
                                   https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples/resolve/main

            For each base URL, "<base_url>/checksums.toml" is downloaded to
            build the manifest; each recording is then fetched from
            "<base_url>/<relative path from checksums.toml>".
            """
        )
        exit(1)
    end
    return (
        manifest_toml = ARGS[1],
        piano_base_url = rstrip(ARGS[2], '/'),
        guitar_base_url = rstrip(ARGS[3], '/'),
    )
end

function main()
    args = cli()
    entries = vcat(piano_entries(args.piano_base_url), guitar_entries(args.guitar_base_url))
    write_manifest(args.manifest_toml, entries)
    return @info "wrote $(args.manifest_toml)" recordings = length(entries)
end

main()

"""
Musical selections: lightweight descriptions of recordings, as opposed to
decoded audio. See [`Sound`](@ref).
"""

const SUPPORTED_INSTRUMENTS = (:piano, :guitar)


"""
    SBank

Abstract supertype for a source of recorded notes ("sample bank").

Concrete subtypes must implement:

- [`artifact_member_name`](@ref): how to map an (instrument, pitch,
  dynamic) selection to the recording name recorded for this bank in
  `recordings.toml`.

"""
abstract type SBank end

"""
Name of the sound bank
"""
function sbank_name(sbank::SBank)
    error("Type $(typeof(sbank)) must implement `sbank_name(sbank)`")
end

"""
Implementations are responsible for safety
"""
function sbank_dir(sbank::SBank)
    error("Type $(typeof(sbank)) must implement `sbank_dir(sbank)`")
end


"""
    artifact_member_name(bank::SBank, inst::Instrument, pitch, dynamic) -> String

Name of the lazily-downloaded `recordings.toml` entry holding the
recording for `inst`/`pitch`/`dynamic` in `bank` (one entry per
recording -- see `src/artifacts.jl`). Must be implemented by every
concrete [`SBank`](@ref).
"""
function artifact_member_name(bank::SBank, inst, pitch::AbstractString, dynamic::Symbol)
    throw(
        ErrorException(
            "artifact_member_name not implemented for $(typeof(bank))"
        )
    )
end


"""
    UniversityIowaSBank

Recordings from the University of Iowa Musical Instrument Samples (MIS)
collection. See NOTICE.md for attribution.
"""
struct UniversityIowaSBank <: SBank
end


function sbank_name(sbank::UniversityIowaSBank)
    return "UniversityIowaSBank"
end

function sbank_dir(sbank::UniversityIowaSBank)
    return lowercase(sbank_name(sbank))
end

function artifact_member_name(::UniversityIowaSBank, inst, pitch::AbstractString, dynamic::Symbol)
    return "$(inst.name)_$(dynamic)_$(pitch)"
end

struct Instrument{B <: SBank}
    bank::B
    name::Symbol
end

function instrument(bank::SBank, name::Symbol)
    if name ∉ SUPPORTED_INSTRUMENTS
        throw(
            ArgumentError(
                "unsupported instrument $(repr(name)); supported instruments are $(SUPPORTED_INSTRUMENTS)"
            )
        )
    end
    return Instrument(bank, name)
end
instrument(bank::SBank, name::AbstractString) = instrument(bank, Symbol(name))


"""
    Sound{I}

A selected recording: an instrument, a pitch (e.g. `"C4"`), and a dynamic
(e.g. `:ff`). A `Sound` does not hold any decoded audio; call [`audio`](@ref)
to retrieve an [`AudioBuffer`](@ref).
"""
struct Sound{I}
    instrument::I
    pitch::String
    dynamic::Symbol
end


"""
    note(inst, pitch; dynamic = :ff) -> Sound

Select a single recorded note. Validates `pitch` and `dynamic` eagerly,
raising an `ArgumentError` for invalid input rather than failing later
during download.

Note that the default dynamic is `:ff` (fortissimo): guitar recordings
are only available at `:ff`, while piano additionally offers `:pp` and
`:mf`.

```julia
c4 = note(piano, "C4")
soft_c4 = note(piano, "C4"; dynamic = :pp)
guitar_a3 = note(guitar, "A3")
```
"""
function note(inst::Instrument, pitch::AbstractString; dynamic::Symbol = :ff)::Sound
    return Sound(inst, String(pitch), dynamic)
end

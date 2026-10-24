# Contributing

## Recordings are downloaded directly from Hugging Face

SoundBank.jl does not bundle or vendor any audio: each piano recording is
downloaded directly, lazily, from the
[`university-iowa-piano-samples`](https://huggingface.co/datasets/sondalex/university-iowa-piano-samples)
Hugging Face dataset, and each guitar recording from the
[`university-iowa-guitar-samples`](https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples)
Hugging Face dataset, the first time that specific instrument/pitch/dynamic
is requested (see `src/artifacts.jl`), and cached locally afterwards.

Downloaded files are checked against the checksum file `recordings.toml`.

## Regenerating `recordings.toml`

1. Regenerate the manifest (this only downloads each dataset's `checksums.toml`):

   ```bash
   julia --project=scripts -e 'import Pkg; Pkg.instantiate()'
   julia --project=scripts scripts/generate_recordings_manifest.jl \
     recordings.toml \
     "https://huggingface.co/datasets/sondalex/university-iowa-piano-samples/resolve/main" \
     "https://huggingface.co/datasets/sondalex/university-iowa-guitar-samples/resolve/main"
   ```

2. Commit the updated `recordings.toml`:

   ```bash
   git add recordings.toml
   git commit -m "Regenerate recordings.toml"
   ```

## Running tests

```julia
using Pkg
Pkg.test("SoundBank")
```

## Code style

This project is formatted with [Runic.jl](https://github.com/fredrikekre/Runic.jl).

To format locally  use `Pkg.Apps.add("Runic")` (on Julia >= 1.12):

```bash
julia --project=@runic --startup-file=no -e 'using Pkg; Pkg.add("Runic")'
julia --project=@runic --startup-file=no -e 'using Runic; exit(Runic.main(["--inplace", "src", "test", "scripts"]))'
```

To only check formatting without writing changes:

```bash
julia --project=@runic --startup-file=no -e 'using Runic; exit(Runic.main(["--check", "--diff", "src", "test", "scripts"]))'
```


## Static analysis

[JET.jl](https://github.com/aviatesk/JET.jl) runs in CI
(`.github/workflows/jet.yml`).

To run it locally, use a throwaway/temporary environment so that the
`SoundBank` dev-path never gets written into the tracked `test/Project.toml`
(this is also what the CI workflow does, in an ephemeral container):

```bash
julia --startup-file=no -e '
    import Pkg
    Pkg.activate(; temp = true)
    Pkg.develop(path = ".")
    Pkg.add("JET")
    using JET, SoundBank
    JET.test_package(SoundBank; target_modules = (SoundBank, ))
'
```

## Running checks locally with pre-commit

[`pre-commit`](https://pre-commit.com/) is configured (`.pre-commit-config.yaml`)
to run Runic automatically before each commit.

```bash
pip install pre-commit
pre-commit install        # installs the git hook, one-time per clone
pre-commit run --all-files # run all hooks against the whole repository
```

## Building the documentation locally

Documentation lives under `docs/`.
Build the docs with:

```bash
julia --project=docs -e 'import Pkg; Pkg.develop(path = "."); Pkg.instantiate()'
julia --project=docs docs/make.jl
```


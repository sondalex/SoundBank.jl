using Documenter
using SoundBank

DocMeta.setdocmeta!(SoundBank, :DocTestSetup, :(using SoundBank); recursive = true)

# `docs/src/index.md` is generated from the repository README so that the
# two never drift apart; README.md remains the single source of truth.
# Badges and repo-relative links (which only resolve on GitHub) are
# rewritten/stripped for the hosted docs site.
let
    readme = read(joinpath(@__DIR__, "..", "README.md"), String)
    readme = replace(readme, r"^\[!\[.*\]\(.*\)\]\(.*\)\n"m => "")
    readme = replace(
        readme,
        "`docs/src/examples.md`" => "[`docs/src/examples.md`](examples.md)",
        r", or the\n\[hosted documentation\]\([^)]*\)\." => ".",
        "[NOTICE.md](NOTICE.md)" => "[NOTICE.md](https://github.com/sondalex/SoundBank.jl/blob/main/NOTICE.md)",
        "[CONTRIBUTING.md](CONTRIBUTING.md)" => "[CONTRIBUTING.md](https://github.com/sondalex/SoundBank.jl/blob/main/CONTRIBUTING.md)",
    )
    write(joinpath(@__DIR__, "src", "index.md"), readme)
end

makedocs(;
    sitename = "SoundBank.jl",
    modules = [SoundBank],
    authors = "sondalex",
    repo = "https://github.com/sondalex/SoundBank.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://sondalex.github.io/SoundBank.jl",
        repolink = "https://github.com/sondalex/SoundBank.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md",
    ],
    checkdocs = :exports,
)

deploydocs(;
    repo = "github.com/sondalex/SoundBank.jl.git",
    devbranch = "main",
    push_preview = true,
)

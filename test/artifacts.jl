@testset "artifacts" begin
    bank = UniversityIowaSBank()
    piano = instrument(bank, :piano)


    @testset "unknown pitch/dynamic raises ArgumentError" begin
        unknown = note(piano, "Z9"; dynamic = :pp)
        @test_throws ArgumentError bundled_note_path(unknown)
    end

    @testset "downloads, verifies checksum, and caches a bundled recording" begin
        c4 = note(piano, "C4"; dynamic = :pp)

        path = bundled_note_path(c4)
        @test isfile(path)

        manifest = SoundBank.load_recordings_manifest()
        name = SoundBank.artifact_member_name(bank, piano, c4.pitch, c4.dynamic)
        entry = manifest[name]
        @test SoundBank.sha256_of(path) == entry["sha256"]

        mtime_after_first_call = mtime(path)

        # Second call hits the cache: the checksum matches so the
        # file is not re-downloaded.
        path_again = bundled_note_path(c4)
        @test path_again == path
        @test mtime(path_again) == mtime_after_first_call
    end

    @testset "re-downloads when the cached file is corrupted" begin
        c4 = note(piano, "C4"; dynamic = :pp)
        path = bundled_note_path(c4)

        write(path, "corrupted")
        @test SoundBank.sha256_of(path) != SoundBank.load_recordings_manifest()[
            SoundBank.artifact_member_name(
                bank, piano, c4.pitch, c4.dynamic
            ),
        ]["sha256"]

        repaired = bundled_note_path(c4)
        manifest = SoundBank.load_recordings_manifest()
        entry = manifest[SoundBank.artifact_member_name(bank, piano, c4.pitch, c4.dynamic)]
        @test SoundBank.sha256_of(repaired) == entry["sha256"]
    end
end

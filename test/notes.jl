struct TempBank <: SBank
end

@testset "notes" begin
    bank = UniversityIowaSBank()
    piano = instrument(bank, :piano)
    guitar = instrument(bank, :guitar)

    @testset "instrument validates supported names" begin
        @test_throws ArgumentError instrument(bank, :violin)
        @test instrument(bank, "piano") isa SoundBank.Instrument
        @test instrument(bank, "guitar") isa SoundBank.Instrument
    end

    @testset "note builds a Sound with defaults" begin
        c4 = note(piano, "C4")
        @test c4.pitch == "C4"
        @test c4.dynamic == :ff
        @test c4.instrument === piano

        soft_c4 = note(piano, "C4"; dynamic = :pp)
        @test soft_c4.dynamic == :pp

        guitar_a3 = note(guitar, "A3")
        @test guitar_a3.pitch == "A3"
        @test guitar_a3.dynamic == :ff
        @test guitar_a3.instrument === guitar
    end

    @testset "SBank interface" begin
        @test SoundBank.artifact_member_name(bank, piano, "C4", :pp) == "piano_pp_C4"
        @test SoundBank.artifact_member_name(bank, guitar, "A3", :ff) == "guitar_ff_A3"
    end
    @testset "sbank_name raises error on unimplemented method for concrete class" begin
        sbank = TempBank()
        @test_throws ErrorException sbank_name(sbank)
    end
    @testset "sbank_dir raises error on unimplemented method for concrete class" begin
        sbank = TempBank()
        @test_throws ErrorException sbank_dir(sbank)
    end
end

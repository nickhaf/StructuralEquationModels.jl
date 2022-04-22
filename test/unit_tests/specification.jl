@testset "ParameterTable - RAMMatrices conversion" begin
    partable = ParameterTable(ram_matrices)
    @test ram_matrices == RAMMatrices(partable)
end

@test get_identifier_indices([:x2, :x10, :x28], model_ml) == [2, 10, 28]

@testset "get_identifier_indices" begin
    pars = [:θ_1, :θ_7, :θ_21]
    @test get_identifier_indices(pars, model_ml) == get_identifier_indices(pars, partable)
    @test get_identifier_indices(pars, model_ml) == get_identifier_indices(pars, RAMMatrices(partable))
end
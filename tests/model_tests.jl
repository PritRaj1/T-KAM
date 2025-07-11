using Test, Random, LinearAlgebra, Lux, ConfParser, Zygote, ComponentArrays

ENV["GPU"] = true
ENV["FULL_QUANT"] = "FP32"
ENV["HALF_QUANT"] = "FP16"

include("../src/T-KAM/T-KAM.jl")
include("../src/utils.jl")
using .T_KAM_model
using .Utils

conf = ConfParse("tests/test_conf.ini")
parse_conf!(conf)
out_dim = parse(Int, retrieve(conf, "KAN_LIKELIHOOD", "output_dim"))

function test_ps_derivative()
    Random.seed!(42)
    dataset = randn(full_quant, 3, 3, 1, 50) 
    model = init_T_KAM(dataset, conf, (3,3,1))
    x_test = first(model.train_loader) |> device
    ps, st = Lux.setup(Random.GLOBAL_RNG, model)
    ps, st = ComponentArray(ps) |> device, st |> device
    model = move_to_hq(model)

    ∇ = first(gradient(p -> first(model.loss_fcn(model, p, st, x_test)), half_quant.(ps)))
    @test norm(∇) > 0
    @test !any(isnan, ∇)
end

function test_grid_update()
    Random.seed!(42)
    dataset = randn(full_quant, 3, 3, 1, 50) 
    model = init_T_KAM(dataset, conf, (3,3,1))
    ps, st = Lux.setup(Random.GLOBAL_RNG, model)
    ps, st = ComponentArray(ps) |> device, st |> device
    model = move_to_hq(model)

    size_grid = size(st.gen[Symbol("1")].grid)
    x = first(model.train_loader) |> device
    model, ps, st, seed = update_model_grid(model, x, ps, Lux.testmode(st))
    @test all(size(st.gen[Symbol("1")].grid) .== size_grid)
    @test !any(isnan, ps)
end

function test_mala_loss()
    Random.seed!(42)
    dataset = randn(full_quant, 3, 3, 1, 50) 
    commit!(conf, "MALA", "use_langevin", "true")
    model = init_T_KAM(dataset, conf, (3,3,1))
    x_test = first(model.train_loader) |> device
    ps, st = Lux.setup(Random.GLOBAL_RNG, model)
    ps, st = ComponentArray(ps) |> device, st |> device
    model = move_to_hq(model)

    ∇ = first(gradient(p -> first(model.loss_fcn(model, p, st, x_test)), half_quant.(ps)))
    @test norm(∇) > 0
    @test !any(isnan, ∇)
end

function test_cnn_loss()
    Random.seed!(42)
    dataset = randn(full_quant, 32, 32, 3, 50)
    commit!(conf, "CNN", "use_cnn_lkhood", "true")
    model = init_T_KAM(dataset, conf, (32, 32, 3))
    x_test = first(model.train_loader) |> device
    ps, st = Lux.setup(Random.GLOBAL_RNG, model)
    ps, st = ComponentArray(ps) |> device, st |> device
    model = move_to_hq(model)

    ∇ = first(gradient(p -> first(model.loss_fcn(model, p, st, x_test)), half_quant.(ps)))
    @test norm(∇) > 0
    @test !any(isnan, ∇)
    commit!(conf, "CNN", "use_cnn_lkhood", "false")
end

function test_SEQ_loss()
    Random.seed!(42)
    dataset = randn(full_quant, 50, 10, 100)
    commit!(conf, "SEQ", "sequence_length", "10")
    commit!(conf, "SEQ", "vocab_size", "50")
    model = init_T_KAM(dataset, conf, (50, 10))
    x_test = first(model.train_loader) |> device
    ps, st = Lux.setup(Random.GLOBAL_RNG, model)
    ps, st = ComponentArray(ps) |> device, st |> device
    model = move_to_hq(model)

    ∇ = first(gradient(p -> first(model.loss_fcn(model, p, st, x_test)), half_quant.(ps)))
    @test norm(∇) > 0
    @test !any(isnan, ∇)
end

@testset "T-KAM Tests" begin
    test_ps_derivative()
    test_grid_update()
    test_mala_loss()
    test_cnn_loss()
    test_SEQ_loss()
end
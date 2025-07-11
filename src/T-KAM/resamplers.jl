module WeightResamplers

export residual_resampler, systematic_resampler, stratified_resampler

using Random, Distributions, LinearAlgebra
using NNlib: softmax

include("../utils.jl")
using .Utils: next_rng, full_quant

function residual_resampler(
    weights::AbstractArray{U}, 
    ESS_bool::AbstractArray{Bool}, 
    B::Int, 
    N::Int; 
    seed::Int=1
    ) where {U<:full_quant}
    """
    Residual resampling for weight filtering.

    Args:
        weights: The weights of the population.
        ESS_bool: A boolean array indicating if the ESS is above the threshold.
        seed: Random seed for reproducibility.

    Returns:
        - The resampled indices.
        - The updated seed.
    """
    # Number times to replicate each sample, (convert to FP64 because stability issues)
    integer_counts = floor.(weights .* N) .|> Int
    num_remaining = dropdims(N .- sum(integer_counts, dims=2); dims=2)

    # Residual weights to resample from
    residual_weights = softmax(weights .* (N .- integer_counts), dims=2)

    # CDF and variate for resampling
    seed, rng = next_rng(seed)
    u = rand(rng, U, B, maximum(num_remaining))
    cdf = cumsum(residual_weights, dims=2)

    idxs = Array{Int}(undef, B, N)
    Threads.@threads for b in 1:B
        c = 1

        if !ESS_bool[b]
            idxs[b, :] .= 1:N
        else
            # Deterministic replication
            for s in 1:N
                count = integer_counts[b, s]
                if count > 0
                    idxs[b, c:c+count-1] .= s
                    c += count
                end
            end

            # Multinomial resampling
            if num_remaining[b] > 0
                idxs[b, c:end] .= searchsortedfirst.(Ref(cdf[b, :]), u[b, 1:num_remaining[b]])
            end
        end
    end
    replace!(idxs, N+1 => N)
    return idxs, seed
end

function systematic_resampler(
    weights::AbstractArray{U}, 
    ESS_bool::AbstractArray{Bool}, 
    B::Int, 
    N::Int;
    seed::Int=1
    ) where {U<:full_quant}
    """
    Systematic resampling for weight filtering.

    Args:
        weights: The weights of the population.
        ESS_bool: A boolean array indicating if the ESS is above the threshold.
        seed: Random seed for reproducibility.

    Returns:
        - The resampled indices.
        - The updated seed.
    """

    cdf = cumsum(weights, dims=2) 

    # Systematic thresholds
    seed, rng = next_rng(seed)
    u = (rand(rng, U, B, 1) .+ (0:N-1)') ./ N

    idxs = Array{Int}(undef, B, N)
    Threads.@threads for b in 1:B
        idxs[b, :] .= !ESS_bool[b] ? collect(1:N) : searchsortedfirst.(Ref(cdf[b, :]), u[b, :])
    end
    replace!(idxs, N+1 => N)
    return idxs, seed
end

function stratified_resampler(
    weights::AbstractArray{U}, 
    ESS_bool::AbstractArray{Bool}, 
    B::Int, 
    N::Int; 
    seed::Int=1
    ) where {U<:full_quant}
    """
    Systematic resampling for weight filtering.

    Args:
        weights: The weights of the population.
        ESS_bool: A boolean array indicating if the ESS is above the threshold.
        seed: Random seed for reproducibility.

    Returns:
        - The resampled indices.
        - The updated seed.
    """

    cdf = cumsum(weights, dims=2) 

    # Stratified thresholds
    seed, rng = next_rng(seed)
    u = (rand(rng, U, B, N) .+ (0:N-1)') ./ N

    idxs = Array{Int}(undef, B, N)
    Threads.@threads for b in 1:B
        idxs[b, :] .= !ESS_bool[b] ? collect(1:N) : searchsortedfirst.(Ref(cdf[b, :]), u[b, :])
    end
    replace!(idxs, N+1 => N)
    return idxs, seed
end

end
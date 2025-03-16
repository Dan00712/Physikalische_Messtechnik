using DrWatson
@quickactivate

using Logging
using DelimitedFiles
using Statistics

using DataFrames
using HypothesisTests
using Distributions

const REJECTION_LIMIT=.05

df = let 
    f = datadir() |> 
        readdir |> 
        x-> filter(x) do f endswith(f, ".tsv") end |> 
        x-> x[1]
    open( joinpath(datadir(), f)) do io
        data, headers =  DelimitedFiles.readdlm(
            io,
            '\t',
            header=true,
            String
        )
    end 

    headers = headers[2:end]
    function better_header(head)
        s = ""
        if startswith(head, "Rot")
            s*="r"
        else
            s*="g"
        end

        i = findfirst(==(','), head) +2
        s *= head[i]
    end
    headers = better_header.(headers)

    data = data[:, 2:end]
    data = map(data) do x 
        replace(x,  ','=>'.')
    end
    data = map(data) do x parse(Float64, x) end

    tmp = [ h => data[:, i] for (i, h) in enumerate(headers)]
    DataFrame(tmp...)
end



function statistic_test(x, y; rejection_limit=0.05)
    # H₀: x & y are both equivalently meassured
    x̄, ȳ = mean(x), mean(y) # mean value
    sx, sy = std(x), std(y) # standard deviation
    @debug "" (x̄, sx) (ȳ, sy)

    @assert (length(x) == length(y)) "Same size of the vectors is required"
    N = length(x)
    t = sqrt(N/(sx^2 + sy^2)) * (x̄-ȳ)
    @debug "t" (t)

    df = let 
        sx_ = sx^2/N 
        sy_ = sy^2/N 

        (sx_ + sy_)^2 /(sx_^2/(N-1) + sy_^2/(N-1))
    end # Welch-Satterthwaite approximation
    @debug "" df
    student = TDist(df) # Student T distribution

    p = 2*ccdf(student, abs(t)) # more numberically stable than 1-cdf(...)
    @debug "p" (p)
    if p > rejection_limit
        @info "H₀ is not rejected"
        true
    else
        @info "H₀ is rejected"
        false
    end
end

testing_pairs = [("rd", "ra"), ("gd", "ga")]
vs = [ 
    statistic_test(df[!, h1], df[!, h2], rejection_limit=REJECTION_LIMIT)
    for (h1, h2) in testing_pairs
]

if all(vs)
    println("TRUE:: null hypothesis cannot be rejected")
else
    println("FALSE:null hypothesis rejected")
end



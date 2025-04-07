using Plots, Distributions

λ = 40		# Bq; expected value
p = Poisson(λ)
# 1 - P(X >= 50) = 1 - cdf(50) = ccdf(49)
# ccdf(x) := P(X > x)
println(ccdf(p, 49))

k = 0:80 		# plot range
ps = pdf.([p], k)

pl = plot(k, ps, title="Zerfälle pro Sekunde", legend=false, color=:black)

# Plot Area under the curve for k >= 50
highlight_range = 50:k[end]
plot!(pl, highlight_range, pdf.([p], highlight_range), fillalpha=.3, fillrange=0)

# Save plot
savefig(pl, "poisson.png")

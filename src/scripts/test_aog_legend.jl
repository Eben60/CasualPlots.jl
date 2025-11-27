using AlgebraOfGraphics
using CairoMakie
using DataFrames

x = 1:10
y = x.^2
df = DataFrame(x=x, y=y, group="1")

plt = data(df) * mapping(:x, :y, color=:group => "") * visual(Scatter)
fg = draw(plt; legend=(show=true, ))

save("test_legend_1.png", fg)

fg2 = draw(plt; legend=(show=false, ))
save("test_legend_2.png", fg2)

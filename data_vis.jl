using CSV
using DataFrames
using CairoMakie
using Dates

function data_vis_histogramm(date, time, max_power, min_power, fig, ax_x, ax_y)
    dt = date .+ time
    power = max_power .+ min_power

    tpl = [(dt[i], power[i]) for i in eachindex(power)]

    dt = Dates.Year(2023):Year(1):Dates.Year(2025)

    print(dt)
end

function data_vis_heatmap(date, time, max_power, min_power, fig, row, col)

    nr_of_rows = 24 * 4 # one row for each datapoint per day

    pos_lin = max_power .- min_power
    pos = reshape(pos_lin, nr_of_rows, :)

    ax_1 = Axis(fig[row, col])
    ax_1.title = "Heatmap"
    ax_1.ylabel = "Tageszeit"
    ax_1.xlabel = "Tag"

    hmap = heatmap!(ax_1, pos', colormap=:seismic, colorrange=(-1, 1) .* maximum(abs, pos))
    Colorbar(fig[row, col+1], hmap; label="Leistung in MW", width=15, ticksize=15, tickalign=1)
    #lines!(ax_2,dt_lin,pos_lin)
    return fig
end

function data_vis_linegraph(date, time, max_power, min_power, fig, row, col)

    pos_lin = max_power .- min_power
    dt = date .+ time

    print(fig)
    print(row)
    print(col)

    ax_1 = Axis(fig[row, col])
    ax_1.title = "Linegraph"
    ax_1.ylabel = "Leistung in MW"
    ax_1.xlabel = "Datum"
    lines!(ax_1, dt, pos_lin)
    return fig
end

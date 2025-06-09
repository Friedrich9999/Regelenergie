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

function data_vis_heatmap(dates, power)

    fig = Figure()

    nr_of_rows = 24 * 4 # one row for each datapoint per day

    yticks = [0, 3, 6, 9, 12, 15, 18, 21, 24] .* 4
    ylabels = ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00", "24:00"]

    pos = reshape(power, nr_of_rows, :)

    xticks = []
    xlabels = []

    print(size(pos))
    day_one = Date(dates[1])
    # print("$day_one, ")
    for i in range(1, size(pos)[2])
        if Day(day_one + Day(i)) == Day(1) && Month(day_one + Day(i)) in [Month(6), Month(12)]
            push!(xticks, i)
            push!(xlabels, Dates.format.(day_one + Day(i), "mm.yyyy"))
            # print("$(Dates.format.(day_one + Day(i), "mm.yyyy")), ")
        end
        #print("$(typeof(Day(day_one + Day(i)))),")
    end
    print(xlabels)

    ax_1 = Axis(fig[1, 1])
    ax_1.title = "Heatmap"
    ax_1.ylabel = "Tageszeit"
    ax_1.xlabel = "Tag"
    hmap = heatmap!(ax_1, pos', colormap=:seismic, colorrange=(-1, 1) .* maximum(abs, pos))
    ax_1.yticks = (yticks, ylabels)
    ax_1.xticks = (xticks, xlabels)
    Colorbar(fig[1, 2], hmap; label="Leistung in MW", width=15, ticksize=15, tickalign=1)
    #lines!(ax_2,dt_lin,pos_lin)
    return fig, ax_1
end

function data_vis_linegraph(x, power, fig, row, col)

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

function data_vis_day(x, y, fig, row, col, ax_1)
    #ax_1 = Axis(fig[row, col])
    ax_1.ylabel = "Leistung in MW"
    ax_1.xlabel = "Tageszeit"

    lines!(ax_1, x, y)
    return fig, ax_1
end

function data_vis_year(x, y, fig, row, col, ax_1, label)
    #ax_1 = Axis(fig[row, col])

    # Plot using the transformed date format on the x-axis
    lines!(ax_1, x, y, label=label)
    return fig, ax_1
end
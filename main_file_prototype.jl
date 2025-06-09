using CairoMakie

include("data_vis.jl")
include("modify_data.jl")
include("components.jl")
include("load_from_db.jl")


years = ["2022", "2023", "2024", "2025"]
days = ["01-01", "04-01", "06-01", "10-01"]
regions = ["50Hertz", "Amprion", "TenneT TSO", "TransnetBW", "Deutschland"]
leistungsarten = ["Primärregelleistung", "Sekundärregelleistung", "Tertiärregelleistung"]

# visualisierung der regelleistung an spezifischen tagen


for y in years
    for d in days
        for region in regions
            for leistungsart in leistungsarten
                # get the date in dd.mm.yyyy format from yyyy-mm-dd format
                date = get_date_format("$y-$d")

                # get your data
                df = get_day(region, "$leistungsart, Windleistung, Solarleistung", "$y-$d")
                dates = df[!, "date"]
                power = df[!, "$leistungsart"]
                power_wind = df[!, "Windleistung"]
                power_solar = df[!, "Solarleistung"]

                # skip is there is no data at the date
                if typeof(power) == Vector{Missing}
                    continue
                end

                # kreiere die figur
                fig = Figure()
                ax_1 = Axis(fig[1, 1])
                ax_1.ylabel = "Leistung in MW"
                ax_1.xlabel = "Tageszeit"

                # zeichne eine kurve
                fig, ax_1 = data_vis_day(dates, power, fig, 1, 1, ax_1)
                fig, ax_1 = data_vis_day(dates, power_wind, fig, 1, 1, ax_1)
                fig, ax_1 = data_vis_day(dates, power_solar, fig, 1, 1, ax_1)

                ax_1.title = "Sekundärregelleistung in MW am $date"
                save_figure("test/grafiken/Sekundärregelleistung/$region/tages_werte/tages_werte_$region-$y-$d.svg", fig)
            end
        end
    end
end

for region in regions
    for y in years
        fig = Figure()
        ax_1 = Axis(fig[1, 1])
        ax_1.ylabel = "Leistung in MW"
        ax_1.xlabel = "Datum"
        ax_1.title = "Sekundärregelleistung $region"
        queuery = "SELECT * FROM Sekundärregelleistung WHERE date LIKE '%$y%'"#
        df = load_db_data(queuery)
        df = average_over_day(df)
        dates = df[!, "date"]
        positive_power = df[!, Symbol("max_power_$region", "_sum")]
        negative_power = df[!, Symbol("min_power_$region", "_sum")]
        power = positive_power .- negative_power

        fig, ax_1 = data_vis_year(dates, power, fig, 1, 1, ax_1, y)
        save_figure("grafiken/Sekundärregelleistung/$region/durchschnittliche tagesleistung $region-$y.svg", fig)
    end
end


leistungsarten = ["Windleistung", "Solarleistung", "Primärregelleistung", "Sekundärregelleistung", "Tertiärregelleistung"]
for region in regions
    for leistungsart in leistungsarten
        # get your data
        df = get_day(region, leistungsart, "any")
        dates = df[!, "date"]
        power = df[!, "$leistungsart"]

        fig, ax1 = data_vis_heatmap(dates, power)

        ax1.title = "Heatmap $leistungsart $region"
        ax1.ylabel = "Tageszeit"
        ax1.xlabel = "Datum"
        save_figure("grafiken/$region/Heatmap_$leistungsart.png", fig)

    end
end
# queuery = "SELECT date, Solarleistung FROM [50Hertz]"
# df = load_db_data(queuery)
# dt = df[!, "date"]
# power = df[!, "Solarleistung"]
# 
# df

##Heatmap
for leistungsart in leistungsarten
    for region in regions
        if region == "deutschland"
            continue
        end
        dates_wind = wind_avg[!, "date"]
        leistung_wind = wind_avg[!, Symbol("leistung$region", "_sum")]
        leistung_solar = solar_avg[!, Symbol("leistung$region", "_sum")]
        leistung_renewable = leistung_wind .+ leistung_solar

        fig = Figure(size=(1920, 1080))
        ax_1 = Axis(fig[1, 1])
        ax_1.ylabel = "Leistung in MW"
        ax_1.xlabel = "Datum"
        ax_1.title = "durchschnittliche $leistungsart $region"
        queuery = "SELECT * FROM $leistungsart"
        df = load_db_data(queuery)
        df[!, "power_$region"] = df[!, "max_power_$region"] .- df[!, "min_power_$region"]
        select!(df, ["date", "min_power_$region", "max_power_$region", "power_$region"])

        df_avg = average_over_week(df)
        dates_avg = df_avg[!, "date"]
        power_avg = df_avg[!, Symbol("power_$region", "_sum")]
        power_avg_min = df_avg[!, Symbol("min_power_$region", "_sum")] .* -1
        power_avg_max = df_avg[!, Symbol("max_power_$region", "_sum")]

        df_min = min_over_week(df)
        dates_min = df_min[!, "date"]
        power_min = df_min[!, Symbol("power_$region", "_min")]

        df_max = max_over_week(df)
        dates_max = df_max[!, "date"]
        power_max = df_max[!, Symbol("power_$region", "_sum")]

        df_std = std_over_week(df)
        dates_std = df_std[!, "date"]
        power_std = df_std[!, Symbol("power_$region", "_sum")]

        fig, ax_1 = data_vis_year(dates_avg, power_avg, fig, 1, 1, ax_1, "Average")
        fig, ax_1 = data_vis_year(dates_avg, power_avg_min, fig, 1, 1, ax_1, "Negiative Power Average")
        fig, ax_1 = data_vis_year(dates_avg, power_avg_max, fig, 1, 1, ax_1, "Positive Power Average")
        fig, ax_1 = data_vis_year(dates_std, power_avg .+ power_std, fig, 1, 1, ax_1, "Standard deviation")
        fig, ax_1 = data_vis_year(dates_std, power_avg .- power_std, fig, 1, 1, ax_1, "Standard deviation")
        fig, ax_1 = data_vis_year(dates_min, power_min, fig, 1, 1, ax_1, "Minimum")
        fig, ax_1 = data_vis_year(dates_max, power_max, fig, 1, 1, ax_1, "Maximum")

        ax_2 = fig[1, 1] = Axis(fig, ylabel="Leistung Erneuerbare")
        fig, ax_2 = data_vis_year(dates_wind, leistung_wind, fig, 1, 1, ax_2, "Average Wind")
        fig, ax_2 = data_vis_year(dates_wind, leistung_solar, fig, 1, 1, ax_2, "Average Solar")
        fig, ax_2 = data_vis_year(dates_wind, leistung_renewable, fig, 1, 1, ax_2, "Average Renewable")
        ax_2.yaxisposition = :right
        #ax2.yticklabelalign = (:left, :center)
        ax_2.xticklabelsvisible = false
        #ax2.xticklabelsvisible = false
        ax_2.xlabelvisible = false
        axislegend(position=:lb)
        save_figure("grafiken/$leistungsart/$region/durchschnittliche Wochenregelleistung $region-2022-2025.svg", fig)
    end
end

for region in regions
    fig = Figure()
    ax_1 = Axis(fig[1, 1])
    ax_1.ylabel = "Leistung in MW"
    ax_1.xlabel = "Datum"
    ax_1.title = "Sekundärregelleistung $region"
    queuery = "SELECT * FROM Sekundärregelleistung"#
    df = load_db_data(queuery)
    df = average_over_day(df)
    dates = df[!, "date"]
    positive_power = df[!, Symbol("max_power_$region", "_sum")]
    negative_power = df[!, Symbol("min_power_$region", "_sum")]
    power = positive_power .- negative_power

    fig, ax_1 = data_vis_year(dates, power, fig, 1, 1, ax_1, "regelleistung")
    save_figure("grafiken/Sekundärregelleistung/$region/durchschnittliche tagesleistung $region-2022-2025.svg", fig)
end

tables = ["Windproduktion", "Solarproduktion"]
regions = ["50hz", "amprion", "tennet", "transnetBW"]

for t in tables
    for y in years
        for d in days
            queuery = "SELECT * FROM $t WHERE date LIKE '%$y-$d%'"#
            df = load_db_data(queuery)
            for region in regions
                dates = df[!, "date"]
                power = df[!, "leistung$region"]

                fig = Figure()
                dates = Time.(dates)
                fig, ax_1 = data_vis_day(dates, power, fig, 1, 1)

                date = "$y-$d"
                date = Date(DateTime("$y-$d", "yyyy-mm-dd"))
                date = Dates.format(date, "dd.mm.yyyy")

                ax_1.title = "Leistung in MW am $date"
                save_figure("grafiken/$t/$region/tages_leistung_$region-$y-$d.svg", fig)
            end
        end
    end
end


queuery = "SELECT * FROM Windproduktion WHERE date LIKE '%2022%'"#
df = load_db_data(queuery)
df = sum_over_day(df)

for t in tables
    for region in regions

        for y in years
            fig = Figure()
            ax_1 = Axis(fig[1, 1])
            ax_1.ylabel = "Leistung in MW"
            ax_1.xlabel = "Datum"
            ax_1.title = "$t Leistung"
            queuery = "SELECT * FROM $t WHERE date LIKE '%$y%'"#
            df = load_db_data(queuery)
            df = sum_over_day(df)
            dates = df[!, "date"]
            power = df[!, Symbol("leistung$region", "_sum")]

            fig, ax_1 = data_vis_year(dates, power, fig, 1, 1, ax_1, y)
            date = "$y"
            date = Date(DateTime("$y", "yyyy-mm-dd"))
            date = Dates.format(date, "dd.mm.yyyy")
            #axislegend()
            save_figure("grafiken/$t/$region/tages_leistung_summe_$region-$y.svg", fig)
        end
    end
end

for t in tables
    queuery = "SELECT * FROM $t"#
    df = load_db_data(queuery)
    df = sum_over_day(df)
    for region in regions
        dates = df[!, "date"]
        power = df[!, Symbol("leistung$region", "_sum")]

        fig = Figure()
        fig, ax_1 = data_vis_day(dates, power, fig, 1, 1)
        ax_1.ylabel = "Leistung in MW"
        ax_1.xlabel = "Datum"
        ax_1.title = "Leistung in MW 2022 - 2025"
        save_figure("grafiken/$t/$region/tages_leistung_summe_$region-2022-2025.svg", fig)
    end
end
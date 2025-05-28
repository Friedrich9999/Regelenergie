using CairoMakie

include("data_vis.jl")
include("load_from_db.jl")
include("modify_data.jl")

years = ["2022", "2023", "2024", "2025"]
days = ["01-01", "04-01", "06-01", "10-01"]
regions = ["50hz", "amprion", "tennet", "transnetBW", "deutschland"]


for i in regions
    if !isdir("grafiken/Sekundärregelleistung/$i")
        # Create the directory
        mkdir("grafiken/Sekundärregelleistung/$i")
    end
    if !isdir("grafiken/Sekundärregelleistung/$i/tages_werte")
        # Create the directory
        mkdir("grafiken/Sekundärregelleistung/$i/tages_werte")
    end
end

# visualisierung der regelleistung an spezifischen tagen

for y in years
    for d in days
        queuery = "SELECT * FROM Sekundärregelleistung WHERE date LIKE '%$y-$d%'"#
        df = load_db_data(queuery)
        for region in regions
            dates = df[!, "date"]
            positive_power = df[!, "max_power_$region"]
            negative_power = df[!, "min_power_$region"]
            power = positive_power .- negative_power

            fig = Figure()
            ax_1 = Axis(fig[1, 1])
            ax_1.ylabel = "Leistung in MW"
            ax_1.xlabel = "Tageszeit"

            fig, ax_1 = data_vis_day(dates, power, fig, 1, 1, ax_1)

            date = "$y-$d"
            date = Date(DateTime("$y-$d", "yyyy-mm-dd"))
            date = Dates.format(date, "dd.mm.yyyy")

            ax_1.title = "Sekundärregelleistung in MW am $date"
            save("grafiken/Sekundärregelleistung/$region/tages_werte/tages_werte_$region-$y-$d.svg", fig)
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
        save("grafiken/Sekundärregelleistung/$region/durchschnittliche tagesleistung $region-$y.svg", fig)
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
    save("grafiken/Sekundärregelleistung/$region/durchschnittliche tagesleistung $region-2022-2025.svg", fig)
end

tables = ["Windproduktion", "Solarproduktion"]
regions = ["50hz", "amprion", "tennet", "transnetBW"]
for t in tables
    if !isdir("grafiken/$t")
        # Create the directory
        mkdir("grafiken/$t")
    end
    for i in regions
        if !isdir("grafiken/$t/$i")
            # Create the directory
            mkdir("grafiken/$t/$i")
        end
    end
end

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
                save("grafiken/$t/$region/tages_leistung_$region-$y-$d.svg", fig)
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
            save("grafiken/$t/$region/tages_leistung_summe_$region-$y.svg", fig)
        end
    end
end


;
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
        save("grafiken/$t/$region/tages_leistung_summe_$region-2022-2025.svg", fig)
    end
end
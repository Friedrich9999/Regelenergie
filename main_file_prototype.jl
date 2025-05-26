using CairoMakie
include("data_vis.jl")
#include("load_data.jl")
include("load_data_api.jl")

## define constants
netze = ["50hz", "amprion", "tennet", "transnetBW", "deutschland"]
data = ["nrvsaldo/AktivierteSRL"]
times = [["2022", "2022"], ["2023", "2023"], ["2024", "2024"], ["2022", "2025"]]
product = "Qualitaetsgesichert"

png_names = ["2022", "2022-2025", "2023", "2024"]

## define data frame
data_frames = Dict()

## get authentication token
token = get_token()

## get data
for d in data
    for t in times
        start_year = t[1]
        end_year = t[2]
        start_time = "$start_year-01-01"
        end_time = "$end_year-12-31"

        data_frames["$d $start_time $end_time"] = load_data(token, d, product, start_time, end_time)

    end
end

i = 0
data_frames
for key in eachindex(data_frames)
    i += 1
    if !isdir("grafiken/Sekundärregelleistung/")
        # Create the directory
        mkdir("grafiken/Sekundärregelleistung/")
    end
    for netz in netze
        app = png_names[i]
        df = data_frames[key]
        ##Heatmap
        fig = Figure(size=(5000, 2000))
        time = df[!, "time"]
        fig = data_vis_heatmap(df[!, "date"], df[!, "time"], df[!, "max_power_$netz"], df[!, "min_power_$netz"], fig, 1, 1)
        save("grafiken/Sekundärregelleistung/Heatmap$app $netz.png", fig)
    end
end

data_frames[regelleistungen[1]] = load_data("Daten/k-Delta f qualitaetsgesichert.csv")
data_frames[regelleistungen[2]] = load_data("Daten/Aktivierte aFRR qualitaetsgesichert [2025-05-03 11-12-05].csv")
data_frames[regelleistungen[3]] = load_data("Daten/Aktivierte mFRR qualitaetsgesichert [2025-05-03 11-12-36].csv")

for key in regelleistungen
    if !isdir("grafiken/$key")
        # Create the directory
        mkdir("grafiken/$key")
    end
    for netz in netze
        df = data_frames[key]
        ##Heatmap
        fig = Figure(size=(5000, 2000))
        time = df[!, "time"]
        print(first(time))
        print(last(time))
        fig = data_vis_heatmap(df[!, "date"], df[!, "time"], df[!, "max_power_$netz"], df[!, "min_power_$netz"], fig, 1, 1)
        save("grafiken/$key/Heatmap_$netz.png", fig)
    end
end

#draw plots into figure
fig = data_vis_heatmap(date_prl, time_prl, max_power_prl, min_power_prl, fig, 1, 1)
fig = data_vis_linegraph(date_prl, time_prl, max_power_prl, min_power_prl, fig, 1, 3)
fig = data_vis_heatmap(date_srl, time_srl, max_power_srl, min_power_srl, fig, 2, 1)
fig = data_vis_linegraph(date_srl, time_srl, max_power_srl, min_power_srl, fig, 2, 3)
fig = data_vis_heatmap(date_trl, time_trl, max_power_trl, min_power_trl, fig, 3, 1)
fig = data_vis_linegraph(date_trl, time_trl, max_power_trl, min_power_trl, fig, 3, 3)

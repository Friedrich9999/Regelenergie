## This is no longer used

using CairoMakie
include("data_vis.jl")
#include("load_data.jl")
include("load_data_api.jl")

## define constants
netze = ["50hz", "amprion", "tennet", "transnetBW", "deutschland"]
regelleistungen = ["Primärregelleistung", "Sekundärregelleistung", "Tertiärregelleistung"]

## define data frame
data_frames = Dict()

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

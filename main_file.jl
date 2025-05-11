using CairoMakie
include("data_vis.jl")
include("load_data.jl")

fig = Figure(size = (5000,2000))


date_prl, time_prl, max_power_prl, min_power_prl = load_data("Daten/k-Delta f qualitaetsgesichert.csv")
date_srl, time_srl, max_power_srl, min_power_srl = load_data("Daten/Aktivierte aFRR qualitaetsgesichert [2025-05-03 11-12-05].csv")
date_trl, time_trl, max_power_trl, min_power_trl = load_data("Daten/Aktivierte mFRR qualitaetsgesichert [2025-05-03 11-12-36].csv")

#draw plots into figure
fig = data_vis_heatmap(date_prl,time_prl,max_power_prl,min_power_prl,fig,1,1)
fig = data_vis_linegraph(date_prl,time_prl,max_power_prl,min_power_prl,fig,1,3)
fig = data_vis_heatmap(date_srl,time_srl,max_power_srl,min_power_srl,fig,2,1)
fig = data_vis_linegraph(date_srl,time_srl,max_power_srl,min_power_srl,fig,2,3)
fig = data_vis_heatmap(date_trl,time_trl,max_power_trl,min_power_trl,fig,3,1)
fig = data_vis_linegraph(date_trl,time_trl,max_power_trl,min_power_trl,fig,3,3)

#save figure
save("test.png", fig)
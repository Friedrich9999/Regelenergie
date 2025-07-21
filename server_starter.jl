import Pkg

Pkg.activate("regel_energie_venv/")

using Genie, Genie.Renderer.Json, Genie.Requests, Genie.Router, Genie.Renderer.Html
#using HTTP
#using JSONTables
using JSON

import Genie.Renderer.Json: json

open("data_gaps.json", "r") do f
    global data_gaps
    data_gaps = JSON.parse(f)
end

open("config.json", "r") do f
    global config_data
    config_data = JSON.parse(f)
end

#using SolutionsController
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = config_data["front_end_ip"]
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

include("load_from_db.jl")

#Genie.config.run_as_server = true

route("/line", method=POST) do
    # Parse the JSON body
    payload = jsonpayload()

    print(payload)

    # Extract the parameters    
    start_date = payload["startDate"]
    end_date = payload["endDate"]
    regions = payload["regions"]
    data_types = payload["dataTypes"]

    qs_selection = ""
    for r in regions
        for t in data_types
            qs_selection *= """, [$r].$t AS "$t $r" """
        end
    end

    qs_join = ""
    for r in regions
        if r == "Deutschland"
            continue
        end
        qs_join *= "INNER JOIN [$r] ON [$r].date = Deutschland.date "
    end

    query = """ SELECT [Deutschland].date $qs_selection FROM Deutschland $qs_join WHERE [Deutschland].date BETWEEN '$start_date' AND '$end_date' ORDER BY [Deutschland].date ASC"""

    df = load_db_data_no_mod(query)

    print("StartDate: $start_date\nEndDate: $end_date\nRegions:$regions\ndata_types: $data_types\n\n")

    df_arr = []
    header = names(df)
    popfirst!(header)
    for h in header
        if header == "Datum" || header == "date"
            continue
        end
        id = occursin("Wind", h) || occursin("Solar", h) ? 1 : 0
        obj = Dict(
            "name" => h,
            "type" => "line",
            "symbol" => "none",
            "sampling" => "lttb",
            "data" => df[!, h],
            "yAxisIndex" => id,
            "markArea" => Dict(
                "itemStyle" => Dict("color" => "rgba(255, 173, 177, 0.4)"),
                "data" => data_gaps[h]
                )
        )
        push!(df_arr, obj)
    end
    return JSON.json(Dict("type" => "line", "status" => "success", "xAxis" => df[!, "date"], "yAxis" => df_arr, "legend" => header))
end


route("/heatmap", method=POST) do
    print("getting heatmap post")
    # Parse the JSON body
    payload = jsonpayload()

    print(payload)

    # Extract the parameters    
    start_date = payload["startDate"]
    end_date = payload["endDate"]
    regions = payload["regions"][1]
    data_types = payload["dataTypes"][1]

    query = "SELECT date, $(data_types) From [$(regions)] WHERE date BETWEEN '$start_date' AND '$end_date' "
    df = load_db_data(query)

    datetimes = df[!, "date"]
    power = df[!, "$(data_types)"]

    dates = Date.(datetimes)
    times = Time.(datetimes)

    new_df = DataFrame("Datum" => dates, "Zeit" => times, "$(data_types)" => power)

    dates = sort(collect(Set(datepart for datepart in Dates.Date.(DateTime.(datetimes)))))
    times = sort(collect(Set(datepart for datepart in Dates.Time.(DateTime.(datetimes)))))

    col = collect(eachrow(Matrix(new_df)))

    max = maximum(abs.(filter(x -> typeof(x) != Missing, power)))
    print("maximum $max")

    dict = Dict("type" => "heatmap","chartName" => occursin("regel", data_types) ? "Abgerufene $data_types in $regions in MW" : "$data_types in $regions in MW", "seriesName" => data_types, "xAxis" => dates, "yAxis" => times, "data" => col, "min" => -max, "max" => max)

    return JSON.json(dict)
end

route("/data", method=GET) do
    print("test")
    return JSON.json(Dict("type" => "data", "status" => "success", "message" => "Data received successfully"))
end

up(async=false)

import Pkg

Pkg.activate("regel_energie_venv/")

using Genie, Genie.Renderer.Json, Genie.Requests
using HTTP
using JSONTables
using JSON

import Genie.Renderer.Json: json


#using SolutionsController
Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "http://localhost:5173"
# This has to be this way - you should not include ".../*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

include("load_from_db.jl")

#Genie.config.run_as_server = true

route("/line/:start_date/:end_date") do
    df = load_db_data("SELECT date, Primärregelleistung From [50Hertz] WHERE date BETWEEN $(payload(:start_date)) AND $(payload(:end_date))")
    json_data = objecttable(df)
    return json_data
end

route("/heatmap/:start_date/:end_date") do
    query = "SELECT date, Primärregelleistung From [50Hertz] WHERE date BETWEEN $(payload(:start_date)) AND $(payload(:end_date))"
    df = load_db_data(query)
    print(df)
    dt = df[!, "date"]
    power = df[!, "Primärregelleistung"]

    nr_of_rows = 24 * 4 # one row for each datapoint per day
    data = reshape(power, nr_of_rows, :)

    dates = Set(datepart for datepart in Dates.Date.(DateTime.(dt)))
    times = Set(datepart for datepart in Dates.Time.(DateTime.(dt)))

    col = collect(eachrow(data))
    dict = Dict("xAxis" => dates, "yAxis" => times, "data" => col)
    json_array = JSON.json(dict)
    return json_array
end


route("/data", method=GET) do
    json_data = objecttable(df)
    return json_data
end

up(async=false)
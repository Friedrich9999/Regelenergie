import Pkg

Pkg.activate("regel_energie_venv/")

using HTTP
using JSONTables
using JSON

include("load_from_db.jl")

file_path = "config.json"

open(file_path, "r") do f
    global config_data
    config_data = JSON.parse(f)
end

regions = config_data["regions"]

data_gap_file_path = "data_gaps.json"
data_gap_dict = Dict()

for region in regions
    query = " SELECT * FROM [$region] ORDER BY date ASC"

    df = load_db_data_no_mod(query)

    header = names(df)
    popfirst!(header)

    for h in header
        data = df[!, h]
        vector_sie = length(data)

        data_gap_beginning = -1

        data_arr = []

        for i in range(1, vector_sie)
            if typeof(data[i]) == Missing
                if i == 1 || typeof(data[i-1]) != Missing
                    data_gap_beginning = i
                elseif i == vector_sie || typeof(data[i+1]) != Missing
                    gap_description = "Fehlende\nDaten"
                    start_date = df[data_gap_beginning, "date"]
                    end_date = df[i,"date"]
                    push!( data_arr, [Dict( "name" => gap_description, "xAxis" => start_date), Dict("xAxis" => end_date)] )
                    println("from $start_date to $end_date: $gap_description")
                    data_gap_beginning = -1
                end
            end
        end
        data_gap_dict["$h $region"] = data_arr
    end
end

open(data_gap_file_path,"w") do f
    write(f, JSON.json(data_gap_dict))
end


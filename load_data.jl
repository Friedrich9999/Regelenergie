using CSV
using DataFrames
using Dates

function parse_comma_float(s::AbstractString)
    # Replace the comma with a dot and parse as a Float64
    return parse(Float64, replace(s, "," => "."))
end

function parse_time(s::AbstractString)
    return Time(DateTime(s, "HH:MM"))
end

function load_data(path::String)
    df = CSV.read(path, delim=";", dateformat="dd.mm.yyyy", DataFrame)


    rename!(df, [:date, :time_zone, :time, :time_end, :unit, :max_power_50hz, :max_power_amprion, :max_power_tennet, :max_power_transnetBW, :max_power_deutschland, :min_power_50hz, :min_power_amprion, :min_power_tennet, :min_power_transnetBW, :min_power_deutschland])

    drop = [:time_zone, :time_end, :unit]
    select!(df, Not(drop))

    time = Array(df[:, 2])

    time = parse_time.(time)
    df[!, "time"] = time
    header = names(df)

    for i in range(3, 12)
        n = Array(df[:, i])
        h = header[i]
        n = parse_comma_float.(n)
        df[!, header[i]] = n
    end

    start = 1
    while time[start] != Time(DateTime("00:00", "HH:MM"))
        start += 1
    end

    e = length(time)
    while time[e] != Time(DateTime("23:45", "HH:MM"))
        e -= 1
    end

    print("genutzte werte von $start bis $e")

    df = df[start:e, :]

    return df
end

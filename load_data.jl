using CSV
using DataFrames
using CairoMakie
using Dates

function parse_comma_float(s::AbstractString)
    # Replace the comma with a dot and parse as a Float64
    return parse(Float64, replace(s, "," => "."))
end

function parse_time(s::AbstractString)
    return Time(DateTime(s, "HH:MM"))
end

## Load and clean Data from csv data use api later
function load_data(path::String)
    df = CSV.read(path,delim =";", dateformat= "dd.mm.yyyy",DataFrame)

    date = Array(df[:,1])
    time = Array(df[:,3])
    max_power = Array(df[:,10])
    min_power = Array(df[:,15])

    max_power = parse_comma_float.(max_power)
    min_power = parse_comma_float.(min_power)

    time = parse_time.(time)

    start = 1
    while time[start] != Time(DateTime("00:00", "HH:MM"))
        start += 1
    end

    e = length(time)
    while time[e] != Time(DateTime("23:45", "HH:MM"))
        e -= 1
    end
    
    date = date[start:e]
    time = time[start:e]
    max_power = max_power[start:e]
    min_power = min_power[start:e]
    
    return date, time, max_power, min_power

end
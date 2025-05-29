using DataFrames
using Dates
using Statistics

function sum_over_day(df::DataFrame)
    # convert date time to date only
    df.date = Date.(df.date)

    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => sum => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function average_over_day(df::DataFrame)
    # convert date time to date only
    df.date = Date.(df.date)

    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> sum(x) / length(x)) => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function sum_over_month(df::DataFrame)
    # convert date time to date only
    df.date = Date.(df.date) .- day.(df.date)

    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => sum => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function average_over_week(df::DataFrame)
    # convert date time to date only
    date = Date.(df.date)
    day_of_week = Day.(Dates.dayofweek.(df.date) .- 1)
    df.date = date .- day_of_week


    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> sum(x) / length(x)) => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function average_over_week(df::DataFrame)
    # convert date time to date only
    date = Date.(df.date)
    day_of_week = Day.(Dates.dayofweek.(df.date) .- 1)
    df.date = date .- day_of_week


    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> sum(x) / length(x)) => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function min_over_week(df::DataFrame)
    # convert date time to date only
    date = Date.(df.date)
    day_of_week = Day.(Dates.dayofweek.(df.date) .- 1)
    df.date = date .- day_of_week


    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> minimum(x)) => Symbol(col, "_min") for col in header]
    )
    return grouped_df
end

function max_over_week(df::DataFrame)
    # convert date time to date only
    date = Date.(df.date)
    day_of_week = Day.(Dates.dayofweek.(df.date) .- 1)
    df.date = date .- day_of_week


    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> maximum(x)) => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end

function std_over_week(df::DataFrame)
    # convert date time to date only
    date = Date.(df.date)
    day_of_week = Day.(Dates.dayofweek.(df.date) .- 1)
    df.date = date .- day_of_week


    header = Array(names(df))
    filter!(e -> e != "date", header)

    # Group by date and apply the sum
    grouped_df = combine(groupby(df, :date),
        [col => (x -> std(x)) => Symbol(col, "_sum") for col in header]
    )
    return grouped_df
end
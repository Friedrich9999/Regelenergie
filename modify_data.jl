using DataFrames
using Dates

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
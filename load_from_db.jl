using DataFrames
using Dates
using SQLite

## this script is used to load data from the Database

function get_date_from_String(s::AbstractString)
    return DateTime(s)
end

# load from data base
db = SQLite.DB("netztransparenz.db")
con = DBInterface

function load_db_data(queuery::String)

    df = DataFrame(con.execute(db, queuery))

    # get date in DateTime format
    dt = Array(df[:, 1])

    dt = get_date_from_String.(dt)
    df[!, "date"] = dt
    return df
end
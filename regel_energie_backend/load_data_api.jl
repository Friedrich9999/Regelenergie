using PyCall
using DataFrames
using Dates
using CSV
using SQLite
using JSON

## Define python Script
py"""
import requests

def get_token():
    client_id = 'cm_app_ntp_id_013b932add9243438c9c58411faa5e6d'
    secret = 'ntp_Eaxzj4SW7er1aeiXGsN8'
    access_token_url = 'https://identity.netztransparenz.de/users/connect/token'

    data = {"grant_type": "client_credentials"}

    response = requests.post(access_token_url, data=data, auth=(client_id, secret))

    print(response.json()["access_token"])

    TOKEN = response.json()["access_token"]

    return TOKEN

def get_data(TOKEN,PRODUCT,START,END):

    request_URL = "https://ds.netztransparenz.de/api/v1/data/{}/{}/{}".format(PRODUCT,START,END)
    response = requests.get(request_URL, headers = {'Authorization': 'Bearer {}'.format(TOKEN)})

    return response.text

"""

function parse_comma_float(s)
    # Replace the comma with a dot and parse as a Float64
    if ismissing(s)
        return 0.0
    end
    return s == "N.A." ? 0.0 : parse(Float64, replace(s, "," => "."))
end

function add_string_floats(positive_float, negative_float)
    positive_float = positive_float == "N.A." ? missing : parse(Float64, replace(positive_float, "," => "."))
    negative_float = negative_float == "N.A." ? missing : parse(Float64, replace(negative_float, "," => "."))
    return positive_float - negative_float
end

function parse_time(s::AbstractString)
    return Time(DateTime(s, "HH:MM"))
end

function get_token()
    return pycall(py"get_token", String)
end

file_path = "config.json"

open(file_path, "r") do f
    global config_data
    config_data = JSON.parse(f)
end

regelleistung = config_data["regelleistung"]
start_date = config_data["start_date"]
end_date = config_data["end_date"]
regions = config_data["regions"]

# Call the Python function from Julia
# get OAuth 2.0 Token
token = get_token()

db = SQLite.DB("regelenergie_daten.db")
con = DBInterface

for key in eachindex(regelleistung)

    # get the data from the api
    product = regelleistung[key]
    response = pycall(py"get_data", String, token, product, start_date, end_date)

    #create dataframe
    df = CSV.File(IOBuffer(response), delim=';', dateformat="dd.mm.yyyy") |> DataFrame

    ## create datetime object
    try
        time = Array(df[:, 3])
    catch e
        println("there was an error with the dataframe $e")
        println(df)
    end
    time = parse_time.(time) .+ Array(df[:, 1])

    # insert date time object
    df[!, "Datum"] = time

    # create dates
    dt = Array(df[:, 1])
    dt = Dates.format.(dt, "yyyy-mm-ddTHH:MM:SS")
    df[!, "Datum"] = dt

    for region in regions
        # get the headers
        header = names(df)
        # filter the header
        filter!((x) -> occursin(region, x) || occursin("Datum", x), header)

        # create data frame subset
        df_subset = select(df, header)
        header = names(df_subset)
        rename!(df_subset, ["date", "positive_$key", "negative_$key"])

        start = 1
        while Time(time[start]) != Time(DateTime("00:00", "HH:MM"))
            start += 1
        end

        e = length(time)
        while Time(time[e]) != Time(DateTime("23:45", "HH:MM"))
            e -= 1
        end

        df_subset = df_subset[start:e, :]
        # remove date from header
        header = names(df_subset)
        popfirst!(header)

        df_subset[!, key] = add_string_floats.(Array(df_subset[:, "positive_$key"]), Array(df_subset[:, "negative_$key"]))
        df_subset = select(df_subset, ["date", key])

        header = names(df_subset)
        popfirst!(header)

        ## Create SQLite Database
        SQLite.execute(db, "CREATE TABLE IF NOT EXISTS [$region](date TEXT PRIMARY KEY)")

        try
            SQLite.execute(db, "ALTER TABLE [$region] ADD COLUMN $key REAL")
        catch e
            print("Altering $region: $(string(e))\n")
        end

        SQLite.transaction(db) do
            for row in eachrow(df_subset)
                SQLite.execute(db, "INSERT OR IGNORE INTO [$region] (date) VALUES ('$(row["date"])');</")
                if typeof(row[2]) == Missing
                    continue
                else
                    SQLite.execute(
                        db,
                        "UPDATE [$region] SET $(key)='$(row[key])' WHERE date = '$(row["date"])'"
                    )
                end
            end
        end
    end
    print("finnished writing \n")
end


renewable_power = config_data["renewable_power"]
for key in eachindex(renewable_power)
    # get the data from the api
    product = renewable_power[key]
    response = pycall(py"get_data", String, token, product, start_date, end_date)

    #create dataframe
    df = CSV.File(IOBuffer(response), delim=';', dateformat="yyyy-mm-dd") |> DataFrame

    ## create datetime object
    time = Array(df[:, 2])
    time = parse_time.(time) .+ Array(df[:, 1])

    # insert date time object
    df[!, "Datum"] = time

    # create dates
    dt = Array(df[:, 1])
    dt = Dates.format.(dt, "yyyy-mm-ddTHH:MM:SS")
    df[!, "Datum"] = dt

    df

    header = names(df)
    # filter the header
    filter!((x) -> occursin("MW", x) || occursin("Datum", x), header)

    # create data frame subset
    df = select(df, header)


    # remove date from header
    header = names(df)
    popfirst!(header)

    for h in header
        n = Array(df[!, h])
        n = parse_comma_float.(n)
        df[!, h] = n
    end

    df


    for region in regions
        # get the headers
        header = names(df)
        # filter the header
        filter!((x) -> occursin(region, x) || occursin("Datum", x), header)

        # create data frame subset
        df_subset = select(df, header)

        df_subset

        if region == "Deutschland"
            df_subset[!, "Windleistung"] = Array(df[:, 2]) .+ Array(df[:, 3]) .+ Array(df[:, 4]) .+ Array(df[:, 5])
        end
        df_subset
        rename!(df_subset, ["date", "$key"])

        start = 1
        while Time(time[start]) != Time(DateTime("00:00", "HH:MM"))
            start += 1
        end

        e = length(time)
        while Time(time[e]) != Time(DateTime("23:45", "HH:MM"))
            e -= 1
        end

        df_subset = df_subset[start:e, :]


        ## Create SQLite Database
        SQLite.execute(db, "CREATE TABLE IF NOT EXISTS [$region](date TEXT PRIMARY KEY)")

        header = names(df_subset)
        popfirst!(header)

        header
        for h in header
            try
                SQLite.execute(db, "ALTER TABLE [$region] ADD COLUMN $h REAL")
            catch e
                print("Altering $region: $(string(e))\n")
            end
        end

        SQLite.transaction(db) do
            for row in eachrow(df_subset)
                val = row[2] < 0 ? 0 : row[2]
                SQLite.execute(db, "INSERT OR IGNORE INTO [$region] (date) VALUES ('$(row[1])');</")
                SQLite.execute(
                    db,
                    "UPDATE [$region] SET $(header[1])='$(val)' WHERE date = '$(row[1])'"
                )
            end
        end
    end

end

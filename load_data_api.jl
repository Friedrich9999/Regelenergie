using PyCall
using DataFrames
using Dates
using CSV
using SQLite

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

function parse_time(s::AbstractString)
    return Time(DateTime(s, "HH:MM"))
end

function get_token()
    return pycall(py"get_token", String)
end


data_dict = Dict("Primärregelleistung" => "nrvsaldo/PRL/Qualitaetsgesichert", "Sekundärregelleistung" => "nrvsaldo/AktivierteSRL/Qualitaetsgesichert", "Tertiärregelleistung" => "nrvsaldo/AktivierteMRL/Qualitaetsgesichert")
start_time = "2022-01-01"
end_time = "2025-12-31"
product = "Qualitaetsgesichert"

# Call the Python function from Julia
# get OAuth 2.0 Token
token = get_token()

for key in eachindex(data_dict)
    product = data_dict[key]
    print("loading data $data, from $start_time until $end_time")

    # get response
    response = pycall(py"get_data", String, token, product, start_time, end_time)

    #create dataframe
    df = CSV.File(IOBuffer(response), delim=';', dateformat="dd.mm.yyyy") |> DataFrame

    time = Array(df[:, 3])

    time = parse_time.(time) .+ Array(df[:, 1])

    drop = [:Zeitzone, :von, :bis, :Datenkategorie, :Datentyp, :Einheit]
    select!(df, Not(drop))

    rename!(df, [:date, :max_power_50hz, :max_power_amprion, :max_power_tennet, :max_power_transnetBW, :max_power_deutschland, :min_power_50hz, :min_power_amprion, :min_power_tennet, :min_power_transnetBW, :min_power_deutschland])

    df[!, "date"] = time

    df

    header = names(df)

    for i in range(2, 11)
        n = Array(df[:, i])
        h = header[i]
        n = parse_comma_float.(n)
        df[!, header[i]] = n
    end

    start = 1
    while Time(time[start]) != Time(DateTime("00:00", "HH:MM"))
        start += 1
    end

    e = length(time)
    while Time(time[e]) != Time(DateTime("23:45", "HH:MM"))
        e -= 1
    end

    print("genutzte werte von $start bis $e")

    df = df[start:e, :]

    content_string = "date TEXT"
    for i in header
        if i != "date"
            content_string *= ",$i REAL"
        end
    end

    dt = Array(df[:, 1])
    dt = Dates.format.(dt, "yyyy-mm-ddTHH:MM:SS")
    df[!, "date"] = dt


    content_string

    ## Create SQLite Database
    db = SQLite.DB("netztransparenz.db")
    con = DBInterface
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS $key($content_string)")
    SQLite.tables(db)
    SQLite.load!(df, db, "$key")
    df = DataFrame(con.execute(db, "SELECT * FROM $key"))
end


data_dict = Dict("Windproduktion" => "hochrechnung/Wind", "Solarproduktion" => "hochrechnung/Solar")

for key in eachindex(data_dict)
    product = data_dict[key]
    print("loading data $product, from $start_time until $end_time")

    # get response
    response = pycall(py"get_data", String, token, product, start_time, end_time)

    #create dataframe
    df = CSV.File(IOBuffer(response), delim=';', dateformat="yyyy-mm-dd") |> DataFrame

    time = Array(df[:, 2])

    time = parse_time.(time) .+ Array(df[:, 1])

    drop = [:Zeitzone_von, :von, :bis, :Zeitzone_bis]
    rename!(df, [:date, :von, :Zeitzone_von, :bis, :Zeitzone_bis, :leistung50hz, :leistungamprion, :leistungtennet, :leistungtransnetBW])
    select!(df, Not(drop))

    df[!, "date"] = time

    df

    df = coalesce.(df, "0,0")

    header = names(df)

    for i in range(2, 5)
        n = Array(df[:, i])
        h = header[i]
        n = parse_comma_float.(n)
        df[!, header[i]] = n
    end

    start = 1
    while Time(time[start]) != Time(DateTime("00:00", "HH:MM"))
        start += 1
    end

    e = length(time)
    while Time(time[e]) != Time(DateTime("23:45", "HH:MM"))
        e -= 1
    end

    print("genutzte werte von $start bis $e")

    df = df[start:e, :]

    content_string = "date TEXT"
    for i in header
        if i != "date"
            content_string *= ",$i REAL"
        end
    end

    dt = Array(df[:, 1])
    dt = Dates.format.(dt, "yyyy-mm-ddTHH:MM:SS")
    df[!, "date"] = dt


    content_string

    ## Create SQLite Database
    db = SQLite.DB("netztransparenz.db")
    con = DBInterface
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS $key($content_string)")
    SQLite.tables(db)
    SQLite.load!(df, db, "$key")
    df = DataFrame(con.execute(db, "SELECT * FROM $key"))
end
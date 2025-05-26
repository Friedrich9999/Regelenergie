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

def get_data(TOKEN, DATA, PRODUCT,START,END):
    client_id = 'cm_app_ntp_id_013b932add9243438c9c58411faa5e6d'
    secret = 'ntp_Eaxzj4SW7er1aeiXGsN8'
    access_token_url = 'https://identity.netztransparenz.de/users/connect/token'

    data = {"grant_type": "client_credentials"}

    response = requests.post(access_token_url, data=data, auth=(client_id, secret))

    print(response.json()["access_token"])

    TOKEN = response.json()["access_token"]

    request_URL = "https://ds.netztransparenz.de/api/v1/data/{}/{}/{}/{}".format(DATA,PRODUCT,START,END)
    response = requests.get(request_URL, headers = {'Authorization': 'Bearer {}'.format(TOKEN)})

    return response.text

"""

function parse_comma_float(s::AbstractString)
    # Replace the comma with a dot and parse as a Float64
    return parse(Float64, replace(s, "," => "."))
end

function parse_time(s::AbstractString)
    return Time(DateTime(s, "HH:MM"))
end

function get_token()
    return pycall(py"get_token", String)
end

function load_data(token, data, product, start_time, end_time)
    # Call the Python function from Julia
    # get OAuth2.0 Token

    # get response
    response = pycall(py"get_data", String, token, data, product, start_time, end_time)

    #create dataframe
    df = CSV.File(IOBuffer(response), delim=';', dateformat="dd.mm.yyyy") |> DataFrame

    drop = [:Zeitzone, :bis, :Datenkategorie, :Datentyp, :Einheit]
    select!(df, Not(drop))

    rename!(df, [:date, :time, :max_power_50hz, :max_power_amprion, :max_power_tennet, :max_power_transnetBW, :max_power_deutschland, :min_power_50hz, :min_power_amprion, :min_power_tennet, :min_power_transnetBW, :min_power_deutschland])

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


## Create SQLite Database
db = SQLite.DB("netztransparenz.db")
con = DBInterface
SQLite.execute(db, "CREATE TABLE IF NOT EXISTS test(type,year)")
SQLite.tables(db)
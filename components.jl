import CairoMakie
include("load_from_db.jl")

function save_figure(path::String, fig::Figure)
    s = ""
    parts = splitpath(path)
    pop!(parts)
    for p in parts
        s = "$s$p/"
        if !isdir(s)
            mkdir(s)
        end
    end
    save(path, fig)
end

function get_day(region::String, datensatz::String, date::String)
    queuery = date == "any" ? "SELECT date, $datensatz FROM [$region] WHERE $datensatz IS NOT NULL" : "SELECT date, $datensatz FROM [$region] WHERE date LIKE '%$date%' AND $datensatz IS NOT NULL"

    print("$queuery\n\n\n\n")

    return load_db_data(queuery)

end

function get_year()
end

function get_date_format(date::String)
    date = Date(DateTime(date, "yyyy-mm-dd"))
    date = Dates.format(date, "dd.mm.yyyy")
end
import CairoMakie

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
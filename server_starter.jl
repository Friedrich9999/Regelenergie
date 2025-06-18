import Pkg

Pkg.activate("regel_energie_venv/")

using Genie, Genie.Renderer.Json, Genie.Requests
using HTTP

import Genie.Renderer.Json: json

#Genie.config.run_as_server = true

route("/") do
    (:message => "Hi there!") |> json
end

route("/echo", method=POST) do
    message = jsonpayload()
    (:echo => (message["message"] * " ")^message["repeat"]) |> json
end


route("/send") do
    response = HTTP.request("POST", "http://localhost:8000/echo", [("Content-Type", "application/json")], """{"message":"hello", "repeat":3}""")

    response.body |> String |> json
end

up(async=false)

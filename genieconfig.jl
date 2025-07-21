import Pkg

Pkg.activate("regel_energie_venv/")

using Genie, Genie.Renderer.Json, Genie.Requests, Genie.Router, Genie.Renderer.Html
using HTTP
using JSONTables
using JSON

import Genie.Renderer.Json: json

Genie.Generator.newapp("regel_energie_backend")

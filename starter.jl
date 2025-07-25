import Pkg

Pkg.activate("regel_energie_venv/")

using Genie

Genie.loadapp("regel_energie_backend/")

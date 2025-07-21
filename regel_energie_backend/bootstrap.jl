(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using RegelEnergieBackend
const UserApp = RegelEnergieBackend
RegelEnergieBackend.main()

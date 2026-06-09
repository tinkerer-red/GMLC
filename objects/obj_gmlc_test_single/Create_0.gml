var env = new GMLC_Env()

env.clearFunctions()
env.clearConstants()
env.clearEnums()
env.clearMacros()
env.clearVariables()

env.set_exposure(GMLC_EXPOSURE.ALL)

function secret_function() {
	return "secret value"
}

var func = env.compile(@'
var glb = -5
var func = glb[$ "secret_function"]
return func()
')

show_message(func())
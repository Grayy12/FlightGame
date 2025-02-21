local Loader = {}
local CachedModules = {}

function Loader.Get(name: string)
	return CachedModules[name]
end

function Loader._Init(scripts: {ModuleScript})
	for _, modscript in scripts do
		if not modscript:IsA('ModuleScript') then continue end
		CachedModules[modscript.Name] = require(modscript)
	end
end

function Loader._Start()
	for _, mod in CachedModules do
		if mod.Start then
			task.spawn(mod.Start)
		end
	end
end

shared.Get = Loader.Get

return Loader

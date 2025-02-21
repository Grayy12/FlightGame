local CollectionService = game:GetService("CollectionService")

local Component = {}
local CachedInstances = {}

function load(input : {ModuleScript})
	for _, moduleScript in input do
		if not moduleScript:IsA("ModuleScript") then continue end
		local module = require(moduleScript)
		local thisTag = module.Tag

		local function instance_added(instance)
			CachedInstances[instance] = CachedInstances[instance] or {}
			local newInstance = module.new(instance)
			CachedInstances[instance][thisTag] = newInstance
		end

		local function instance_removed(instance)
			local components = CachedInstances[instance]

			for tag, component in components do
				if component.Destroy then
					component:Destroy()
				end
				components[tag] = nil
			end
		end

		for _, existing in CollectionService:GetTagged(thisTag) do
			instance_added(existing)
		end

		CollectionService:GetInstanceAddedSignal(thisTag):Connect(instance_added)
		CollectionService:GetInstanceRemovedSignal(thisTag):Connect(instance_removed)
	end
end

function Component.Load(components: any)
	if typeof(components) == "Instance" then
		load(components:GetChildren())
	elseif typeof(components) == "table" then
		load(components)
	end
end

function Component.GetComponents(instance: Instance)
	return CachedInstances[instance]
end

function Component.GetComponent(instance: Instance, tag: string)
	return CachedInstances[instance] and CachedInstances[instance][tag]
end

return Component


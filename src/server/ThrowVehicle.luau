local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Component) 

local ev_ThrowVehicle = ReplicatedStorage.Remote.ThrowVehicle

local ThrowVehicle = {}

function ThrowVehicle.Start()
	ev_ThrowVehicle.OnServerEvent:Connect(function(player: Player, direction: Vector3)
		local character = player.Character
		local heldVehicle = player:FindFirstChild("Held_Vehicle")
		
		if not player:GetAttribute("Holding_Vehicle") or not character or not heldVehicle then return end
		
		local car = Component.GetComponent(heldVehicle.Value, "Car")
		
		if not car then return end
		
		car:Throw(direction)
	end)
end


return ThrowVehicle

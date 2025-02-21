local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local ev_ThrowVehicle = game:GetService("ReplicatedStorage"):WaitForChild("Remote").ThrowVehicle

local connection

local ThrowCar = {}

function ThrowCar.Start()
	localPlayer:GetAttributeChangedSignal("Holding_Vehicle"):Connect(AttributeChanged)
	AttributeChanged()
end

function AttributeChanged()
	local holding = localPlayer:GetAttribute("Holding_Vehicle")
	local character = localPlayer.Character
	
	if not holding or not character then
		if connection then connection:Disconnect() end
		return
	end
	
	if connection then connection:Disconnect() end
	
	
	connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			ev_ThrowVehicle:FireServer((localPlayer:GetMouse().Hit.Position - character.PrimaryPart.Position).Unit)
			connection:Disconnect()
			connection = nil
		end
	end)
end

return ThrowCar

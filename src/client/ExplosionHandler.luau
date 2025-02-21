local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = {character}
overlapParams.MaxParts = 34

local ev_Landed: RemoteEvent = ReplicatedStorage:WaitForChild("Remote").Landed

local LandingHandler = {}

function LandingHandler.Start()
	localPlayer.CharacterAdded:Connect(CharacterAdded)
	CharacterAdded(character)
end

function CharacterAdded(newChar)
	character = newChar
	local humanoid: Humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function() end)
	--humanoid.StateChanged:Connect(Landing)
	
	
end

function SendExlposionObjects(position)
	overlapParams:AddToFilter(character)
	local parts = workspace:GetPartBoundsInRadius(position, 20, overlapParams)

	ev_Landed:FireServer(
		parts,
		position
	)
end

function Landing(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	if new == Enum.HumanoidStateType.Landed then
		SendExlposionObjects(character.PrimaryPart.Position)
	end
end


UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then return end
	
	if input.KeyCode == Enum.KeyCode.T then
		SendExlposionObjects(localPlayer:GetMouse().Hit.Position)
	end
end)

return LandingHandler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = { character }

local ev_Union: RemoteEvent = ReplicatedStorage:WaitForChild("Remote").Union

local Destruction = {}

function Destruction.Start()
	if true then return end
	localPlayer.CharacterAdded:Connect(function(newChar)
		character = newChar
		local humanoid: Humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function() end)
	end)

	RunService.RenderStepped:Connect(function()
		Destruction._Update()
	end)
end

local function checkDetection(root: BasePart)
	local rootVelocity = root.AssemblyLinearVelocity

	local ray: RaycastResult? = workspace:Spherecast(root.Position, 2, rootVelocity.Unit * 5, rayParams)

	if ray then
		local model = ray.Instance:FindFirstAncestorOfClass("Model")
		if model and Players:GetPlayerFromCharacter(model) then
			return false
		end

		return true, ray.Instance, ray.Position
	else
		return false
	end
end

function Destruction._Update()
	if not character then
		return
	end

	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local root: BasePart = character.PrimaryPart
	local rootVelocity = root.AssemblyLinearVelocity

	local detected, detectedPart, rayPosition = checkDetection(root)

	if detected and rootVelocity.Magnitude >= 10 then
		--print("Destroying", detectedPart)

		local otherParts = {}
		for i, v in character:GetDescendants() do
			if v:IsA("BasePart") then
				table.insert(otherParts, v)
			end
		end

		detectedPart.Color = Color3.new(1, 0, 0)
		ev_Union:FireServer(detectedPart, root, otherParts, rayPosition)
	end
end

return Destruction

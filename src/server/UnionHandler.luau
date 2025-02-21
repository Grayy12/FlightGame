local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ev_Union: RemoteEvent = ReplicatedStorage.Remote.Union

local Union = {}

local function convertMeshToPart(root: BasePart, meshes: { MeshPart }, rayPosition: Vector3)
	local newParts = {}
	for i, v: MeshPart in meshes do
		local newPart = Instance.new("Part")
		newPart.Size = v.Size * 3
		newPart.Transparency = 0.5
		newPart.CanCollide = false
		newPart.Anchored = true
		local offset = v.Position - root.Position
		newPart.CFrame = CFrame.new(rayPosition + offset)

		-- newPart.Parent = workspace
		table.insert(newParts, newPart)
	end

	return newParts
end

function Union.Start()
	ev_Union.OnServerEvent:Connect(function(player: Player, detectedPart: BasePart, root: BasePart, otherParts, rayPosition)
		local success, newUnion = pcall(function()
			return detectedPart:SubtractAsync(convertMeshToPart(root, otherParts, rayPosition))
		end)

		if success and newUnion then
			newUnion.Position = detectedPart.Position
			newUnion.Parent = workspace
			detectedPart.Parent = game.ServerStorage
			warn("Server:", "worked")
		else
			warn("Server:", "error", newUnion)
		end
	end)
end

return Union

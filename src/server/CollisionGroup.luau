local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local CollisionGroup = {}

function CollisionGroup.Start()
	Players.PlayerAdded:Connect(player_added)
	Players.PlayerRemoving:Connect(player_removed)
	
	for _, player in Players:GetPlayers() do
		player_added(player)
	end
end

function player_added(player: Player)
	local userid = tostring(player.UserId)
	
	if table.find(PhysicsService:GetRegisteredCollisionGroups(), userid) then return end
	
	PhysicsService:RegisterCollisionGroup(userid)
	PhysicsService:CollisionGroupSetCollidable(userid, userid, false)
	
	player.CharacterAdded:Connect(character_added)
	
	local char = player.Character
	
	if char then
		character_added(char)
	end
end

function character_added(character:Model)
	local player = Players:GetPlayerFromCharacter(character)
	local userid = tostring(player.UserId)
	
	for i, v in character:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = userid		
		end
	end
end

function player_removed(player: Player)
	local userid = tostring(player.UserId)
	PhysicsService:UnregisterCollisionGroup(userid)
end

return CollisionGroup

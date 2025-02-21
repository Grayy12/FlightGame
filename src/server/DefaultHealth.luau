local Players = game:GetService("Players")

local DefaultHealth = {}

function DefaultHealth.Start()
	for _, player in Players:GetPlayers() do
		SetDefaultHealth(player)
	end
	
	Players.PlayerAdded:Connect(function(player: Player)
		SetDefaultHealth(player)
	end)
end

function SetDefaultHealth(player: Player)
	local character = player.Character
	
	if character then
		character.Humanoid.MaxHealth = 1/0
		character.Humanoid.Health = 1/0
	end
	
	player.CharacterAdded:Connect(function(character: Model)
		character.Humanoid.MaxHealth = 1/0
		character.Humanoid.Health = 1/0
	end)
end

return DefaultHealth

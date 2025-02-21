local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ev_Landed: RemoteEvent = ReplicatedStorage.Remote.Landed
local ev_PlaySound: RemoteEvent = ReplicatedStorage.Remote.PlaySound

local explosionSound: Sound = ReplicatedStorage.Assets.Explosion

local ServerExplosion = {}

function ServerExplosion.Start()
	ev_Landed.OnServerEvent:Connect(ServerExplosion.Explode)
end

function ServerExplosion.Explode(player, parts, position)
	local soundPlayed = false
	for _, part:BasePart in parts do
		if part:HasTag("NoBoom") then continue end

		part.Anchored = false
		part.AssemblyLinearVelocity = (part.Position - position).Unit * 560
		local explo = Instance.new("Explosion", part)
		explo.BlastRadius = 30
		explo.BlastPressure = 50
		explo.Position = part.Position
		explo.DestroyJointRadiusPercent = 0

		if not soundPlayed then
			soundPlayed = true
			ev_PlaySound:FireAllClients(explosionSound, position, 1000)
		end

		game:GetService("Debris"):AddItem(part, 5)
	end

	if #parts == 0 then
		local explo = Instance.new("Explosion", workspace.Debris)
		explo.BlastRadius = 30
		explo.BlastPressure = 50
		explo.Position = position
		explo.DestroyJointRadiusPercent = 0
		ev_PlaySound:FireAllClients(explosionSound, position, 1000)
	end
end

return ServerExplosion

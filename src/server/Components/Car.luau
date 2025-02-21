local Explosion = require(game:GetService("ServerScriptService").Server.ServerExplosionHandler)

local Car = {
	Tag = "Car"
}

Car.__index = Car 

local THROW_STRENGTH = 450

function Car.new(instance: Model)
	local self = setmetatable({
		prompt = Instance.new("ProximityPrompt"),
		instance = instance,
		thrown = false
	}, Car)

	self:Init()

	return self
end

function Car:Init()
	local mainPart: BasePart = self.instance.PrimaryPart

	-- Setup ProximityPrompt
	self.prompt.Parent = mainPart
	self.prompt.KeyboardKeyCode = Enum.KeyCode.V
	self.prompt.ObjectText = self.instance.Name
	self.prompt.ActionText = "Pickup"
	self.prompt.HoldDuration = 0.25
	self.prompt.RequiresLineOfSight = false

	self.prompt.Triggered:Connect(function(player)
		local character = player.Character
		if player:GetAttribute("Holding_Vehicle") == true or not character then return end
		player:SetAttribute("Holding_Vehicle", true)

		local carValue = Instance.new("ObjectValue", player)
		carValue.Name = "Held_Vehicle"
		carValue.Value = self.instance
		self.carValue = carValue

		local hrp: BasePart = character.PrimaryPart

		for _, part in self.instance:GetDescendants() do
			if part:IsA("BasePart") then
				part.Massless = true
				part.Anchored = false
			end
		end

		self.instance:PivotTo(hrp.CFrame * CFrame.new(0, 3.5, 0))

		local weld = Instance.new("WeldConstraint", hrp)
		weld.Part0 = hrp
		weld.Part1 = mainPart
		self.weld = weld

		self.player = player
		mainPart:SetNetworkOwner(player)

		self.prompt.Enabled = false
	end)
end

function Car:Throw(direction: Vector3)
	local player: Player = self.player
	local weld: WeldConstraint = self.weld
	local mainPart: BasePart = self.instance.PrimaryPart

	if not player or not weld or self.thrown then return end
	self.thrown = true

	for _, part: BasePart in self.instance:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = false
			part.CollisionGroup = tostring(player.UserId)
		end
	end

	weld:Destroy()
	weld = nil
	self.weld = nil

	mainPart:SetNetworkOwner()

	mainPart:ApplyImpulse(direction * THROW_STRENGTH * mainPart.AssemblyMass)

	player:SetAttribute("Holding_Vehicle", nil)
	self.carValue:Destroy()
	self.carValue = nil

	local hit
	local starttick = tick()
	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = true
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {self.instance}

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.instance}

	while (not hit and tick() - starttick <= 10) and task.wait() do
		local ray = workspace:Raycast(mainPart.Position, mainPart.AssemblyLinearVelocity.Unit * 10, rayParams)

		if ray then
			hit = true
			local parts = workspace:GetPartBoundsInRadius(ray.Position, 15, overlapParams)
			Explosion.Explode(nil, parts, ray.Position)

			for _, weldConstrant: WeldConstraint in self.instance:GetDescendants() do
				if not weldConstrant:IsA("WeldConstraint") and not weldConstrant:IsA("Weld") then continue end

				weldConstrant:Destroy()
			end
		end
	end

	task.delay(1, function()
		self:Destroy()
	end)
end

function Car:Destroy()	
	if self.player and self.carValue and self.carValue.Value == self.instance then
		warn("Setting Nil", self.carValue.Value:GetFullName())
		self.player:SetAttribute("Holding_Vehicle", nil)
	end

	if self.weld then
		self.weld:Destroy()
		self.weld = nil
	end

	if self.instance then
		self.instance:Destroy()
		self.instance = nil
	end

	if self.carValue then
		self.carValue:Destroy()
		self.carValue = nil
	end

	self = nil
end

return Car

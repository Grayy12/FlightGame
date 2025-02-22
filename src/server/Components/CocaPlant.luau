local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tools = ReplicatedStorage.Tools
local CocaTool = Tools.Cocoa
local isStudio = RunService:IsStudio()

local RESPAWN_TIME = isStudio and 0.5 or 10
local PICKUP_TIME = isStudio and 0.5 or 15

local CocaPlant = {
	Tag = "Coca",
}

CocaPlant.__index = CocaPlant

function CocaPlant.new(instance: Model)
	local self = {
		prompt = Instance.new("ProximityPrompt"),
		plant = instance,
		plantBackup = instance:Clone(),
		state = "Planted",
		connection = nil,
	}
	setmetatable(self, CocaPlant)

	self:Init()

	return self
end

function CocaPlant:Init()
	self.prompt.Parent = self.plant
	self.prompt.KeyboardKeyCode = Enum.KeyCode.V
	self.prompt.ObjectText = self.plant.Name
	self.prompt.ActionText = "Pickup"
	self.prompt.HoldDuration = PICKUP_TIME
	self.prompt.RequiresLineOfSight = false

	self.connection = self.prompt.Triggered:Connect(function(player)
		if self.state == "Planted" then
			self.state = "PickedUp"

			local plantTool = CocaTool:Clone()
			plantTool.Parent = player.Backpack

			self.connection:Disconnect()
      self.connection = nil

			self:Respawn()
		end
	end)
end

function CocaPlant:Respawn()
	self:Destroy()

  task.wait(RESPAWN_TIME)

  local newInstance = self.plantBackup:Clone()
	newInstance.Parent = workspace

  self = nil
end

function CocaPlant:Destroy()
  if self.connection and self.connection.Connected then
    self.connection:Disconnect()
  end

  self.connection = nil

  self.plant:Destroy()
end

return CocaPlant

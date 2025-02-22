local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ev_PlaySound: RemoteEvent = ReplicatedStorage.Remote.PlaySound

local Assets = ReplicatedStorage.Assets
local StirringSound = Assets["Water Slosh"]

local IS_STUDIO = RunService:IsStudio()

local States = {
  IDLE = "Idle",
  STIRRING = "Stirring",
  EXTRACTING = "Extracting",
  PICKED_UP = "PickedUp"
}

local StateTransitions = {
  [States.IDLE] = States.STIRRING,
  [States.STIRRING] = States.EXTRACTING,
  [States.EXTRACTING] = States.IDLE,
}

local StateTimes = {
  [States.IDLE] = .5,
  [States.STIRRING] = 10,
  [States.EXTRACTING] = 3,
}

local StateActionText = {
  [States.IDLE] = "Dump Cocoa",
  [States.STIRRING] = "Stir",
  [States.EXTRACTING] = "Extract",
}

local ExtractionBarrel = {
	Tag = "ExtractionBarrel",
}

ExtractionBarrel.__index = ExtractionBarrel

function ExtractionBarrel.new(instance: Model)
	local self = {
		prompt = Instance.new("ProximityPrompt"),
		barrel = instance,
		state = States.IDLE,
		connections = {},
	}
	setmetatable(self, ExtractionBarrel)

	self:Init()

	return self
end

function ExtractionBarrel:_promptTriggered(player): ()
  self:NextState()
end

function ExtractionBarrel:Init()
	self.prompt.Parent = self.barrel
	self.prompt.KeyboardKeyCode = Enum.KeyCode.V
	self.prompt.ObjectText = self.barrel.Name
	self.prompt.ActionText = StateActionText[self.state]
	self.prompt.HoldDuration = StateTimes[self.state]
	self.prompt.RequiresLineOfSight = false

	self:_newConnection(self.prompt.Triggered:Connect(function(player)
    self:_promptTriggered(player)
  end))
end

function ExtractionBarrel:_updateProximityPrompt()
  local newprompt = self.prompt:Clone()
  newprompt.Parent = self.barrel
  self.prompt:Destroy()
  self.prompt = newprompt

  self:_clearConnections()

  self:_newConnection(self.prompt.Triggered:Connect(function(player)
    self:_promptTriggered(player)
  end))
end

function ExtractionBarrel:_newConnection(connection: RBXScriptConnection)
  table.insert(self.connections, connection)
end

function ExtractionBarrel:_clearConnections()
  for _, connection in self.connections do
    if connection and connection.Connected then
      connection:Disconnect()
    end
  end
  self.connections = {}
end

function ExtractionBarrel:NextState()
	self.state = StateTransitions[self.state]
  self.prompt.HoldDuration = StateTimes[self.state]
  self.prompt.ActionText = StateActionText[self.state]

  if self.state == "Stirring" then
    -- self.prompt.Enabled = false

  end

  self:_updateProximityPrompt()
end

function ExtractionBarrel:Destroy()
  self:_clearConnections()

  self.barrel:Destroy()

  self = nil
end

return ExtractionBarrel

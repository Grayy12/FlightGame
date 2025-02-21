local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Loader = require(ReplicatedStorage:WaitForChild('Loader'))
local Component = require(ReplicatedStorage.Component)

Loader._Init(script:GetChildren())
Loader._Start()

Component.Load(script.Components)
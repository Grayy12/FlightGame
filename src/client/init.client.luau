local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Loader = require(ReplicatedStorage:WaitForChild('Loader'))

Loader._Init(script:GetChildren())
Loader._Start()
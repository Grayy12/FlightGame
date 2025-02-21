local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local ev_PlaySound: RemoteEvent = ReplicatedStorage:WaitForChild("Remote").PlaySound

local SoundManager = {}

function SoundManager.Start()
  ev_PlaySound.OnClientEvent:Connect(function(sound, position, distance, volume)
    local soundHolder = Instance.new("Part", workspace.Debris)
    local soundInstance: Sound = sound:Clone()

    soundHolder.CanCollide = false
    soundHolder.Transparency = 1
    soundHolder.Anchored = true
    soundHolder.Position = position
    soundHolder.Size = Vector3.new(0.1, 0.1, 0.1)

    soundInstance.Volume = volume or 1
    soundInstance.Parent = soundHolder
    -- soundInstance.RollOffMinDistance = distance / 2
    soundInstance.RollOffMaxDistance = distance

    if not soundInstance.IsLoaded then
      soundInstance.Loaded:Wait()
    end

    soundInstance:Play()

    soundInstance.Ended:Once(function()
      soundHolder:Destroy()
    end)
  end)
end

return SoundManager